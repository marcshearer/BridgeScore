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
            self = (percent ? .percent : .numeric)
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
    case age
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
    case declarerPair
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
    case passout
    case partScore(pairType: PairType)
    case game(pairType: PairType)
    case smallSlam(pairType: PairType)
    case grandSlam(pairType: PairType)
    case spacer
    case calculated(column: CalculatedColumn)
    case prompt(prompt: CalculatedPrompt)
    
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
        .contractLevel,
        .contractSuit,
        .contractDouble,
        .contractRedouble,
        .age,
        .passout,
        .partScore(pairType: .we),
        .game(pairType: .we),
        .smallSlam(pairType: .we),
        .grandSlam(pairType: .we),
        .passout,
        .partScore(pairType: .they),
        .game(pairType: .they),
        .smallSlam(pairType: .they),
        .grandSlam(pairType: .they)
    ]
    
    static let allColumns: [InsightColumn] =
    [.eventDesc,
     .location,
     .partner,
     .date,
     .age,
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
     .declarerPair,
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
     .passout,
     .partScore(pairType: .we),
     .game(pairType: .we),
     .smallSlam(pairType: .we),
     .grandSlam(pairType: .we),
     .partScore(pairType: .they),
     .game(pairType: .they),
     .smallSlam(pairType: .they),
     .grandSlam(pairType: .they),
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
        case .suit(let pairType), .declare(let pairType), .medianTricks(let pairType), .modeTricks(let pairType), .ddTricks(let pairType), .fit(let pairType), .partScore(let pairType), .game(let pairType), .smallSlam(let pairType), .grandSlam(let pairType):
            result += pairType.string
        case .points(let seatPlayer):
            result += seatPlayer.suffix
        case .calculated(let calculated):
            result = "calc.\(calculated.name)"
        case .prompt(let prompt):
            result = "prompt.\(prompt.name)"
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
        case .age:
            "Age"
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
            "Contract Double"
        case .contractRedouble:
            "Contract Redouble"
        case .made:
            "Made"
        case .contractMade:
            "Contract / Made"
        case .declarer:
            "By"
        case .declarerPair:
            "By Pair"
        case .score:
            "Score"
        case .fieldSize:
            "Field Size"
        case .gameOdds:
            "Game Odds%"
        case .slamOdds:
            "Slam Odds%"
        case .compContract:
            "Compete Contract"
        case .compDeclarer:
            "Compete By"
        case .compDdMade:
            "Compete Made"
        case .compDdScore:
            "Compete DD Score"
        case .compMakeScore:
            "Compete Make Score"
        case .compMakeOdds:
            "Compete Make Odds"
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
        case .passout:
            "Passout"
        case .partScore(let seatPlayer):
            "\(seatPlayer.string) Part Score"
        case .game(let seatPlayer):
            "\(seatPlayer.string) Game"
        case .smallSlam(let seatPlayer):
            "\(seatPlayer.string) Small Slam"
        case .grandSlam(let seatPlayer):
            "\(seatPlayer.string) Grand Slam"
        case .spacer:
            ""
        case .calculated(let column):
            column.title
        case .prompt(let prompt):
            prompt.promptText
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
        case .age:
                .numeric
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
        case .declarerPair:
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
        case .passout, .partScore, .game, .smallSlam, .grandSlam:
                .percent
        case .spacer:
                .string
        case .calculated(let column):
            InsightColumnType(columnType: column.type, percent: column.percent)
        case .prompt(let prompt):
            InsightColumnType(columnType: prompt.type, percent: false)
        }
    }
    
    var visibility: CalculatedVisibility {
        switch self {
        case .boardIndex, .boardNumber, .sessionNumber:
            .boardOnly
        case .calculated(let calculated):
            calculated.visibility
        default:
            switch type {
            case .numeric:
                    .both
            case .boolean:
                    .both
            case .string:
                    .boardOnly
            }
        }
    }
    
    var totalType: CalculatedTotalType? {
        switch self {
        case .contractDouble:
            .total
        case .contractRedouble:
            .total
        case .made:
            .total
        case .calculated(let calculated):
            calculated.totalType
        default:
            .average
        }
    }
    
    func value<ViewModel: NSObject>(report: Report, viewModel: ViewModel) throws -> CalculatedValue {
        let value = try insightValue(report: report, boardSummary: viewModel as! BoardSummaryViewModel)
        if self.insightType == .percent {
            value.numeric! /= 100
        }
        return value
    }
    
    func totalValue<ViewModel: NSObject>(report: Report, viewModel: ViewModel) throws -> CalculatedValue {
        let boardSummary = viewModel as! BoardSummaryViewModel
        let value = try self.insightValue(report: report, boardSummary: boardSummary)
        switch self {
        case .compDdMade, .compDdScore, .ddTricks,.totalTricksDd:
            return CalculatedValue(value.numeric! < 0 ? 0 : value.numeric!)
        default:
            return value
        }
    }
    
    var isCalculated: Bool {
        if case .calculated = self {
            true
        } else {
            false
        }
    }
    
    var calculatedColumn: CalculatedColumn? {
        if case .calculated(let calculated) = self {
            calculated
        } else {
            nil
        }
    }
    
    var isPrompt: Bool {
        if case .prompt = self {
            true
        } else {
            false
        }
    }
    
    var promptColumn: CalculatedPrompt? {
        if case .prompt(let prompt) = self {
            prompt
        } else {
            nil
        }
    }
    
    func insightValue(report: Report, boardSummary: BoardSummaryViewModel) throws -> CalculatedValue {
        switch self {
        case .eventDesc:
            return summaryValue(boardSummary.scorecard.desc)
        case .boardIndex:
            return summaryValue(boardSummary.boardIndex)
        case .sessionNumber:
            return summaryValue(boardSummary.session)
        case .boardNumber:
            return summaryValue(boardSummary.boardNumber)
        case .location:
            return summaryValue(boardSummary.location!.name)
        case .partner:
            return summaryValue(boardSummary.partner!.name)
        case .date:
            return summaryValue(Utility.dateString(boardSummary.date, format: "dd/MM/yyyy"))
        case .age:
            return summaryValue(todayNumber - DayNumber(from: boardSummary.date))
        case .vulnerability:
            return summaryValue(boardSummary.vulnerability.string)
        case .eventType:
            return summaryValue(boardSummary.eventType.string)
        case .boardScoreType:
            return summaryValue(boardSummary.boardScoreType.brief)
        case .contract:
            return summaryValue(boardSummary.contract.compact)
        case .contractLevel:
            return summaryValue(boardSummary.contract.level.number)
        case .contractSuit:
            return summaryValue(boardSummary.contract.suit.string)
        case .contractDouble:
            return summaryValue(boardSummary.contract.double == .doubled)
        case .contractRedouble:
            return summaryValue(boardSummary.contract.double == .redoubled)
        case .contractMade:
            return summaryValue(boardSummary.contract.level == .passout ? boardSummary.contract.string : boardSummary.contract.compact + " " + Scorecard.madeString(made: boardSummary.made ?? 0))
        case .declarer:
            return summaryValue(boardSummary.declarer.simple)
        case .declarerPair:
            return summaryValue(boardSummary.declarer.pairType.string)
        case .made:
            return summaryValue(boardSummary.made ?? 0)
        case .score:
            return summaryValue(boardSummary.score)
        case .fieldSize:
            return summaryValue(boardSummary.fieldSize)
        case .gameOdds:
            return summaryValue(boardSummary.gameOdds)
        case .slamOdds:
            return summaryValue(boardSummary.slamOdds)
        case .compContract:
            return summaryValue(boardSummary.compContract.compact)
        case .compDeclarer:
            return summaryValue(boardSummary.compDeclarer.string)
        case .compDdMade:
            return summaryValue(boardSummary.compDdMade ?? 0)
        case .compDdScore:
            return summaryValue(boardSummary.compDdScore)
        case .compMakeScore:
            return summaryValue(boardSummary.compMakeScore)
        case .compMakeOdds:
            return summaryValue(boardSummary.compMakeOdds)
        case .suit(let pairType):
            return summaryValue(boardSummary.suit[pairType]!.string)
        case .declare(let pairType):
            return summaryValue(boardSummary.declare[pairType]!)
        case .medianTricks(let pairType):
            return summaryValue(boardSummary.medianTricks[pairType]!)
        case .modeTricks(let pairType):
            return summaryValue(boardSummary.modeTricks[pairType]!)
        case .ddTricks(let pairType):
            return summaryValue(boardSummary.ddTricks[pairType]!)
        case .fit(let pairType):
            return summaryValue(boardSummary.fit[pairType]!)
        case .points(let seatPlayer):
            return summaryValue(boardSummary.points[seatPlayer]!)
        case .suitType:
            return summaryValue(boardSummary.contract.suitType.string)
        case .levelType:
            return summaryValue("\(boardSummary.contract.levelType.rawValue)")
        case .totalTricks:
            return summaryValue(boardSummary.totalTricks)
        case .totalTricksDd:
            return summaryValue(boardSummary.ddTricks[.we]! < 0 || boardSummary.ddTricks[.they]! < 0 ? 0 : boardSummary.totalTricksDd)
        case .passout:
            return summaryValue(boardSummary.passout)
        case .partScore(let pairType):
            return summaryValue(boardSummary.partScore[pairType]!)
        case .game(let pairType):
            return summaryValue(boardSummary.game[pairType]!)
        case .smallSlam(let pairType):
            return summaryValue(boardSummary.smallSlam[pairType]!)
        case .grandSlam(let pairType):
            return summaryValue(boardSummary.grandSlam[pairType]!)
        case .spacer:
            return CalculatedValue("")
        case .calculated(let column):
            do {
                return try column.value(report: report, viewModel: boardSummary, evaluate: recurseValue)
            } catch {
                throw CalculatedError.errorEvaluatingCalculatedColumn(column.name)
            }
        case .prompt(let prompt):
            return prompt.value ?? prompt.calculatedDefaultValue
        }
    }
    
    func totalValue(value: Float, count: Int) -> Float {
        switch totalType {
        case .average:
            return value / Float(count)
        default:
            return value
        }
    } 
    
    func summaryValue(_ value: Any) -> CalculatedValue {
        switch insightType {
        case .percent:
            CalculatedValue(Float(value as! Int) / Float(100))
        case .numeric:
            CalculatedValue(value as! Int)
        case .string:
            CalculatedValue(value as! String)
        case .boolean:
            CalculatedValue(value as! Bool)
        }
    }
    
    func recurseValue(report: Report, boardSummary: BoardSummaryViewModel, column: InsightColumn) throws -> CalculatedValue {
        return try column.insightValue(report: report, boardSummary: boardSummary)
    }
    
    func formattedText(report: Report, _ value: CalculatedValue) -> String {
        switch self.insightType {
        case .string:
            return value.string!
        case .boolean:
            return value.boolean!.asTick
        case .numeric:
            let blankIf = blankIf
            if blankIf != .none && blankIf.evaluate(value: value.numeric!) {
                return ""
            } else {
                return value.numeric!.toString(places: decimalPlaces)
            }
        case .percent:
            if blankIf.evaluate(value: value.numeric!) {
                return ""
            } else {
                return Utility.round(value.numeric! * 100, places: 2).toString(places: decimalPlaces) + "%"
            }
        }
    }
    
    func textValue(report: Report, boardSummary: BoardSummaryViewModel) -> AttributedString {
        do {
            let text = try formattedText(report: report, insightValue(report: report, boardSummary: boardSummary))
            
            // Only have a case for fields where above is not correct
            return switch self {
            case .location:
                AttributedString(boardSummary.location!.short == "" ? boardSummary.location!.name : boardSummary.location!.short)
            case .partner:
                AttributedString(boardSummary.partner!.name.components(separatedBy: " ").first!)
            case .sessionNumber:
                AttributedString(boardSummary.session == 0 ? "" : "\(boardSummary.session)")
            case .contract:
                boardSummary.contract.colorCompact
            case .contractMade:
                boardSummary.contract.level == .passout ? boardSummary.contract.colorString :  boardSummary.contract.colorCompact + " " + AttributedString(Scorecard.madeString(made: boardSummary.made ?? 0))
            case .made:
                AttributedString(Scorecard.madeString(made: boardSummary.made ?? 0))
            case .levelType:
                AttributedString(boardSummary.contract.levelType.string)
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
            180
        case .date, .location, .suitType, .levelType, .eventType:
            120
        case .partner, .contractMade, .boardScoreType, .declarer:
            100
        case .contract, .compContract, .compDeclarer:
            90
        case .calculated(let calculated):
            CGFloat(calculated.width)
        case .spacer:
            0
        default:
            80
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
            .left
        case .boardIndex, .sessionNumber, .boardNumber, .vulnerability, .eventType, .boardScoreType, .contract, .contractMade, .declarer, .made, .compContract, .compDeclarer, .suit, .suitType, .levelType, .partner, .location, .date:
            .center
        case .calculated(let calculated):
            calculated.align
        default:
            .right
        }
    }
    
    var blankIf: CalculatedBlankIf {
        switch self {
        case .sessionNumber, .contractLevel, .fieldSize , .gameOdds, .slamOdds, .compDdScore, .compMakeScore, .compMakeOdds, .medianTricks, .modeTricks, .ddTricks, .fit, .points, .totalTricks, .totalTricksDd, .passout, .partScore, .game, .smallSlam, .grandSlam:
            .zero
        case .calculated(let calculated):
            calculated.blankIf
        default:
            .none
        }
    }
    
    var recalculationIndex: Int {
        if case .calculated(let calculated) = self {
            calculated.recalculationIndex
        } else {
            0
        }
    }
}
