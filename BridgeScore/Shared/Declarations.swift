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
var bigFont: Font { Font.system(size: (MyApp.format != .phone ? 50.0 : 24.0)) }
var bannerFont: Font { Font.system(size: (MyApp.format != .phone ? 32.0 : 24.0)) }
var alternateBannerFont: Font { Font.system(size: (MyApp.format != .phone ? 20.0 : 18.0)) }
var defaultFont: Font { Font.system(size: (MyApp.format != .phone ? 28.0 : 24.0)) }
var toolbarFont: Font { Font.system(size: (MyApp.format != .phone ? 16.0 : 14.0)) }
var captionFont: Font { Font.system(size: (MyApp.format != .phone ? 20.0 : 18.0)) }
var inputTitleFont: Font { Font.system(size: (MyApp.format != .phone ? 20.0 : 18.0)) }
var inputFont: Font { Font.system(size: (MyApp.format != .phone ? 16.0 : 14.0)) }
var messageFont: Font { Font.system(size: (MyApp.format != .phone ? 16.0 : 14.0)) }
var searchFont: Font { Font.system(size: (MyApp.format != .phone ? 20.0 : 16.0)) }
var smallFont: Font { Font.system(size: (MyApp.format != .phone ? 14.0 : 12.0)) }
var tinyFont: Font { Font.system(size: (MyApp.format != .phone ? 12.0 : 8.0)) }
var responsibleTitleFont: Font {  Font.system(size: (MyApp.format != .phone ? 30.0 : 18.0)) }
var responsibleCaptionFont: Font {  Font.system(size: (MyApp.format != .phone ? 12.0 : 8.0)) }

#if canImport(UIKit)
// Fonts in scorecard (UIFont)
var titleFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format != .phone ? 16.0 : 10.0)) }
var titleCaptionFont: UIFont { UIFont.systemFont(ofSize: (MyApp.format != .phone ? 16.0 : 10.0)) }
var cellFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format != .phone ? 28.0 : 16.0)) }
var boardFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format != .phone ? 28.0 : 18.0)) }
var boardTitleFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format != .phone ? 28.0 : 14.0)) }
var pickerTitleFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format != .phone ? 30.0 : 18.0)) }
var pickerCaptionFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format != .phone ? 12.0 : 8.0)) }
var windowTitleFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format != .phone ? 30.0 : 20.0)) }
var sectionTitleFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format != .phone ? 24.0 : 16.0)) } 
var smallCellFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format != .phone ? 22.0 : 12.0)) }
var tinyCellFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format != .phone ? 8.0 : 6.0)) }
var replaceFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format != .phone ? 30.0 : 20.0)) }
var replaceTitleFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format != .phone ? 30.0 : 20.0)) }
var analysisFont: UIFont { UIFont.systemFont(ofSize: (MyApp.format != .phone ? 16.0 : 12.0)) }
var analysisCommentFont: UIFont { UIFont.systemFont(ofSize: (MyApp.format != .phone ? 20.0 : 12.0)) }
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

public var isLandscape: Bool {
#if canImport(UIKit)
    UIScreen.main.bounds.width > UIScreen.main.bounds.height
#else
    true
#endif
}

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
