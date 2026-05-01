//
//  Insights View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 27/04/2026.
//

import SwiftUI

enum InsightColumn {
    
    case eventDesc
    case boardIndex
    case sessionNumber
    case boardNumber
    case partner
    case location
    case date
    case vulnerability
    case eventType
    case boardScoreType
    case contract
    case contractMade
    case declarer
    case made
    case score
    case fieldSize
    case gameOdds
    case slamOdds
    case compContract
    case compDeclarer
    case compDdMade
    case compDdScore
    case compMakeScore
    case compMakeOdds
    case suit(pairType: PairType)
    case declare(pairType: PairType)
    case medianTricks(pairType: PairType)
    case modeTricks(pairType: PairType)
    case ddTricks(pairType: PairType)
    case fit(pairType: PairType)
    case points(seatPlayer: SeatPlayer)
    case suitType
    case levelType
    case totalTricks
    case totalTricksDd
    
    static let defaultPinnedColumns: [InsightColumn] =
    [.eventDesc,
     .boardNumber,
     .partner,
     .location,
     .date]
    
    static let defaultColumns: [InsightColumn] =
    [.vulnerability,
     .eventType,
     .boardScoreType,
     .contractMade,
     .declarer,
     .score,
     .fieldSize,
     .gameOdds,
     .slamOdds,
     .suit(pairType: .we),
     .declare(pairType: .we),
     .medianTricks(pairType: .we),
     .modeTricks(pairType: .we),
     .ddTricks(pairType: .we),
     .fit(pairType: .we),
     .suit(pairType: .they),
     .declare(pairType: .they),
     .medianTricks(pairType: .they),
     .modeTricks(pairType: .they),
     .ddTricks(pairType: .they),
     .fit(pairType: .they),
     .points(seatPlayer: .player),
     .points(seatPlayer: .partner),
     .points(seatPlayer: .lhOpponent),
     .points(seatPlayer: .rhOpponent),
     .suitType,
     .levelType,
     .totalTricks,
     .totalTricksDd,
     .compContract,
     .compDeclarer,
     .compDdMade,
     .compDdScore,
     .compMakeScore,
     .compMakeOdds]
    
    var title: String {
        switch self {
        case .eventDesc:
            "Event Description"
        case .sessionNumber:
            "Session"
        case .boardIndex, .boardNumber:
            "Board"
        case .location:
            "Location"
        case .partner:
            "Partner"
        case .date:
            "Date"
        case .vulnerability:
            "Vul"
        case .eventType:
            "Type"
        case .boardScoreType:
            "Score Type"
        case .contract:
            "Contract"
        case .contractMade:
            "Contract"
        case .declarer:
            "By"
        case .made:
            "Made"
        case .score:
            "Score"
        case .fieldSize:
            "Field Size"
        case .gameOdds:
            "Game Odds%"
        case .slamOdds:
            "Slam Odds%"
        case .compContract:
            "Comp Cont"
        case .compDeclarer:
            "Comp By"
        case .compDdMade:
            "Comp Made"
        case .compDdScore:
            "Comp DD Score"
        case .compMakeScore:
            "Comp Make Score"
        case .compMakeOdds:
            "Comp Make Odds"
        case .suit(let pairType):
            "Suit \(pairType.string)"
        case .declare(let pairType):
            "Declare \(pairType.string)%"
        case .medianTricks(let pairType):
            "Median Made \(pairType.string)"
        case .modeTricks(let pairType):
            "Mode Made \(pairType.string)"
        case .ddTricks(let pairType):
            "DD Made \(pairType.string)"
        case .fit(let pairType):
            "Fit \(pairType.string)"
        case .points(let seatPlayer):
            "Points \(seatPlayer.string)"
        case .suitType:
            "Suit Type"
        case .levelType:
            "Level Type"
        case .totalTricks:
            "Total Tricks"
        case .totalTricksDd:
            "Total Tricks DD"
        }
    }
    
