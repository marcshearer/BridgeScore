//
//  Scorecard Type Classes.swift
//  BridgeScore
//
//  Created by Marc Shearer on 12/01/2025.
//

public enum VpType: Int, CaseIterable {
    case wbfContinuous = 1
    case wbfDiscrete = 2
    case sbuDiscrete = 3
    case acblDiscrete = 4
    case unknown = 0
    
    public var isContinuous: Bool {
        self == .wbfContinuous
    }
    
    public var places: Int {
        switch self {
        case .wbfContinuous:
            2
        default:
            0
        }
    }
    
    public static var validCases: [VpType] {
        VpType.allCases.filter({$0 != .unknown})
    }
    
    public var string: String {
        switch self {
        case .sbuDiscrete:
            "SBU VPs"
        case .acblDiscrete:
            "ACBL VPs"
        case .wbfContinuous:
            "VPs (Cont)"
        case .wbfDiscrete:
            "VPs"
        case .unknown:
            "Unknown VPs"
        }
    }
    
    public var verbose: String {
        switch self {
        case .wbfContinuous:
            "Continuous VPs"
        case .wbfDiscrete:
            "Discrete VPs"
        default:
            string
        }
    }
}

public enum AggregateType: CaseIterable, Equatable {
    case average
    case total
    case vp(type: VpType)
    case unknown

    init?(rawValue: Int, vpType: VpType = .unknown) {
        switch rawValue {
        case 1:
            self = .average
        case 2:
            self = .total
        case 3:
            self = .vp(type: vpType)
        case 4:
            self = .unknown
        default:
            return nil
        }
    }
    
    public var string: String {
        switch self {
        case .vp:
            "VPs"
        default:
            "\(self)".capitalized
        }
    }
    
    public var verbose: String {
        switch self {
        case .vp(let vpType):
            vpType.verbose
        default:
            "\(self)".capitalized
        }
    }
    
    public var rawValue: Int {
        switch self {
        case .average:
            1
        case .total:
            2
        case .vp:
            3
        case .unknown:
            0
        }
    }
    
    public static var allCases: [AggregateType] {
        [.average, .total, .vp(type: .unknown), .unknown]
    }
    
    public static var validCases: [AggregateType] {
        AggregateType.allCases.filter({$0 != .unknown})
    }
    
    public var isVp:Bool {
        switch self {
        case .vp:
            true
        default:
            false
        }
    }
    
    public var isContinuousVp: Bool {
        if case .vp(let vpType) = self {
            (vpType.isContinuous)
        } else {
            false
        }
    }
    
    public static func ~= (lhs: AggregateType, rhs: AggregateType) -> Bool {
        // Equality taken as the top level matches rather than any associated values
        return lhs.rawValue == rhs.rawValue
    }
    
    public func places(subsidiaryScoreType: ScoreType) -> Int {
        switch self {
        case .average:
            2
        case .total:
            subsidiaryScoreType.places
        case .vp(let vpType):
            vpType.places
        case .unknown:
            0
        }
    }
    
    public func aggregate(total: Float, count: Int, boards: Int, places: Int) -> Float? {
        let average = (count == 0 ? 0 : Utility.round(total / Float(count), places: 2))
        return switch self {
        case .average:
            Utility.round(average, places: places)
        case .total:
            Utility.round(total, places: places)
        case .vp(let type):
            switch type {
            case .wbfContinuous:
                BridgeImps(Int(Utility.round(total))).vp(boards: boards, places: places)
            case .wbfDiscrete:
                Float(BridgeImps(Int(Utility.round(total))).discreteVp(boards: boards))
            case .sbuDiscrete:
                Float(BridgeImps(Int(Utility.round(total))).sbuDiscreteVp(boards: boards))
            case .acblDiscrete:
                Float(BridgeImps(Int(Utility.round(total))).acblDiscreteVp(boards: boards))
            case .unknown:
                nil
            }
        case .unknown:
            nil
        }
    }
}

