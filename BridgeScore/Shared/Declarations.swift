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

let inputTopHeight: CGFloat = (MyApp.format == .tablet ? 20.0 : 10.0)
let inputDefaultHeight: CGFloat = 30.0
let inputToggleDefaultHeight: CGFloat = (MyApp.format == .tablet ? 30.0 : 16.0)
let bannerHeight: CGFloat = (MyApp.format == .tablet ? 80.0 : 50.0)
let minimumBannerHeight: CGFloat = 40.0
let bannerBottom: CGFloat = (MyApp.format == .tablet ? 30.0 : 10.0)
let slideInMenuRowHeight: CGFloat = (MyApp.target == .iOS ? 50 : 35)

// Fonts
var defaultFont = Font.system(size: (MyApp.format == .tablet ? 28.0 : 20.0))
var toolbarFont = Font.system(size: (MyApp.format == .tablet ? 16.0 : 12.0))
var captionFont = Font.system(size: (MyApp.format == .tablet ? 20.0 : 16.0))
var inputTitleFont = Font.system(size: (MyApp.format == .tablet ? 20.0 : 16.0))
var inputFont = Font.system(size: (MyApp.format == .tablet ? 16.0 : 12.0))
var messageFont = Font.system(size: (MyApp.format == .tablet ? 16.0 : 12.0))

// Fonts in scorecard
var titleFont = UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 16.0 : 12.0), weight: .bold)
var titleCaptionFont = UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 16.0 : 12.0))
var cellFont = UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 28.0 : 16.0))
var boardFont = UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 28.0 : 20.0))
var pickerTitleFont = UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 30.0 : 24.0))
var pickerCaptionFont = UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 10.0 : 8.0))

// Backups
let backupDirectoryDateFormat = "yyyy-MM-dd-HH-mm-ss-SSS"
let backupDateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"

// Other constants
let tagMultiplier = 1000000

// Localisable names

public let appName = "Bridge Score"
public let appImage = "bridge score"

public let dateFormat = "EEEE d MMMM"

public enum UIMode {
    case uiKit
    case appKit
    case unknown
}

// Application specific types
public enum Type: Int, CaseIterable {
    case percent = 0
    case vp = 1
    case imp = 2
    
    public var string: String {
        switch self {
        case .percent:
            return "Match Points Pairs (%)"
        case .imp:
            return "IMP Pairs"
        case .vp:
            return "Victory Point Teams"
        }
    }
}

public enum Participant: Int, EnumPickerType {
    case scorer = 0
    case partner = 1
    case opponent = 2
    
    public var string: String {
        if self == .scorer {
            return "Self"
        }
        return "\(self)".capitalized
    }
    
    public var short: String {
        return string.left(1)
    }
}

public enum OptionalParticipant: Int, EnumPickerType {
    case unknown = 0
    case scorer = 1
    case partner = 2
    case opponent = 3
    
    public var string: String {
        if self == .scorer {
            return "Self"
        }
        return "\(self)".capitalized
    }
    
    public var short: String {
        if self == .unknown {
            return ""
        } else {
            return string.left(1)
        }
    }
    
}

public enum Seat: Int, EnumPickerType {
    case unknown = 0
    case north = 1
    case east = 2
    case south = 4
    case west = 5
    
    public var string: String {
        return "\(self)".capitalized
    }
    
    public var short: String {
        if self == .unknown {
            return ""
        }
        return string.left(1)
    }

}

// Scorecard view types
enum ColumnType: Codable {
    case table
    case sitting
    case tableScore
    case versus
    case board
    case contract
    case declarer
    case made
    case score
    case comment
    case responsible
    
    var string: String {
        return "\(self)"
    }
}

enum ColumnSize: Codable {
    case fixed(CGFloat)
    case flexible
}

enum ContractElement: Int {
    case level = 0
    case suit = 1
    case double = 2
}

public enum ContractLevel: Int, CaseIterable {
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
            return "P"
        default:
            return "\(self.rawValue)"
        }
    }
    
    var hasSuit: Bool {
        return self != .blank && self != .passout
    }
    
    var hasDouble: Bool {
        return hasSuit
    }
}

public enum ContractSuit: Int, CaseIterable {
    case blank = 0
    case club = 1
    case diamond = 2
    case heart = 3
    case spade = 4
    case noTrump = 5
    
    var string: String {
        switch self {
        case .blank:
            return ""
        case .club:
            return "C"
        case .diamond:
            return "D"
        case .heart:
            return "H"
        case .spade:
            return "S"
        case .noTrump:
            return "NT"
        }
    }
    
    var hasDouble: Bool {
        return self != .blank
    }
}

public enum ContractDouble: Int, CaseIterable {
    case undoubled = 0
    case doubled = 1
    case redoubled = 2
    
    var string: String {
        switch self {
        case .undoubled:
            return ""
        case .doubled:
            return "*"
        case .redoubled:
            return "**"
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
    public var suit: ContractSuit = .blank {
        didSet {
            if !suit.hasDouble {
                double = .undoubled
            }
        }
    }
    public var double: ContractDouble = .undoubled
    
    init(level: ContractLevel = .blank, suit: ContractSuit = .blank, double: ContractDouble = .undoubled) {
        self.level = level
        self.suit = suit
        self.double = double
    }
    
    static public func ==(lhs: Contract, rhs: Contract) -> Bool {
        return lhs.level == rhs.level && lhs.suit == rhs.suit && lhs.double == rhs.double
    }
}

#if canImport(UIKit)
public let target: UIMode = .uiKit
#elseif canImport(appKit)
public let target: UIMode = .appKit
#else
public let target: UIMode = .unknow
#endif
