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
public let appGroup = "group.com.sheareronline.BridgeScore" // Has to match entitlements
public let widgetKind = "com.sheareronline.BridgeScore"

// Sizes

var inputTopHeight: CGFloat { MyApp.format == .tablet ? 20.0 : 10.0 }
let inputDefaultHeight: CGFloat = 30.0
var inputToggleDefaultHeight: CGFloat { MyApp.format == .tablet ? 30.0 : 16.0 }
var bannerHeight: CGFloat { isLandscape ? (MyApp.format == .tablet ? 60.0 : 50.0)
                                        : (MyApp.format == .tablet ? 60.0 : 40.0) }
var alternateBannerHeight: CGFloat { MyApp.format == .tablet ? 50.0 : 35.0 }
var minimumBannerHeight: CGFloat { MyApp.format == .tablet ? 40.0 : 20.0 }
var bannerBottom: CGFloat { (MyApp.format == .tablet ? 30.0 : (isLandscape ? 5.0 : 10.0)) }
var slideInMenuRowHeight: CGFloat { MyApp.target == .iOS ? 50 : 25 }

// Fonts (Font)
var bannerFont: Font { Font.system(size: (MyApp.format == .tablet ? 32.0 : 24.0)) }
var alternateBannerFont: Font { Font.system(size: (MyApp.format == .tablet ? 20.0 : 18.0)) }
var defaultFont: Font { Font.system(size: (MyApp.format == .tablet ? 28.0 : 24.0)) }
var toolbarFont: Font { Font.system(size: (MyApp.format == .tablet ? 16.0 : 14.0)) }
var captionFont: Font { Font.system(size: (MyApp.format == .tablet ? 20.0 : 18.0)) }
var inputTitleFont: Font { Font.system(size: (MyApp.format == .tablet ? 20.0 : 18.0)) }
var inputFont: Font { Font.system(size: (MyApp.format == .tablet ? 16.0 : 14.0)) }
var messageFont: Font { Font.system(size: (MyApp.format == .tablet ? 16.0 : 14.0)) }
var searchFont: Font { Font.system(size: (MyApp.format == .tablet ? 20.0 : 16.0)) }

// Fonts in scorecard (UIFont)
var titleFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 16.0 : 10.0)) }
var titleCaptionFont: UIFont { UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 16.0 : 10.0)) }
var cellFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 28.0 : 16.0)) }
var boardFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 28.0 : 18.0)) }
var boardTitleFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 28.0 : 14.0)) }
var pickerTitleFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 30.0 : 18.0)) }
var pickerCaptionFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 12.0 : 8.0)) }
var windowTitleFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 30.0 : 20.0)) }
var sectionTitleFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 24.0 : 16.0)) }
var smallCellFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 22.0 : 12.0)) }
var replaceFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 30.0 : 20.0)) }
var replaceTitleFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 30.0 : 20.0)) }

// Slide in IDs - Need to be declared here as there seem to be multiple instances of views
let scorecardListViewId = UUID()
let scorecardInputViewId = UUID()
let scorecardDetailViewId = UUID()
let layoutSetupViewId = UUID()
let statsViewId = UUID()

// Backups
let backupDirectoryDateFormat = "yyyy-MM-dd-HH-mm-ss-SSS"
let backupDateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"

// Other constants
let tagMultiplier = 1000000
let nullUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

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
public enum AggregateType {
    case average
    case total
    case continuousVp
    case discreteVp
    case acblDiscreteVp
    case percentVp
    
    public func scoreType(subsidiaryScoreType: ScoreType) -> ScoreType {
        switch self {
        case .average:
            return subsidiaryScoreType
        case .total:
            return subsidiaryScoreType
        case .continuousVp, .discreteVp, .acblDiscreteVp, .percentVp:
            return .vp
        }
    }
}

public enum ScoreType {
    case percent
    case imp
    case xImp
    case acblVp
    case vp
    case unknown
    