public enum ScoreType: Equatable, CaseIterable {
    case percent
    case imp
    case xImp
    case butlerImp
    case vp(type: VpType)
    case aggregate
    case unknown
    
    public init?(rawValue: Int, vpType: VpType = .unknown) {
        switch rawValue {
        case 1:
            self = .percent
        case 2:
            self = .imp
        case 3:
            self = .xImp
        case 4:
            self = .butlerImp
        case 5:
            self = .vp(type: vpType)
        case 6:
            self = .aggregate
        case 0:
            self = .unknown
        default:
            return nil
        }
    }
    
    public var rawValue: Int {
        switch self {
        case .percent:
            1
        case .imp:
            2
        case .xImp:
            3
        case .butlerImp:
            4
        case .vp:
            5
        case .aggregate:
            6
        case .unknown:
            0
        }
    }
    
    public static func ~= (lhs: ScoreType, rhs: ScoreType) -> Bool {
        // Equality taken as the top level matches rather than any associated values
        return lhs.rawValue == rhs.rawValue
    }
    
    public static var allCases: [ScoreType] {
        [.unknown, .percent, .imp, .xImp, .butlerImp, .vp(type: .unknown), .aggregate]
    }
    
    public static var validCases: [ScoreType] {
        ScoreType.allCases.filter({!($0 ~= ScoreType.unknown) && !$0.isVp})
    }
    
    public var isVp:Bool {
        switch self {
        case .vp:
            true
        default:
            false
        }
    }
    
    public var isContinuousVp: Bool {
        if case .vp(let vpType) = self {
            (vpType.isContinuous)
        } else {
            false
        }
    }
    
   public var string: String {
        switch self {
        case .percent:
            return "Match Points %"
        case .xImp:
            return "Cross-IMPs"
        case .butlerImp:
            return "Butler IMPs"
        case .imp:
            return "Imps"
        case .vp:
            return "VPs"
        case .aggregate:
            return "Aggregate"
        case .unknown:
            return ""
        }
    }
    
    public var title: String {
        switch self {
        case .percent:
            return "Score %"
        case .xImp:
            return "X Imps"
        case .butlerImp:
            return "B Imps"
        case .imp:
            return "Imps"
        case .vp:
            return "VPs"
        case .aggregate:
            return "Score"
        case .unknown:
            return ""
        }
    }
 
    public var places: Int {
        switch self {
        case .percent:
            2
        case .xImp:
            2
        case .butlerImp:
            2
        case .imp:
            0
        case .vp(let vpType):
            vpType.places
        case .aggregate:
            0
        case .unknown:
            0
        }
    }
    
    public var significant: Float {
        switch self {
        case .percent:
            return 19.5
        case .imp, .xImp, .butlerImp:
            return 3.5
        case .vp:
            return 2.5
        case .aggregate:
            return 100.0
        case .unknown:
            return 0.0
        }
    }
    
    public func prefix(score: Float) -> String {
        switch self {
        case .imp, .xImp, .butlerImp, .aggregate:
            return (score > 0 ? "+" : "")
        default:
            return ""
        }
    }
    
    public var unsigned: Bool {
        switch self {
        case .imp, .xImp, .aggregate:
            false
        default:
            true
        }
    }
    
    public var suffix: String {
        switch self {
        case .percent:
            return "%"
        case .xImp, .imp, .butlerImp:
            return " Imps"
        case .vp:
            return " VPs"
        default:
            return ""
        }
    }
    
    public var shortSuffix: String {
        switch self {
        case .percent:
            return "%"
        case .vp:
            return "VPs"
        default:
            return ""
        }
    }
    
    init(importScoringType: String?) {
        switch importScoringType {
        case "MATCH_POINTS":
            self = .percent
        case "CROSS_IMPS":
            self = .xImp
        case "IMPS":
            self = .imp
        default:
            self = .unknown
        }
    }
}

