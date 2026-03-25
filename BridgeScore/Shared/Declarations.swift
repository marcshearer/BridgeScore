//
//  Declarations.swift
// Bridge Score
//
//  Created by Marc Shearer on 01/02/2021.
//

import CoreGraphics
import SwiftUI
import Combine

// Parameters

public let maxRetention = 366
public let appId = "com.sheareronline.bridgescore"
public let appGroup = "group.\(appId)" // Has to match entitlements
public let lastScorecardWidgetKind = "\(appId).lastScorecard"
public let createScorecardWidgetKind = "\(appId).createScorecard"
public let statsWidgetKind = "\(appId).stats"
public let otherPlayer = "Other"
public let otherLocation = "Other"
public let schemaVersion = 1
// Sizes

var inputTopHeight: CGFloat { MyApp.format != .phone ? 20.0 : 10.0 }
let inputDefaultHeight: CGFloat = 30.0
var inputToggleDefaultHeight: CGFloat { MyApp.format != .phone ? 30.0 : 16.0 }
var bannerHeight: CGFloat { isLandscape ? (MyApp.format != .phone ? 60.0 : 50.0)
                                        : (MyApp.format != .phone ? 60.0 : 40.0) }
var alternateBannerHeight: CGFloat { MyApp.format != .phone ? 35.0 : 35.0 }
var minimumBannerHeight: CGFloat { MyApp.format != .phone ? 40.0 : 20.0 }
var bannerBottom: CGFloat { (MyApp.format != .phone ? 30.0 : (isLandscape ? 5.0 : 10.0)) }
var slideInMenuRowHeight: CGFloat { MyApp.target == .iOS ? 50 : 40 }

// Fonts (Font)
var bigFont =                   Set.font(computer: 50, phone:  24)
var bannerFont =                Set.font(computer: 32, phone:  24)
var alternateBannerFont =       Set.font(computer: 20, phone:  18)
var defaultFont =               Set.font(computer: 28, phone:  24)
var toolbarFont =               Set.font(computer: 16, phone:  14)
var captionFont =               Set.font(computer: 20, phone:  18)
var inputTitleFont =            Set.font(computer: 20, phone:  18)
var inputFont =                 Set.font(computer: 16, phone:  14)
var messageFont =               Set.font(computer: 16, phone:  14)
var searchFont =                Set.font(computer: 20, phone:  16)
var smallFont =                 Set.font(computer: 14, phone:  12)
var tinyFont =                  Set.font(computer: 12, phone:   8)
var responsibleTitleFont =      Set.font(computer: 30, phone:  18)
var responsibleCaptionFont =    Set.font(computer: 12, phone:   8)

#if canImport(UIKit)
// Fonts in scorecard (UIFont)
var titleFont =                 Set.uiFont(computer: 16, phone:  10)
var titleCaptionFont =          Set.uiFont(computer: 16, phone:  10)
var cellFont =                  Set.uiFont(computer: 28, phone:  16)
var boardFont =                 Set.uiFont(computer: 28, phone:  18)
var boardTitleFont =            Set.uiFont(computer: 28, phone:  14)
var pickerTitleFont =           Set.uiFont(computer: 30, phone:  18)
var pickerCaptionFont =         Set.uiFont(computer: 12, phone:   8)
var windowTitleFont =           Set.uiFont(computer: 30, phone:  20)
var sectionTitleFont =          Set.uiFont(computer: 24, phone:  16)
var smallCellFont =             Set.uiFont(computer: 22, phone:  12)
var smallerCellFont =           Set.uiFont(computer: 14, phone:  10)
var tinyCellFont =              Set.uiFont(computer:  8, phone:   6)
var replaceFont =               Set.uiFont(computer: 30, phone:  20)
var replaceTitleFont =          Set.uiFont(computer: 30, phone:  20)
var analysisFont =              Set.uiFont(computer: 16, phone:  12)
var analysisCommentFont =       Set.uiFont(computer: 24, tablet: 20, phone: 12)
#endif

// Slide in IDs - Need to be declared here as there seem to be multiple instances of views
let scorecardListViewId = UUID()
let scorecardInputViewId = UUID()
let scorecardDetailViewId = UUID()
let scorecardTypeViewId = UUID()
let layoutSetupViewId = UUID()
let statsViewId = UUID()

// iCloud database identifier
let iCloudIdentifier = "iCloud.MarcShearer.BridgeScore"

// Columns for record IDs
let recordIdKeys: [String:[String]] = [:]

// Backups
let backupDirectoryDateFormat = "yyyy-MM-dd-HH-mm-ss-SSS"
let backupDateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
let recordIdDateFormat = "yyyy-MM-dd-HH-mm-ss"

// Other constants
let tagMultiplier = 1000000
let nullUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
let useBboHandViewer = false

