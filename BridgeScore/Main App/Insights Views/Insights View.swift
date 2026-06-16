//
//  Insights View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 27/04/2026.
//

import SwiftUI

enum ScrollViews : CaseIterable, Hashable {
    case heading
    case data
    case scrollIndicator
}

 enum InsightDisplayMode {
     case noData
     case updating
     case loading
     case preparing
     case displaying
     case stopped
     
     var text: String {
         switch self {
         case .noData:
             "No Matching Data"
         case .updating:
             "Refreshing Data..."
         case .loading:
             "Loading Data..."
         case .preparing:
             "Preparing View..."
         case .stopped:
             "View Stopped"
         default:
             ""
         }
     }
}

struct InsightsView: View {
    @Environment(\.dismiss) var dismiss
    @State var allBoardSummaries: [BoardSummaryExtension] = []
    @State var boardSummaries: [BoardSummaryExtension] = []
    @State var unfilteredIndex: [SortData] = []
    @State var filteredIndex: [SortData] = []
    @StateObject var report = Report()
    @State var showBoardSummary: BoardSummaryExtension? = nil
    @State var dismissView: Bool = false
    @State var buttonId: [UUID:UUID] = [:]
    @State fileprivate var displayMode: InsightDisplayMode = .loading
    @State fileprivate var isEditing: Bool = false
    @State var showPrompts: Bool = false
    @State var showLoad: Bool = false
    @StateObject private var scrollSync = ScrollSync<ScrollViews>()
    @State var activeColumn: Int? = nil
    @State var horizontalScroll: Bool = false
    @State var scrollWidth: CGFloat = 0
    @State var lowestTotalLevel: [SortTotalType:Int] = [:] // Dictionary contains lowest level for axis
    @State var gridColumns: Int = 1
    @State var gridPrefixes: [String] = []
    @State var gridTotals: [SortData] = []
    @State var gridRowExpanded: SortData? = nil
    let rowHeight: CGFloat = 30
    
    var body: some View {
        StandardView("Insights") {
            GeometryReader { geometry in
                ZStack {
                    // Header overlay
                    VStack(spacing: 0) {
                        Rectangle()
                            .frame(height: 90 + geometry.safeAreaInsets.top)
                            .foregroundColor(Palette.contrastTile.background)
                            .ignoresSafeArea()
                        Spacer()
                    }
                    
                    toolBarView()
                        .zIndex(99)
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height: 10)
                        // Header
                        HStack(alignment: .top, spacing: 0) {
                            headerView(columns: report.values.pinnedColumns, pinned: true)
                                .zIndex(1)
                            HorizontalScrollView(id: .heading, widths: unpinnedWidths + [spacerWidth], scrollSync: scrollSync, activeColumn: $activeColumn) {
                                headerView(columns: report.values.unpinnedColumns, pinned: false)
                            }
                        }
                        .frame(height: 80)
                        switch displayMode {
                        case .updating, .loading, .preparing, .stopped, .noData:
                            MiddleCenteredText(text: displayMode.text)
                                .font(bigFont)
                                .palette(.background, .theme)
                        default:
                            // Main values
                            ScrollViewReader { proxy in
                                ScrollView(.vertical) {
                                    VStack(spacing: 0) {
                                        HStack(spacing: 0) {
                                            HStack {
                                                LazyVStack(alignment: .leading, spacing: 0) {
                                                    ForEach($filteredIndex, id: \.id) { rowData in
                                                        rowView(data: rowData, columns: report.values.pinnedColumns, pinned: true)
                                                            .zIndex(1)
                                                    }
                                                }
                                                .frame(width: report.values.pinnedColumns.map{$0.width}.reduce(0, +) + 40)
                                            }
                                            HorizontalScrollView(id: .data, widths: unpinnedWidths + [spacerWidth], scrollSync: scrollSync, activeColumn: $activeColumn) {
                                                LazyVStack(alignment: .leading, spacing: 0) {
                                                    ForEach($filteredIndex, id: \.id) { rowData in
                                                        rowView(data: rowData, columns: report.values.unpinnedColumns, pinned: false)
                                                            .id(rowData.id)
                                                    }
                                                }
                                            }
                                        }
                                        Color.black.frame(height: 3)
                                    }
                                }
                                .ignoresSafeArea(edges: .bottom)
                            }
                            VStack {
                                HStack{
                                    HStack {
                                        spacerView(columns: report.values.pinnedColumns, pinned: true)
                                    }
                                    HorizontalScrollView(showsIndicators: true, id: .scrollIndicator, widths: unpinnedWidths + [spacerWidth], scrollSync: scrollSync, activeColumn: $activeColumn) {
                                        spacerView(columns: report.values.unpinnedColumns, pinned: false)
                                            .zIndex(1)
                                    }
                                    .onScrollGeometryChange(for: Bool.self) { geometry in
                                        geometry.contentSize.width > geometry.containerSize.width
                                    } action: { _, scroll in
                                        horizontalScroll = scroll
                                    }
                                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                                        geometry.containerSize.width
                                    } action: { [self] (_, newScrollWidth) in
                                        scrollWidth = newScrollWidth
                                    }
                                }
                                Spacer()
                            }
                            .frame(height: horizontalScroll ? 20 : 0)
                            .ignoresSafeArea(edges: .bottom)
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .fullScreenCover(isPresented: $isEditing) {
                    showSetup(frame: geometry.frame(in: .global))
                }
                .fullScreenCover(item: $showBoardSummary, onDismiss: {
                    if let scorecard = Scorecard.current.scorecard {
                        Scorecard.current.saveAll(scorecard: scorecard)
                        Scorecard.current.clear()
                    }
                }, content: { boardSummary in
                    showDetails(boardSummary: boardSummary, frame: geometry.frame(in: .global))
                })
                .sheet(isPresented: $showPrompts) {
                    InsightsPromptEntryView(report: report) { (run) in
                        if run {
                            runReport()
                        } else {
                            displayMode = .stopped
                        }
                    }
                }
                .sheet(isPresented: $showLoad) {
                    InsightsReportViewStorageLoadDialog(report: report, forceDismiss: true, clearPrevious: {
                        // Need to clear view
                        displayMode = .loading
                        filteredIndex = []
                    }, completion: {
                        if !report.values.prompts.isEmpty {
                            showLoad = false
                            showPrompts = true
                        } else {
                            runReport()
                        }
                    })
                }
                .allowsHitTesting(!isEditing && !showPrompts && showBoardSummary == nil)
            }
            
        }
        .onAppear {
            Task {
                loadDefaultView()
                await loadData()
            }
        }
    }
    
