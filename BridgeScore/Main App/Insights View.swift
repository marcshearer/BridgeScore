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
    @State var boardSummaries: [BoardSummaryExtension] = []
    @StateObject var report = Report(pinnedColumns: InsightColumn.defaultPinnedColumns, unpinnedColumns: InsightColumn.defaultColumns, calculatedColumns: [])
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
                                            ForEach(0..<boardSummaries.count, id: \.self) { boardIndex in
                                                rowView(boardSummary: boardSummaries[boardIndex], columns: report.values.pinnedColumns)
                                            }
                                        }
                                        .frame(width: report.values.pinnedColumns.map{$0.width}.reduce(0, +))
                                        Spacer().frame(width: 20)
                                    }
                                    .palette(.alternate)
                                    scrollSync.scrollView(showsIndicators: false, id: .data) {
                                        LazyVStack(alignment: .leading, spacing: 0) {
                                            ForEach(0..<boardSummaries.count, id: \.self) { boardIndex in
                                                rowView(boardSummary: boardSummaries[boardIndex], columns: report.values.unpinnedColumns)
                                            }
                                        }
                                        .fixedSize(horizontal: true, vertical: false)
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
            InsightsSaveReportView.load(report: report, from: "default")
                boardSummaries = Insights.Load()
            if boardSummaries.isEmpty {
                // TODO Shouldn't need this
                Insights.build()
                boardSummaries = Insights.Load()
            }
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
                    
                    Button("\(editMode ? "􀈄" : "􀈎")") {
                       editMode.toggle()
                    }
                    
                    Spacer().frame(width: 40)
                    
                    Button("􀆄") {
                        dismiss()
                    }
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
    
    func rowView(boardSummary: BoardSummaryExtension, columns: [InsightColumn]) -> some View {
        HStack(spacing: 0){
            ForEach(0..<columns.count, id: \.self) { columnIndex in
                let column = columns[columnIndex]
                HStack {
                    if column.align != .left {
                        Spacer()
                    }
                    Text(column.textValue(boardSummary: boardSummary))
                    if column.align != .right {
                        Spacer()
                    }
                }
                .frame(width: column.width, height: 20)
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
}

