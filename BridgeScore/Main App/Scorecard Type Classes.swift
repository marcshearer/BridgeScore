//
//  Scorecard Type Classes.swift
//  BridgeScore
//
//  Created by Marc Shearer on 12/01/2025.
//

public enum AggregateType {
    case average
    case total
    case continuousVp
    case discreteVp
    case sbuDiscreteVp
    case acblDiscreteVp
    case percentVp
    case contPercentVp
    
    public func scoreType(subsidiaryScoreType: ScoreType) -> ScoreType {
        switch self {
        case .average:
            return subsidiaryScoreType
        case .total:
            return subsidiaryScoreType
        case .continuousVp, .discreteVp, .percentVp, .contPercentVp:
            return .vp
        case .sbuDiscreteVp:
            return .sbuVp
        case .acblDiscreteVp:
            return .acblVp
        }
    }
}

public enum ScoreType {
    case percent
    case imp
    case xImp
    case butlerImp
    case acblVp
    case sbuVp
    case vp
    case aggregate
    case unknown
    
    public var string: String {
        switch self {
        case .percent:
            return "Score %"
        case .xImp:
            return "X Imps"
        case .butlerImp:
            return "B Imps"
        case .imp:
            return "Imps"
        case .vp, .sbuVp, .acblVp:
            return "VPs"
        case .aggregate:
            return "Score"
        case .unknown:
            return ""
        }
    }
    
    public var significant: Float {
        switch self {
        case .percent:
            return 19.5
        case .imp, .xImp, .butlerImp:
            return 3.5
        case .vp, .sbuVp, .acblVp:
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
        self != .imp && self != .xImp && self != .aggregate
    }
    
    public var suffix: String {
        switch self {
        case .percent:
            return "%"
        case .xImp, .imp, .butlerImp:
            return " Imps"
        case .vp, .acblVp:
            return " VPs"
        default:
            return ""
        }
    }
    public var shortSuffix: String {
        switch self {
        case .percent:
            return "%"
        case .vp, .acblVp:
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

public enum ScorecardType: Int, CaseIterable {
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
            return "Teams Overall VPs (Cont)"
        case .sbuVpTableTeam:
            return "Teams Match SBU VPs"
        case .acblVpTableTeam:
            return "Teams Match ACBL VPs"
        case .percentIndividual:
            return "Individual Match Points"
        }
    }
    
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
        return tableAggregate.scoreType(subsidiaryScoreType: boardScoreType)
    }
    
    public var sessionScoreType: ScoreType {
        return sessionAggregate.scoreType(subsidiaryScoreType: boardScoreType)
    }
    
    public var matchScoreType: ScoreType {
        return matchAggregate.scoreType(subsidiaryScoreType: tableScoreType)
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
            return .average
        case .xImp, .vpMatchTeam, .aggregate, .butlerImp:
            return .total
        case .vpTableTeam:
            return .discreteVp
        case .sbuVpTableTeam:
            return .sbuDiscreteVp
        case .acblVpTableTeam:
            return .acblDiscreteVp
        case .vpXImp, .vpContTableTeam:
            return .continuousVp
        case .vpPercent:
            return .percentVp
        case .vpContPercent:
            return .contPercentVp
        }
    }
    
    public var sessionAggregate: AggregateType {
        switch self {
        case .percent, .percentIndividual:
            return .average
        case .xImp, .vpXImp, .vpMatchTeam, .vpTableTeam,  .vpContTableTeam, .sbuVpTableTeam, .acblVpTableTeam, .vpPercent, .vpContPercent, .aggregate, .butlerImp:
            return .total
        }
    }
    
    public var matchAggregate: AggregateType {
        switch self {
        case .percent, .percentIndividual:
            return .average
        case .xImp, .vpXImp, .vpTableTeam,  .vpContTableTeam, .sbuVpTableTeam, .acblVpTableTeam, .vpPercent, .vpContPercent, .aggregate, .butlerImp:
            return .total
        case  .vpMatchTeam:
            return .continuousVp
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
            case .vp, .acblVp:
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