    func runReport() {
        displayMode = .preparing
        unfilteredIndex = []
        filteredIndex = []
        Task(priority: .userInitiated) {
            if let errorMessage = await reload() {
                MessageBox.shared.show(errorMessage)
            }
            await MainActor.run {
                displayMode = filteredIndex.isEmpty ? .noData : .displaying
            }
        }
    }
    
    func toolBarView() -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                HStack {
                    Spacer()
                    
                    Text("Insights - \(report.values.viewName)")
                    
                    Spacer()
                }
                    HStack {
                        Spacer()
                        if !report.values.prompts.isEmpty {
                            Button("\(Image(systemName: "slider.horizontal.3"))") {
                                displayMode = .loading
                                unfilteredIndex = []
                                filteredIndex = []
                                showPrompts = true
                            }
                            Spacer().frame(width: 40)
                        }
                        
                        Button("\(Image(systemName: "square.and.pencil"))") {
                            isEditing = true
                        }
                        
                        Spacer().frame(width: 40)
                        
                        Button("\(Image(systemName: "menubar.arrow.down.rectangle"))") {
                            showLoad = true
                        }
                        
                        Spacer().frame(width: 40)
                        
                        Button("\(Image(systemName: "xmark"))") {
                            dismiss()
                        }
                        .keyboardShortcut(.cancelAction)
                        .disabled(isEditing)
                        
                        Spacer()
                            .frame(width: 20)
                    }
                }
                .frame(height: 30)
                Spacer()
                Separator(direction: .horizontal, thickness: 2)
            }
            .frame(height: 40)
            .font(bannerFont)
            .palette(.contrastTile)
            .ignoresSafeArea()
            Spacer()
        }
    }
    
    func headerView(columns: [InsightColumn], pinned: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 0) {
                if pinned {
                    Color.clear.frame(width: 20)
                }
                ForEach(0..<(pinned ? 1 : gridColumns) * columns.count, id: \.self) { combinedIndex in
                    let gridColumnIndex = combinedIndex / columns.count
                    let columnIndex = combinedIndex % columns.count
                    let column = columns[columnIndex]
                    HStack(spacing: 0) {
                        if column.align != .left {
                            Spacer()
                        }
                        let prefix = (pinned || gridColumnIndex > gridPrefixes.count - 1 ? "" : gridPrefixes[gridColumnIndex])
                        Text("\(prefix == "" ? "" : "\(prefix) ")\(column.title)")
                            .lineLimit(nil)
                            .multilineTextAlignment(column.align.textAlignment)
                        if column.align != .right {
                            Spacer()
                        }
                    }
                    .frame(width: column.width)
                }
                if !pinned {
                    Color.clear.frame(width: spacerWidth)
                        .debugPrint("\(spacerWidth) \(scrollWidth) \(unpinnedTotalWidth)")
                } else {
                    Color.clear.frame(width: 20)
                }
            }
            .frame(height: 70)
            Spacer().frame(height: 10)
        }
        .frame(height: 80)
        .palette(.contrastTile)
    }
    
    func rowView(data: Binding<SortData>, columns: [InsightColumn], pinned: Bool) -> some View {
        let level = data.wrappedValue.yTotalLevel
        return HStack(spacing: 0) {
            if data.wrappedValue.yTotalLevel == nil {
                rowViewData(data: data, boardSummary: (data.source.wrappedValue as BoardSummaryExtension?)!, columns: columns, pinned: pinned)
            } else if pinned {
                rowViewTotalHeading(data: data, columns: columns)
            } else {
                rowViewTotalValues(data: data, columns: columns)
            }
        }
        .palette(rowColor(level: level, bottomGridRow: (report.values.gridMode && level == report.yLevels.count)))
    }
    
    func rowViewData(data: Binding<SortData>, boardSummary: BoardSummaryExtension, columns: [InsightColumn], replaceTotal: Bool = false, pinned: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            if pinned {
                Color.clear.frame(width: 20, height: rowHeight)
            }
            ForEach(0..<(pinned ? 1 : gridColumns) * columns.count, id: \.self) { combinedIndex in
                let gridColumnIndex = combinedIndex / columns.count
                let columnIndex = combinedIndex % columns.count
                let column = columns[columnIndex]
                HStack {
                    if !pinned && report.values.gridMode && columnIndex == 0 {
                        line(gridIndex: gridColumnIndex, allLines: columns.count > 1)
                    }
                    if column.align != .left {
                        Spacer()
                    }
                    if column.visibility.isInBoard && isInColumn(index: gridColumnIndex, sortData: data.wrappedValue) {
                        Text(column.textValue(report: report, boardSummary: boardSummary))
                    } else {
                        Text("")
                    }
                    if column.align != .right {
                        Spacer()
                    }
                    if !pinned && report.values.gridMode && combinedIndex == gridColumns * columns.count - 1 {
                        line(gridIndex: 0)
                    }
                }
                .frame(width: column.width, height: rowHeight)
            }
            if !pinned {
                Color.clear.frame(width: spacerWidth, height: rowHeight)
            } else {
                Color.clear.frame(width: 20, height: rowHeight)
            }
        }
        .contentShape(Rectangle())
        .help("\(boardSummary.scorecard.desc)\nDate: \(Utility.dateString(boardSummary.scorecard.date, format: "dd/MM/yyyy"))\nLocation: \(boardSummary.location!.name)\nPartner: \(boardSummary.partner!.name)\nBoard: \(boardSummary.boardNumber) of \(boardSummary.scorecard.boards)")
        .onTapGesture {
            if loadDetails(boardSummary: boardSummary) {
                showBoardSummary = boardSummary
            }
        }
    }
    
    func isInColumn(index: Int, sortData: SortData) -> Bool {
        !report.values.gridMode || (gridTotals[index].xKeys == Array(sortData.xKeys.prefix(gridTotals[index].xTotalLevel!)))
    }
    
    func rowViewTotalHeading(data: Binding<SortData>, columns: [InsightColumn], replaceTotal: Bool = false,) -> some View {
        HStack(spacing: 0) {
            let width = columns.map({$0.width}).reduce(0,+) + 40
            let bottomGridLevel = (report.values.gridMode && data.wrappedValue.yTotalLevel == report.yLevels.count)
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Spacer().frame(width: CGFloat(data.wrappedValue.yTotalLevel! * 20))
                    HStack(spacing: 0) {
                        Image(systemName: data.wrappedValue.state == .expanded ? "minus" : "plus")
                            .id(buttonId[data.wrappedValue.id, default: UUID()])
                            .frame(width: 30, height: rowHeight)
                            .background(Color.clear)
                            .contentShape(Rectangle())
                    }
                    .frame(width: 30)
                    Text(data.wrappedValue.yTotalLevel == 0 ? "Grand Total" : "\(bottomGridLevel ? "" : "Total for " )\(data.wrappedValue.levelKey!)")
                    Spacer()
                }
                .debugPrint("Total Heading \(width)")
                .bold()
            }
            .frame(width: width, height: rowHeight)
            .fixedSize()
        }
        .onTapGesture {
            buttonId[data.wrappedValue.id, default: UUID()] = UUID()
            let newState = data.wrappedValue.state.inverse
            data.wrappedValue.state = newState
            if newState == .expanded && report.values.gridMode && data.wrappedValue.yTotalLevel == lowestTotalLevel[.yAxis]! {
                // Only allow one bottom row to be expanded in grid mode
                gridRowExpanded?.state = .collapsed
                gridRowExpanded = data.wrappedValue
            } else if newState == .collapsed && gridRowExpanded == data.wrappedValue {
                gridRowExpanded = nil
            }
            filterData()
        }
        .onAppear {
            buttonId[data.wrappedValue.id] = UUID()
        }
    }
    
    func rowViewTotalValues(data: Binding<SortData>, columns: [InsightColumn], replaceTotal: Bool = false) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<(gridColumns * columns.count), id: \.self) { combinedIndex in
                let gridColumnIndex = combinedIndex / columns.count
                let columnIndex = combinedIndex % columns.count
                let gridColumn = data.wrappedValue.linked.isEmpty ? data.wrappedValue : data.wrappedValue.linked[gridColumnIndex]
                let column = columns[columnIndex]
                HStack(spacing: 0) {
                    if report.values.gridMode && columnIndex == 0 {
                        line(gridIndex: gridColumnIndex, allLines: columns.count > 1)
                    }
                    if column.align != .left {
                        Spacer()
                    }
                    if let total = gridColumn.total(column: column), let value = total.value, let count = total.count {
                        let showValue = column.totalValue(value: value, count: count)
                        if column.insightType == .percent {
                            Text((showValue * Float(100)).toString(places: column.decimalPlaces) + "%")
                        } else {
                            Text(showValue.toString(places: column.decimalPlaces))
                        }
                    } else {
                        Text("")
                    }
                    if column.align != .right {
                        Spacer()
                    }
                    if report.values.gridMode && combinedIndex == gridColumns * columns.count - 1 {
                        line(gridIndex: 0)
                    }
                }
                .bold()
                .frame(width: column.width, height: rowHeight)
                .fixedSize()
                .padding(.horizontal, 0)
            }
            Color.clear.frame(width: spacerWidth, height: rowHeight)
        }
    }
    
    func line(gridIndex: Int, allLines: Bool = false) -> some View {
        HStack(spacing: 0) {
            if gridIndex == 0 || gridTotals[gridIndex - 1].xTotalLevel != gridTotals[gridIndex].xTotalLevel || allLines {
                let level = (gridIndex == 0 ? gridTotals[gridIndex].xTotalLevel! : min(gridTotals[gridIndex - 1].xTotalLevel!, gridTotals[gridIndex].xTotalLevel!))
                let thickness = (lowestTotalLevel[.xAxis]! + (allLines ? 1 : 0) - level)
                Color.black.frame(width: CGFloat(thickness), height: rowHeight)
            }
        }
    }
    
    func spacerView(columns: [InsightColumn], pinned: Bool) -> some View {
        HStack(spacing: 0) {
            let totalcolumnWidth = columns.map{$0.width}.reduce(0,+)
            let width = (CGFloat(pinned	 ? 1 : gridColumns) *  totalcolumnWidth) + (pinned ? 40 : spacerWidth)
            Color.clear.frame(width: width, height: horizontalScroll ? 15 : 0)
        }
    }
    
    var unpinnedWidths: [CGFloat] {
        let widths = report.values.unpinnedColumns.map({$0.width})
        var result: [CGFloat] = []
        for _ in 0..<gridColumns {
            result.append(contentsOf: widths)
        }
        return result
    }
    
    var unpinnedTotalWidth : CGFloat {
        unpinnedWidths.reduce(0,+)
    }
    
    var spacerWidth: CGFloat {
        // Width of padding when unpinned scroll view isn't full
        max(30, scrollWidth - unpinnedTotalWidth)
    }
    
    func rowColor(level: Int?, bottomGridRow: Bool) -> ThemeBackgroundColorName {
        if bottomGridRow {
            .background
        } else {
            switch level {
            case nil:
                (report.values.gridMode ? .gridDetail : .background)
            case 0:
                    .grandTotal
            case 1:
                    .subtotal1
            case 2:
                    .subtotal2
            default:
                    .subtotal3
            }
        }
    }
    
    func showDetails(boardSummary: BoardSummaryExtension, frame: CGRect) -> some View {
        let width = min(1400, frame.width) // Allow for safe area
        let height = min(1024, (frame.height))
        let frame = CGRect(x: (frame.width - width) / 2,
                           y: ((frame.height - height) / 2),
                           width: width,
                           height: height)
        return ZStack{
            Color.black.opacity(0.4)
            AnalysisViewer(board: boardSummary.board!, traveller: boardSummary.traveller!, sitting: boardSummary.seat!, frame: frame, initialYOffset: frame.height + 100, dismissView: $dismissView)
        }
        .background(BackgroundBlurView(opacity: 0.0))
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
            dismissView = true
        }
    }
    
    func showSetup(frame: CGRect) -> some View {
        let width = min(1600, frame.width) // Allow for safe area
        let height = min(max(1024, frame.height - 10), (frame.height))
        return ZStack{
            Color.black.opacity(0.4)
            InsightsSetupView(report: report, data: boardSummaries.first, dismissView: $dismissView, completion: runReport)
                .frame(width: width, height: height)
        }
        .background(BackgroundBlurView(opacity: 0.0))
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
            dismissView = true
        }
    }
    
    func loadDetails(boardSummary: BoardSummaryExtension) -> Bool {
        let scorecard = boardSummary.scorecard
        Scorecard.current.clear()
        Scorecard.current.load(scorecard: scorecard)
        if boardSummary.board == nil || boardSummary.traveller == nil || boardSummary.seat == nil {
            if let (board, traveller, seat) = Scorecard.getBoardTraveller(boardIndex: boardSummary.boardIndex, equivalentSeat: false) {
                boardSummary.board = board
                boardSummary.traveller = traveller
                boardSummary.seat = seat
                return true
            } else {
                boardSummary.board = nil
                boardSummary.traveller = nil
                boardSummary.seat = nil
                Scorecard.current.clear()
                return false
            }
        } else {
            return true
        }
    }
    
    func filterData() {
        let filtered = unfilteredIndex.filter{ showRow(row: $0) }
        filteredIndex = filtered
    }
    
    func showRow(row: SortData) -> Bool {
        var show = true
        if row.cellType == .total && row.state == .hidden {
            // Non-subtotalled total
            show = false
        } else {
            // Check all levels above
            var current: SortData? = row.yTotalCell
            repeat {
                if current?.cellType == .total {
                    show = (current?.state != .collapsed)
                }
                current = current?.yTotalCell
            } while show && current != nil
        }
        return show
    }
    
    func loadDefaultView() {
        let defaultUrl = InsightsReportViewStorage.url(for: UserDefault.defaultViewName.string)
        if !InsightsReportViewStorage.load(report: report, from: defaultUrl) {
            do {
                try InsightsReportViewStorage.createEmptyView(report: report)
            } catch {
                // Just ignore for now
                print(error)
            }
        }
    }
    func loadData() async {
        // Load master data
        displayMode = .updating
        await Insights.update()
        await allBoardSummaries = Insights.load()
        if !report.values.prompts.isEmpty {
            showPrompts = true
        } else {
            runReport()
        }
    }
     
    func reload() async -> String? {
        var sortIndex: [SortData] = []
        var recalculationIndexes: [String:Int] = [:]
        var errorMessage: String? = nil
        let axisTypes = [SortTotalType.yAxis, .xAxis]
        let levels: [SortTotalType:[CalculatedSortLevel]] = [.xAxis: report.xLevels, .yAxis: report.yLevels]
        var cellTotals: [[CalculatedValue]:[[CalculatedValue]:SortData]] = [:]
        var rowTotals: [[CalculatedValue]:[SortData]] = [:]
        var axisTotals: [SortTotalType:[Int:[SortData]]] = [:] // [axis:[level:[Totals]]]
        let filterService = DataFilterService()
        var referenced: Set<InsightColumn> = []
        let sortDirections = levels.mapValues{ $0.map{$0.direction} }
        lowestTotalLevel = levels.mapValues { $0.count }
        gridRowExpanded = nil
        
        do {
            // Refresh report
            try report.refresh(includePrompts: false)
            
            // Filter at bottom level
            boardSummaries = await filterService.filterData(report: report, allBoardSummaries: allBoardSummaries)
            
            // Generate recalculation indexes to work out sequence to recalculate totals in
            recalculationIndexes = try report.generateRecalculationIndexes()
            
            // Build sort index
            for boardSummary in boardSummaries {
                var sortKeys: [SortTotalType:[CalculatedValue]] = [:]
                for axis in axisTypes {
                    sortKeys[axis] = []
                    for level in levels[axis]! {
                        let value = try level.key!.sortValue(report: report, viewModel: boardSummary)
                        sortKeys[axis]!.append(value)
                    }
                }
                // Add row to index
                sortIndex.append(SortData(cellType: .data, xKeys: sortKeys[.xAxis]!, yKeys: sortKeys[.yAxis]!, source: boardSummary))
            }
            
            if !sortIndex.isEmpty {
                
                // Execute the sort
                try sortIndex.sort(by: { try SortIndex.sort($0, $1, directions: sortDirections[.xAxis]! + sortDirections[.yAxis]!)})
                
                // Build totals and sub-totals
                
                // Build a list of columns referenced in totals
                referenced = try report.referencedColumns.filter{$0.visibility != .none && $0.visibility != .boardOnly}
                
                // Build a grid of the bottom level totals for each cell
                var axisTotalDictionaries: [SortTotalType:[[CalculatedValue]:SortData]] = [:] // [axis:[keys:Totals]]
                var runningTotals = SortTotals()
                var currentCell: SortData? = nil
                
                for (boardIndex, sortElement) in sortIndex.enumerated() {
                    // Set up current total cell if necessary
                    currentCell = currentCell ?? SortData(cellType: .total,totalType: .cell, xTotalLevel: lowestTotalLevel[.xAxis], yTotalLevel: lowestTotalLevel[.yAxis], xKeys: sortElement.xKeys, yKeys: sortElement.yKeys, source: sortElement.source, firstIndex: boardIndex)
                    
                    // Insert upward pointers
                    sortElement.set(totalCell: currentCell)
                    
                    // Add current data to totals
                    try referenced.forEach { column in
                        let numeric = try getValue(sortElement: sortElement, column: column)
                        runningTotals.add(column: column, value: numeric)
                    }
                    
                    if (boardIndex == sortIndex.count - 1) || (sortElement.xKeys != sortIndex[boardIndex + 1].xKeys) || (sortElement.yKeys != sortIndex[boardIndex + 1].yKeys) {
                        
                        // Last for these keys - save it
                        currentCell!.set(totals: runningTotals)
                        currentCell!.lastIndex = boardIndex
                        cellTotals[sortElement.yKeys, default: [:]][sortElement.xKeys] = currentCell!
                        rowTotals[sortElement.yKeys, default: []].append(currentCell!)
                        
                        // Now add it to row and column totals
                        for axis in axisTypes {
                            if !levels[axis]!.isEmpty {
                                if let totalCell = axisTotalDictionaries[axis]?[sortElement.keys(axis: axis)] {
                                    // Add to existing total
                                    totalCell.add(totals: runningTotals)
                                } else {
                                    // Start a new total
                                    let newTotal = currentCell!.copy(totalType: axis, totalLevel: lowestTotalLevel[axis]!, totals: runningTotals, state: levels[axis]![lowestTotalLevel[axis]! - 1].combinedState)
                                    axisTotalDictionaries[axis, default: [:]][currentCell!.keys(axis: axis)] = newTotal
                                }
                                currentCell!.set(totalCell: axisTotalDictionaries[axis]![sortElement.keys(axis: axis)]!, axis: axis)
                            }
                        }
                        
                        // Zero running totals
                        currentCell = nil
                        runningTotals = SortTotals()
                    }
                }
                
                // Convert dictionaries for row/column totals to arrays and sort
                for axis in axisTypes {
                    if axisTotalDictionaries[axis] == nil {
                        axisTotals[axis] = [:]
                    } else {
                        axisTotals[axis, default: [:]][lowestTotalLevel[axis]!] = try axisTotalDictionaries[axis]!.values.sorted(by: { try SortIndex.sort($0, $1, directions: sortDirections[axis]!)})
                    }
                }
                
                // Starting from lowest level, work up recalculating and then discarding any totals that fail selection
                // Then summarise at next level up
                for axis in axisTypes {
                    // Need to do x-axis simply to remove any columns which fail sub-total selection
                    if !axisTotals[axis]!.isEmpty {
                        for levelIndex in (-1..<lowestTotalLevel[axis]!).reversed() {
                            
                            // Recalculate the last level totals added and discard if fail total selection
                            if let levelTotals = axisTotals[axis]?[levelIndex + 1], !levelTotals.isEmpty {
                                for (index, total) in axisTotals[axis]![levelIndex + 1]!.enumerated().reversed() {
                                    
                                    try recalculate(total: total) { column, value in
                                        axisTotals[axis]![levelIndex + 1]![index].set(column: column, value: value)
                                    }
                                    
                                    if levelIndex >= 0 {
                                        // Discard if necessary
                                        let discarded = try applySubtotalSelection(total: total)
                                        if discarded {
                                            // Remove it - note this might still be pointed to by subsidiary data, but not a problem as won't be working up to it
                                            axisTotals[axis]![levelIndex + 1]!.remove(at: index)
                                        } else {
                                            // Set the level key
                                            total.levelKey = levels[axis]![levelIndex].key!.textValue(report: report, boardSummary: total.source!)
                                        }
                                    }
                                }
                            }
                            
                            if levelIndex >= 0 {
                                // Create next level up
                                var runningTotals = SortTotals()
                                var currentTotal: SortData? = nil
                                let totals = axisTotals[axis]![levelIndex + 1]!
                                for (index, total) in totals.enumerated() {
                                    // Setup total if necessary
                                    currentTotal = currentTotal ?? total.copy(totalType: axis, totalLevel: levelIndex, firstIndex: index, state: levelIndex == 0 ? .expanded : levels[axis]![levelIndex - 1].defaultState)
                                    
                                    // Point up to new next level
                                    total.set(totalCell: currentTotal)
                                    
                                    // Add current to running totals
                                    runningTotals.add(totals: total.totals)
                                    
                                    if index == axisTotals[axis]![levelIndex + 1]!.count - 1 || total.keys(axis: axis).prefix(levelIndex) != totals[index + 1].keys(axis: axis).prefix(levelIndex) {
                                        // Key is about to change - store this total and start a new one
                                        currentTotal!.set(totals: runningTotals)
                                        currentTotal!.lastIndex = index
                                        axisTotals[axis]![levelIndex, default: []].append(currentTotal!)
                                        // Zero totals
                                        currentTotal = nil
                                        runningTotals = SortTotals()
                                    }
                                }
                            }
                        }
                    }
                }
                // Set gridColumns
                recalculateGrid()
                // Now build output list (recursively)
                unfilteredIndex = []
                if let grandTotal = axisTotals[.yAxis]?[0]?.first {
                    try addToUnfilteredIndex(element: grandTotal)
                }
            }
            
            filterData()
            
        } catch let error as CalculatedError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Unknown error: \(error)"
        }
        if let errorMessage = errorMessage {
            MessageBox.shared.show(errorMessage)
        }
        
        return errorMessage
        
        func recalculateGrid() {
            gridColumns = max(1, axisTotals[.xAxis]!.values.map{$0.count}.reduce(0,+))
            if report.values.gridMode {
                gridTotals = recurseTotals(xElement: axisTotals[.xAxis]![0]!.first!)
                for total in gridTotals {
                    let xKeys = total.xKeys
                    if xKeys.isEmpty {
                        gridPrefixes.append("Total")
                    } else {
                        var words: [String] = []
                        for key in xKeys {
                            let components = key.text.split(separator: " ")
                            if components.isEmpty {
                                words.append("Blank")
                            } else {
                                words.append(String(components.first!))
                            }
                        }
                        gridPrefixes.append(words.joined(separator: " "))
                    }
                }
            } else {
                gridPrefixes = []
            }
        }
        
        func recurseTotals(xElement: SortData) -> [SortData] {
            if xElement.cellType == .total {
                let level = xElement.xTotalLevel!
                var result = [xElement]
                if level < lowestTotalLevel[.xAxis]! {
                    // A higher level total/subtotal - add next lower level
                    for index in xElement.firstIndex!...xElement.lastIndex! {
                        result.append(contentsOf: recurseTotals(xElement: axisTotals[.xAxis]![level + 1]![index]))
                    }
                }
                return result
            } else {
                return []
            }
        }
        
        func addToUnfilteredIndex(element: SortData) throws {
            // Adds y axis to the main index recursively
            unfilteredIndex.append(element)
            if element.cellType == .total {
                let level = element.yTotalLevel!
                if level < lowestTotalLevel[.yAxis]! {
                    // A higher level total/subtotal - add next lower level
                    for index in element.firstIndex!...element.lastIndex! {
                        try addToUnfilteredIndex(element: axisTotals[.yAxis]![level + 1]![index])
                    }
                } else if report.values.gridMode {
                    // A bottom level total of a grid - add in the records
                    let row = rowTotals[element.yKeys]!
                    for cell in row {
                        for index in cell.firstIndex!...cell.lastIndex! {
                            try addToUnfilteredIndex(element: sortIndex[index])
                        }
                    }
                } else  {
                    // A bottom level total of a non-grid - add in the records
                    for index in element.firstIndex!...element.lastIndex! {
                        try addToUnfilteredIndex(element: sortIndex[index])
                    }
                }
                if report.values.gridMode {
                    // Grid - add in the linked elements
                    try addToLinkedData(yElement: element, xElement: axisTotals[.xAxis]![0]!.first!)
                }
            }
        }
        
        func addToLinkedData(yElement: SortData, xElement: SortData) throws {
            // Adds x axis to the linked values for a y axis element, calculating values as we go
            let xTotal = try calculateLinkedValues(yElement: yElement, xElement: xElement)
            yElement.linked.append(xTotal)
            if xElement.cellType == .total {
                let level = xElement.xTotalLevel!
                if level < lowestTotalLevel[.xAxis]! {
                    // A higher level total/subtotal - add next lower level
                    for index in xElement.firstIndex!...xElement.lastIndex! {
                        try addToLinkedData(yElement: yElement, xElement: axisTotals[.xAxis]![level + 1]![index])
                    }
                }
            }
        }
        
        func calculateLinkedValues(yElement: SortData, xElement: SortData) throws -> SortData {
            let result = xElement.copy(totals: SortTotals())
            result.totalType = .compound
            result.yTotalLevel = yElement.yTotalLevel
            result.xTotalLevel = xElement.xTotalLevel
            result.yTotalCell = yElement.yTotalCell
            result.xTotalCell = xElement.xTotalCell
            result.yKeys = yElement.yKeys
            result.xKeys = xElement.xKeys
            result.firstIndex = 0
            result.lastIndex = 0
            result.levelKey = ""
            
            // Now add up cell totals for all levels below
            let yKeys = iterate(element: yElement, axis: .yAxis)
            let xKeys = iterate(element: xElement, axis: .xAxis)
            for yKey in yKeys {
                for xKey in xKeys {
                    if let cell = cellTotals[yKey]?[xKey] {
                        result.add(totals: cell.totals)
                    }
                }
            }
            

            try recalculate(total: result) { column, value in
                if result.total(column: column) != nil {
                    result.set(column: column, value: value)
                }
            }
            
            return result
        }
        
        func iterate(element: SortData, axis: SortTotalType) -> [[CalculatedValue]] {
            var result: [[CalculatedValue]] = []
            let level = element.totalLevel!
            if level == lowestTotalLevel[axis] {
                result.append(element.keys(axis: axis))
            } else {
                for index in element.firstIndex!...element.lastIndex! {
                    result.append(contentsOf: iterate(element: axisTotals[axis]![level+1]![index], axis: axis))
                }
            }
            return result
        }
        
        func applySubtotalSelection(total: SortData) throws -> Bool {
            let level = total.totalLevel!
            return try !levels[total.totalType!]![level - 1].value(report: report, viewModel: total.source!, level: level, evaluate: evaluateColumn)
            
            func evaluateColumn(boardSummary: BoardSummaryExtension, column: InsightColumn) throws -> CalculatedValue? {
                if let total = total.total(column: column), let value = total.value {
                    return CalculatedValue(value)
                } else {
                    return try column.insightValue(report: report, boardSummary: boardSummary)
                }
            }
        }
        
        func recalculate(total: SortData, update: (InsightColumn, Float)->()) throws {
            for column in referenced.filter({$0.isPrompt}) {
                if case .prompt(let prompt) = column {
                    // Prompts are always effectively recalculated - i.e. have a constant value
                    if let value = prompt.value, value.isNumeric {
                        update(column, value.numeric!)
                    }
                }
            }
            for column in referenced.filter({$0.isCalculated}).sorted(by: { (recalculationIndexes[$0.calculatedColumn!.name] ?? 0) < (recalculationIndexes[$1.calculatedColumn!.name] ?? 0)}) {
                if case .calculated(let calculated) = column {
                    if calculated.recalculate {
                        if let newValue = try recalculateValue(total: total, column: column, boardSummary: total.source!) {
                            update(column, newValue.numeric!)
                        } else {
                            throw CalculatedError.errorEvaluatingCalculatedColumn(column.title)
                        }
                    }
                }
            }
        }
        
        func recalculateValue(total: SortData, column: InsightColumn, boardSummary: BoardSummaryExtension) throws -> CalculatedValue? {
            var result: CalculatedValue?
            if case .calculated(let calculated) = column {
                result = try calculated.value(report: report, viewModel: boardSummary, evaluate: recalculateEvaluate)
            }
            return result
            
            func recalculateEvaluate(report: Report, boardSummary: BoardSummaryExtension, column: InsightColumn) throws -> CalculatedValue? {
                // Get value for totals rather than from the view model
                if let value = total.total(column: column)?.value {
                    return CalculatedValue(value)
                } else {
                    return try column.insightValue(report: report, boardSummary: boardSummary)
                }
            }
        }
        
        func getValue(sortElement: SortData, column: InsightColumn) throws -> Float {
            let value = try column.totalValue(report: report, viewModel: sortElement.source!)
            let numeric =
            if value.isBoolean {
                Float(value.boolean! ? 1 : 0)
            } else if value.isNumeric{
                value.numeric!
            } else {
                Float(0)
            }
            return numeric
        }
    }
}