public enum EventType: Int, CaseIterable {
    case individual = 1
    case pairs = 2
    case teams = 4
    case unknown = 0
    
    public static var validCases: [EventType] {
        EventType.allCases.filter({$0 != .unknown})
    }
    
    public var string: String {
        "\(self)".capitalized
    }
    
    public var players: Int {
        rawValue
    }
}

public class ScorecardType: Equatable {
    public var eventType: EventType
    public var boardScoreType: ScoreType
    public var aggregateType: AggregateType
    public var headToHead: Bool
    
    init(eventType: EventType = .unknown, boardScoreType: ScoreType = .unknown, aggregateType: AggregateType = .unknown, matchAggregate: AggregateType = .unknown, headToHead: Bool = false) {
        self.eventType = eventType
        self.boardScoreType = boardScoreType
        self.aggregateType = aggregateType
        self.headToHead = headToHead
    }

    public static func == (lhs: ScorecardType, rhs: ScorecardType) -> Bool {
        return lhs.eventType == rhs.eventType && lhs.boardScoreType == rhs.boardScoreType && lhs.aggregateType == rhs.aggregateType && (lhs.eventType != .teams || lhs.headToHead == rhs.headToHead)
    }
    
    public var tableAggregate: AggregateType {
        if eventType == .teams && headToHead {
            .total
        } else {
            aggregateType
        }
    }
    
    public var matchAggregate: AggregateType {
        if eventType == .teams && headToHead {
            aggregateType
        } else if tableAggregate == .average {
            .average
        } else {
            .total
        }
    }
    
    public var string: String {
        var vpType: VpType? = nil
        if case let .vp(aggregateVpType) = aggregateType {
            vpType = aggregateVpType
        } else {
            vpType = nil
        }
        
        var result = eventType.string
        if eventType == .teams {
            if headToHead {
                result = "Head-to-head Teams"
            }
        }
        if eventType != .teams || vpType == nil {
            result += " " + boardScoreType.string
        }
        if let vpType = vpType {
            if eventType != .teams {
                result += " as"
            }
            result += " " + vpType.string
        }

        return result
    }
    
    public var validScoreTypes: [ScoreType] {
        switch eventType {
        case .pairs:
            [.percent, .xImp, .butlerImp, .aggregate]
        case .teams:
            [.imp, .aggregate]
        case .individual:
            [.percent]
        default:
            []
        }
    }
    
    public var validAggregateTypes: [AggregateType] {
        switch boardScoreType {
        case .percent:
            [.average, .vp(type: .unknown)]
        case .xImp, .butlerImp:
            [.total, .vp(type: .unknown)]
        case .imp:
            [.vp(type: .unknown), .total]
        case .aggregate:
            [.total]
        default:
            []
        }
    }
    
    public func validVpTypes(overrideType: AggregateType? = nil) -> [VpType] {
        switch overrideType ?? aggregateType {
        case .vp:
            switch boardScoreType {
            case .percent:
                [.wbfDiscrete, .wbfContinuous]
            default:
                VpType.validCases
            }
        default:
            []
        }
    }

    public var players: Int {
        eventType.players
    }
    
    public var isVp: Bool {
        aggregateType.isVp
    }
    
    public var isContinuousVp: Bool {
        aggregateType.isContinuousVp
    }
    
    public var tableScoreType: ScoreType {
        switch tableAggregate {
        case .vp(let vpType):
            .vp(type: vpType)
        case .total:
            boardScoreType
        case .average:
            boardScoreType
        case .unknown:
            .unknown
        }
    }
    
    public var matchScoreType: ScoreType {
        switch matchAggregate {
        case .vp(let vpType):
            .vp(type: vpType)
        case .total:
            tableScoreType
        case .average:
            tableScoreType
        case .unknown:
            .unknown
        }
    }
    
    public var boardPlaces: Int {
        boardScoreType.places
    }
    public var tablePlaces: Int {
        tableScoreType.places
    }
    
