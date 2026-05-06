//
//  Insight Column.swift
//  BridgeScore
//
//  Created by Marc Shearer on 06/05/2026.
//

import SwiftUI

enum InsightColumnType {
    case string
    case numeric
    case percent
    case boolean
}

enum InsightColumn : DerivedVariable, Codable, Hashable, Equatable, Transferable {
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
    case made
    case declarer
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
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
    
    static let defaultPinnedColumns: [InsightColumn] =
    [.eventDesc,
     .location,
     .partner,
     .date,
     .boardNumber]
    
    static let defaultExcludeColumns: [InsightColumn] = [
        .boardIndex,
        .sessionNumber,
        .contract,
        .made,
    ]
    
    static let allColumns: [InsightColumn] =
    [.eventDesc,
     .location,
     .partner,
     .date,
     .sessionNumber,
     .boardNumber,
     .vulnerability,
     .eventType,
     .boardScoreType,
     .contract,
     .made,
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
    
    static let defaultColumns = InsightColumn.allColumns.filter{!defaultPinnedColumns.contains($0) && !defaultExcludeColumns.contains($0)}
    
    var name: String {
        var result = "\(self)"
        if let start = result.components(separatedBy: "(").first {
            result = start
        }
        switch self {
        case .suit(let pairType), .declare(let pairType), .medianTricks(let pairType), .modeTricks(let pairType), .ddTricks(let pairType), .fit(let pairType):
            result += pairType.string
        case .points(let seatPlayer):
            result += seatPlayer.suffix
        default:
            break
        }
        return result
    }
    
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
        case .made:
            "Made"
        case .contractMade:
            "Contract / Made"
        case .declarer:
            "By"
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
    
    var type: DerivedType {
        switch self.insightType {
        case .numeric, .percent:
                .numeric
        case .boolean:
                .boolean
        case .string:
                .string
        }
    }
    
    var decimalPlaces: Int {
        0
    }
    
    var insightType: InsightColumnType {
        switch self {
        case .eventDesc:
                .string
        case .sessionNumber:
                .numeric
        case .boardIndex, .boardNumber:
                .numeric
        case .location:
                .string
        case .partner:
                .string
        case .date:
                .string
        case .vulnerability:
                .string
        case .eventType:
                .string
        case .boardScoreType:
                .string
        case .contract:
                .string
        case .made:
                .numeric
        case .contractMade:
                .string
        case .declarer:
                .string
        case .score:
                .numeric
        case .fieldSize:
                .numeric
        case .gameOdds:
                .percent
        case .slamOdds:
                .percent
        case .compContract:
                .string
        case .compDeclarer:
                .string
        case .compDdMade:
                .numeric
        case .compDdScore:
                .numeric
        case .compMakeScore:
                .numeric
        case .compMakeOdds:
                .percent
        case .suit:
                .string
        case .declare:
                .percent
        case .medianTricks:
                .numeric
        case .modeTricks:
                .numeric
        case .ddTricks:
                .numeric
        case .fit:
                .numeric
        case .points:
                .numeric
        case .suitType:
                .string
        case .levelType:
                .string
        case .totalTricks:
                .numeric
        case .totalTricksDd:
                .numeric
        }
    }
    
    func value<ViewModel: NSObject>(viewModel: ViewModel) -> DerivedValue {
        var value = insightValue(boardSummary: viewModel as! BoardSummaryViewModel)
        if self.insightType == .percent {
            value.numeric! /= 100
        }
        return value
    }
    
    func insightValue(boardSummary: BoardSummaryViewModel) -> DerivedValue {
        return switch self {
        case .eventDesc:
            DerivedValue(boardSummary.scorecard.desc)
        case .boardIndex:
            DerivedValue(boardSummary.boardIndex)
        case .sessionNumber:
            DerivedValue(boardSummary.session)
        case .boardNumber:
            DerivedValue(boardSummary.boardNumber)
        case .location:
            DerivedValue(boardSummary.location!.short == "" ? boardSummary.location!.name : boardSummary.location!.short)
        case .partner:
            DerivedValue(boardSummary.partner!.name.components(separatedBy: " ").first!)
        case .date:
            DerivedValue(Utility.dateString(boardSummary.date, format: "dd/MM/yyyy"))
        case .vulnerability:
            DerivedValue(boardSummary.vulnerability.string)
        case .eventType:
            DerivedValue(boardSummary.eventType.string)
        case .boardScoreType:
            DerivedValue(boardSummary.boardScoreType.brief)
        case .contract:
            DerivedValue(boardSummary.contract.compact)
        case .contractMade:
            DerivedValue(boardSummary.contract.compact + " " + Scorecard.madeString(made: boardSummary.made ?? 0))
        case .declarer:
            DerivedValue(boardSummary.declarer.pairType.string)
        case .made:
            DerivedValue(Scorecard.madeString(made: boardSummary.made ?? 0))
        case .score:
            DerivedValue(boardSummary.score)
        case .fieldSize:
            DerivedValue(boardSummary.fieldSize)
        case .gameOdds:
            DerivedValue(boardSummary.gameOdds)
        case .slamOdds:
            DerivedValue(boardSummary.slamOdds)
        case .compContract:
            DerivedValue(boardSummary.compContract.compact)
        case .compDeclarer:
            DerivedValue(boardSummary.compDeclarer.string)
        case .compDdMade:
            DerivedValue(boardSummary.compDdMade ?? 0)
        case .compDdScore:
            DerivedValue(boardSummary.compDdScore)
        case .compMakeScore:
            DerivedValue(boardSummary.compMakeScore)
        case .compMakeOdds:
            DerivedValue(boardSummary.compMakeOdds)
        case .suit(let pairType):
            DerivedValue(boardSummary.suit[pairType]!.string)
        case .declare(let pairType):
            DerivedValue(boardSummary.declare[pairType]!)
        case .medianTricks(let pairType):
            DerivedValue(boardSummary.medianTricks[pairType]!)
        case .modeTricks(let pairType):
            DerivedValue(boardSummary.modeTricks[pairType]!)
        case .ddTricks(let pairType):
            DerivedValue(boardSummary.ddTricks[pairType]!)
        case .fit(let pairType):
            DerivedValue(boardSummary.fit[pairType]!)
        case .points(let seatPlayer):
            DerivedValue(boardSummary.points[seatPlayer]!)
        case .suitType:
            DerivedValue(boardSummary.suitType.string)
        case .levelType:
            DerivedValue(boardSummary.levelType.string)
        case .totalTricks:
            DerivedValue(boardSummary.totalTricks)
        case .totalTricksDd:
            DerivedValue(boardSummary.ddTricks[.we]! < 0 || boardSummary.ddTricks[.they]! < 0 ? 0 : boardSummary.totalTricksDd)
        }
    }
    
    func textValue(boardSummary: BoardSummaryViewModel) -> AttributedString {
        var text = self.insightValue(boardSummary: boardSummary).integerText
        if self.insightType == .percent {
            text += "%"
        }
        
        // Only have a case for fields where above is not correct
        return switch self {
        case .sessionNumber:
            AttributedString(boardSummary.session == 0 ? "" : "\(boardSummary.session)")
        case .contract:
            boardSummary.contract.colorCompact
        case .contractMade:
            boardSummary.contract.colorCompact + " " + AttributedString(Scorecard.madeString(made: boardSummary.made ?? 0))
        case .made:
            AttributedString(Scorecard.madeString(made: boardSummary.made ?? 0))
        case .compContract:
            !boardSummary.isCompetitive ? "" : boardSummary.compContract.colorCompact
        case .compDeclarer:
            AttributedString(!boardSummary.isCompetitive ? "" : text)
        case .compDdMade:
            AttributedString(!boardSummary.isCompetitive || (boardSummary.compDdMade ?? -1) < 0 ? "" : text)
        case .compDdScore:
            AttributedString(!boardSummary.isCompetitive || (boardSummary.compDdMade ?? -1) < 0 ? "" : text)
        case .compMakeScore:
            AttributedString(!boardSummary.isCompetitive ? "" : text)
        case .compMakeOdds:
            AttributedString(!boardSummary.isCompetitive ? "" : text)
        case .suit(let pairType):
            boardSummary.suit[pairType]!.colorString
        case .medianTricks(let pairType):
            AttributedString(boardSummary.suit[pairType]! == .blank ? "" : text)
        case .modeTricks(let pairType):
            AttributedString(boardSummary.suit[pairType]! == .blank ? "" : text)
        case .ddTricks(let pairType):
            AttributedString(boardSummary.ddTricks[pairType]! < 0 ? "" : boardSummary.suit[pairType]! == .blank ? "" : text)
        case .fit(let pairType):
            AttributedString(boardSummary.suit[pairType]! == .blank ? "" : text)
        case .totalTricksDd:
            AttributedString(boardSummary.ddTricks[.we]! < 0 || boardSummary.ddTricks[.they]! < 0 ? "" : text)
        default:
            AttributedString(text)
        }
    }
    
    var align: TextAlignment {
        switch self {
        case .eventDesc:
                .leading
        case .boardIndex, .sessionNumber, .boardNumber, .vulnerability, .eventType, .boardScoreType, .contract, .contractMade, .declarer, .made, .compContract, .compDeclarer, .suit, .suitType, .levelType, .partner, .location, .date:
                .center
        default:
                .trailing
        }
    }
        
    var width: CGFloat {
        switch self {
        case .eventDesc:
            180
        case .date, .location, .suitType, .levelType, .eventType:
            120
        case .partner, .contractMade, .boardScoreType:
            100
        case .contract:
            90
        default:
            80
        }
    }
}
