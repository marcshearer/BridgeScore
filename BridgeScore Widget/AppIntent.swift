//
//  AppIntent.swift
//  BridgeScore Widget
//
//  Created by Marc Shearer on 29/01/2025.
//

import WidgetKit
import AppIntents

struct BridgeScoreConfiguration: WidgetConfigurationIntent {
    
    static var title: LocalizedStringResource = "Scorecard Details"
    
    @Parameter(title: "Location: ") var location: LocationEntity?
}
