//
//  Declarations.swift
// Bridge Score
//
//  Created by Marc Shearer on 01/02/2021.
//

import CoreGraphics
import SwiftUI

// Parameters

public let maxRetention = 366
public let appGroup = "group.com.sheareronline.bridgescore" // Has to match entitlements
public let widgetKind = "com.sheareronline.bridgescore"

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

// Slide in IDs - Need to be declared here as there seem to be multiple instances of views
let scorecardListViewId = UUID()
let scorecardInputViewId = UUID()
let scorecardDetailViewId = UUID()
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

public enum UIMode {
    case uiKit
    case appKit
    case unknown
}

public var isLandscape: Bool {
    UIScreen.main.bounds.width > UIScreen.main.bounds.height
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
            return (todayNumber - offset).date
        }
    }
}

public enum Responsible: Int, EnumPickerType, Identifiable {
    public var id: Int { rawValue }
    
    case opponentMinus = -3
    case luckMinus = -5
    case teamMinus = -4
    case partnerMinus = -2
    case scorerMinus = -1
    case unknown = 0
    case scorerPlus = 1
    case partnerPlus = 2
    case teamPlus = 4
    case luckPlus = 5
    case opponentPlus = 3
    case blank = -99
    
    public var string: String {
        switch self {
        case .unknown, .blank:
            return ""
        case .scorerMinus, .scorerPlus:
            return "Self"
        case .partnerMinus, .partnerPlus:
            return "Partner"
        case .teamMinus, .teamPlus:
            return "Team"
        case .opponentPlus, .opponentMinus:
            return "Opps"
        case .luckPlus:
            return "Lucky"
        case .luckMinus:
            return "Unlucky"
        }
    }
    
    public var full: String {
        switch self {
        case .unknown:
            return "None"
        default:
            return string
        }
    }
    
    public var short: String {
        switch self {
        case .unknown, .blank:
            return ""
        case .luckMinus:
            return "L-"
        case .scorerMinus, .partnerMinus, .opponentMinus, .teamMinus:
            return "\(string.left(1))-"
        case .scorerPlus, .partnerPlus, .opponentPlus, .teamPlus, .luckPlus:
            return "\(string.left(1))+"
        }
    }
    
    public static var validCases: [Responsible] {
        let players = Scorecard.current.scorecard?.type.players ?? 2
        return allCases.filter({$0 != .blank && (players == 4 || ($0 != .teamPlus && $0 != .teamMinus)) && (players > 1 || ($0 != .partnerMinus && $0 != .partnerPlus))})
    }
    
    public var partnerInverse : Responsible {
        switch self {
        case .partnerPlus, .partnerMinus, .scorerPlus, .scorerMinus:
            Responsible(rawValue: -rawValue)!
        default:
            self
        }
    }
    
