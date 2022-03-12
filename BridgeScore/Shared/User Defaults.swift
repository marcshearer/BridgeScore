//
//  User Defaults.swift
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
    case currentUnsaved
    case currentId
    case currentLocation
    case currentPartner
    case currentDate
    case currentDescription
    case currentComment
    case currentType
    case currentBoards
    case currentBoardsTable
    case currentresetNumbers
    case currentScore
    case currentMaxScore
    case currentPosition
    case currentEntry
    case currentDrawing
    case currentWidth
    case filterPartner
    case filterLocation
    case filterDateFrom
    case filterDateTo
    case filterType
    case filterSearchText
    
    public var name: String { "\(self)" }
    
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
        case .currentUnsaved:
            return false
        case .currentId:
            return nil
        case .currentLocation:
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
            return Type.percent.rawValue
        case .currentBoards:
            return 1
        case .currentBoardsTable:
            return 1
        case .currentresetNumbers:
            return false
        case .currentScore:
            return ""
        case .currentMaxScore:
            return ""
        case .currentPosition:
            return 0
        case .currentEntry:
            return 0
        case .currentDrawing:
            return Data()
        case .currentWidth:
            return 0.0
        case .filterPartner:
            return nil
        case .filterLocation:
            return nil
        case .filterDateFrom:
            return nil
        case .filterDateTo:
            return nil
        case .filterType:
            return nil
        case .filterSearchText:
            return ""
        }
    }
    
    public func set(_ value: Any?) {
        if value == nil {
            MyApp.defaults.set(nil, forKey: self.name)
        } else if let uuid = value as? UUID {
            MyApp.defaults.set(uuid.uuidString, forKey: self.name)
        } else if let type = value as? Type {
            MyApp.defaults.set("\(type.rawValue)", forKey: self.name)
        } else if let date = value as? Date {
            MyApp.defaults.set(date.toFullString(), forKey: self.name)
        } else {
            MyApp.defaults.set(value, forKey: self.name)
        }
    }
    
    public var string: String {
        return MyApp.defaults.string(forKey: self.name)!
    }
    
    public var int: Int {
        return MyApp.defaults.integer(forKey: self.name)
    }
    
    public var float: Float {
        return MyApp.defaults.float(forKey: self.name)
    }
    
    public var bool: Bool {
        return MyApp.defaults.bool(forKey: self.name)
    }
    
    public var data: Data {
        return MyApp.defaults.data(forKey: self.name)!
    }
    
    public var date: Date? {
        let dateString = MyApp.defaults.string(forKey: self.name) ?? ""
        if dateString == "" {
            return nil
        } else {
            return Date(from: dateString, format: Date.fullDateFormat)
        }
    }
    
    public var uuid: UUID? {
        var result: UUID?
        if let uuid = UUID(uuidString: MyApp.defaults.string(forKey: self.name)!) {
            result = uuid
        }
        return result
    }
    
    public var type: Type? {
        return Type(rawValue: Int(MyApp.defaults.string(forKey: self.name) ?? "") ?? -1)
    }
}
