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
var slideInMenuRowHeight: CGFloat { MyApp.target == .iOS ? 50 : 40 }

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
var smallFont: Font { Font.system(size: (MyApp.format == .tablet ? 14.0 : 12.0)) }
var tinyFont: Font { Font.system(size: (MyApp.format == .tablet ? 12.0 : 8.0)) }
var responsibleTitleFont: Font {  Font.system(size: (MyApp.format == .tablet ? 30.0 : 18.0)) }
var responsibleCaptionFont: Font {  Font.system(size: (MyApp.format == .tablet ? 12.0 : 8.0)) }

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
var tinyCellFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 8.0 : 6.0)) }
var replaceFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 30.0 : 20.0)) }
var replaceTitleFont: UIFont {  UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 30.0 : 20.0)) }
var analysisFont: UIFont { UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 16.0 : 12.0)) }

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
    case aggregate
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
        case .xImp:
            return 3.5
        case .imp:
            return 3.5
        case .vp, .acblVp:
            return 2.5
        case .aggregate:
            return 100.0
        case .unknown:
            return 0.0
        }
    }
    
    public func prefix(score: Float) -> String {
        switch self {
        case .imp, .xImp, .aggregate:
            return (score > 0 ? "+" : "")
        default:
            return ""
        }
    }
    
    public var suffix: String {
        switch self {
        case .percent:
            return "%"
        case .xImp, .imp:
            return " Imps"
        case .vp, .acblVp:
            return " VPs"
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

public enum Type: Int, CaseIterable {
    case percent = 0
    case vpPercent = 3
    case vpXImp = 4
    case xImp = 2
    case butlerImp = 10
    case aggregate = 8
    case vpMatchTeam = 1
    case vpTableTeam = 6
    case vpContTableTeam = 9
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
        case .butlerImp:
            return "Pairs Butler Imps"
        case .vpXImp:
            return "Pairs Cross-IMPs as VPs"
        case .aggregate:
            return "Pairs Aggregate"
        case .vpMatchTeam:
            return "Teams Match VPs"
        case .vpTableTeam:
            return "Teams Table VPs (Disc)"
        case .vpContTableTeam:
            return "Teams Table VPs (Cont)"
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
        case .vpMatchTeam, .vpTableTeam, .vpContTableTeam, .acblVpTableTeam, .butlerImp:
            return .imp
        case .aggregate:
            return .aggregate
        }
    }
    
    public var players: Int {
        switch self {
        case.percentIndividual:
            return 1
        case .percent, .xImp, .butlerImp, .vpXImp, .vpPercent, .aggregate:
            return 2
        case .vpMatchTeam, .vpTableTeam, .vpContTableTeam, .acblVpTableTeam:
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
        case .vpMatchTeam, .vpTableTeam, .vpContTableTeam, .acblVpTableTeam, .aggregate, .butlerImp:
            return 0
        }
    }

    public var tablePlaces: Int {
        switch self {
        case .percent, .xImp, .vpXImp,  .vpContTableTeam, .percentIndividual:
            return 2
        case .vpMatchTeam, .vpPercent, .vpTableTeam, .acblVpTableTeam, .aggregate, .butlerImp:
            return 0
        }
    }
    
    public var matchPlaces: Int {
        switch self {
        case .percent, .xImp, .vpXImp, .vpContTableTeam, .vpMatchTeam, .percentIndividual:
            return 2
        case .vpPercent, .vpTableTeam, .acblVpTableTeam, .aggregate, .butlerImp:
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
        case .acblVpTableTeam:
            return .acblDiscreteVp
        case .vpXImp, .vpContTableTeam:
            return .continuousVp
        case .vpPercent:
            return .percentVp
        }
    }
    
    public var matchAggregate: AggregateType {
        switch self {
        case .percent, .percentIndividual:
            return .average
        case .xImp, .vpXImp, .vpTableTeam,  .vpContTableTeam, .acblVpTableTeam, .vpPercent, .aggregate, .butlerImp:
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
        case .vpXImp, .vpTableTeam, .vpContTableTeam, .acblVpTableTeam, .vpPercent, .vpMatchTeam:
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
        case .vpXImp, .vpTableTeam, .acblVpTableTeam, .vpPercent:
            return Float(tables * 20)
        case .vpMatchTeam:
            return 20
        default:
            return nil
        }
    }
    
    public func invertScore(score: Float, pair: Pair = .ew) -> Float {
        if pair == .ns {
            return score
        } else {
            return (self.boardScoreType == .percent ? 100 - score : (score == 0 ? 0 : -score))
        }
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

public enum ContractLevel: Int, ContractEnumType, Equatable, Comparable {
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
        return (self == .passout) ? "Pass" : string.left(1)
    }
    
    static var smallSlam: ContractLevel { Values.smallSlamLevel }
    
    static var grandSlam: ContractLevel { Values.grandSlamLevel }
    
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
    
    var tricks: Int {
        rawValue + Values.trickOffset
    }
    
    public static func < (lhs: ContractLevel, rhs: ContractLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public static func == (lhs: ContractLevel, rhs: ContractLevel) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

public enum Suit: Int, ContractEnumType, Equatable, Comparable {
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
            return "♣︎"
        case .diamonds:
            return "♦︎"
        case .hearts:
            return "♥︎"
        case .spades:
            return "♠︎"
        case .noTrumps:
            return "NT"
        }
    }
    
    var colorString: AttributedString {
        return AttributedString(self.string, color: self.color)
    }
    
    var attributedString: NSAttributedString {
        return NSAttributedString(self.string, color: UIColor(self.color))
    }
    
    public var color: Color {
        get {
            switch self {
            case .diamonds, .hearts:
                return .red
            case .clubs, .spades:
                return .black
            default:
                return .black
            }
        }
    }
    
    var short: String {
        return "\(self)".left(1).uppercased()
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
    
    static var realSuits: [Suit] {
        return Suit.allCases.filter({$0.valid && $0 != .noTrumps})
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
    
    var gameTricks : Int {
        switch self {
        case .noTrumps:
            return 3
        case .hearts, .spades:
            return 4
        case .clubs, .diamonds:
            return 5
        default:
            return 0
        }
    }
    
    func trickPoints(tricks: Int) -> Int {
        return (tricks < 0 ? 0 : (firstTrick + (tricks >= 1 ? (tricks - 1) * subsequentTricks : 0)))
    }
    
    func overTrickPoints(tricks: Int) -> Int {
        return (tricks < 0 ? 0 : tricks * subsequentTricks)
    }
    
    public static func == (lhs: Suit, rhs: Suit) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    public static func < (lhs: Suit, rhs: Suit) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
}

public enum ContractDouble: Int, ContractEnumType, Equatable, Comparable {
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
            return "*"
        case .redoubled:
            return "**"
        }
    }
    
    var bold: String {
        switch self {
        case .undoubled:
            return ""
        case .doubled:
            return "✱"
        case .redoubled:
            return "✱✱"
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
    
    public static func < (lhs: ContractDouble, rhs: ContractDouble) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

infix operator <-: ComparisonPrecedence
infix operator >+: ComparisonPrecedence

public class Contract: Equatable, Comparable, Hashable {
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
            return "\(level.short) \(suit.string) \(double.bold)"
        }
    }
    
    public var undoubled: Contract {
        let contract = Contract(copying: self)
        contract.double = .undoubled
        return contract
    }
    
    public var compact: String {
        switch level {
        case .blank:
            return ""
        case .passout:
            return "Pass Out"
        default:
            return "\(level.short)\(suit.string)\(double.short)"
        }
    }
    
    public var colorString: AttributedString {
        switch level {
        case .blank:
            return ""
        case .passout:
            return "Pass Out"
        default:
            return AttributedString("\(level.short) ") + suit.colorString + AttributedString(" ") + AttributedString(double.bold)
        }
    }
    
    public var attributedCompact: NSAttributedString {
        switch level {
        case .blank:
            return NSAttributedString("")
        case .passout:
            return NSAttributedString("Pass Out")
        default:
            return NSAttributedString(level.short) + suit.attributedString + NSAttributedString(double.short)
        }
    }
    
    public var attributedString: NSAttributedString {
        switch level {
        case .blank:
            return NSAttributedString("")
        case .passout:
            return NSAttributedString("Pass Out")
        default:
            return NSAttributedString("\(level.short) ") + suit.attributedString + NSAttributedString(" \(double.bold)")
        }
    }
    
    public var colorCompact: AttributedString {
        switch level {
        case .blank:
            return ""
        case .passout:
            return "Pass Out"
        default:
            return AttributedString(level.short) + suit.colorString + AttributedString(double.short)
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
    
    init(string: String) {
        self.level = .blank
        self.suit = .blank
        self.double = .undoubled

        var string = string.trim().uppercased()
        if string != "" {
            if string.left(1) == "P" {
                self.level = .passout
            } else {
                let level = ContractLevel(rawValue: Int(string.left(1)) ?? ContractLevel.blank.rawValue) ?? .blank
                if level != .blank && level != .passout {
                    var double = ContractDouble.undoubled
                    if string.right(2) == "XX" {
                        double = .redoubled
                    } else if string.right(1) == "X" {
                        double = .doubled
                    }
                    string = string.replacingOccurrences(of: "X", with: "")
                    let suit = Suit(string: string.mid(1,1))
                    if suit != .blank {
                        self.level = level
                        self.suit = suit
                        self.double = double
                    }
                }
            }
        }
    }
    
    init(copying contract: Contract) {
        self.copy(from: contract)
    }
    
    convenience init?(higher than: Contract, suit: Suit) {
        self.init(copying: than)
        self.suit = suit
        if suit <= than.suit {
            if let nextLevel = ContractLevel(rawValue: self.level.rawValue + 1) {
                self.level = nextLevel
            } else {
                return nil
            }
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(level)
        hasher.combine(suit)
        hasher.combine(double)
    }
    
    static public func == (lhs: Contract, rhs: Contract) -> Bool {
        return lhs.level == rhs.level && lhs.suit == rhs.suit && lhs.double == rhs.double
    }

    static public func < (lhs: Contract, rhs: Contract) -> Bool {
        return lhs.level < rhs.level || (lhs.level == rhs.level && (lhs.suit < rhs.suit || (lhs.suit == rhs.suit && lhs.double < rhs.double)))
    }
    
    static public func > (lhs: Contract, rhs: Contract) -> Bool {
        return lhs.level > rhs.level || (lhs.level == rhs.level && (lhs.suit > rhs.suit || (lhs.suit == rhs.suit && lhs.double > rhs.double)))
    }

    static public func <- (lhs: Contract, rhs: Contract) -> Bool {
        // Lesser level and suit (not just doubled)
        return lhs.level < rhs.level ||  (lhs.level == rhs.level && (lhs.suit < rhs.suit))
    }

    static public func >+ (lhs: Contract, rhs: Contract) -> Bool {
        // Greater level and suit (not just doubled)
        return lhs.level > rhs.level || (lhs.level == rhs.level && (lhs.suit > rhs.suit))
    }

    func copy(from: Contract) {
        self.level = from.level
        self.suit = from.suit
        self.double = from.double
    }
    
    public var canClear: Bool {
        level != .blank || suit != .blank || double != .undoubled
    }
    
    public var tricks: Int { level == .passout ? 0 : Values.trickOffset + level.rawValue }
}

public class OptimumScore: Equatable {
    public var contract: Contract
    public var declarer: Pair
    public var made: Int
    public var nsPoints: Int
    
    init(contract: Contract, declarer: Pair, made: Int, nsPoints: Int) {
        self.contract = contract
        self.declarer = declarer
        self.made = made
        self.nsPoints = nsPoints
    }
    
    init?(string: String, vulnerability: Vulnerability) {
        var contract: Contract?
        var declarer: Pair?
        var made: Int?
        var nsPoints: Int?
        
        var contractsPointsStrings = string.components(separatedBy: ": ")
        if contractsPointsStrings.count == 1 {
            contractsPointsStrings = string.components(separatedBy: "; ")
        }
        if contractsPointsStrings.count >= 2 {
            let nsPointsString = contractsPointsStrings.last!
            let declarerContractStrings = contractsPointsStrings.first!.components(separatedBy: ",").first!.components(separatedBy: " ")
            if declarerContractStrings.count >= 2 {
                let declarerString = declarerContractStrings.first!
                let contractString = declarerContractStrings.last!.components(separatedBy: "=").first!.components(separatedBy: "+").first!.components(separatedBy: "-").first!
                declarer = Pair(string: declarerString)
                if declarer != .unknown {
                    contract = Contract(string: contractString)
                    if contract?.level != .blank {
                        nsPoints = Int(nsPointsString)
                        if nsPoints != nil {
                            made = Scorecard.made(contract: contract!, vulnerability: vulnerability, declarer: declarer!.seats.first!, points: (declarer! == .ns ? nsPoints! : -nsPoints!))
                        }
                    }
                }
            }
        }
        if let contract = contract, let declarer = declarer, let made = made, let nsPoints = nsPoints {
            self.contract = contract
            self.declarer = declarer
            self.made = made
            self.nsPoints = nsPoints
        } else {
            return nil
        }
    }
    
    
    public static func == (lhs: OptimumScore, rhs: OptimumScore) -> Bool {
        lhs.contract == rhs.contract && lhs.declarer == rhs.declarer && lhs.made == rhs.made && lhs.nsPoints == rhs.nsPoints
    }
}

#if canImport(UIKit)
public let target: UIMode = .uiKit
#elseif canImport(appKit)
public let target: UIMode = .appKit
#else
public let target: UIMode = .unknow
#endif