// Localisable names

public let appName = "Bridge Scorecard"
public let appImage = "bridge score"

public let dateFormat = "EEEE d MMMM yyyy"
public let shortDateFormat = "EEE d MMM"

public enum UIMode {
    case uiKit
    case appKit
    case unknown
}

public var isLandscape: Bool = (MyApp.format == .phone ? false : true)

// Application specific types

public enum TotalCalculation: Int, CaseIterable {
    case automatic = 0
    case manual = 1
    
    public var string: String {
        switch self {
        case .automatic:
            return "Calculated automatically"
        case .manual:
            return "Entered manually"
        }
    }
}

public enum RegularDay: Int, CaseIterable {
    case none = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7
    
    var string: String {
        "\(self)".capitalized
    }
    
    var lastDate: Date {
        if self == .none {
            return Date()
        } else {
            let todayNumber = DayNumber.today
            let dayOfWeek = (todayNumber.value + 1 % 7) + 1
            let offset = (7 + dayOfWeek - rawValue) % 7
            return DayNumber(from: (todayNumber - offset).date).date
        }
    }
}

enum AnalysisOptionFormat: Int, CaseIterable, Identifiable {
    case tricks = 0
    case made = 1
    case points = 2
    case score = 3
    
    public var id: Self { self }
    
    var string: String { "\(self)".capitalized }
}

public enum ImportSource: Int, Equatable, CaseIterable {
    case none = 0
    case bbo = 1
    case bridgeWebs = 2
    case pbn = 3
    case usebio = 4
    
    static var validCases: [ImportSource] {
        return ImportSource.allCases.filter({$0 != .none})
    }
    
    static var sortedValidCases: [ImportSource] {
        ImportSource.allCases.filter({$0 != .none}).sorted(by: {$0.sequence < $1.sequence})
    }
    
    var sequence: Int {
        switch self {
        case .none:
            return 0
        case .pbn:
            return 1
        case .usebio:
            return 2
        case .bbo:
            return 3
        case .bridgeWebs:
            return 4
        }
    }
    
    var string: String {
        switch self {
        case .none:
            return "No import"
        case .bbo:
            return "Import from BBO"
        case .bridgeWebs:
            return "Import from BridgeWebs"
        case .pbn:
            return "Import PBN file"
        case .usebio:
            return "Import Usebio file"
        }
    }
    
    var from: String {
        switch self {
        case .none:
            return ""
        case .bbo:
            return "BBO"
        case .bridgeWebs:
            return "BridgeWebs"
        case .pbn:
            return "PBN file"
        case .usebio:
            return "Usebio file"
        }
    }
}

public enum Pair: Int, CaseIterable, Identifiable, Equatable {
    case ns
    case ew
    case unknown
    
    public var id: Self { self }
    
    init(string: String) {
        switch string.uppercased() {
        case "NS", "N", "S":
            self = .ns
        case "EW", "E", "W":
            self = .ew
        default:
            self = .unknown
        }
    }
    
    var string: String {
        switch self {
        case .ns:
            return "North / South"
        case .ew:
            return "East / West"
        default:
            return "Unknown"
        }
    }
    
    var short: String {
        return "\(self)".uppercased()
    }
    
    static var validCases: [Pair] {
        return Pair.allCases.filter{$0 != .unknown}
    }
    
    var other: Pair {
        switch self {
        case .ns:
            return .ew
        case .ew:
            return .ns
        default:
            return .unknown
        }
    }
    

    
    var sign: Int {
        switch self {
        case .ns:
            return 1
        case .ew:
            return -1
        default:
            return 0
        }
    }
    
    public static func < (lhs: Pair, rhs: Pair) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
}

#if canImport(UIKit)
public let target: UIMode = .uiKit
#elseif canImport(appKit)
public let target: UIMode = .appKit
#else
public let target: UIMode = .unknown
#endif

fileprivate class Set {
    
#if canImport(UIKit)
    static func uiFont(font: UIFont? = nil, computer: CGFloat, tablet: CGFloat? = nil, phone: CGFloat? = nil) -> UIFont {
        let size = switch MyApp.format {
        case .computer: computer
        case .tablet:   tablet ?? computer
        case .phone:    phone ?? tablet ?? computer
        }
        return font?.withSize(size) ?? UIFont.systemFont(ofSize: size)
    }
#endif
    
    static func font(fontName: String? = nil, computer: CGFloat, tablet: CGFloat? = nil, phone: CGFloat? = nil) -> Font {
        let size = switch MyApp.format {
        case .computer: computer
        case .tablet:   tablet ?? computer
        case .phone:    phone ?? tablet ?? computer
        }
        if let fontName = fontName {
            return Font.custom(fontName, size: size)
        } else {
            return Font.system(size: size)
        }
    }
}

