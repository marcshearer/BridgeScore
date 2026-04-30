//
//  Insights View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 27/04/2026.
//

import SwiftUI

enum InsightColumn {
    
    case desc
    case boardIndex
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
    
    static let defaultCases: [InsightColumn] = [.desc, .boardIndex, .partner, .location, .date, .vulnerability, .eventType, .boardScoreType, .contractMade, .declarer, .score, .fieldSize, .gameOdds, .slamOdds, .compContract, .compDeclarer, .compDdMade, .compDdScore, .compMakeScore, .compMakeOdds, .suit(pairType: .we), .declare(pairType: .we), .medianTricks(pairType: .we), .modeTricks(pairType: .we), .ddTricks(pairType: .we), .fit(pairType: .we), .suit(pairType: .they), .declare(pairType: .they), .medianTricks(pairType: .they), .modeTricks(pairType: .they), .ddTricks(pairType: .they), .fit(pairType: .they), .points(seatPlayer: .player), .points(seatPlayer: .partner), .points(seatPlayer: .lhOpponent), .points(seatPlayer: .rhOpponent), .suitType, .levelType, .totalTricks, .totalTricksDd]
    
    var title: String {
        switch self {
        case .desc:
            "Desc"
        case .boardIndex:
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
        case .desc:
            AttributedString(boardSummary.scorecard.desc)
        case .boardIndex:
            AttributedString("\(boardSummary.boardIndex)")
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
            !boardSummary.isCompetitive ? "" : AttributedString(Scorecard.madeString(made: boardSummary.compDdMade ?? 0))
        case .compDdScore:
            !boardSummary.isCompetitive ? "" : AttributedString("\(boardSummary.compDdScore)%")
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
            AttributedString(boardSummary.suit[pairType]! == .blank ? "" : "\(boardSummary.ddTricks[pairType]!)")
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
            AttributedString("\(boardSummary.totalTricksDd)")
        }
    }
    
    var align: TextAlignment {
        switch self {
        case .desc, .partner, .location:
                .leading
        case .vulnerability, .eventType, .boardScoreType, .contract, .contractMade, .declarer, .made, .compContract, .compDeclarer, .suit, .suitType, .levelType:
                .center
        default:
                .trailing
        }
    }
        
    var width: CGFloat {
        switch self {
        case .desc:
            250
        case .date, .suitType, .levelType:
            120
        case .partner, .location:
            100
        case .contract:
            90
        default:
            50
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
                            LazyVGrid(columns: gridColumns, pinnedViews: [.sectionHeaders]) {
                                Section(header: headerView) {
                                    if !boardSummaries.isEmpty {
                                        ForEach(0..<((columns.count * boardSummaries.count) - 1), id: \.self) { index in
                                            let columnIndex = index % columns.count
                                            let boardIndex = index / columns.count
                                            let column = columns[columnIndex]
                                            Text(column.value(boardSummary: boardSummaries[boardIndex]))
                                                .frame(width: column.width, height: 20)
                                        }
                                    }
                                }
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
        LazyVGrid(columns: gridColumns) {
            ForEach(0..<columns.count, id: \.self) { columnIndex in
                let column = columns[columnIndex]
                Text(column.title)
                    .frame(width: column.width, height: 80)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
            }
        }
        .palette(.contrastTile)
    }
}
