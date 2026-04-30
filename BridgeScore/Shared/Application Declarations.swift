//
//  Application Declarations.swift
//  BridgeScore
//
//  Created by Marc Shearer on 01/02/2025.
//

import Combine
import SwiftUI

let ScorecardListViewChange = PassthroughSubject<ScorecardDetails, Never>()

public enum Responsible: Int, EnumPickerType, Identifiable {
    public var id: Int { rawValue }
    
    case opponentMinus = -3
    case luckMinus = -5
    case teamMinus = -4
    case partnerMinus = -2
    case scorerMinus = -1
    case unknown = 0
    case query = 99
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
        case .query:
            return "Discuss"
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
        case .query:
            return "\(string.left(1))"
        }
    }
        
    public var imageName: String? {
        switch self {
        case .query:
            "person.fill.questionmark"
        default:
            nil
        }
    }
     
    public var show: String { short }
    
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

extension Pair {
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
    
    public func offset(by pairType: PairType) -> Pair {
        pairType == .we ? self : self.other
    }
}

public enum SeatPlayer: Int, CaseIterable {
    case unknown = -1
    case player = 0
    case partner = 2
    case lhOpponent = 1
    case rhOpponent = 3
    
    init(sitting: Seat, seat: Seat) {
        self.init(rawValue: sitting.offset(to: seat))!
    }
    
    var isOpponent: Bool {
        self == .lhOpponent || self == .rhOpponent
    }
    
    var offset: Int {
        rawValue
    }
    
    static var validCases: [SeatPlayer] {
        allCases.filter{$0 != .unknown}
    }
    
    var pairType: PairType {
        switch self {
        case .player, .partner:
            .we
        case .lhOpponent, .rhOpponent:
            .they
        default:
            .unknown
        }
    }
    
    var string: String {
        switch self {
        case .player:
            "Self"
        case .partner:
            "Partner"
        case .lhOpponent:
            "LH Opp"
        case .rhOpponent:
            "RH Opp"
        default:
            ""
        }
    }
}

public enum PairType: Int, CaseIterable {
    case unknown = -1
    case we = 0
    case they = 2
    
    var seatPlayers: [SeatPlayer] {
        switch self {
        case .we:
            [.player, .partner]
        case .they:
            [.lhOpponent, .rhOpponent]
        default: []
        }
    }
    
    var string: String {
        self == .unknown ? "" : "\(self)".capitalized
    }
    
    static var validCases: [PairType] {
        allCases.filter{$0 != .unknown}
    }
}

public enum SuitType: Int {
    case major
    case minor
    case noTrumps
    case unknown
    
    init(suit: Suit) {
        switch suit {
        case .hearts, .spades:
            self = .major
        case .clubs, .diamonds:
            self = .minor
        default:
            self = .noTrumps
        }
    }
    
    var gameTricks: Int {
        switch self {
        case .noTrumps:
            Values.noTrumpGameLevel.tricks
        case .major:
            Values.majorGameLevel.tricks
        case .minor:
            Values.minorGameLevel.tricks
        default:
            0
        }
    }
    
    var string: String {
        if self == .noTrumps {
            "No Trumps"
        } else {
            "\(self)".capitalized
        }
    }
}

public enum LevelType: Int {
    case passout
    case partScore
    case game
    case slam
    
    init(level: ContractLevel, suit: Suit) {
        if level == .passout {
            self = .passout
        } else if level == ContractLevel.smallSlam || level == ContractLevel.grandSlam {
            self = .slam
        } else {
            let gameTricks = SuitType(suit: suit).gameTricks
            if level.tricks >= gameTricks {
                self = .game
            } else {
                self = .partScore
            }
        }
    }
    
    var string: String {
        switch self {
        case .passout:
            "Pass out"
        case .partScore:
            "Part score"
        default:
            "\(self)".capitalized
        }
    }
    
}

protocol EnumPickerDelegate {
    func enumPickerDidChange(to: Any, allowPopup: Bool)
}

extension EnumPickerDelegate {
    func enumPickerDidChange(to: Any) {
        enumPickerDidChange(to: to, allowPopup: false)
    }
}

protocol EnumPickerType : CaseIterable, Equatable {
    static var validCases: [Self] {get}
    static var allCases: [Self] {get}
    var string: String {get}
    var show: String {get}
    var short: String {get}
    var imageName: String? {get}
    var rawValue: Int {get}
    init?(rawValue: Int)
}

public enum Seat: Int, EnumPickerType, ContractEnumType, Identifiable {
    case unknown = 0
    case north = 1
    case east = 2
    case south = 3
    case west = 4
    
    public var id: Self { self }
    
    public var show: String { short }
    
    public var imageName: String? { nil }
    
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
        switch self {
        case .unknown:
            ""
        default:
            "\(self)".capitalized
        }
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
                return ""
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
            return ""
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

public enum SeatVulnerability: Int {
    case unknown = 0
    case none = 1
    case we = 2
    case they = 3
    case both = 4
    
    init(boardNumber: Int, sitting: Seat) {
        let vulnerability = Vulnerability(board: boardNumber)
        var seatVulnerability = SeatVulnerability(rawValue: vulnerability.rawValue)!
        if sitting.pair != .ns {
            if vulnerability == .ns {
                seatVulnerability = .they
            } else if vulnerability == .ew {
                seatVulnerability = .we
            }
        }
        self = seatVulnerability
    }
    
    public var string: String {
        switch self {
        case .unknown:
            return "?"
        case .none:
            return "-"
        case .we:
            return "We"
        case .they:
            return "They"
        case .both:
            return "All"
        }
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
    public static var noTrumpGameLevel: ContractLevel { .three }
    public static var majorGameLevel: ContractLevel { .four }
    public static var minorGameLevel: ContractLevel { .five }
}
