//
//  User Default.swift
//  BridgeScore
//
//  Created by Marc Shearer on 12/03/2022.
//

import Foundation

enum UserDefault: String, CaseIterable {
    case database
    case lastVersion
    case lastBuild
    case minVersion
    case minMessage
    case infoMessage
    case analysisOptionFormat
    case currentUnsaved
    case currentId
    case currentLocation
    case currentScorer
    case currentPartner
    case currentDate
    case currentDescription
    case currentComment
    case currentType
    case currentManualTotals
    case currentBoards
    case currentBoardsTable
    case currentSessions
    case currentResetNumbers
    case currentScore
    case currentMaxScore
    case currentPosition
    case currentEntry
    case currentImportSource
    case currentImportNext
    
    public var defaultValue: Any? {
        switch self {
        case .database:
            return "unknown"
        case .lastVersion:
            return "0.0"
        case .lastBuild:
            return 0
        case .minVersion:
            return 0
        case .minMessage:
            return ""
        case .infoMessage:
            return ""
        case .analysisOptionFormat:
            return AnalysisOptionFormat.score.rawValue
        case .currentUnsaved:
            return false
        case .currentId:
            return nil
        case .currentLocation:
            return nil
        case .currentScorer:
            return nil
        case .currentPartner:
            return nil
        case .currentDate:
            return Date()
        case .currentDescription:
            return ""
        case .currentComment:
            return ""
        case .currentType:
            return .none
        case .currentManualTotals:
            return false
        case .currentBoards:
            return 1
        case .currentBoardsTable:
            return 1
        case .currentSessions:
            return 1
        case .currentResetNumbers:
            return false
        case .currentScore:
            return ""
        case .currentMaxScore:
            return ""
        case .currentPosition:
            return 0
        case .currentEntry:
            return 0
        case .currentImportSource:
            return .none
        case .currentImportNext:
            return 1
        }
    }
    
    public var name: String { "\(self)" }
       
    public func set(_ value: Any?) {
        UserDefault.set(value, forKey: self.name)
    }
    
    public var string: String {
        return UserDefault.string(forKey: self.name)
    }
    
    public var int: Int {
        return UserDefault.int(forKey: self.name)
    }
    
    public var float: Float {
        return UserDefault.float(forKey: self.name)
    }
    
    public var bool: Bool {
        return UserDefault.bool(forKey: self.name)
    }
    
    public var data: Data {
        return UserDefault.data(forKey: self.name)
    }
    
    public var array: [Any] {
        return UserDefault.array(forKey: self.name)
    }
    
    public var date: Date? {
        return UserDefault.date(forKey: self.name)
    }
    
    public var uuid: UUID? {
        return  UserDefault.uuid(forKey: self.name)
    }
    
    public var type: ScorecardType? {
        return UserDefault.type(forKey: self.name)
    }
    
    public var importSource: ImportSource? {
        return UserDefault.importSource(forKey: self.name)
    }
    
    public static func set(_ value: Any?, forKey name: String) {
        if value == nil {
            MyApp.defaults.set(nil, forKey: name)
        } else if let array = value as? [Any] {
            MyApp.defaults.set(array, forKey: name)
        } else if let uuid = value as? UUID {
            MyApp.defaults.set(uuid.uuidString, forKey: name)
        } else if let type = value as? ScorecardType {
            MyApp.defaults.set("\(type.eventType.rawValue)", forKey: "\(name)-eventType")
            UserDefault.setScoreType(type: type.boardScoreType, forKey: "\(name)-boardScoreType")
            UserDefault.setAggregateType(type: type.aggregateType, forKey: "\(name)-aggregateType")
            MyApp.defaults.set(type.headToHead, forKey: "\(name)-headToHead")
        } else if let date = value as? Date {
            MyApp.defaults.set(date.toFullString(), forKey: name)
        } else {
            MyApp.defaults.set(value, forKey: name)
        }
    }
    
    public static func setScoreType(type: ScoreType, forKey name: String) {
        MyApp.defaults.set("\(type.rawValue)", forKey: name)
        switch type {
        case .vp(let type):
            MyApp.defaults.set("\(type)", forKey: "\(name)-vpType")
        default:
            break
        }
    }
    
    public static func setAggregateType(type: AggregateType, forKey name: String) {
        MyApp.defaults.set("\(type.rawValue)", forKey: name)
        switch type {
        case .vp(let type):
            MyApp.defaults.set("\(type)", forKey: "\(name)-vpType")
        default:
            break
        }
    }
        
