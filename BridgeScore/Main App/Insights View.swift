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
    case loading
    case displaying
    case editing
}

struct InsightsView: View {
    @Environment(\.dismiss) var dismiss
    @State var allBoardSummaries: [BoardSummaryExtension] = []
    @State var boardSummaries: [BoardSummaryExtension] = []
    @State var rowIndex: [SortData<BoardSummaryExtension,InsightTotal>] = []
    @StateObject var report = Report()
    @State var showBoardSummary: BoardSummaryExtension? = nil
    @State var dismissView: Bool = false
    @State var buttonId: [UUID:UUID] = [:]
    @State fileprivate var displayMode: InsightDisplayMode = .loading { didSet {
        
    }}
    @StateObject private var scrollSync = ScrollSync<ScrollViews>()
    
    var body: some View {
        StandardView("Insights") {
            GeometryReader { geometry in
                ZStack {
                    VStack(spacing: 0) {
                        Rectangle()
                            .frame(height: displayMode == .editing ? 40 : 90 + geometry.safeAreaInsets.top)
                            .foregroundColor(Palette.contrastTile.background)
                            .ignoresSafeArea()
                        Spacer()
                    }
                    
                    toolBarView()
                        .zIndex(99)
                    if displayMode != .editing {
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer().frame(height: 10)
                            HStack(alignment: .top, spacing: 0) {
                                Spacer().frame(width: 10)
                                headerView(columns: report.values.pinnedColumns)
                                Spacer().frame(width: 20)
                                scrollSync.horizontalScrollView(id: .heading) {
                                    headerView(columns: report.values.unpinnedColumns)
                                }
                                Spacer().frame(width: 10)
                            }
                            .frame(height: 80)
                            if displayMode == .loading {
                                MiddleCenteredText(text: "Loading...")
                                    .font(bigFont)
                                    .palette(.background, .theme)
                            } else {
                                ScrollView(.vertical) {
                                    HStack(spacing: 0) {
                                        HStack {
                                            Spacer().frame(width: 10)
                                            LazyVStack(alignment: .leading, spacing: 0) {
                                                ForEach($rowIndex, id: \.id) { rowData in
                                                    if showRow(totalIndex: rowData.wrappedValue.totalIndex) {
                                                        rowView(data: rowData, columns: report.values.pinnedColumns, replaceTotal: true)
                                                    }
                                                }
                                            }
                                            .frame(width: report.values.pinnedColumns.map{$0.width}.reduce(0, +))
                                            Spacer().frame(width: 20)
                                        }
                                        .palette(.alternate)
                                        scrollSync.horizontalScrollView(showsIndicators: false, id: .data) {
                                            LazyVStack(alignment: .leading, spacing: 0) {
                                                ForEach($rowIndex, id: \.id) { rowData in
                                                    if showRow(totalIndex: rowData.wrappedValue.totalIndex) {
                                                        rowView(data: rowData, columns: report.values.unpinnedColumns)
                                                    }
                                                }
                                            }
                                        }
                                        Spacer().frame(width: 10)
                                    }
                                }
                                HStack{
                                    HStack {
                                        Spacer().frame(width: 10)
                                        spacerView(columns: report.values.pinnedColumns)
                                        Spacer().frame(width: 20)
                                    }
                                    .palette(.alternate)
                                    scrollSync.horizontalScrollView(showsIndicators: true, id: .scrollIndicator) {
                                        spacerView(columns: report.values.unpinnedColumns)
                                    }
                                    Spacer().frame(width: 10)
                                }
                            }
                        }
                    } else {
                        InsightsSetupView(report: report, data: boardSummaries.first)
                        Spacer()
                    }
                }
                .fullScreenCover(item: $showBoardSummary, onDismiss: {
                    if let scorecard = Scorecard.current.scorecard {
                        Scorecard.current.saveAll(scorecard: scorecard)
                        Scorecard.current.clear()
                    }
                }, content: { boardSummary in
                    showDetails(boardSummary: boardSummary, frame: geometry.frame(in: .global))
                })
            }
            
        }
        .onAppear {
            Task {
                loadDefaultView()
                await loadData()
            }
        }
    }
    
    func showRow(totalIndex: [Int?]) -> Bool {
        var result = true
        for index in totalIndex {
            if let index = index {
                if !rowIndex[index].expanded {
                    result = false
                    break
                }
            }
        }
        return result
    }
    
    func loadDefaultView() {
        let defaultUrl = InsightsReportViewStorage.url(for: UserDefault.defaultViewName.string)
        if !InsightsReportViewStorage.load(report: report, from: defaultUrl) {
            do {
                try report.update(from: ReportValues(pinnedColumns: InsightColumn.defaultPinnedColumns, unpinnedColumns: InsightColumn.defaultColumns))
            } catch {
                // Just ignore for now
            }
        }
    }
    func loadData() async {
        // Load master data
        await allBoardSummaries = Insights.load()
        if allBoardSummaries.isEmpty {
            // TODO Shouldn't need this
            await Insights.build()
            await allBoardSummaries = Insights.load()
        }
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
                    
                    if displayMode == .editing {
                        Button("\("􀈄")") {
                            rowIndex = []
                            displayMode = .loading
                            Task(priority: .userInitiated) {
                                if let errorMessage = await reload() {
                                    MessageBox.shared.show(errorMessage)
                                }
                                await MainActor.run {
                                    displayMode = .displaying
                                }
                            }
                        }
                        .keyboardShortcut(.cancelAction)
                    } else if displayMode == .displaying {
                        Button("\("􀈎")") {
                            displayMode = .editing
                        }
                    }
                    
                    Spacer().frame(width: 40)
                    
                    Button("􀆄") {
                        dismiss()
                    }
                    .disabled(displayMode == .editing)
                    .opacity(displayMode == .editing ? 0.3 : 1)
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
    
    func headerView(columns: [InsightColumn]) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<columns.count, id: \.self) { columnIndex in
                let column = columns[columnIndex]
                HStack {
                    if column.align != .left {
                        Spacer()
                    }
                    Text(column.title)
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)
                    if column.align != .right {
                        Spacer()
                    }
                }
                .frame(width: column.width, height: 80)
            }
        }
        .palette(.contrastTile)
    }
    
    func rowView(data: Binding<SortData<BoardSummaryExtension,InsightTotal>>, columns: [InsightColumn], replaceTotal: Bool = false) -> some View {
        LazyHStack {
            if data.wrappedValue.totalLevel == nil {
                let boardSummary = (data.source.wrappedValue as BoardSummaryExtension?)!
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
                        .frame(width: column.width, height: 20)
                    }
                }.contentShape(Rectangle())
                    .help("\(boardSummary.scorecard.desc)\nDate: \(Utility.dateString(boardSummary.scorecard.date, format: "dd/MM/yyyy"))\nLocation: \(boardSummary.location!.name)\nPartner: \(boardSummary.partner!.name)\nBoard: \(boardSummary.boardNumber) of \(boardSummary.scorecard.boards)")
                    .onTapGesture {
                        if loadDetails(boardSummary: boardSummary) {
                            showBoardSummary = boardSummary
                        }
                    }
            } else if !replaceTotal {
                LazyHStack(spacing: 0) {
                    ForEach(0..<columns.count, id: \.self) { columnIndex in
                        let column = columns[columnIndex]
                        VStack(spacing: 0) {
                            Separator(direction: .horizontal, padding: false, thickness: 2, color: .black)
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
                            .palette(.background, .theme, clear: true)
                            .frame(width: column.width, height: 18)
                        }
                        .frame(width: column.width, height: 20)
                        .fixedSize()
                    }
                }
            } else {
                let width = columns.map({$0.width}).reduce(0, +)
                LazyHStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Separator(direction: .horizontal, padding: false, thickness: 2, color: .black)
                        HStack {
                            Spacer()
                                .frame(width: CGFloat(data.wrappedValue.totalLevel! * 20))
                            Button {
                                data.wrappedValue.expanded.toggle()
                                buttonId[data.wrappedValue.id] = UUID()
                            } label: {
                                Image(systemName: data.wrappedValue.expanded ? "minus" : "plus")
                                    .id(buttonId[data.wrappedValue.id])
                            }
                            Text(data.wrappedValue.totalLevel == 0 ? "Grand Total" : "Total for \(data.wrappedValue.levelKey!)")
                            Spacer()
                        }
                        .bold()
                        .palette(.background, .theme, clear: true)
                        .frame(width: width, height: 18)
                    }
                    .frame(width: width, height: 20)
                    .fixedSize()
                }
                
            }
        }
        .onAppear {
            buttonId[data.wrappedValue.id] = UUID()
        }
    }
    
    func spacerView(columns: [InsightColumn]) -> some View {
        Spacer().frame(width: columns.map{$0.width}.reduce(0,+), height: 10)
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
    
    func reload() async -> String? {
        var recalculationIndexes: [String:Int] = [:]
        var totals: [[InsightColumn:InsightTotal]] = []
        var errorMessage: String? = nil
        let levels = report.values.levels.filter({!$0.isBoard})
        let filterService = DataFilterService()
        var referenced: Set<InsightColumn> = []
        var sortIndex: [SortData<BoardSummaryExtension,InsightTotal>] = []
        var boardIndex: Int = 0
        var inserted = 0
        var sortDirections: [SortDirection]
        
        do {
            try report.refresh()
            
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
                sortIndex.append(SortData(rowType: .data, keys: sortKeys, source: boardSummary))
            }
            
            if !sortIndex.isEmpty {
                // Execute the sort
                sortDirections = levels.map{$0.direction}
                if !sortDirections.isEmpty {
                    try sortIndex.sort(by: { try SortIndex.sort($0, $1, directions: sortDirections)})
                }
                // Build totals and sub-totals
                referenced = try report.referencedColumns.filter{$0.visibility != .none && $0.visibility != .boardOnly}
                
                // 0 index is grand total followed by others
                for levelIndex in 0...sortDirections.count {
                    totals.append([:])
                    for column in referenced {
                        totals[levelIndex][column] = InsightTotal()
                    }
                }
                
                boardIndex = 0
                while boardIndex + inserted < sortIndex.count {
                    // Check if changed
                    var changed = Array(repeating: false, count: levels.count + 1)
                    if boardIndex > 0 && !sortDirections.isEmpty {
                        for levelIndex in 1...sortDirections.count {
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
                        let lastIndex = boardIndex + inserted - 1
                        try insertTotals(startLevelIndex: 1, lastIndex: { lastIndex }, changed: { levelIndex in changed[levelIndex] }) { (levelIndex) in
                            // Setup zeroed totals
                            totals[levelIndex] = [:]
                            for column in referenced {
                                totals[levelIndex][column] = InsightTotal()
                            }
                        }
                    }
                    // Add current row to totals
                    for column in referenced {
                        let value = try column.totalValue(report: report, viewModel: sortIndex[boardIndex + inserted].source!)
                        let numeric =
                        if value.isBoolean {
                            Float(value.boolean! ? 1 : 0)
                        } else {
                            value.numeric!
                        }
                        for levelIndex in 0...sortDirections.count {
                            if levelIndex == 0 || levels[levelIndex - 1].subtotal {
                                totals[levelIndex][column]!.add(index: boardIndex + inserted, value: numeric)
                            }
                        }
                    }
                    boardIndex += 1
                }
                // Insert final totals
                try insertTotals(startLevelIndex: 0, lastIndex: { sortIndex.count - 1 }, changed: { _ in true}, zeroTotals: { _ in })

                // Build pointer from row to subtotals (excluding grand total)
                var totalIndex: [Int?] = Array(repeating: nil, count : sortIndex.count - 1)
                for index in (0..<sortIndex.count).reversed() {
                    if sortIndex[index].rowType == .total {
                        // total
                        totalIndex[sortIndex[index].totalLevel!] = index
                    }
                    sortIndex[index].totalIndex = totalIndex
                    if sortIndex[index].rowType == .total {
                        // Don't point back to yourself
                        sortIndex[index].totalIndex[sortIndex[index].totalLevel!] = nil
                    }
                }
                
                rowIndex = sortIndex
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
        
        func insertTotals(startLevelIndex: Int, lastIndex: ()->Int, changed: (Int)->Bool, zeroTotals: (Int)->()) throws {
            for levelIndex in (startLevelIndex...sortDirections.count).reversed() {
                if levelIndex == 0 || levels[levelIndex - 1].isTotalling {
                    if changed(levelIndex) {
                        var discarded = false
                        // First check for recalculation
                        print("\(lastIndex()) \(levelIndex)")
                        try recalculate(levelIndex: levelIndex, boardSummary: sortIndex[lastIndex()].source! as BoardSummaryExtension) { column, value in
                            totals[levelIndex][column]!.set(value: value)
                        }
                        if levelIndex != 0 {
                            // Remove it if selected out
                            discarded = try applySubtotalSelection(levelIndex: levelIndex, boardSummary: sortIndex[lastIndex()].source! as BoardSummaryExtension)
                        }
                        if !discarded && (levelIndex == 0 || levels[levelIndex - 1].subtotal) {
                            // Now insert it
                            let boardSummary = sortIndex[lastIndex()].source! as BoardSummaryExtension
                            let levelKey = levelIndex == 0 ? "" : (levels[levelIndex - 1].key!.textValue(report: report, boardSummary: boardSummary))
                            sortIndex.insert(SortData(rowType: .total, totalLevel: levelIndex, levelKey: levelKey, keys: sortIndex[boardIndex + inserted - 1].keys, source: boardSummary, totals: totals[levelIndex]), at: boardIndex + inserted)
                            inserted += 1
                        }
                        zeroTotals(levelIndex)
                    }
                }
            }
        }
        
        func applySubtotalSelection(levelIndex: Int, boardSummary: BoardSummaryExtension) throws -> Bool {
            if try !levels[levelIndex - 1].value(report: report, viewModel: boardSummary, level: levelIndex, evaluate: evaluateColumn) {
                // Failed selection - need to remove the rows from the sort index and reduce all higher level totals
                for rightIndex in 0..<levelIndex {
                    // Reduce higher level subtotals and grand totals by this amount
                    for column in referenced {
                        totals[rightIndex][column]!.subtract(totals[levelIndex][column]!)
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
            for column in totals[levelIndex].keys.sorted(by: { (recalculationIndexes[$0.name] ?? 0) < (recalculationIndexes[$1.name] ?? 0)}) {
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