    func value(boardSummary: BoardSummaryViewModel) -> AttributedString {
        switch self {
        case .eventDesc:
            AttributedString(boardSummary.scorecard.desc)
        case .boardIndex:
            AttributedString("\(boardSummary.boardIndex)")
        case .sessionNumber:
            AttributedString(boardSummary.session == 0 ? "" : "\(boardSummary.session)")
        case .boardNumber:
            AttributedString("\(boardSummary.boardNumber)")
        case .location:
            AttributedString(boardSummary.location!.short == "" ? boardSummary.location!.name : boardSummary.location!.short)
        case .partner:
            AttributedString(boardSummary.partner!.name.components(separatedBy: " ").first!)
        case .date:
            AttributedString(Utility.dateString(boardSummary.date, format: "dd/MM/yyyy"))
        case .vulnerability:
            AttributedString(boardSummary.vulnerability.string)
        case .eventType:
            AttributedString(boardSummary.eventType.string)
        case .boardScoreType:
            AttributedString(boardSummary.boardScoreType.brief)
        case .contract:
            boardSummary.contract.colorCompact
        case .contractMade:
            boardSummary.contract.colorCompact + " " + AttributedString(Scorecard.madeString(made: boardSummary.made ?? 0))
        case .declarer:
            AttributedString("\(boardSummary.declarer.pairType.string)")
        case .made:
            AttributedString(Scorecard.madeString(made: boardSummary.made ?? 0))
        case .score:
            AttributedString("\(boardSummary.score)%")
        case .fieldSize:
            AttributedString("\(boardSummary.fieldSize)")
        case .gameOdds:
            AttributedString("\(boardSummary.gameOdds)%")
        case .slamOdds:
            AttributedString("\(boardSummary.slamOdds)%")
        case .compContract:
            !boardSummary.isCompetitive ? "" : boardSummary.compContract.colorCompact
        case .compDeclarer:
            !boardSummary.isCompetitive ? "" : AttributedString("\(boardSummary.compDeclarer.string)")
        case .compDdMade:
            !boardSummary.isCompetitive || (boardSummary.compDdMade ?? -1) < 0 ? "" : AttributedString(Scorecard.madeString(made: boardSummary.compDdMade ?? 0))
        case .compDdScore:
            !boardSummary.isCompetitive || (boardSummary.compDdMade ?? -1) < 0 ? "" : AttributedString("\(boardSummary.compDdScore)%")
        case .compMakeScore:
            !boardSummary.isCompetitive ? "" : AttributedString("\(boardSummary.compMakeScore)%")
        case .compMakeOdds:
            !boardSummary.isCompetitive ? "" : AttributedString("\(boardSummary.compMakeOdds)%")
        case .suit(let pairType):
            boardSummary.suit[pairType]!.colorString
        case .declare(let pairType):
            AttributedString("\(boardSummary.declare[pairType]!)%")
        case .medianTricks(let pairType):
            AttributedString(boardSummary.suit[pairType]! == .blank ? "" : "\(boardSummary.medianTricks[pairType]!)")
        case .modeTricks(let pairType):
            AttributedString(boardSummary.suit[pairType]! == .blank ? "" : "\(boardSummary.modeTricks[pairType]!)")
        case .ddTricks(let pairType):
            AttributedString(boardSummary.ddTricks[pairType]! < 0 ? "" : boardSummary.suit[pairType]! == .blank ? "" : "\(boardSummary.ddTricks[pairType]!)")
        case .fit(let pairType):
            AttributedString(boardSummary.suit[pairType]! == .blank ? "" : "\(boardSummary.fit[pairType]!)")
        case .points(let seatPlayer):
            AttributedString("\(boardSummary.points[seatPlayer]!)")
        case .suitType:
            AttributedString(boardSummary.suitType.string)
        case .levelType:
            AttributedString(boardSummary.levelType.string)
        case .totalTricks:
            AttributedString("\(boardSummary.totalTricks)")
        case .totalTricksDd:
            boardSummary.ddTricks[.we]! < 0 || boardSummary.ddTricks[.they]! < 0 ? "" :  AttributedString("\(boardSummary.totalTricksDd)")
        }
    }
    
    var align: TextAlignment {
        switch self {
        case .eventDesc, .partner, .location:
                .leading
        case .boardIndex, .sessionNumber, .boardNumber, .vulnerability, .eventType, .boardScoreType, .contract, .contractMade, .declarer, .made, .compContract, .compDeclarer, .suit, .suitType, .levelType:
                .center
        default:
                .trailing
        }
    }
        
