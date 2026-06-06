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

class InsightColumnConfig : Codable, Equatable, Hashable, Identifiable, ObservableObject {
    var title: String = ""
    var width: Int = 80
    var align: CalculatedAlignment = .right
    var blankIf: CalculatedBlankIf = .none
    var visibility: CalculatedVisibility = .both
    var totalType: CalculatedTotalType = .average
    
    init() {
    }
    
    convenience init(from column: InsightColumn) {
        self.init()
        title = column.title
        width = Int(column.width)
        align = column.align
        blankIf = column.blankIf
        visibility = column.visibility
        totalType = column.totalType ?? .average
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(width)
        hasher.combine(align)
        hasher.combine(blankIf)
        hasher.combine(visibility)
        hasher.combine(totalType)
    }
    
    enum CodingKeys: String, CodingKey {
        case title
        case width
        case align
        case blankIf
        case visibility
        case totalType
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        width = try container.decodeIfPresent(Int.self, forKey: .width) ?? 80
        align = try container.decodeIfPresent(CalculatedAlignment.self, forKey: .align) ?? .right
        blankIf = try container.decodeIfPresent(CalculatedBlankIf.self, forKey: .blankIf) ?? .none
        visibility = try container.decodeIfPresent(CalculatedVisibility.self, forKey: .visibility) ?? .both
        totalType = try container.decodeIfPresent(CalculatedTotalType.self, forKey: .totalType) ?? .average
    }
    
    func copy(from: InsightColumnConfig) {
        self.title = from.title
        self.width = from.width
        self.align = from.align
        self.blankIf = from.blankIf
        self.visibility = from.visibility
        self.totalType = from.totalType
    }
    
    static func == (lhs: InsightColumnConfig, rhs: InsightColumnConfig) -> Bool {
        return lhs.title == rhs.title && lhs.align == rhs.align && lhs.width == rhs.width && lhs.blankIf == rhs.blankIf && lhs.visibility == rhs.visibility && lhs.totalType == rhs.totalType
    }
}



enum InsightColumn : Codable, Hashable, Equatable, Transferable {
    case eventDesc(config: InsightColumnConfig? = nil)
    case boardIndex(config: InsightColumnConfig? = nil)
    case sessionNumber(config: InsightColumnConfig? = nil)
    case boardNumber(config: InsightColumnConfig? = nil)
    case partner(config: InsightColumnConfig? = nil)
    case location(config: InsightColumnConfig? = nil)
    case date(config: InsightColumnConfig? = nil)
    case age(config: InsightColumnConfig? = nil)
    case vulnerability(config: InsightColumnConfig? = nil)
    case eventType(config: InsightColumnConfig? = nil)
    case eventLevel(config: InsightColumnConfig? = nil)
    case boardScoreType(config: InsightColumnConfig? = nil)
    case contract(config: InsightColumnConfig? = nil)
    case contractLevel(config: InsightColumnConfig? = nil)
    case contractSuit(config: InsightColumnConfig? = nil)
    case contractDouble(config: InsightColumnConfig? = nil)
    case contractRedouble(config: InsightColumnConfig? = nil)
    case contractMade(config: InsightColumnConfig? = nil)
    case made(config: InsightColumnConfig? = nil)
    case tricks(config: InsightColumnConfig? = nil)
    case declarer(config: InsightColumnConfig? = nil)
    case declarerPair(config: InsightColumnConfig? = nil)
    case score(config: InsightColumnConfig? = nil)
    case fieldSize(config: InsightColumnConfig? = nil)
    case gameOdds(config: InsightColumnConfig? = nil)
    case slamOdds(config: InsightColumnConfig? = nil)
    case compContract(config: InsightColumnConfig? = nil)
    case compContractLevel(config: InsightColumnConfig? = nil)
    case compDeclarer(config: InsightColumnConfig? = nil)
    case compDdTricks(config: InsightColumnConfig? = nil)
    case compDdScore(config: InsightColumnConfig? = nil)
    case compMakeScore(config: InsightColumnConfig? = nil)
    case compMakeOdds(config: InsightColumnConfig? = nil)
    case suit(config: InsightColumnConfig? = nil, pairType: PairType)
    case declare(config: InsightColumnConfig? = nil, pairType: PairType)
    case medianTricks(config: InsightColumnConfig? = nil, pairType: PairType)
    case modeTricks(config: InsightColumnConfig? = nil, pairType: PairType)
    case ddTricks(config: InsightColumnConfig? = nil, pairType: PairType)
    case fit(config: InsightColumnConfig? = nil, pairType: PairType)
    case points(config: InsightColumnConfig? = nil, seatPlayer: SeatPlayer)
    case suitType(config: InsightColumnConfig? = nil)
    case levelType(config: InsightColumnConfig? = nil)
    case totalTricks(config: InsightColumnConfig? = nil)
    case totalTricksDd(config: InsightColumnConfig? = nil)
    case passout(config: InsightColumnConfig? = nil)
    case partScore(config: InsightColumnConfig? = nil, pairType: PairType)
    case game(config: InsightColumnConfig? = nil, pairType: PairType)
    case smallSlam(config: InsightColumnConfig? = nil, pairType: PairType)
    case grandSlam(config: InsightColumnConfig? = nil, pairType: PairType)
    case spacer
    case calculated(column: CalculatedColumn)
    case prompt(prompt: CalculatedPrompt)
    
