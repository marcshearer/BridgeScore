//
//  Summary Details Widget.swift
//  BridgeScore
//
//  Created by Marc Shearer on 03/02/2025.
//

import WidgetKit
import SwiftUI
import AppIntents
import Charts

struct SummaryDetailsWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: lastScorecardWidgetKind,
            intent: LastScorecardWidgetConfiguration.self,
            provider: LastScorecardWidgetProvider()
        ) { (configuration) in
            LastScorecardWidgetEntryView(entry: LastScorecardWidgetEntry(filters: configuration.filters, palette: configuration.palette, title: configuration.title))
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Latest Scorecard")
        .description("Displays the latest Scorecard for a location")
        .supportedFamilies([.systemMedium])
    }
}
