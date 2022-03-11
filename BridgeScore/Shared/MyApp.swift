//
//  MyApp.swift
//  BridgeScore
//
//  Created by Marc Shearer on 25/02/2021.
//

import CloudKit
import CoreData
import SwiftUI

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
        }
    }
    
    public func set(_ value: Any) {
        if let uuid = value as? UUID {
            MyApp.defaults.set(uuid.uuidString, forKey: self.name)
        } else if let type = value as? Type {
            MyApp.defaults.set(type.rawValue, forKey: self.name)
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
    
    public var date: Date {
        return Date(from: MyApp.defaults.string(forKey: self.name) ?? "", format: Date.fullDateFormat)
    }
    
    public var uuid: UUID? {
        var result: UUID?
        if let uuid = UUID(uuidString: MyApp.defaults.string(forKey: self.name)!) {
            result = uuid
        }
        return result
    }
    
    public var type: Type {
        return Type(rawValue: MyApp.defaults.integer(forKey: self.name)) ?? Type.percent
    }
}

class MyApp {
    
    
    enum Target {
        case iOS
        case macOS
    }
   
    enum Format {
        case computer
        case tablet
        case phone
    }

    enum Database: String {
        case development = "Development"
        case production = "Production"
        case unknown = ""
        
        public var name: String {
            return self.rawValue
        }
    }
    
    static let shared = MyApp()
    
    static let defaults = UserDefaults(suiteName: appGroup)!
    
    /// Database to use - This  **MUST MUST MUST** match icloud entitlement
    static let expectedDatabase: Database = .production
    
    public static var database: Database = .unknown
    public static var undoManager = UndoManager()
    
    #if targetEnvironment(macCatalyst)
    public static let target: Target = .macOS
    #else
    public static let target: Target = .iOS
    #endif

    public static var format: Format = .tablet
 
    public func start() {
        #if !widget
            MasterData.shared.load()
        #endif
        Themes.selectTheme(.standard)
        self.registerDefaults()
        #if !widget
        Version.current.load()
        // Remove comment (CAREFULLY) if you want to clear the iCloud DB
        // DatabaseUtilities.initialiseAllCloud() {
            // Remove (CAREFULLY) if you want to clear the Core Data DB
            //DatabaseUtilities.initialiseAllCoreData()
            self.setupDatabase()
            // self.setupPreviewData()
        //}
              
        #if canImport(UIKit)
        UITextView.appearance().backgroundColor = .clear
        #endif
        #endif
    }
    
    private func setupDatabase() {
        
        // Get saved database
        MyApp.database = Database(rawValue: UserDefault.database.string) ?? .unknown
        
        #if !widget
            // Check which database we are connected to
        #endif
    }
     
    #if !widget
    private func setupPreviewData() {
        let viewContext = CoreData.context!
        
        do {
            try viewContext.save()
        } catch {
            fatalError()
        }
    }
    #endif
    
    private func registerDefaults() {
        var initial: [String:Any] = [:]
        for value in UserDefault.allCases {
            initial[value.name] = value.defaultValue ?? ""
        }
        MyApp.defaults.register(defaults: initial)
    }
}

enum BridgeScoreError: Error {
    case invalidData
}