    var config: InsightColumnConfig? {
        let mirror = Mirror(reflecting: self)
        guard let configValue = mirror.children.first?.value else { return nil }
        if let directConfig = configValue as? InsightColumnConfig {
            return directConfig
        }
        let tupleMirror = Mirror(reflecting: configValue)
        if let tupleValue = tupleMirror.children.first?.value {
            return tupleValue as? InsightColumnConfig
        }
        return nil
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
    
    static let defaultPinnedColumns: [InsightColumn] =
    [.eventDesc(config: nil),
     .location(config: nil),
     .partner(config: nil),
     .date(config: nil),
     .boardNumber(config: nil)]
    
    static let defaultExcludeColumns: [InsightColumn] = [
        .boardIndex(config: nil),
        .sessionNumber(config: nil),
        .contract(config: nil),
        .made(config: nil),
        .tricks(config: nil),
        .contractLevel(config: nil),
        .contractSuit(config: nil),
        .contractDouble(config: nil),
        .contractRedouble(config: nil),
        .compContractLevel(config: nil),
        .age(config: nil),
        .passout(config: nil),
        .partScore(config: nil, pairType: .we),
        .game(config: nil, pairType: .we),
        .smallSlam(config: nil, pairType: .we),
        .grandSlam(config: nil, pairType: .we),
        .passout(config: nil),
        .partScore(config: nil, pairType: .they),
        .game(config: nil, pairType: .they),
        .smallSlam(config: nil, pairType: .they),
        .grandSlam(config: nil, pairType: .they)
    ]
    
    static let allColumns: [InsightColumn] =
    [.eventDesc(config: nil),
     .location(config: nil),
     .partner(config: nil),
     .date(config: nil),
     .age(config: nil),
     .sessionNumber(config: nil),
     .boardNumber(config: nil),
     .vulnerability(config: nil),
     .eventType(config: nil),
     .eventLevel(config: nil),
     .boardScoreType(config: nil),
     .contract(config: nil),
     .contractLevel(config: nil),
     .contractSuit(config: nil),
     .contractDouble(config: nil),
     .contractRedouble(config: nil),
     .made(config: nil),
     .tricks(config: nil),
     .contractMade(config: nil),
     .declarer(config: nil),
     .declarerPair(config: nil),
     .score(config: nil),
     .fieldSize(config: nil),
     .gameOdds(config: nil),
     .slamOdds(config: nil),
     .suit(pairType: .we),
     .declare(pairType: .we),
     .medianTricks(pairType: .we),
     .modeTricks(pairType: .we),
     .ddTricks(pairType: .we),
     .fit(config: nil, pairType: .we),
     .suit(config: nil, pairType: .they),
     .declare(config: nil, pairType: .they),
     .medianTricks(config: nil, pairType: .they),
     .modeTricks(config: nil, pairType: .they),
     .ddTricks(config: nil, pairType: .they),
     .fit(config: nil, pairType: .they),
     .passout(config: nil),
     .partScore(config: nil, pairType: .we),
     .game(config: nil, pairType: .we),
     .smallSlam(config: nil, pairType: .we),
     .grandSlam(config: nil, pairType: .we),
     .partScore(config: nil, pairType: .they),
     .game(config: nil, pairType: .they),
     .smallSlam(config: nil, pairType: .they),
     .grandSlam(config: nil, pairType: .they),
     .points(config: nil, seatPlayer: .player),
     .points(config: nil, seatPlayer: .partner),
     .points(config: nil, seatPlayer: .lhOpponent),
     .points(config: nil, seatPlayer: .rhOpponent),
     .suitType(config: nil),
     .levelType(config: nil),
     .totalTricks(config: nil),
     .totalTricksDd(config: nil),
     .compContract(config: nil),
     .compContractLevel(config: nil),
     .compDeclarer(config: nil),
     .compDdTricks(config: nil),
     .compDdScore(config: nil),
     .compMakeScore(config: nil),
     .compMakeOdds(config: nil)]
    
    static let defaultColumns = InsightColumn.allColumns.filter{!defaultPinnedColumns.contains($0) && !defaultExcludeColumns.contains($0)}
    
    static func updateConfig(column: InsightColumn, config: InsightColumnConfig?) -> InsightColumn {
        switch column {
        case eventDesc:
                .eventDesc(config: config)
        case boardIndex:
                .boardIndex(config: config)
        case sessionNumber:
                .sessionNumber(config: config)
        case boardNumber:
                .boardNumber(config: config)
        case partner:
                .partner(config: config)
        case location:
                .location(config: config)
        case date:
                .date(config: config)
        case age:
                .age(config: config)
        case vulnerability:
                .vulnerability(config: config)
        case eventType:
                .eventType(config: config)
        case eventLevel:
                .eventLevel(config: config)
        case boardScoreType:
                .boardScoreType(config: config)
        case contract:
                .contract(config: config)
        case contractLevel:
                .contractLevel(config: config)
        case contractSuit:
                .contractSuit(config: config)
        case contractDouble:
                .contractDouble(config: config)
        case contractRedouble:
                .contractRedouble(config: config)
        case contractMade:
                .contractMade(config: config)
        case made:
                .made(config: config)
        case tricks:
                .tricks(config: config)
        case declarer:
                .declarer(config: config)
        case declarerPair:
                .declarerPair(config: config)
        case score:
                .score(config: config)
        case fieldSize:
                .fieldSize(config: config)
        case gameOdds:
                .gameOdds(config: config)
        case slamOdds:
                .slamOdds(config: config)
        case compContract:
                .compContract(config: config)
        case compContractLevel:
                .compContractLevel(config: config)
        case compDeclarer:
                .compDeclarer(config: config)
        case compDdTricks:
                .compDdTricks(config: config)
        case compDdScore:
                .compDdScore(config: config)
        case compMakeScore:
                .compMakeScore(config: config)
        case compMakeOdds:
                .compMakeOdds(config: config)
        case suit(_, let pairType):
                .suit(config: config, pairType: pairType)
        case declare(_, let pairType):
                .declare(config: config, pairType: pairType)
        case medianTricks(_, let pairType):
                .medianTricks(config: config, pairType: pairType)
        case modeTricks(_, let pairType):
                .modeTricks(config: config, pairType: pairType)
        case ddTricks(_, let pairType):
                .ddTricks(config: config, pairType: pairType)
        case fit(_, let pairType):
                .fit(config: config, pairType: pairType)
        case points(_, let seatPlayer):
                .points(config: config, seatPlayer: seatPlayer)
        case suitType:
                .suitType(config: config)
        case levelType:
                .levelType(config: config)
        case totalTricks:
                .totalTricks(config: config)
        case totalTricksDd:
                .totalTricksDd(config: config)
        case passout:
                .passout(config: config)
        case partScore(_, let pairType):
                .partScore(config: config, pairType: pairType)
        case game(_, let pairType):
                .game(config: config, pairType: pairType)
        case smallSlam(_, let pairType):
                .smallSlam(config: config, pairType: pairType)
        case grandSlam(_, let pairType):
                .grandSlam(config: config, pairType: pairType)
        default:
            column
        }
    }
    
    var name: String {
        var result = "\(self)"
        if let start = result.components(separatedBy: "(").first {
            result = start
        }
        switch self {
        case .suit(_, let pairType), .declare(_, let pairType), .medianTricks(_, let pairType), .modeTricks(_, let pairType), .ddTricks(_, let pairType), .fit(_, let pairType), .partScore(_, let pairType), .game(_, let pairType), .smallSlam(_, let pairType), .grandSlam(_, let pairType):
            result += pairType.string
        case .points(_, let seatPlayer):
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
        if let config = self.config {
            config.title
        } else {
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
            case .eventLevel:
                "Event Level"
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
            case .tricks:
                "Tricks Made"
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
            case .compContractLevel:
                "Compete Contract Level"
            case .compDeclarer:
                "Compete By"
            case .compDdTricks:
                "Compete DD Tricks"
            case .compDdScore:
                "Compete DD Score"
            case .compMakeScore:
                "Compete Make Score"
            case .compMakeOdds:
                "Compete Make Odds"
            case .suit(_, let pairType):
                "\(pairType.string) Suit"
            case .declare(_, let pairType):
                "\(pairType.string) Declare%"
            case .medianTricks(_, let pairType):
                "\(pairType.string) Median Tricks"
            case .modeTricks(_, let pairType):
                "\(pairType.string) Mode Tricks"
            case .ddTricks(_, let pairType):
                "\(pairType.string) DD Tricks"
            case .fit(_, let pairType):
                "\(pairType.string) Fit"
            case .points(_, let seatPlayer):
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
            case .partScore(_, let seatPlayer):
                "\(seatPlayer.string) Part Score"
            case .game(_, let seatPlayer):
                "\(seatPlayer.string) Game"
            case .smallSlam(_, let seatPlayer):
                "\(seatPlayer.string) Small Slam"
            case .grandSlam(_, let seatPlayer):
                "\(seatPlayer.string) Grand Slam"
            case .spacer:
                ""
            case .calculated(let column):
                column.title
            case .prompt(let prompt):
                prompt.promptText
            }
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
        case .eventLevel:
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
        case .tricks:
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
        case .compContractLevel:
                .numeric
        case .compDeclarer:
                .string
        case .compDdTricks:
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
        if let config = self.config {
            config.visibility
        } else {
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
    }
    
    var totalType: CalculatedTotalType? {
        if let config = self.config {
            config.totalType
        } else {
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
        case .compDdTricks, .compDdScore, .ddTricks,.totalTricksDd:
            return CalculatedValue(value.numeric! <= -999 ? 0 : value.numeric!)
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
        case .eventLevel:
            return summaryValue(boardSummary.location!.level.string)
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
        case .tricks:
            return summaryValue((boardSummary.made ?? 0) + boardSummary.contract.level.tricks)
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
        case .compContractLevel:
            return summaryValue(boardSummary.compContract.level.number)
        case .compDeclarer:
            return summaryValue(boardSummary.compDeclarer.string)
        case .compDdTricks:
            return summaryValue(boardSummary.compDdTricks ?? 0)
        case .compDdScore:
            return summaryValue(boardSummary.compDdScore)
        case .compMakeScore:
            return summaryValue(boardSummary.compMakeScore)
        case .compMakeOdds:
            return summaryValue(boardSummary.compMakeOdds)
        case .suit(_, let pairType):
            return summaryValue(boardSummary.suit[pairType]!.string)
        case .declare(_, let pairType):
            return summaryValue(boardSummary.declare[pairType]!)
        case .medianTricks(_, let pairType):
            return summaryValue(boardSummary.medianTricks[pairType]!)
        case .modeTricks(_, let pairType):
            return summaryValue(boardSummary.modeTricks[pairType]!)
        case .ddTricks(_, let pairType):
            return summaryValue(boardSummary.ddTricks[pairType]!)
        case .fit(_, let pairType):
            return summaryValue(boardSummary.fit[pairType]!)
        case .points(_, let seatPlayer):
            return summaryValue(boardSummary.points[seatPlayer]!)
        case .suitType:
            return summaryValue(boardSummary.contract.suitType.string)
        case .levelType:
            return summaryValue("\(boardSummary.contract.levelType.string)")
        case .totalTricks:
            return summaryValue(boardSummary.totalTricks)
        case .totalTricksDd:
            return summaryValue(boardSummary.ddTricks[.we]! <= -999 || boardSummary.ddTricks[.they]! <= -999 ? 0 : boardSummary.totalTricksDd)
        case .passout:
            return summaryValue(boardSummary.passout)
        case .partScore(_, let pairType):
            return summaryValue(boardSummary.partScore[pairType]!)
        case .game(_, let pairType):
            return summaryValue(boardSummary.game[pairType]!)
        case .smallSlam(_, let pairType):
            return summaryValue(boardSummary.smallSlam[pairType]!)
        case .grandSlam(_, let pairType):
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
            case .score:
                AttributedString(formattedScore(score: boardSummary.score))
            case .levelType:
                AttributedString(boardSummary.contract.levelType.string)
            case .compContract:
                !boardSummary.isCompetitive ? "" : boardSummary.compContract.colorCompact
            case .compDeclarer:
                AttributedString(!boardSummary.isCompetitive ? "" : text)
            case .compDdTricks:
                AttributedString(!boardSummary.isCompetitive || (boardSummary.compDdTricks ?? -999) <= -999 ? "" : text)
            case .compDdScore:
                AttributedString(!boardSummary.isCompetitive || (boardSummary.compDdTricks ?? -999) <= -999 ? "" : formattedScore(score: boardSummary.compDdScore))
            case .compMakeScore:
                AttributedString(!boardSummary.isCompetitive ? "" : formattedScore(score: boardSummary.compMakeScore))
            case .compMakeOdds:
                AttributedString(!boardSummary.isCompetitive ? "" : text)
            case .suit(_, let pairType):
                boardSummary.suit[pairType]!.colorString
            case .medianTricks(_, let pairType):
                AttributedString(boardSummary.suit[pairType]! == .blank ? "" : text)
            case .modeTricks(_, let pairType):
                AttributedString(boardSummary.suit[pairType]! == .blank ? "" : text)
            case .ddTricks(_, let pairType):
                AttributedString(boardSummary.ddTricks[pairType]! <= -999 ? "" : boardSummary.suit[pairType]! == .blank ? "" : text)
            case .fit(_, let pairType):
                AttributedString(boardSummary.suit[pairType]! == .blank ? "" : text)
            case .totalTricksDd:
                AttributedString(boardSummary.ddTricks[.we]! <= -999 || boardSummary.ddTricks[.they]! <= -999 ? "" : text)
            default:
                AttributedString(text)
            }
        } catch {
            return AttributedString("ERROR")
        }
        
        func formattedScore(score: Int) -> String {
            "\(boardSummary.boardScoreType.prefix(score: Float(score)))\(score)\(boardSummary.boardScoreType.shortSuffix)"
        }
    }
    
    var width: CGFloat {
        if let config = self.config {
            CGFloat(config.width)
        } else {
            switch self {
            case .eventDesc:
                180
            case .date:
                130
            case .location, .suitType, .levelType, .eventType, .eventLevel:
                120
            case .partner, .contractMade, .boardScoreType, .declarer:
                100
            case .contract, .compContract, .compDeclarer, .compContractLevel:
                90
            case .calculated(let calculated):
                CGFloat(calculated.width)
            case .spacer:
                0
            default:
                80
            }
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
        if let config = self.config {
            config.align
        } else {
            switch self {
            case .eventDesc:
                    .left
            case .boardIndex, .sessionNumber, .boardNumber, .vulnerability, .eventType, .eventLevel, .boardScoreType, .contract, .contractMade, .declarer, .made, .compContract, .compDeclarer, .suit, .suitType, .levelType, .partner, .location, .date:
                    .center
            case .calculated(let calculated):
                calculated.align
            default:
                    .right
            }
        }
    }
    
    var blankIf: CalculatedBlankIf {
        switch self {
        case .sessionNumber, .contractLevel, .fieldSize , .gameOdds, .slamOdds, .compContractLevel, .compDdScore, .compMakeScore, .compMakeOdds, .medianTricks, .modeTricks, .ddTricks, .fit, .points, .totalTricks, .totalTricksDd, .passout, .partScore, .game, .smallSlam, .grandSlam:
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