    public var matchPlaces: Int {
        matchScoreType.places
    }
    
    public func matchSuffix(scorecard: ScorecardViewModel) -> String {
        switch matchScoreType {
        case .vp:
            if let maxScore = scorecard.maxScore {
                return " / \(maxScore.toString(places: matchPlaces))"
            } else {
                return ""
            }
        default:
            return matchScoreType.suffix
        }
    }
    
    public func matchPrefix(scorecard: ScorecardViewModel) -> String {
        return matchScoreType.prefix(score: scorecard.score ?? 0)
    }
    
    public func maxScore(tables: Int) -> Float? {
        if matchAggregate == .average && boardScoreType == .percent {
            100
        } else if matchAggregate == .total {
            if tableAggregate.isVp {
                Float(tables * 20)
            } else {
                nil
            }
        } else if matchAggregate.isVp {
            20
        } else {
            nil
        }
    }
    
    public func invertScore(score: Float, pair: Pair = .ew, type: ScoreType? = nil) -> Float {
        if pair == .ns {
            return score
        } else {
            switch type ?? self.boardScoreType {
            case .vp:
                return (20 - score)
            case .percent:
                return 100 - score
            default:
                return (score == 0 ? 0 : -score)
            }
        }
    }
    
    public func invertTableScore(score: Float, pair: Pair = .ew) -> Float {
        return invertScore(score: score, pair: pair, type: boardScoreType)
    }
    
    public func invertMatchScore(score: Float, pair: Pair = .ew) -> Float {
        return invertScore(score: score, pair: pair, type: matchScoreType)
    }

    public var description: String {
        switch players {
        case 1:
            return "Player"
        case 4:
            return "Team"
        default:
            return "Pair"
        }
    }
}


public enum OldScorecardType: Int, CaseIterable {
    case percent = 0
    case vpPercent = 3
    case vpContPercent = 11
    case vpXImp = 4
    case xImp = 2
    case butlerImp = 10
    case aggregate = 8
    case vpTableTeam = 6
    case vpContTableTeam = 9
    case vpMatchTeam = 1
    case sbuVpTableTeam = 12
    case acblVpTableTeam = 5
    case percentIndividual = 7
    
    public func convert() -> ScorecardType {
        // Converts old scorecard type enum to new type class
        var eventType: EventType
        var boardScoreType: ScoreType
        var aggregateType: AggregateType
        var headToHead: Bool
        switch self {
        case .percent:
            eventType = .pairs
            boardScoreType = .percent
            aggregateType = .average
            headToHead = false
        case .vpPercent:
            eventType = .pairs
            boardScoreType = .percent
            aggregateType = .vp(type: .wbfDiscrete)
            headToHead = false
        case .vpContPercent:
            eventType = .pairs
            boardScoreType = .percent
            aggregateType = .vp(type: .wbfContinuous)
            headToHead = false
        case .vpXImp:
            eventType = .pairs
            boardScoreType = .xImp
            aggregateType = .vp(type: .wbfDiscrete)
            headToHead = false
        case .xImp:
            eventType = .pairs
            boardScoreType = .xImp
            aggregateType = .total
            headToHead = false
        case .butlerImp:
            eventType = .pairs
            boardScoreType = .butlerImp
            aggregateType = .total
            headToHead = false
        case .aggregate:
            eventType = .pairs
            boardScoreType = .aggregate
            aggregateType = .total
            headToHead = false
        case .vpTableTeam:
            eventType = .teams
            boardScoreType = .imp
            aggregateType = .vp(type: .wbfDiscrete)
            headToHead = false
        case .vpContTableTeam:
            eventType = .teams
            boardScoreType = .imp
            aggregateType = .vp(type: .wbfContinuous)
            headToHead = false
        case .vpMatchTeam:
            eventType = .teams
            boardScoreType = .imp
            aggregateType = .vp(type: .wbfContinuous)
            headToHead = true
        case .sbuVpTableTeam:
            eventType = .teams
            boardScoreType = .imp
            aggregateType = .vp(type: .sbuDiscrete)
            headToHead = false
        case .acblVpTableTeam:
            eventType = .teams
            boardScoreType = .imp
            aggregateType = .vp(type: .acblDiscrete)
            headToHead = false
        case .percentIndividual:
            eventType = .individual
            boardScoreType = .percent
            aggregateType = .average
            headToHead = false
        }
        return ScorecardType(eventType: eventType, boardScoreType: boardScoreType, aggregateType: aggregateType, headToHead: headToHead)
    }

