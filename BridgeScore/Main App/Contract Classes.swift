//
//  Contract Classes.swift
//  BridgeScore
//
//  Created by Marc Shearer on 12/01/2025.
//

import SwiftUI

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
    
    init(character: String) {
        self = .blank
        if let rawValue = Int(character) {
            if let level = ContractLevel(rawValue: rawValue) {
                self = level
            }
        } else if character.left(1).uppercased() == "P" {
            self = .passout
        }
    }
    
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
    
    var isValid: Bool {
        return self != .blank && self != .passout
    }
    
    static var validCases: [ContractLevel] {
        return ContractLevel.allCases.filter({$0.isValid})
    }
    
    var hasSuit: Bool {
        return isValid
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
            ""
        case .clubs:
            "♣︎"
        case .diamonds:
            "♦︎"
        case .hearts:
            "♥︎"
        case .spades:
            "♠︎"
        case .noTrumps:
            "NT"
        }
    }
    
    var contrast: String {
        switch self {
        case .spades:
            "♤"
        default:
            string
        }
    }
    
    var words: String {
        switch self {
        case .blank:
            return ""
        case .clubs:
            return "Clubs"
        case .diamonds:
            return "Diamonds"
        case .hearts:
            return "Hearts"
        case .spades:
            return "Spades"
        case .noTrumps:
            return "No Trumps"
        }
    }
    
    var singular: String {
        switch self {
        case .blank:
            return ""
        case .clubs:
            return "Club"
        case .diamonds:
            return "Diamond"
        case .hearts:
            return "Heart"
        case .spades:
            return "Spade"
        case .noTrumps:
            return "No Trump"
        }
    }
    
    var colorString: AttributedString {
        return AttributedString(self.string, color: self.color)
    }
    
    var colorContrast: AttributedString {
        return AttributedString(self.contrast, color: self.color)
    }
    
    var attributedString: NSAttributedString {
        return NSAttributedString(self.string, color: UIColor(self.color))
    }
    
    var attributedContrast: NSAttributedString {
        return NSAttributedString(self.contrast, color: UIColor(self.color))
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
        return (self == .noTrumps ? "NT" : character)
    }
    
    var character: String {
        return ("\(self)".left(1).uppercased())
    }
    
    var button: String {
        return string
    }
    
    var isValid: Bool {
        return self != .blank
    }
    
    static var validCases: [Suit] {
        return Suit.allCases.filter({$0.isValid})
    }
    
    static var realSuits: [Suit] {
        return Suit.allCases.filter({$0.isValid && $0 != .noTrumps})
    }
    
    var hasDouble: Bool {
        return self.isValid
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
    
    var bold: NSAttributedString {
        switch self {
        case .undoubled:
            NSAttributedString(string: "")
        case .doubled:
            ContractDouble.symbol
        case .redoubled:
            ContractDouble.symbol + ContractDouble.symbol
        }
    }
    
    static var symbol: NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "staroflife.fill")
        return NSAttributedString(attachment: attachment)
    }
    
    var button: String {
        switch self {
        case .undoubled:
            return "-"
        case .doubled:
            return "􀑇"
        case .redoubled:
            return "􀑇􀑇"
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

    public var attributedContrast: NSAttributedString {
        switch level {
        case .blank:
            return NSAttributedString("")
        case .passout:
            return NSAttributedString("Pass Out")
        default:
            return NSAttributedString(level.short) + suit.attributedContrast + NSAttributedString(double.short)
        }
    }

    public var attributedString: NSAttributedString {
        switch level {
        case .blank:
            return NSAttributedString("")
        case .passout:
            return NSAttributedString("Pass Out")
        default:
            return NSAttributedString("\(level.short) ") + suit.attributedString + double.bold
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
    
    public var colorContrast: AttributedString {
        switch level {
        case .blank:
            return ""
        case .passout:
            return "Pass Out"
        default:
            return AttributedString(level.short) + suit.colorContrast + AttributedString(double.short)
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
    
    var isValid: Bool {
        level.isValid && (level == .passout || suit.isValid)
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