    public static func string(forKey name: String) -> String {
        return MyApp.defaults.string(forKey: name)!
    }
    
    public static func int(forKey name: String) -> Int {
        return MyApp.defaults.integer(forKey: name)
    }
    
    public static func float(forKey name: String) -> Float {
        return MyApp.defaults.float(forKey: name)
    }
    
    public static func bool(forKey name: String) -> Bool {
        return MyApp.defaults.bool(forKey: name)
    }
    
    public static func data(forKey name: String) -> Data {
        return MyApp.defaults.data(forKey: name)!
    }
    
    public static func array(forKey name: String) -> [Any] {
        return MyApp.defaults.array(forKey: name)!
    }
    
    public static func date(forKey name: String) -> Date? {
        let dateString = MyApp.defaults.string(forKey: name) ?? ""
        if dateString == "" {
            return nil
        } else {
            return Date(from: dateString, format: Date.fullDateFormat)
        }
    }
    
    public static func uuid(forKey name: String) -> UUID? {
        var result: UUID?
        if let uuid = UUID(uuidString: MyApp.defaults.string(forKey: name)!) {
            result = uuid
        }
        return result
    }
    
    public static func type(forKey name: String) -> ScorecardType? {
        let eventType = eventType(forKey: "\(name)-eventType")
        let boardScoreType = scoreType(forKey: "\(name)-boardScoreType")
        let aggregateType = aggregateType(forKey: "\(name)-aggregateType")
        let headToHead = MyApp.defaults.bool(forKey: "\(name)-headToHead")
        return ScorecardType(eventType: eventType, boardScoreType: boardScoreType, aggregateType: aggregateType, headToHead: headToHead)
    }
    
    public static func eventType(forKey name: String) -> EventType {
        EventType(rawValue: Int(MyApp.defaults.string(forKey: "\(name)") ?? "") ?? -1) ?? .unknown
    }
 
    public static func scoreType(forKey name: String) -> ScoreType {
        let scoreTypeRawValue = Int(MyApp.defaults.string(forKey: "\(name)") ?? "") ?? -1
        if scoreTypeRawValue == ScoreType.vp(type: .unknown).rawValue {
            let vpType = vpType(forKey: "\(name)-vpType")
            return .vp(type: vpType)
        } else {
            return ScoreType(rawValue: scoreTypeRawValue) ?? .unknown
        }
    }
    
    public static func aggregateType(forKey name: String) -> AggregateType {
        let aggregateRawValue = Int(MyApp.defaults.string(forKey: "\(name)") ?? "") ?? -1
        if aggregateRawValue == AggregateType.vp(type: .unknown).rawValue {
            let vpType = vpType(forKey: "\(name)-vpType")
            return .vp(type: vpType)
        } else {
            return AggregateType(rawValue: aggregateRawValue) ?? .unknown
        }
    }
    
    public static func vpType(forKey name: String) -> VpType {
        return VpType(rawValue: Int(MyApp.defaults.string(forKey: "\(name)") ?? "") ?? -1) ?? .unknown
    }
    
    public static func importSource(forKey name: String) -> ImportSource? {
        return ImportSource(rawValue: Int(MyApp.defaults.string(forKey: name) ?? "") ?? -1)
    }
}

enum FilterType: CaseIterable {
    case list
    case stats
    
    var string: String {
        return "\(self)"
    }
}

enum FilterUserDefault: String, CaseIterable {
    case filterPartners
    case filterLocations
    case filterDateFrom
    case filterDateTo
    case filterTypes
    case filterSearchText
    
    public var defaultValue: Any? {
        let empty: [Any?] = []
        switch self {
        case .filterPartners:
            return empty
        case .filterLocations:
            return empty
        case .filterDateFrom:
            return nil
        case .filterDateTo:
            return nil
        case .filterTypes:
            return empty
        case .filterSearchText:
            return ""
        }
    }
    
    public func name(_ type: FilterType) -> String {
        return type.string + "\(self)".capitalized
    }
    
    public func set(_ value: Any?, type: FilterType) {
        UserDefault.set(value, forKey: self.name(type))
    }

    public func string(_ type: FilterType) -> String {
        return UserDefault.string(forKey: self.name(type))
    }
    
    public func array(_ type: FilterType) -> [Any] {
        return UserDefault.array(forKey: self.name(type))
    }
    
    public func date(_ type: FilterType) -> Date? {
        return UserDefault.date(forKey: self.name(type))
    }
}

