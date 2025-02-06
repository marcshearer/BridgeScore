//
//  Summary Details Widget.swift
//  BridgeScore
//
//  Created by Marc Shearer on 03/02/2025.
//

import WidgetKit
import SwiftUI
import AppIntents

struct StatsWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: statsWidgetKind,
            intent: StatsWidgetConfiguration.self,
            provider: StatsWidgetProvider()
        ) { (configuration) in
            StatsWidgetEntryView(entry: StatsWidgetEntry(locations: configuration.locations, players: configuration.players, eventTypes: configuration.eventTypes, dateRange: configuration.dateRange, palette: configuration.palette, title: configuration.title))
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Statistics")
        .description("Displays statistics")
        .supportedFamilies([.systemLarge, .systemExtraLarge])
    }
}

public struct StatsWidgetConfiguration: WidgetConfigurationIntent {
    
    public static var title: LocalizedStringResource = "Statistics"
    
    public init() { }
    
    @Parameter(title: "Locations: ") var locations: [LocationEntity]?
    @Parameter(title: "Partners: ") var players: [PlayerEntity]?
    @Parameter(title: "Event types: ") var eventTypes: [WidgetEventType]?
    @Parameter(title: "Date range: ") var dateRange: WidgetDateRange?
    @Parameter(title: "Colour scheme") var palette: PaletteEntity?
    @Parameter(title: "Title: ") var title: String?
    
    public static var parameterSummary: some ParameterSummary {
        Summary("Create scorecard for \(\.$locations) \(\.$players) \(\.$eventTypes) \(\.$dateRange) \(\.$palette) \(\.$title)")
    }
}

struct StatsWidgetProvider: AppIntentTimelineProvider {
    
    init() {
        // Set up core data stack
        CoreData.context = PersistenceController.shared.container.viewContext
        MyApp.shared.start()
    }
    
    func placeholder(in context: Context) -> StatsWidgetEntry {
        StatsWidgetEntry()
    }
    
    func timeline(for configuration: StatsWidgetConfiguration, in context: Context) async -> Timeline<StatsWidgetEntry> {
        return Timeline(entries: [StatsWidgetEntry(locations: configuration.locations, players: configuration.players, eventTypes: configuration.eventTypes, dateRange: configuration.dateRange, palette: configuration.palette, title: configuration.title)], policy: .atEnd)
    }
    
    func snapshot(for configuration: StatsWidgetConfiguration, in context: Context) async -> StatsWidgetEntry {
        return StatsWidgetEntry(locations: configuration.locations, players: configuration.players, eventTypes: configuration.eventTypes, dateRange: configuration.dateRange, palette: configuration.palette, title: configuration.title)
    }
}

struct StatsWidgetEntry: TimelineEntry {
    var date: Date
    var locations: [LocationEntity]? = nil
    var players: [PlayerEntity]? = nil
    var eventTypes: [WidgetEventType]? = nil
    var dateRange: WidgetDateRange = .all
    var palette: PaletteEntity? = nil
    var title: String? = nil
    var data: [WidgetGraphValue] = []
    var running: [WidgetGraphValue] = []
    
    init(date: Date? = nil, locations: [LocationEntity]? = nil, players: [PlayerEntity]? = nil, eventTypes: [WidgetEventType]? = nil, dateRange: WidgetDateRange? = nil, palette: PaletteEntity? = nil, title: String? = nil) {
        let palette = palette ?? paletteEntityList.first!
        self.date = Date()
        self.locations = locations
        self.players = players
        self.eventTypes = eventTypes
        self.dateRange = dateRange ?? .all
        self.palette = palette
        self.title = title
        getData()
    }
    
    mutating func getData() {
        data = ScorecardEntity.scorecards(locationIds: locations?.map({$0.id}), playerIds: players?.map({$0.id}), eventTypes: eventTypes, dateRange: dateRange, scored: true).reversed().enumerated().map({WidgetGraphValue(sequence: $0, value: ($1.scoreValue/$1.maxScoreValue) * 100, date: $1.date)})
        
        let averageCount = (Int(data.count / 4) * 2) + 3

        let preData = ScorecardEntity.scorecards(locationIds: locations?.map({$0.id}), playerIds: players?.map({$0.id}), eventTypes: eventTypes, dateRange: dateRange, scored: true, preData: averageCount - 1).reversed().enumerated().map({WidgetGraphValue(sequence: $0 - averageCount + 1, value: ($1.scoreValue/$1.maxScoreValue) * 100)})
        
        let combined = preData + data
        
        running = []
        var divisor = Float(preData.count)
        var runningTotal = preData.map{$0.value}.reduce(0,+)
        
        for (index, entry) in data.enumerated() {
            divisor = min(divisor + 1, Float(averageCount))
            runningTotal += entry.value
            if divisor == Float(averageCount) {
                // Have got the right number for an average
                let average = runningTotal / divisor
                running.append(WidgetGraphValue(sequence: entry.sequence, value: average))
                // Remove the first entry in the current average
                runningTotal -= combined[index + preData.count - averageCount + 1].value
            }
        }
        
    }
        
    func value(_ scorecardMO: ScorecardMO) -> Float {
        return (scorecardMO.scoreValue/scorecardMO.maxScoreValue) * Float(100)
    }
}

struct StatsWidgetEntryView : View {
    var entry: StatsWidgetProvider.Entry

    var body: some View {
        let paletteEntity = entry.palette ?? paletteEntityList.first!
        let theme = PaletteColor(paletteEntity.detailPalette)
        let label = entry.title
        Button(intent: StatsAppIntent(locations: entry.locations ?? [], players: entry.players ?? [], eventTypes: entry.eventTypes ?? [], dateRange: entry.dateRange), label: {
            WidgetContainer(label: label, palette: PaletteColor(paletteEntity.containerPalette), titlePosition: .top) {
                WidgetGraph(values: entry.data, running: entry.running, palette: entry.palette ?? paletteEntityList.first!)
                .containerBackground(theme.background, for: .widget)
            }
        })
        .buttonStyle(RectangleButtonStyle())
        .ignoresSafeArea()
    }
}