actor DataFilterService {
    func filterData(report: Report, allBoardSummaries: [BoardSummaryExtension]) -> [BoardSummaryExtension] {
        // This entire synchronous operation runs safely off the main thread
        return allBoardSummaries.filter({selectRow(boardSummary: $0)})
        
        func selectRow(boardSummary: BoardSummaryExtension) -> Bool {
            var show = true
            let selections = report.values.levels.filter({$0.levelType == .board})
            for index in 0..<selections.count {
                do {
                    if try !selections[index].value(report: report, viewModel: boardSummary, level: 0, evaluate: evaluateColumn) {
                        show = false
                    }
                } catch {
                    show = false // TODO Need to handle better
                }
            }
            return show
            
            func evaluateColumn(boardSummary: BoardSummaryViewModel, column: InsightColumn) throws -> CalculatedValue? {
                return try column.insightValue(report: report, boardSummary: boardSummary)
            }
        }
    }
}

class InsightTotal : Comparable {
    var count: Int?
    var value: Float?
    
    init() {
    }
    
    convenience init(from: InsightTotal) {
        self.init()
        self.count = from.count
        self.value = from.value
    }
    
    func add(value: Float) {
        self.count = (self.count ?? 0) + 1
        self.value = (self.value ?? 0) + value
    }
    
    func add(total: InsightTotal) {
        self.count = (self.count ?? 0) + (total.count ?? 0)
        self.value = (self.value ?? 0) + (total.value ?? 0)
    }
    
    func set(value: Float) {
        self.value = value
    }
    
    func subtract(_ reduction: InsightTotal) {
        count = (count ?? 0) - (reduction.count ?? 0)
        value = (value ?? 0) - (reduction.value ?? 0)
    }
    
    static func < (lhs: InsightTotal, rhs: InsightTotal) -> Bool {
        (lhs.value ?? 0) < (rhs.value ?? 0)
    }
    
    static func == (lhs: InsightTotal, rhs: InsightTotal) -> Bool {
        (lhs.value ?? 0) == (rhs.value ?? 0)
    }
    
    func copy(from: InsightTotal) {
        count = from.count
        value = from.value
    }
}

