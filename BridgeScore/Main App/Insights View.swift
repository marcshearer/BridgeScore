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
     case building
     case loading
     case preparing
     case displaying
     case stopped
     
     var text: String {
         switch self {
         case .building:
             "Building Data..."
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
    @State var sortIndex: [SortData<BoardSummaryExtension,InsightTotal>] = []
    @State var filteredIndex: [SortData<BoardSummaryExtension,InsightTotal>] = []
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
    let rowHeight: CGFloat = 30
    
    var body: some View {
        StandardView("Insights") {
            GeometryReader { geometry in
                ZStack {
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
                        HStack(alignment: .top, spacing: 0) {
                            headerView(columns: report.values.pinnedColumns, pinned: true)
                                .zIndex(1)
                            HorizontalScrollView(id: .heading, widths: report.values.unpinnedSpacerColumns.map{$0.width}, scrollSync: scrollSync, activeColumn: $activeColumn) {
                                headerView(columns: report.values.unpinnedSpacerColumns, pinned: false)
                            }
                        }
                        .frame(height: 80)
                        switch displayMode {
                        case .building, .loading, .preparing, .stopped:
                            MiddleCenteredText(text: displayMode.text)
                                .font(bigFont)
                                .palette(.background, .theme)
                        default:
                            ScrollViewReader { proxy in
                                ScrollView(.vertical) {
                                    HStack(spacing: 0) {
                                        HStack {
                                            LazyVStack(alignment: .leading, spacing: 0) {
                                                ForEach($filteredIndex, id: \.id) { rowData in
                                                    rowView(data: rowData, columns: report.values.pinnedColumns, pinned: true)
                                                        .zIndex(1)
                                                }
                                            }
                                            .frame(width: report.values.pinnedColumns.map{$0.width}.reduce(0, +))
                                        }
                                        HorizontalScrollView(id: .data, widths: report.values.unpinnedSpacerColumns.map{$0.width}, scrollSync: scrollSync, activeColumn: $activeColumn) {
                                            LazyVStack(alignment: .leading, spacing: 0) {
                                                ForEach($filteredIndex, id: \.id) { rowData in
                                                    rowView(data: rowData, columns: report.values.unpinnedSpacerColumns, pinned: false)
                                                        .id(rowData.id)
                                                }
                                            }
                                        }
                                    }
                                }
                                .ignoresSafeArea(edges: .bottom)
                            }
                            VStack {
                                HStack{
                                    HStack {
                                        spacerView(columns: report.values.pinnedColumns, pinned: true)
                                    }
                                    HorizontalScrollView(showsIndicators: true, id: .scrollIndicator, widths: report.values.unpinnedSpacerColumns.map{$0.width}, scrollSync: scrollSync, activeColumn: $activeColumn) {
                                        spacerView(columns: report.values.unpinnedSpacerColumns, pinned: false)
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
                    InsightsReportViewStorageLoadDialog(report: report, forceDismiss: true) {
                        if !report.values.prompts.isEmpty {
                            showLoad = false
                            showPrompts = true
                        } else {
                            runReport()
                        }
                    }
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
        sortIndex = []
        filteredIndex = []
        Task(priority: .userInitiated) {
            if let errorMessage = await reload() {
                MessageBox.shared.show(errorMessage)
            }
            await MainActor.run {
                displayMode = .displaying
            }
        }
    }
    
    func toolBarView() -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Spacer()
                HStack {
                    Spacer()
                    
                    Text("Insights - \(report.values.viewName)")
                    
                    Spacer()
                    
                    if !report.values.prompts.isEmpty {
                        Button("􀌆") {
                            displayMode = .loading
                            sortIndex = []
                            filteredIndex = []
                            showPrompts = true
                        }
                        Spacer().frame(width: 40)
                    }
                    
                    Button("\("􀈎")") {
                        isEditing = true
                    }
            
                    Spacer().frame(width: 40)
                    
                    Button("􀤁") {
                        showLoad = true
                    }
                    
                    Spacer().frame(width: 40)
                    
                    Button("􀆄") {
                        dismiss()
                    }
                    .disabled(isEditing)
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                        .frame(width: 20)
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
        LazyHStack(spacing: 0) {
            if pinned {
                Color.clear.frame(width: 20, height: rowHeight)
            }
            ForEach(0..<columns.count, id: \.self) { columnIndex in
                let column = columns[columnIndex]
                HStack {
                    if column.align != .left {
                        Spacer()
                    }
                    Text(column.title)
                        .lineLimit(nil)
                        .multilineTextAlignment(column.align.textAlignment)
                    if column.align != .right {
                        Spacer()
                    }
                }
                .frame(width: column.width, height: 80)
            }
            if !pinned {
                Color.clear.frame(width: 20, height: rowHeight)
            }
        }
        .palette(.contrastTile)
    }
    
    func rowView(data: Binding<SortData<BoardSummaryExtension,InsightTotal>>, columns: [InsightColumn], pinned: Bool) -> some View {
        LazyHStack(spacing: 0) {
            Color.clear.frame(width: 20, height: rowHeight)
            if data.wrappedValue.totalLevel == nil {
                rowViewData(data: data, boardSummary: (data.source.wrappedValue as BoardSummaryExtension?)!, columns: columns)
            } else if pinned {
                rowViewTotalHeading(data: data, columns: columns)
            } else {
                rowViewTotalValues(data: data, columns: columns)
            }
            if !pinned {
                Color.clear.frame(width: 20, height: rowHeight)
            }
        }
        .palette(rowColor(level: data.wrappedValue.totalLevel))
    }
    
    func rowViewData(data: Binding<SortData<BoardSummaryExtension,InsightTotal>>, boardSummary: BoardSummaryExtension, columns: [InsightColumn], replaceTotal: Bool = false) -> some View {
        
        LazyHStack(alignment: .top, spacing: 0) {
            ForEach(0..<columns.count, id: \.self) { columnIndex in
                let column = columns[columnIndex]
                HStack {
                    if column.align != .left {
                        Spacer()
                    }
                    if column.visibility.isInBoard {
                        Text(column.textValue(report: report, boardSummary: boardSummary))
                    } else {
                        Text("")
                    }
                    if column.align != .right {
                        Spacer()
                    }
                }
                .frame(width: column.width, height: rowHeight)
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
    
    func rowViewTotalHeading(data: Binding<SortData<BoardSummaryExtension,InsightTotal>>, columns: [InsightColumn], replaceTotal: Bool = false,) -> some View {
        
        LazyHStack(spacing: 0) {
            let width = columns.map({$0.width}).reduce(0, +)
            VStack(spacing: 0) {
                HStack {
                    Spacer().frame(width: CGFloat(data.wrappedValue.totalLevel! * 20))
                    HStack {
                        Button {
                            buttonId[data.wrappedValue.id, default: UUID()] = UUID()
                            data.wrappedValue.state = data.wrappedValue.state.inverse
                            filterData()
                        } label: {
                            Image(systemName: data.wrappedValue.state == .expanded ? "minus" : "plus")
                                .id(buttonId[data.wrappedValue.id, default: UUID()])
                                .frame(width: 30, height: rowHeight)
                                .background(Color.clear)
                                .contentShape(Rectangle())
                        }
                    }
                    .frame(width: 30)
                    Text(data.wrappedValue.totalLevel == 0 ? "Grand Total" : "Total for \(data.wrappedValue.levelKey!)")
                    Spacer()
                }
                .bold()
            }
            .frame(width: width, height: rowHeight)
            .fixedSize()
        }
        .onAppear {
            buttonId[data.wrappedValue.id] = UUID()
        }
    }
    
    func rowViewTotalValues(data: Binding<SortData<BoardSummaryExtension,InsightTotal>>, columns: [InsightColumn], replaceTotal: Bool = false) -> some View {
        
        LazyHStack(spacing: 0) {
            ForEach(0..<columns.count, id: \.self) { columnIndex in
                let column = columns[columnIndex]
                VStack(spacing: 0) {
                    HStack {
                        if column.align != .left {
                            Spacer()
                        }
                        if let total = data.wrappedValue.totals[column], let value = total.value, let count = total.count {
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
                    }
                    .bold()
                }
                .frame(width: (column == .spacer ? spacerWidth : column.width), height: rowHeight)
                .fixedSize()
            }
            Spacer().background(Color.blue)
                .frame(maxWidth: .infinity)
                .frame(height: rowHeight)
        }
    }
    
    func spacerView(columns: [InsightColumn], pinned: Bool) -> some View {
        HStack(spacing: 0) {
            if pinned {
                Spacer().frame(width: 20)
            }
            Spacer().frame(width: columns.map{$0.width}.reduce(0,+), height: horizontalScroll ? 15 : 0)
            if !pinned {
                Spacer().frame(width: 20)
            }
        }
    }
    
    var spacerWidth: CGFloat {
        // Width of padding when unpinned scroll view isn't full
        max(0, scrollWidth - report.values.unpinnedSpacerColumns.map{$0.width}.reduce(0,+))
    }
    
    func rowColor(level: Int?) -> ThemeBackgroundColorName {
        switch level {
        case nil:
                .background
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
        let filtered = sortIndex.filter{ showRow(rowType: $0.rowType!, totalIndex: $0.totalIndex) }
        filteredIndex = filtered
    }
    
    func showRow(rowType: InsightRowType, totalIndex: [Int?]) -> Bool {
        var show = true
        for index in totalIndex.reversed() {
            if let index = index {
                if sortIndex[index].state == .collapsed {
                    show = false
                }
            }
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
        await allBoardSummaries = Insights.load()
        if allBoardSummaries.isEmpty {
            // TODO Shouldn't need this
            displayMode = .building
            await Insights.build()
            await allBoardSummaries = Insights.load()
        }
        if !report.values.prompts.isEmpty {
            showPrompts = true
        } else {
            runReport()
        }
    }
    
    
    func reload() async -> String? {
        var recalculationIndexes: [String:Int] = [:]
        var totals: [[InsightColumn:InsightTotal]] = []
        var errorMessage: String? = nil
        let levels = report.values.levels.filter({!$0.isBoard})
        let filterService = DataFilterService()
        var referenced: Set<InsightColumn> = []
        var boardIndex: Int = 0
        var inserted = 0
        var sortDirections: [SortDirection]
        var firstIndex: [Int] = []
        
        do {
            // Filter at bottom level
            boardSummaries = await filterService.filterData(report: report, allBoardSummaries: allBoardSummaries)
            
            // Generate recalculation indexes to work out sequence to recalculate totals in
            recalculationIndexes = try report.generateRecalculationIndexes()
            
            // Build sort index
            for boardSummary in boardSummaries {
                var sortKeys: [CalculatedValue] = []
                for level in levels {
                    let value = try level.key!.value(report: report, viewModel: boardSummary)
                    sortKeys.append(value)
                }
                // Add dummy entry for total level
                sortKeys.append(CalculatedValue(Int.max))
                // Add to index
                sortIndex.append(SortData(rowType: .data, keys: sortKeys, source: boardSummary))
            }
            
            if !sortIndex.isEmpty {
                // Execute the sort
                sortDirections = levels.map{$0.direction}
                sortDirections.append(.ascending)
                firstIndex = Array(repeating: 0, count: sortDirections.count)
                
                try sortIndex.sort(by: { try SortIndex.sort($0, $1, directions: sortDirections)})
                // Build totals and sub-totals
                referenced = try report.referencedColumns.filter{$0.visibility != .none && $0.visibility != .boardOnly}
                
                // 0 index is grand total followed by others
                for levelIndex in 0...levels.count {
                    totals.append([:])
                    for column in referenced {
                        totals[levelIndex][column] = InsightTotal()
                    }
                }
                
                boardIndex = 0
                while boardIndex + inserted < sortIndex.count {
                    // Check if changed
                    var changed = Array(repeating: false, count: levels.count + 1)
                    if boardIndex > 0 && !levels.isEmpty {
                        for levelIndex in 1...levels.count {
                            if levels[levelIndex - 1].isTotalling {
                                if levelIndex >= 2 && changed[levelIndex - 1] {
                                    // Higher level key has changed
                                    changed[levelIndex] = true
                                } else if sortIndex[boardIndex + inserted].keys[levelIndex - 1] != sortIndex[boardIndex + inserted - 1].keys[levelIndex - 1] {
                                    // This key has changed
                                    changed[levelIndex] = true
                                }
                            }
                        }
                        
                        // Insert a sub-total and zero the running total if changed
                        try insertTotals(startLevelIndex: 1, lastBoardIndex: { boardIndex + inserted - 1 }, changed: { levelIndex in changed[levelIndex] }) { (levelIndex) in
                            // Setup zeroed totals
                            totals[levelIndex] = [:]
                            for column in referenced {
                                totals[levelIndex][column] = InsightTotal()
                            }
                        }
                        for levelIndex in 0...levels.count {
                            if changed[levelIndex] {
                                firstIndex[levelIndex] = boardIndex + inserted
                            }
                        }
                    }
                    // Add current row to totals
                    for column in referenced {
                        let value = try column.totalValue(report: report, viewModel: sortIndex[boardIndex + inserted].source!)
                        let numeric =
                        if value.isBoolean {
                            Float(value.boolean! ? 1 : 0)
                        } else if value.isNumeric{
                            value.numeric!
                        } else {
                            Float(0)
                        }
                        for levelIndex in 0...levels.count {
                            if levelIndex == 0 || levels[levelIndex - 1].subtotal {
                                totals[levelIndex][column]!.add(index: boardIndex + inserted, value: numeric)
                            }
                        }
                    }
                    boardIndex += 1
                }
                // Insert final totals
                try insertTotals(startLevelIndex: 0, lastBoardIndex: { sortIndex.count - 1 }, changed: { _ in true}, zeroTotals: { _ in })
                
                // Resort to move totals in front of data
                try sortIndex.sort(by: { try SortIndex.sort($0, $1, directions: sortDirections)})

                // Build pointer from row to subtotals (excluding grand total)
                var totalIndex: [Int?] = Array(repeating: nil, count : sortIndex.count)
                for index in (0..<sortIndex.count) {
                    if sortIndex[index].rowType == .total {
                        // Total - fill it in and clear anything at a lower level
                        let level = sortIndex[index].totalLevel!
                        totalIndex[level] = index
                        for subIndex in (level + 1)..<(sortIndex.count) {
                            totalIndex[subIndex] = 0
                        }
                    }
                    sortIndex[index].totalIndex = totalIndex
                    if sortIndex[index].rowType == .total {
                        // Don't point back to yourself
                        sortIndex[index].totalIndex[sortIndex[index].totalLevel!] = nil
                    }
                }
                filterData()
            }
        } catch let error as CalculatedError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Unknown error: \(error)"
        }
        if let errorMessage = errorMessage {
            MessageBox.shared.show(errorMessage)
        }
        
        return errorMessage
        
        func insertTotals(startLevelIndex: Int, lastBoardIndex: ()->Int, changed: (Int)->Bool, zeroTotals: (Int)->()) throws {
            // Note this function reads and updates values in caller
            // Parameters are only for things that are different between final totals and previous ones
            for levelIndex in (startLevelIndex...levels.count).reversed() {
                if levelIndex == 0 || levels[levelIndex - 1].isTotalling {
                    if changed(levelIndex) {
                        var discarded = false
                        // First check for recalculation
                        let startBoardIndex = totals[levelIndex][referenced.first!]!.startIndex ?? 0
                        if startBoardIndex <= lastBoardIndex() {
                            try recalculate(levelIndex: levelIndex, boardSummary: sortIndex[lastBoardIndex()].source! as BoardSummaryExtension) { column, value in
                                totals[levelIndex][column]!.set(value: value)
                            }
                            if levelIndex != 0 {
                                // Remove it if selected out
                                discarded = try applySubtotalSelection(levelIndex: levelIndex, boardSummary: sortIndex[lastBoardIndex()].source! as BoardSummaryExtension)
                            }
                            if !discarded && (levelIndex == 0 || levels[levelIndex - 1].subtotal) {
                                // Now insert it unless it is a total of zero records
                                let lastBoardIndex = lastBoardIndex()
                                let boardSummary = sortIndex[lastBoardIndex].source! as BoardSummaryExtension
                                let levelKey = (levelIndex == 0 ? "" : (levels[levelIndex - 1].key!.textValue(report: report, boardSummary: boardSummary)))
                                let levelState: SortDataState = (levelIndex == 0 ? .expanded : (levels[levelIndex - 1].defaultState))
                                var sortKeys = sortIndex[startBoardIndex].keys
                                sortKeys[levels.count] = CalculatedValue(levelIndex)
                                sortIndex.insert(SortData(rowType: .total, totalLevel: levelIndex, levelKey: levelKey, keys: sortKeys, source: boardSummary, totals: totals[levelIndex], state: levelState), at: boardIndex + inserted)
                                inserted += 1
                            }
                        }
                        zeroTotals(levelIndex)
                    }
                }
            }
        }
        
        func applySubtotalSelection(levelIndex: Int, boardSummary: BoardSummaryExtension) throws -> Bool {
            if try !levels[levelIndex - 1].value(report: report, viewModel: boardSummary, level: levelIndex, evaluate: evaluateColumn) {
                // Failed selection - need to remove the rows from the sort index and reduce all higher level totals
                for higherLevelIndex in 0..<levelIndex {
                    // Reduce higher level subtotals and grand totals by this amount
                    for column in referenced {
                        totals[higherLevelIndex][column]!.subtract(totals[levelIndex][column]!)
                    }
                }
                // Now remove all the entries back to startIndex
                for removeIndex in ((totals[levelIndex][referenced.first!]!.startIndex ?? 0)..<(boardIndex + inserted)).reversed() {
                    if sortIndex[removeIndex].totalLevel == nil {
                        boardIndex -= 1
                    } else {
                        inserted -= 1
                    }
                    sortIndex.remove(at: removeIndex)
                }
                return true
            } else {
                return false
            }
            
            func evaluateColumn(boardSummary: BoardSummaryExtension, column: InsightColumn) throws -> CalculatedValue? {
                if let total = totals[levelIndex][column], let value = total.value {
                    return CalculatedValue(value)
                } else {
                    return try column.insightValue(report: report, boardSummary: boardSummary)
                }
            }
        }
        
        func recalculate(levelIndex: Int, boardSummary: BoardSummaryExtension, update: (InsightColumn, Float)->()) throws {
            for column in totals[levelIndex].keys.filter({$0.isCalculated}).sorted(by: { (recalculationIndexes[$0.calculatedColumn!.name] ?? 0) < (recalculationIndexes[$1.calculatedColumn!.name] ?? 0)}) {
                if case .calculated(let calculated) = column {
                    if calculated.recalculate {
                        if let newValue = try recalculateValue(levelIndex: levelIndex, column: column, boardSummary: boardSummary) {
                            update(column, newValue.numeric!)
                        } else {
                            throw CalculatedError.errorEvaluatingCalculatedColumn(column.title)
                        }
                    }
                }
            }
        }
        
        func recalculateValue(levelIndex: Int, column: InsightColumn, boardSummary: BoardSummaryExtension) throws -> CalculatedValue? {
            var result: CalculatedValue?
            if case .calculated(let calculated) = column {
                result = try calculated.value(report: report, viewModel: boardSummary, evaluate: recalculateEvaluate)
            }
            return result
            
            func recalculateEvaluate(report: Report, boardSummary: BoardSummaryExtension, column: InsightColumn) throws -> CalculatedValue? {
                // Get value for totals rather than from the view model
                if let value = totals[levelIndex][column]?.value {
                    return CalculatedValue(value)
                } else {
                    return try column.insightValue(report: report, boardSummary: boardSummary)
                }
            }
        }
    }
}

actor DataFilterService {
    func filterData(report: Report, allBoardSummaries: [BoardSummaryExtension]) -> [BoardSummaryExtension] {
        // This entire synchronous operation runs safely off the main thread
        return allBoardSummaries.filter({selectRow(boardSummary: $0)})
        
        func selectRow(boardSummary: BoardSummaryExtension) -> Bool {
            var show = true
            let selections = report.values.levels.filter({$0.isBoard})
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

class InsightTotal:Comparable {
    var startIndex: Int?
    var count: Int?
    var value: Float?
    
    init() {
    }
    
    func add(index: Int, value: Float) {
        self.startIndex = self.startIndex ?? index
        self.count = (self.count ?? 0) + 1
        self.value = (self.value ?? 0) + value
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
}

enum InsightRowType {
    case header
    case data
    case total
}