    public var string: String {
        switch self {
        case .percent:
            return "Pairs MPs"
        case .vpPercent:
            return "Pairs MPs as VPs (Disc)"
        case .vpContPercent:
            return "Pairs MPs as VPs (Cont)"
        case .xImp:
            return "Pairs Cross-IMPs"
        case .butlerImp:
            return "Pairs Butler Imps"
        case .vpXImp:
            return "Pairs Cross-IMPs as VPs"
        case .aggregate:
            return "Pairs Aggregate"
        case .vpTableTeam:
            return "Teams Match VPs (Disc)"
        case .vpContTableTeam:
            return "Teams Match VPs (Cont)"
        case .vpMatchTeam:
            return "Teams Head-to-head VPs (Cont)"
        case .sbuVpTableTeam:
            return "Teams Match SBU VPs"
        case .acblVpTableTeam:
            return "Teams Match ACBL VPs"
        case .percentIndividual:
            return "Individual Match Points"
        }
    }
    /*
    public var boardScoreType: ScoreType {
        switch self {
        case .percent, .vpPercent, .vpContPercent, .percentIndividual:
            return .percent
        case .xImp, .vpXImp:
            return .xImp
        case .butlerImp:
            return .butlerImp
        case .vpMatchTeam, .vpTableTeam, .vpContTableTeam, .sbuVpTableTeam, .acblVpTableTeam:
            return .imp
        case .aggregate:
            return .aggregate
        }
    }
    
    public var players: Int {
        switch self {
        case.percentIndividual:
            return 1
        case .percent, .xImp, .butlerImp, .vpXImp, .vpPercent, .vpContPercent, .aggregate:
            return 2
        case .vpMatchTeam, .vpTableTeam, .vpContTableTeam, .sbuVpTableTeam, .acblVpTableTeam:
            return 4
        }
    }
    
    public var tableScoreType: ScoreType {
        return tableAggregate.scoreType
    }
    
    public var sessionScoreType: ScoreType {
        return sessionAggregate.scoreType
    }
    
    public var matchScoreType: ScoreType {
        return matchAggregate.scoreType
    }
    
    public var boardPlaces: Int {
        switch self {
        case .percent, .xImp, .vpPercent, .vpContPercent, .vpXImp, .percentIndividual:
            return 2
        case .vpMatchTeam, .vpTableTeam, .vpContTableTeam, .sbuVpTableTeam, .acblVpTableTeam, .aggregate, .butlerImp:
            return 0
        }
    }

    public var tablePlaces: Int {
        switch self {
        case .percent, .xImp, .vpXImp, .vpContPercent, .vpContTableTeam, .percentIndividual:
            return 2
        case .vpMatchTeam, .vpPercent, .vpTableTeam, .sbuVpTableTeam, .acblVpTableTeam, .aggregate, .butlerImp:
            return 0
        }
    }
    
    public var matchPlaces: Int {
        switch self {
        case .percent, .xImp, .vpXImp, .vpContPercent, .vpContTableTeam, .vpMatchTeam, .percentIndividual:
            return 2
        case .vpPercent, .vpTableTeam, .sbuVpTableTeam, .acblVpTableTeam, .aggregate, .butlerImp:
            return 0
        }
    }
    
    public var tableAggregate: AggregateType {
        switch self {
        case .percent, .percentIndividual:
            return .average(subsidiaryScoreType: boardScoreType)
        case .xImp, .vpMatchTeam, .aggregate, .butlerImp:
            return .total(subsidiaryScoreType: boardScoreType)
        case .vpTableTeam:
            return .vp(type: .wbfDiscrete)
        case .sbuVpTableTeam:
            return .vp(type: .sbuDiscrete)
        case .acblVpTableTeam:
            return .vp(type: .acblDiscrete)
        case .vpXImp, .vpContTableTeam:
            return .vp(type: .wbfContinuous)
        case .vpPercent:
            return .vp(type: .wbfDiscrete)
        case .vpContPercent:
            return .vp(type: .wbfContinuous)
        }
    }
    
    public var sessionAggregate: AggregateType {
        switch self {
        case .percent, .percentIndividual:
            return .average(subsidiaryScoreType: tableScoreType)
        case .xImp, .vpXImp, .vpMatchTeam, .vpTableTeam,  .vpContTableTeam, .sbuVpTableTeam, .acblVpTableTeam, .vpPercent, .vpContPercent, .aggregate, .butlerImp:
            return .total(subsidiaryScoreType: tableScoreType)
        }
    }
    
    public var matchAggregate: AggregateType {
        switch self {
        case .percent, .percentIndividual:
            return .average(subsidiaryScoreType: tableScoreType)
        case .xImp, .vpXImp, .vpTableTeam,  .vpContTableTeam, .sbuVpTableTeam, .acblVpTableTeam, .vpPercent, .vpContPercent, .aggregate, .butlerImp:
            return .total(subsidiaryScoreType: tableScoreType)
        case  .vpMatchTeam:
            return .vp(type: .wbfContinuous)
        }
    }
    
    public func matchSuffix(scorecard: ScorecardViewModel) -> String {
        switch self {
        case .percent, .percentIndividual:
            return "%"
        case .xImp, .butlerImp:
            return " IMPs"
        case .vpXImp, .vpTableTeam, .vpContTableTeam, .sbuVpTableTeam, .acblVpTableTeam, .vpPercent, .vpContPercent, .vpMatchTeam:
            if let maxScore = scorecard.maxScore {
                return " / \(maxScore.toString(places: matchPlaces))"
            } else {
                return ""
            }
        case .aggregate:
            return ""
        }
    }
    
    public func matchPrefix(scorecard: ScorecardViewModel) -> String {
        switch self {
        case .xImp, .aggregate, .butlerImp:
            return (scorecard.score ?? 0 > 0 ? "+" : "")
        default:
            return ""
        }
    }
    
    public func maxScore(tables: Int) -> Float? {
        switch self {
        case .percent, .percentIndividual:
            return 100
        case .vpXImp, .vpTableTeam, .sbuVpTableTeam, .acblVpTableTeam, .vpContTableTeam, .vpPercent, .vpContPercent:
            return Float(tables * 20)
        case .vpMatchTeam:
            return 20
        default:
            return nil
        }
    }
    
    public func invertScore(score: Float, pair: Pair = .ew, type: ScoreType? = nil) -> Float {
        if pair == .ns {
            return score
        } else {
            switch type ?? self.boardScoreType {
            case .vp:
                return (20 - score)
            case .percent:
                return 100 - score
            default:
                return (score == 0 ? 0 : -score)
            }
        }
    }
    
    public func invertTableScore(score: Float, pair: Pair = .ew) -> Float {
        return invertScore(score: score, pair: pair, type: boardScoreType)
    }
    
    public func invertMatchScore(score: Float, pair: Pair = .ew) -> Float {
        return invertScore(score: score, pair: pair, type: matchScoreType)
    }

    public var description: String {
        switch players {
        case 1:
            return "Player"
        case 4:
            return "Team"
        default:
            return "Pair"
        }
    }
 */
}