    public var teamInverse: Responsible {
        switch self {
        case .partnerPlus, .scorerPlus:
            .teamPlus
        case .partnerMinus, .scorerMinus:
            .teamMinus
        case .teamPlus:
            .scorerPlus
        case .teamMinus:
            .scorerMinus
        default:
            self
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
    
    var seats: [Seat] {
        switch self {
        case .ns:
            return [.north, .south]
        case .ew:
            return [.east, .west]
        default:
            return []
        }
    }
    
    var first: Seat {
        return seats.first!
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

public enum SeatPlayer: Int {
    case player = 0
    case partner = 2
    case lhOpponent = 1
    case rhOpponent = 3
    
    var isOpponent: Bool {
        self == .lhOpponent || self == .rhOpponent
    }
}

public enum Seat: Int, EnumPickerType, ContractEnumType, Identifiable {
    case unknown = 0
    case north = 1
    case east = 2
    case south = 3
    case west = 4
    
    public var id: Self { self }
    
    init(string: String) {
        switch string.uppercased() {
        case "N":
            self = .north
        case "E":
            self = .east
        case "S":
            self = .south
        case "W":
            self = .west
        default:
            self = .unknown
        }
    }
    
    public static var paired: [Seat] {
        [.north, .south, .east, .west]
    }
    
    public static func dealer(board: Int) -> Seat {
        return Seat(rawValue: ((board - 1) % 4) + 1) ?? .unknown
    }
    
    public func seatPlayer(_ seatPlayer: SeatPlayer) -> Seat {
        return self.offset(by: seatPlayer.rawValue)
    }
    
    public func seatPlayer(_ seat: Seat) -> SeatPlayer {
        return SeatPlayer(rawValue: offset(to: seat))!
    }
    
    public var string: String {
        return "\(self)".capitalized
    }
    
    public var button: String {
        return string
    }
    
    public var pair: Pair {
        switch self {
        case .north, .south:
            return .ns
        case .east, .west:
            return .ew
        default:
            return .unknown
        }
    }
    
    var equivalent: Seat {
        Seat(rawValue: ((6 - self.rawValue) % 4) + 1)!
    }
    
    func offset(by offset: Int) -> Seat {
        return Seat(rawValue: (((self.rawValue + offset - 1) % 4) + 1))!
    }
    
    func offsetNsEw(by offset: Int) -> Seat {
        let seats: [Seat] = [.north, .south, .east, .west]
        let current = seats.firstIndex(where: {$0 == self})!
        return seats[(current + offset) % 4]
    }
    
    func offset(to seat: Seat) -> Int {
        return (seat.rawValue + 4 - self.rawValue) % 4
    }
    
    static public var validCases: [Seat] {
        return Seat.allCases.filter{$0 != .unknown}
    }
    
    public var partner: Seat {
        return (self == .unknown ? .unknown : Seat(rawValue: ((self.rawValue + 1) % 4) + 1)!)
    }
    
    public var leftOpponent : Seat {
        (self == .unknown ? .unknown : Seat(rawValue: ((self.rawValue) % 4) + 1)!)
    }

    public var rightOpponent : Seat {
        (self == .unknown ? .unknown : Seat(rawValue: ((self.rawValue + 2) % 4) + 1)!)
    }
    
    public var opponents : [Seat] {
        return [leftOpponent, rightOpponent]
    }
    
    public var versus: [Seat] {
        if Scorecard.current.scorecard?.type.players == 1 {
            return [partner] + opponents
        } else {
            return opponents
        }
    }
    
    public var short: String {
        if self == .unknown {
            return ""
        }
        return string.left(1)
    }
    
    public func player(sitting: Seat) -> String {
        switch self {
        case sitting:
            if sitting == .unknown {
                return "Unknown"
            } else {
                return "Self"
            }
        case sitting.partner:
            return "Partner"
        case sitting.leftOpponent:
            return "Left"
        case sitting.rightOpponent:
            return "Right"
        default:
            return "Unknown"
        }
    }
}

public enum Vulnerability: Int {
    case unknown = 0
    case none = 1
    case ns = 2
    case ew = 3
    case both = 4

    init(board: Int) {
        self = Vulnerability(rawValue: (((board - 1) + ((board - 1) / 4)) % 4) + 1) ?? .unknown
    }
    
    public var string: String {
        switch self {
        case .unknown:
            return "?"
        case .none:
            return "-"
        case .ns:
            return "NS"
        case .ew:
            return "EW"
        case .both:
            return "All"
        }
    }
    
    public var short: String {
        switch self {
        case .unknown:
            return "?"
        case .none:
            return "-"
        case .ns:
            return "N"
        case .ew:
            return "E"
        case .both:
            return "B"
        }
    }
    
    public func isVulnerable(seat: Seat) -> Bool {
        switch seat {
        case .north, .south:
            return nsVulnerable
        case .east, .west:
            return ewVulnerable
        default:
            return false
        }
    }
    
    public var nsVulnerable: Bool {
        self == .ns || self == .both
    }

    public var ewVulnerable: Bool {
        self == .ew || self == .both
    }
}

public enum Values {
    case nonVulnerable
    case vulnerable
    
    init(_ vulnerable: Bool) {
        self = (vulnerable ? .vulnerable : .nonVulnerable)
    }
    
    public var gamePoints: Int { 100 }
    public var gameBonus: Int { self == .nonVulnerable ? 300 : 500 }
    public var doubledOvertrick: Int { self == .nonVulnerable ? 100 : 200}
    public var insult: Int { 50 }
    public var partScoreBonus: Int { 50 }
    public var smallSlamBonus: Int { self == .nonVulnerable ? 500 : 750 }
    public var grandSlamBonus: Int { self == .nonVulnerable ? 1000 : 1500 }
    public var firstUndertrick: Int { self == .nonVulnerable ? 50 : 100 }
    public var nextTwoDoubledUndertricks: Int { self == .nonVulnerable ? 200 : 300 }
    public var subsequentDoubledUndertricks: Int { 300 }
    public static var trickOffset: Int { 6 }
    public static var smallSlamLevel: ContractLevel { .six }
    public static var grandSlamLevel: ContractLevel { .seven }
}

#if canImport(UIKit)
public let target: UIMode = .uiKit
#elseif canImport(appKit)
public let target: UIMode = .appKit
#else
public let target: UIMode = .unknow
#endif
