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
    
    init(columnType: CalculatedType, percent: Bool) {
        switch columnType {
        case .numeric:
            self = (percent ? .percent :.numeric)
        case .string:
            self = .string
        case .boolean:
            self = .boolean
        }
    }
}

enum InsightColumn : Codable, Hashable, Equatable, Transferable {
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
    case contractLevel
    case contractSuit
    case contractDouble
    case contractRedouble
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
    case calculated(column: CalculatedColumn)
    
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
     .contractLevel,
     .contractSuit,
     .contractDouble,
     .contractRedouble,
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
        case .contractLevel:
            "Contract Level"
        case .contractSuit:
            "Contract Suit"
        case .contractDouble:
            "ContractDouble"
        case .contractRedouble:
            "ContractRedouble"
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
            "\(pairType.string) Suit"
        case .declare(let pairType):
            "\(pairType.string) Declare%"
        case .medianTricks(let pairType):
            "\(pairType.string) Median Made"
        case .modeTricks(let pairType):
            "\(pairType.string) Mode Made"
        case .ddTricks(let pairType):
            "\(pairType.string) DD Made"
        case .fit(let pairType):
            "\(pairType.string) Fit"
        case .points(let seatPlayer):
            "\(seatPlayer.string) Points"
        case .suitType:
            "Suit Type"
        case .levelType:
            "Level Type"
        case .totalTricks:
            "Total Tricks"
        case .totalTricksDd:
            "Total Tricks DD"
        case .calculated(let column):
            column.title
        }
    }
    
    var type: CalculatedType {
        switch self.insightType {
        case .numeric, .percent:
                .numeric
        case .boolean:
                .boolean
        case .string:
                .string
        }
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
        case .contractLevel:
                .numeric
        case .contractSuit:
                .string
        case .contractDouble:
                .boolean
        case .contractRedouble:
                .boolean
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
        case .calculated(let column):
            InsightColumnType(columnType: column.type, percent: column.percent)
        }
    }
    
    func value<ViewModel: NSObject>(viewModel: ViewModel) throws -> CalculatedValue {
        var value = try insightValue(boardSummary: viewModel as! BoardSummaryViewModel)
        if self.insightType == .percent {
            value.numeric! /= 100
        }
        return value
    }
    
    func insightValue(boardSummary: BoardSummaryViewModel) throws -> CalculatedValue {
        switch self {
        case .eventDesc:
            return CalculatedValue(boardSummary.scorecard.desc)
        case .boardIndex:
            return CalculatedValue(boardSummary.boardIndex)
        case .sessionNumber:
            return CalculatedValue(boardSummary.session)
        case .boardNumber:
            return CalculatedValue(boardSummary.boardNumber)
        case .location:
            return CalculatedValue(boardSummary.location!.short == "" ? boardSummary.location!.name : boardSummary.location!.short)
        case .partner:
            return CalculatedValue(boardSummary.partner!.name.components(separatedBy: " ").first!)
        case .date:
            return CalculatedValue(Utility.dateString(boardSummary.date, format: "dd/MM/yyyy"))
        case .vulnerability:
            return CalculatedValue(boardSummary.vulnerability.string)
        case .eventType:
            return CalculatedValue(boardSummary.eventType.string)
        case .boardScoreType:
            return CalculatedValue(boardSummary.boardScoreType.brief)
        case .contract:
            return CalculatedValue(boardSummary.contract.compact)
        case .contractLevel:
            return CalculatedValue(boardSummary.contract.level.number)
        case .contractSuit:
            return CalculatedValue(boardSummary.contract.suit.string)
        case .contractDouble:
            return CalculatedValue(boardSummary.contract.double == .doubled)
        case .contractRedouble:
            return CalculatedValue(boardSummary.contract.double == .redoubled)
        case .contractMade:
            return CalculatedValue(boardSummary.contract.compact + " " + Scorecard.madeString(made: boardSummary.made ?? 0))
        case .declarer:
            return CalculatedValue(boardSummary.declarer.pairType.string)
        case .made:
            return CalculatedValue(boardSummary.made ?? 0)
        case .score:
            return CalculatedValue(boardSummary.score)
        case .fieldSize:
            return CalculatedValue(boardSummary.fieldSize)
        case .gameOdds:
            return CalculatedValue(boardSummary.gameOdds)
        case .slamOdds:
            return CalculatedValue(boardSummary.slamOdds)
        case .compContract:
            return CalculatedValue(boardSummary.compContract.compact)
        case .compDeclarer:
            return CalculatedValue(boardSummary.compDeclarer.string)
        case .compDdMade:
            return CalculatedValue(boardSummary.compDdMade ?? 0)
        case .compDdScore:
            return CalculatedValue(boardSummary.compDdScore)
        case .compMakeScore:
            return CalculatedValue(boardSummary.compMakeScore)
        case .compMakeOdds:
            return CalculatedValue(boardSummary.compMakeOdds)
        case .suit(let pairType):
            return CalculatedValue(boardSummary.suit[pairType]!.string)
        case .declare(let pairType):
            return CalculatedValue(boardSummary.declare[pairType]!)
        case .medianTricks(let pairType):
            return CalculatedValue(boardSummary.medianTricks[pairType]!)
        case .modeTricks(let pairType):
            return CalculatedValue(boardSummary.modeTricks[pairType]!)
        case .ddTricks(let pairType):
            return CalculatedValue(boardSummary.ddTricks[pairType]!)
        case .fit(let pairType):
            return CalculatedValue(boardSummary.fit[pairType]!)
        case .points(let seatPlayer):
            return CalculatedValue(boardSummary.points[seatPlayer]!)
        case .suitType:
            return CalculatedValue(boardSummary.suitType.string)
        case .levelType:
            return CalculatedValue(boardSummary.levelType.string)
        case .totalTricks:
            return CalculatedValue(boardSummary.totalTricks)
        case .totalTricksDd:
            return CalculatedValue(boardSummary.ddTricks[.we]! < 0 || boardSummary.ddTricks[.they]! < 0 ? 0 : boardSummary.totalTricksDd)
        case .calculated(let column):
            do {
                return try column.value(viewModel: boardSummary, evaluate: recurseValue)
            } catch {
                throw CalculatedError.errorEvaluatingCalculatedColumn(column.name)
            }
        }
    }
    
    func recurseValue(boardSummary: BoardSummaryViewModel, column: InsightColumn) throws -> CalculatedValue {
        return try column.insightValue(boardSummary: boardSummary)
    }
    
    func formattedText(_ value: CalculatedValue) -> String {
        switch value.type {
        case .string:
            return value.string!
        case .boolean:
            return value.boolean! ? "✔️" : ""
        case .numeric:
            if blankIf.evaluate(value: value.numeric!) {
                return ""
            } else {
                return value.numeric!.toString(places: decimalPlaces)
            }
        }
    }
    
    func textValue(boardSummary: BoardSummaryViewModel) -> AttributedString {
        do {
            var text = try formattedText(insightValue(boardSummary: boardSummary))
            if self.insightType == .percent && text != "" {
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
        } catch {
            return AttributedString("ERROR")
        }
    }
    
    var width: CGFloat {
        switch self {
        case .eventDesc:
            return 180
        case .date, .location, .suitType, .levelType, .eventType:
            return 120
        case .partner, .contractMade, .boardScoreType:
            return 100
        case .contract:
            return 90
        case .calculated(let calculated):
            return CGFloat(calculated.width)
        default:
            return 80
        }
    }
    
    var decimalPlaces: Int {
        switch self {
        case .calculated(let calculated):
            calculated.decimalPlaces
        default:
            0
        }
    }
    
    var align: CalculatedAlignment {
        switch self {
        case .eventDesc:
            return .left
        case .boardIndex, .sessionNumber, .boardNumber, .vulnerability, .eventType, .boardScoreType, .contract, .contractMade, .declarer, .made, .compContract, .compDeclarer, .suit, .suitType, .levelType, .partner, .location, .date:
            return .center
        case .calculated:
            switch type {
            case .boolean:
                return .center
            case .numeric:
                return .right
            case .string:
                return .left
            }
        default:
            return .right
        }
    }
    
    var blankIf: CalculatedBlankIf {
        switch self {
        case .sessionNumber, .contractLevel, .score, .fieldSize , .gameOdds, .slamOdds, .compDdScore, .compMakeScore, .compMakeOdds, .medianTricks, .modeTricks, .ddTricks, .fit, .points, .totalTricks, .totalTricksDd:
            .zero
        case .calculated(let calculated):
            calculated.blankIf
        default:
            .none
        }
    }
}
