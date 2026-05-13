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

struct InsightsView: View {
    @Environment(\.dismiss) var dismiss
    @State var allBoardSummaries: [BoardSummaryExtension] = []
    @State var boardSummaries: [BoardSummaryExtension] = []
    @State var rowIndex: [SortData<BoardSummaryExtension>] = []
    @StateObject var report = Report()
    @State var showBoardSummary: BoardSummaryExtension? = nil
    @State var dismissView: Bool = false
    @State var editMode: Bool = false
    @StateObject private var scrollSync = ScrollSync<ScrollViews>()
    
    var body: some View {
        StandardView("Insights") {
            GeometryReader { geometry in
                ZStack {
                    VStack(spacing: 0) {
                        Rectangle()
                            .frame(height: editMode ? 40 : 90 + geometry.safeAreaInsets.top)
                            .foregroundColor(Palette.contrastTile.background)
                            .ignoresSafeArea()
                        Spacer()
                    }
                    
                    toolBarView()
                        .zIndex(99)
                    if !editMode {
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer().frame(height: 10)
                            HStack(alignment: .top, spacing: 0) {
                                Spacer().frame(width: 10)
                                headerView(columns: report.values.pinnedColumns)
                                Spacer().frame(width: 20)
                                scrollSync.scrollView(id: .heading) {
                                    headerView(columns: report.values.unpinnedColumns)
                                }
                                Spacer().frame(width: 10)
                            }
                            .frame(height: 80)
                            ScrollView(.vertical) {
                                HStack(spacing: 0) {
                                    HStack {
                                        Spacer().frame(width: 10)
                                        LazyVStack(alignment: .leading, spacing: 0) {
                                            ForEach(0..<rowIndex.count, id: \.self) { index in
                                                rowView(data: rowIndex[index], columns: report.values.pinnedColumns)
                                            }
                                        }
                                        .frame(width: report.values.pinnedColumns.map{$0.width}.reduce(0, +))
                                        Spacer().frame(width: 20)
                                    }
                                    .palette(.alternate)
                                    scrollSync.scrollView(showsIndicators: false, id: .data) {
                                        LazyVStack(alignment: .leading, spacing: 0) {
                                            ForEach(0..<rowIndex.count, id: \.self) { index in
                                                rowView(data: rowIndex[index], columns: report.values.unpinnedColumns)
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
                                scrollSync.scrollView(showsIndicators: true, id: .scrollIndicator) {
                                    spacerView(columns: report.values.unpinnedColumns)
                                }
                                Spacer().frame(width: 10)
                            }
                        }
                    } else {
                        InsightsSetupView(report: report, data: boardSummaries.first, editMode: $editMode)
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
    
    func loadDefaultView() {
        let defaultUrl = InsightsReportViewStorage.url(for: UserDefault.defaultViewName.string)
        if !InsightsReportViewStorage.load(report: report, from: defaultUrl) {
            report.update(from: ReportValues(pinnedColumns: InsightColumn.defaultPinnedColumns, unpinnedColumns: InsightColumn.defaultColumns))
        }
    }
    func loadData() async {
        // Load master data
        await allBoardSummaries = Insights.Load()
        if allBoardSummaries.isEmpty {
            // TODO Shouldn't need this
            await Insights.build()
            await allBoardSummaries = Insights.Load()
        }
        if let errorMessage = reload() {
            MessageBox.shared.show(errorMessage)
        }
    }
    
    func toolBarView() -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Spacer()
                HStack {
                    Spacer()
                    
                    Text("Insights")
                    
                    Spacer()
                    
                    if editMode {
                        Button("\("􀈄")") {
                            if let errorMessage = reload() {
                                MessageBox.shared.show(errorMessage)
                            }
                            editMode = false
                        }
                        .keyboardShortcut(.cancelAction)
                    } else {
                        Button("\("􀈎")") {
                            editMode = true
                        }
                    }
                    
                    Spacer().frame(width: 40)
                    
                    Button("􀆄") {
                        dismiss()
                    }
                    .disabled(editMode)
                    .opacity(editMode ? 0.3 : 1)
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
    
    func rowView(data: SortData<BoardSummaryExtension>, columns: [InsightColumn]) -> some View {
        LazyHStack {
            if data.totalLevel == nil {
                let boardSummary = (data.source as BoardSummaryExtension?)!
                LazyHStack(alignment: .top, spacing: 0) {
                    ForEach(0..<columns.count, id: \.self) { columnIndex in
                        let column = columns[columnIndex]
                        HStack {
                            if column.align != .left {
                                Spacer()
                            }
                            if column.visibility.isInBoard {
                                Text(column.textValue(boardSummary: boardSummary))
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
            } else {
                LazyHStack(spacing: 0){
                    ForEach(0..<columns.count, id: \.self) { columnIndex in
                        let column = columns[columnIndex]
                        VStack(spacing: 0) {
                            Separator(direction: .horizontal, padding: false, thickness: 2, color: .black)
                            HStack {
                                if column.align != .left {
                                    Spacer()
                                }
                                if let (count, value) = data.totals[column] {
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
                    }
                }
            }
        }
    }
    
    func selectRow(boardSummary: BoardSummaryExtension) -> Bool {
        var show = true
        let selections = report.values.levels.filter({$0.isBoard})
        for index in 0..<selections.count {
            do {
                if try !selections[index].value(viewModel: boardSummary, level: 0, evaluate: evaluateColumn) {
                    show = false
                }
            } catch {
                show = false // TODO Need to handle better
            }
        }
        return show
    }
    
    func evaluateColumn(boardSummary: BoardSummaryViewModel, column: InsightColumn) throws -> CalculatedValue? {
        return try column.insightValue(boardSummary: boardSummary)
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
    
    func reload() -> String? {
        // Clear cached parses
        report.reset()
        
        // Filter at bottom level
        boardSummaries = allBoardSummaries.filter({selectRow(boardSummary: $0)})
        
        var errorMessage: String? = nil
        let levels = report.values.levels.filter({!$0.isBoard})
        do {
            // Build sort index
            var sortIndex: [SortData<BoardSummaryExtension>] = []
            for boardSummary in boardSummaries {
                var sortKeys: [CalculatedValue] = []
                for level in levels {
                    let value = try level.key!.value(viewModel: boardSummary)
                    sortKeys.append(value)
                }
                sortIndex.append(SortData(keys: sortKeys, source: boardSummary))
            }
            if !sortIndex.isEmpty {
                var sortDirections: [SortDirection] = []
                for level in levels {
                    sortDirections.append(level.direction)
                }
                if !sortDirections.isEmpty {
                    try sortIndex.sort(by: { try SortIndex.sort($0, $1, directions: sortDirections)})
                }
                // Build totals and sub-totals
                let referenced = try report.referencedColumns.filter{$0.visibility != .none && $0.visibility != .boardOnly}
                
                // 0 inded is grand total followed by others
                var totals: [[InsightColumn:(Int,Float)]] = Array(repeating: [:], count: sortDirections.count + 1)
                
                var inserted = 0
                for index in 0..<sortIndex.count {
                    // Check if changed
                    var changed = Array(repeating: false, count: levels.count + 1)
                    if index > 0 {
                        for levelIndex in 1...sortDirections.count {
                            if levels[levelIndex - 1].subtotal {
                                if levelIndex >= 2 && changed[levelIndex - 1] {
                                    // Higher level key has changed
                                    changed[levelIndex] = true
                                } else if sortIndex[index + inserted].keys[levelIndex - 1] != sortIndex[index + inserted - 1].keys[levelIndex - 1] {
                                    // This key has changed
                                    changed[levelIndex] = true
                                }
                            }
                        }
                    }
                    // Insert a sub-total and zero the running total if changed
                    for levelIndex in (1...sortDirections.count).reversed() {
                        if levels[levelIndex - 1].subtotal {
                            if changed[levelIndex] {
                                sortIndex.insert(SortData(totalLevel: levelIndex, keys: sortIndex[index + inserted - 1].keys, totals: totals[levelIndex]), at: index + inserted)
                                inserted += 1
                                totals[levelIndex] = [:]
                            }
                        }
                    }
                    // Add current row to totals
                    for column in referenced {
                        let value = try! column.totalValue(viewModel: sortIndex[index + inserted].source!)
                        let numeric =
                            if value.isBoolean {
                                Float(value.boolean! ? 1 : 0)
                            } else {
                                value.numeric!
                            }
                        for levelIndex in 0...sortDirections.count {
                            if levelIndex == 0 || levels[levelIndex - 1].subtotal {
                                let (currentCount, currentTotal) = totals[levelIndex][column] ?? (0, 0)
                                totals[levelIndex][column] = (currentCount + 1, currentTotal + numeric)
                            }
                        }
                    }
                }
                // Insert final totals
                for levelIndex in (0...sortDirections.count).reversed() {
                    if levelIndex == 0 || levels[levelIndex - 1].subtotal {
                        sortIndex.append(SortData(totalLevel: levelIndex, keys: levelIndex == 0 ? [] : sortIndex.last!.keys, totals: totals[levelIndex]))
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
    }
}