    var width: CGFloat {
        switch self {
        case .eventDesc:
            280
        case .date, .suitType, .levelType, .eventType:
            120
        case .partner, .location, .contractMade, .boardScoreType:
            100
        case .contract:
            90
        default:
            80
        }
    }
}

struct InsightsView: View {
    @Environment(\.dismiss) var dismiss
    @State var boardSummaries: [BoardSummaryExtension] = []
    @State var pinnedColumns = InsightColumn.defaultPinnedColumns
    @State var columns = InsightColumn.defaultColumns
    @State var showBoardSummary: BoardSummaryExtension? = nil
    @State var dismissView: Bool = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        StandardView("Insights") {
            GeometryReader { geometry in
                ZStack {
                    VStack(spacing: 0) {
                        Rectangle()
                            .frame(height: 120)
                            .foregroundColor(Palette.contrastTile.background)
                            .ignoresSafeArea()
                        Spacer()
                    }
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button("􀆄") {
                                dismiss()
                            }
                            .keyboardShortcut(.cancelAction)
                            .font(bannerFont)
                            .palette(.contrastTile)
                            Spacer()
                                .frame(width: 20)
                        }
                        .ignoresSafeArea()
                        Spacer()
                    }
                    .zIndex(99)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top, spacing: 0) {
                            Spacer().frame(width: 10)
                            headerView(columns: pinnedColumns)
                                .zIndex(1)
                            GeometryReader { _ in
                                headerView(columns: columns)
                                    .offset(x: scrollOffset)
                            }
                            Spacer().frame(width: 10)
                        }
                        .frame(height: 80)
                        
                        ScrollView(.vertical) {
                            HStack(alignment: .top, spacing: 0) {
                                Spacer().frame(width: 10)
                                LazyVStack(alignment: .leading, spacing: 0) {
                                    ForEach(0..<boardSummaries.count, id: \.self) { boardIndex in
                                        rowView(boardSummary: boardSummaries[boardIndex], columns: pinnedColumns)
                                    }
                                }
                                .frame(width: pinnedColumns.map{$0.width}.reduce(0, +))
                                GeometryReader { outerGeometry in
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        ZStack(alignment: .topLeading) {
                                            GeometryReader { innerGeometry in
                                                Color.clear
                                                    .frame(width: 0, height: 0)
                                                    .preference(key: ScrollOffsetKey.self, value: innerGeometry.frame(in: .named("Outer VStack")).minX - outerGeometry.frame(in: .named("Outer VStack")).minX)
                                            }
                                            LazyVStack(alignment: .leading, spacing: 0) {
                                                ForEach(0..<boardSummaries.count, id: \.self) { boardIndex in
                                                    rowView(boardSummary: boardSummaries[boardIndex], columns: columns)
                                                }
                                            }
                                            .fixedSize(horizontal: true, vertical: false)
                                        }
                                    }
                                    .onPreferenceChange(ScrollOffsetKey.self) { value in
                                        scrollOffset = value
                                    }
                                }
                                Spacer().frame(width: 10)
                            }
                        }
                    }
                    .coordinateSpace(name: "Outer VStack")
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
            Insights.build()
            boardSummaries = Insights.Load()
        }
    }
    
    func headerView(columns: [InsightColumn]) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<columns.count, id: \.self) { columnIndex in
                let column = columns[columnIndex]
                HStack {
                    if column.align != .leading {
                        Spacer()
                    }
                    Text(column.title)
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)
                    if column.align != .trailing {
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
                    if column.align != .leading {
                        Spacer()
                    }
                    Text(column.value(boardSummary: boardSummary))
                    if column.align != .trailing {
                        Spacer()
                    }
                }
                .frame(width: column.width, height: 20)
            }
        }
        .onTapGesture {
            if loadDetails(boardSummary: boardSummary) {
                showBoardSummary = boardSummary
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

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let newValue = nextValue()
        if newValue != 0 {
            value = newValue
            print(value)
        }
    }
}
