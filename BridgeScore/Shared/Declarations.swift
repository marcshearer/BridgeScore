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
let SlideInMenuRowHeight: CGFloat = (MyApp.target == .iOS ? 50 : 35)

// Fonts
var defaultFont = Font.system(size: (MyApp.format == .tablet ? 28.0 : 20.0))
var toolbarFont = Font.system(size: (MyApp.format == .tablet ? 16.0 : 12.0))
var captionFont = Font.system(size: (MyApp.format == .tablet ? 20.0 : 16.0))
var inputTitleFont = Font.system(size: (MyApp.format == .tablet ? 20.0 : 16.0))
var inputFont = Font.system(size: (MyApp.format == .tablet ? 16.0 : 12.0))
var messageFont = Font.system(size: (MyApp.format == .tablet ? 16.0 : 12.0))
var titleFont = Font.system(size: (MyApp.format == .tablet ? 16.0 : 12.0), weight: .bold)
var cellFont = Font.system(size: (MyApp.format == .tablet ? 16.0 : 12.0))

// Localisable names

public let appName = "Bridge Score"
public let appImage = "BridgeScore"

public let dateFormat = "EEEE d MMMM"

public enum UIMode {
    case uiKit
    case appKit
    case unknown
}

public enum Type: Int, CaseIterable {
    case percent = 0
    case imp = 1
    
    public var string: String {
        switch self {
        case .percent:
            return "Match Points (%)"
        case .imp:
            return "IMPs"
        }
    }
}

public enum Position: Int, CaseIterable {
    case scorer = 0
    case partner = 1
    case opponent = 2
    
    public var string: String {
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

