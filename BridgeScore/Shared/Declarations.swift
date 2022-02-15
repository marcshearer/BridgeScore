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

var titleFont = UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 16.0 : 12.0), weight: .bold)
var cellFont = UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 28.0 : 16.0))
var boardFont = UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 28.0 : 20.0))
var pickerTitleFont = UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 30.0 : 24.0), weight: .bold)
var pickerCaptionFont = UIFont.systemFont(ofSize: (MyApp.format == .tablet ? 10.0 : 8.0))

// Backups
let backupDirectoryDateFormat = "yyyy-MM-dd-HH-mm-ss-SSS"
let backupDateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"

// Localisable names

public let appName = "Bridge Score"
public let appImage = "bridge score"

public let dateFormat = "EEEE d MMMM"

public enum UIMode {
    case uiKit
    case appKit
    case unknown
}

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
            return "self"
        }
        return "\(self)"
    }
}

#if canImport(UIKit)
public let target: UIMode = .uiKit
#elseif canImport(appKit)
public let target: UIMode = .appKit
#else
public let target: UIMode = .unknow
#endif

// Scorecard view types

enum RowType: Int {
    case heading = 0
    case body = 1
    case total = 2
}

enum ColumnType: Codable {
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

struct ScorecardRow {
    var row: Int
    var type: RowType
    var table: Int?
    var board: BoardViewModel?
}

struct ScorecardColumn: Codable {
    var type: ColumnType
    var heading: String
    var size: ColumnSize
    var width: CGFloat?
}