    public var string: String {
        switch self {
        case .percent:
            return "Score %"
        case .xImp:
            return "X Imps"
        case .imp:
            return "Imps"
        case .vp, .acblVp:
            return "VPs"
        case .unknown:
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

public enum Type: Int, CaseIterable {
    case percent = 0
    case vpPercent = 3
    case vpXImp = 4
    case xImp = 2
    case vpMatchTeam = 1
    case vpTableTeam = 6
    case acblVpTableTeam = 5
    case percentIndividual = 7

    public var string: String {
        switch self {
        case .percent:
            return "Pairs Match Points"
        case .vpPercent:
            return "Pairs Match Points as VPs"
        case .xImp:
            return "Pairs Cross-IMPs"
        case .vpXImp:
            return "Pairs Cross-IMPs as VPs"
        case .vpMatchTeam:
            return "Teams Match VPs"
        case .vpTableTeam:
            return "Teams Table VPs"
        case .acblVpTableTeam:
            return "Teams Table ACBL VPs"
        case .percentIndividual:
            return "Individual Match Points"
        }
    }
    
    public var boardScoreType: ScoreType {
        switch self {
        case .percent, .vpPercent, .percentIndividual:
            return .percent
        case .xImp, .vpXImp:
            return .xImp
        case .vpMatchTeam, .vpTableTeam, .acblVpTableTeam:
            return .imp
        }
    }
    
    public var players: Int {
        switch self {
        case.percentIndividual:
            return 1
        case .percent, .xImp, .vpXImp, .vpPercent:
            return 2
        case .vpMatchTeam, .vpTableTeam, .acblVpTableTeam:
            return 4
        }
    }
    
    public var tableScoreType: ScoreType {
        return tableAggregate.scoreType(subsidiaryScoreType: boardScoreType)
    }
    
    public var matchScoreType: ScoreType {
        return matchAggregate.scoreType(subsidiaryScoreType: tableScoreType)
    }
    
    public var boardPlaces: Int {
        switch self {
        case .percent, .xImp, .vpPercent, .vpXImp, .percentIndividual:
            return 2
        case .vpMatchTeam, .vpTableTeam, .acblVpTableTeam:
            return 0
        }
    }

    public var tablePlaces: Int {
        switch self {
        case .percent, .xImp, .vpXImp, .percentIndividual:
            return 2
        case .vpMatchTeam, .vpPercent, .vpTableTeam, .acblVpTableTeam:
            return 0
        }
    }
    
    public var matchPlaces: Int {
        switch self {
        case .percent, .xImp, .vpXImp, .vpMatchTeam, .percentIndividual:
            return 2
        case .vpPercent, .vpTableTeam, .acblVpTableTeam:
            return 0
        }
    }
    
    public var tableAggregate: AggregateType {
        switch self {
        case .percent, .percentIndividual:
            return .average
        case .xImp, .vpMatchTeam:
            return .total
        case .vpTableTeam:
            return .discreteVp
        case .acblVpTableTeam:
            return .acblDiscreteVp
        case .vpXImp:
            return .continuousVp
        case .vpPercent:
            return .percentVp
        }
    }
    
    public var matchAggregate: AggregateType {
        switch self {
        case .percent, .percentIndividual:
            return .average
        case .xImp, .vpXImp, .vpTableTeam, .acblVpTableTeam, .vpPercent:
            return .total
        case  .vpMatchTeam:
            return .continuousVp
        }
    }
    
    public func matchSuffix(scorecard: ScorecardViewModel) -> String {
        switch self {
        case .percent, .percentIndividual:
            return "%"
        case .xImp:
            return " IMPs"
        case .vpXImp, .vpTableTeam, .acblVpTableTeam, .vpPercent, .vpMatchTeam:
            if let maxScore = scorecard.maxScore {
                return " / \(maxScore.toString(places: matchPlaces))"
            } else {
                return ""
            }
        }
    }
    
    public func matchPrefix(scorecard: ScorecardViewModel) -> String {
        switch self {
        case .xImp:
            return (scorecard.score ?? 0 > 0 ? "+" : "")
        default:
            return ""
        }
    }
    
    public func maxScore(tables: Int) -> Float? {
        switch self {
        case .percent, .percentIndividual:
            return 100
        case .vpXImp, .vpTableTeam, .acblVpTableTeam, .vpPercent:
            return Float(tables * 20)
        case .vpMatchTeam:
            return 20
        default:
            return nil
        }
    }
    
    public func invertScore(score: Float) -> Float {
        return (self.boardScoreType == .percent ? 100 - score : (score == 0 ? 0 : -score))
    }
}

public enum ResetBoardNumber: Int, CaseIterable {
    case continuous = 0
    case perTable = 1
    
    public var string: String {
        switch self {
        case .continuous:
            return "Continuous for match"
        case .perTable:
            return "Restart for each table"
        }
    }
}

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

public enum Responsible: Int, EnumPickerType {
    case opponentMinus = -3
    case partnerMinus = -2
    case scorerMinus = -1
    case unknown = 0
    case scorerPlus = 1
    case partnerPlus = 2
    case opponentPlus = 3
    
    public var string: String {
        switch self {
        case .unknown:
            return ""
        case .scorerMinus, .scorerPlus:
            return "Self"
        case .partnerMinus, .partnerPlus:
            return "Partner"
        default:
            return "Opponent"
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
        case .unknown:
            return ""
        case .scorerMinus, .partnerMinus, .opponentMinus:
            return "\(string.left(1))-"
        case .scorerPlus, .partnerPlus, .opponentPlus:
            return "\(string.left(1))+"
        }
    }
}

public enum Pair: Int, CaseIterable {
    case ns
    case ew
    case unknown
    
    init(string: String) {
        switch string.uppercased() {
        case "NS":
            self = .ns
        case "EW":
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
    
}

public enum Seat: Int, EnumPickerType, ContractEnumType {
    case unknown = 0
    case north = 1
    case south = 3
    case east = 2
    case west = 4
    
    init(string: String) {
        switch string.uppercased() {
        case "N":
            self = .north
        case "S":
            self = .south
        case "E":
            self = .east
        case "W":
            self = .west
        default:
            self = .unknown
        }
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
    
    public var short: String {
        if self == .unknown {
            return ""
        }
        return string.left(1)
    }
    
    public func player(sitting: Seat) -> String {
        switch self {
        case sitting:
            return "Self"
        case sitting.partner:
            return "Partner"
        case sitting.leftOpponent:
            return "Left"
        case sitting.rightOpponent:
            return "Right"
        default:
            return self.string
        }
    }
}

public enum Vulnerability: Int {
    case none = 0
    case ns = 1
    case ew = 2
    case both = 3

    init(board: Int) {
        self = Vulnerability(rawValue: ((board - 1) + ((board - 1) / 4)) % 4)!
    }
    
    public var string: String {
        switch self {
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
}

// Scorecard view types
enum ColumnType: Int, Codable {
    case table = 0
    case sitting = 1
    case tableScore = 2
    case versus = 3
    case board = 4
    case contract = 5
    case declarer = 6
    case made = 7
    case points = 8
    case score = 9
    case comment = 10
    case responsible = 11
    case vulnerable = 12
    case dealer = 13
    
    var string: String {
        return "\(self)"
    }
}

enum ColumnSize: Codable, Equatable {
    case fixed([CGFloat])
    case flexible
}

enum ContractElement: Int {
    case level = 0
    case suit = 1
    case double = 2
}

protocol ContractEnumType : CaseIterable, Equatable {
    var string: String {get}
    var short: String {get}
    var button: String {get}
    var rawValue: Int {get}
}

public enum ContractLevel: Int, ContractEnumType {
    case blank = 0
    case passout = -1
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    
    var string: String {
        switch self {
        case .blank:
            return ""
        case .passout:
            return "Pass Out"
        default:
            return "\(self.rawValue)"
        }
    }
    
    var short: String {
        return string.left(1)
    }
    
    var button: String {
        return string
    }
    
    var valid: Bool {
        return self != .blank && self != .passout
    }
    
    static var validCases: [ContractLevel] {
        return ContractLevel.allCases.filter({$0.valid})
    }
    
    var hasSuit: Bool {
        return valid
    }
    
    var hasDouble: Bool {
        return hasSuit
    }
}

public enum Suit: Int, ContractEnumType {
    case blank = 0
    case clubs = 1
    case diamonds = 2
    case hearts = 3
    case spades = 4
    case noTrumps = 5
    
    init(string: String) {
        switch string.uppercased() {
        case "C":
            self = .clubs
        case "D":
            self = .diamonds
        case "H":
            self = .hearts
        case "S":
            self = .spades
        case "N":
            self = .noTrumps
        default:
            self = .blank
        }
    }
    
    var string: String {
        switch self {
        case .blank:
            return ""
        case .clubs:
            return "??????"
        case .diamonds:
            return "??????"
        case .hearts:
            return "??????"
        case .spades:
            return "??????"
        case .noTrumps:
            return "NT"
        }
    }
    
    var short: String {
        return string
    }
    
    var button: String {
        return string
    }
    
    var valid: Bool {
        return self != .blank
    }
    
    static var validCases: [Suit] {
        return Suit.allCases.filter({$0.valid})
    }
    
    var hasDouble: Bool {
        return self.valid
    }
    
    var firstTrick: Int {
        switch self {
        case .noTrumps:
            return 40
        case .spades, .hearts:
            return 30
        case .clubs, .diamonds:
            return 20
        default:
            return 0
        }
    }

    var subsequentTricks: Int {
        switch self {
        case .noTrumps:
            return 30
        default:
            return firstTrick
        }
    }
    
    func trickPoints(tricks: Int) -> Int {
        return (tricks < 0 ? 0 : (firstTrick + (tricks >= 1 ? (tricks - 1) * subsequentTricks : 0)))
    }
    
    func overTrickPoints(tricks: Int) -> Int {
        return (tricks < 0 ? 0 : tricks * subsequentTricks)
    }
    
}

public enum ContractDouble: Int, ContractEnumType {
    case undoubled = 0
    case doubled = 1
    case redoubled = 2

    var string: String {
        return "\(self)".capitalized
    }
    
    var short: String {
        switch self {
        case .undoubled:
            return ""
        case .doubled:
            return "???"
        case .redoubled:
            return "??????"
        }
    }
    
    var button: String {
        switch self {
        case .undoubled:
            return "-"
        case .doubled:
            return "X"
        case .redoubled:
            return "XX"
        }
    }
    
    var multiplier: Int {
        switch self {
        case .undoubled:
            return 1
        case .doubled:
            return 2
        case .redoubled:
            return 4
        }
    }
}

public class Contract: Equatable {
    public var level: ContractLevel = .blank {
        didSet {
            if !level.hasSuit {
                suit = .blank
            }
        }
    }
    public var suit: Suit = .blank {
        didSet {
            if !suit.hasDouble {
                double = .undoubled
            }
        }
    }
    public var double: ContractDouble = .undoubled
    
    public var string: String {
        switch level {
        case .blank:
            return ""
        case .passout:
            return "Pass Out"
        default:
            return "\(level.short) \(suit.short) \(double.short)"
        }
    }
    
    init(level: ContractLevel = .blank, suit: Suit = .blank, double: ContractDouble = .undoubled) {
        self.level = level
        if level.hasSuit {
            self.suit = suit
            if suit.hasDouble {
                self.double = double
            } else {
                self.double = .undoubled
            }
        } else {
            self.suit = .blank
            self.double = .undoubled
        }
    }
    
    init(copying contract: Contract) {
        self.copy(from: contract)
    }
    
    static public func ==(lhs: Contract, rhs: Contract) -> Bool {
        return lhs.level == rhs.level && lhs.suit == rhs.suit && lhs.double == rhs.double
    }
    
    func copy(from: Contract) {
        self.level = from.level
        self.suit = from.suit
        self.double = from.double
    }
    
    public var canClear: Bool {
        level != .blank || suit != .blank || double != .undoubled
    }
}

#if canImport(UIKit)
public let target: UIMode = .uiKit
#elseif canImport(appKit)
public let target: UIMode = .appKit
#else
public let target: UIMode = .unknow
#endif
