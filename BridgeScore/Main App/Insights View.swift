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
    
    static let defaultCases: [InsightColumn] =
    [.eventDesc,
     .sessionNumber,
     .boardNumber,
     .partner,
     .location,
     .date,
     .vulnerability,
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
            AttributedString(boardSummary.location!.name.components(separatedBy: " ").first!)
        case .partner:
            AttributedString(boardSummary.partner!.name.components(separatedBy: " ").first!)
        case .date:
            AttributedString(Utility.dateString(boardSummary.date, format: "dd/MM/yyyy"))
        case .vulnerability:
            AttributedString(boardSummary.vulnerability.string)
        case .eventType:
            AttributedString(boardSummary.eventType.string)
        case .boardScoreType:
            AttributedString(boardSummary.boardScoreType.string)
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
        case .date, .suitType, .levelType:
            120
        case .partner, .location, .contractMade:
            100
        case .contract:
            90
        default:
            80
        }
    }
}

struct InsightsView: View {
    @State var boardSummaries: [BoardSummaryViewModel] = []
    @State var columns = InsightColumn.defaultCases
    var gridColumns : [GridItem] { Array(repeating: GridItem(.adaptive(minimum: 50), spacing: 0), count: columns.count) }
    
    var body: some View {
        StandardView("Insights") {
            ZStack {
                VStack(spacing: 0) {
                    Rectangle()
                        .frame(height: 80)
                        .foregroundColor(Palette.contrastTile.background)
                    Spacer()
                }
                VStack(spacing: 0) {
                    ScrollView(.horizontal) {
                        ScrollView {
                            HStack {
                                Spacer().frame(width: 10)
                                LazyVStack(pinnedViews: [.sectionHeaders]) {
                                    Section(header: headerView) {
                                        if !boardSummaries.isEmpty {
                                            Grid(horizontalSpacing: 5) {
                                                ForEach(0..<boardSummaries.count, id: \.self) { boardIndex in
                                                    GridRow {
                                                        ForEach(0..<columns.count, id: \.self) { columnIndex in
                                                            let column = columns[columnIndex]
                                                            HStack {
                                                                if column.align != .leading {
                                                                    Spacer()
                                                                }
                                                                Text(column.value(boardSummary: boardSummaries[boardIndex]))
                                                                if column.align != .trailing {
                                                                    Spacer()
                                                                }
                                                            }
                                                            .frame(width: column.width, height: 20)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .fixedSize(horizontal: true, vertical: false)
                                Spacer().frame(width: 10)
                            }
                        }
                        .clipped()
                    }
                    .clipped()
                }
            }
            Spacer()
        }
        .onAppear {
            Insights.build()
            boardSummaries = Insights.Load()
        }
    }
    
    var headerView : some View {
        HStack {
            Spacer().frame(width: 10)
            Grid(horizontalSpacing: 5) {
                GridRow {
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
            }
            Spacer().frame(width: 10)
        }
        .palette(.contrastTile)
    }
}
