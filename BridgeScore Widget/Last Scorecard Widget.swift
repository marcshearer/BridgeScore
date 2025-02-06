//
//  Scorecard Details Widget.swift
//  BridgeScore Widget
//
//  Created by Marc Shearer on 29/01/2025.
//

import WidgetKit
import SwiftUI
import AppIntents

struct LastScorecardWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: lastScorecardWidgetKind,
            intent: LastScorecardWidgetConfiguration.self,
            provider: LastScorecardWidgetProvider()
        ) { (configuration) in
            LastScorecardWidgetEntryView(entry: LastScorecardWidgetEntry(filters: configuration.filters, palette: configuration.palette, title: configuration.title))
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Last Scorecard Details")
        .description("Displays information about last Scorecard at selected locations")
        .supportedFamilies([.systemMedium])
    }
}

public struct LastScorecardWidgetConfiguration: WidgetConfigurationIntent {
    
    public static var title: LocalizedStringResource = "Scorecard Details"
    
    public init() { }
    
    @Parameter(title: "Locations: ") var filters: [LocationEntity]?
    @Parameter(title: "Colour scheme") var palette: PaletteEntity?
    @Parameter(title: "Title: ") var title: String?
    
    public static var parameterSummary: some ParameterSummary {
        Summary("Create scorecard for \(\.$filters) \(\.$palette) \(\.$title)")
    }
}

struct LastScorecardWidgetProvider: AppIntentTimelineProvider {
    
    init() {
        // Set up core data stack
        CoreData.context = PersistenceController.shared.container.viewContext
        MyApp.shared.start()
    }
    
    func placeholder(in context: Context) -> LastScorecardWidgetEntry {
        LastScorecardWidgetEntry()
    }
    
    func timeline(for configuration: LastScorecardWidgetConfiguration, in context: Context) async -> Timeline<LastScorecardWidgetEntry> {
        if let filters = configuration.filters {
            return Timeline(entries: [LastScorecardWidgetEntry(filters: filters, palette: configuration.palette, title: configuration.title)], policy: .atEnd)
        } else {
            return Timeline(entries: [LastScorecardWidgetEntry()], policy: .atEnd)
        }
    }
    
    func snapshot(for configuration: LastScorecardWidgetConfiguration, in context: Context) async -> LastScorecardWidgetEntry {
        return LastScorecardWidgetEntry(filters: configuration.filters, palette: configuration.palette, title: configuration.title)
    }
}

struct LastScorecardWidgetEntry: TimelineEntry {
    var date: Date
    var desc: String?
    var filters: [LocationEntity]? = nil
    var palette: PaletteEntity? = nil
    var title: String? = nil
    var location: LocationEntity? = nil
    var score: String? = nil
    var position: String? = nil
    var type: String? = nil
    var scorecardId: UUID? = nil
    var noDate: Bool = true
    
    init(date: Date? = nil, filters: [LocationEntity]? = nil, palette: PaletteEntity? = nil, title: String? = nil) {
        let palette = palette ?? paletteEntityList.first!
        self.filters = filters
        self.palette = palette
        self.title = title
        if let scorecardMO = ScorecardEntity.getLastScorecard(for: filters) {
            self.scorecardId = scorecardMO.scorecardId
            self.desc = scorecardMO.desc
            self.date = scorecardMO.date
            self.noDate = false
            self.location = LocationEntity(id: scorecardMO.locationId)
            let type = scorecardMO.type
            self.type = scorecardMO.type.brief
            if let score = scorecardMO.score {
                self.score = type.scoreString(score: score, maxScore: scorecardMO.maxScore)
                position = type.positionString(score: score, position: scorecardMO.position, entry: scorecardMO.entry)
            }
        } else {
            self.date = Date()
        }
    }
}

struct LastScorecardWidgetEntryView : View {
    var entry: LastScorecardWidgetProvider.Entry

    var body: some View {
        let paletteEntity = entry.palette ?? paletteEntityList.first!
        let theme = PaletteColor(paletteEntity.detailPalette)
        let label = entry.title ?? (entry.filters?.first == nil || entry.filters!.count > 1 || entry.filters!.first!.id == nullUUID ? "Most recent" : entry.filters!.first!.name)
        Button(intent: LastScorecardAppIntent(id: entry.scorecardId ?? nullUUID), label: {
            WidgetContainer(label: label, palette: PaletteColor(paletteEntity.containerPalette), titlePosition: .left) {
                VStack(spacing: 0) {
                    if entry.noDate {
                        Text("No Scorecard found").font(.title3)
                    } else {
                        if let desc = entry.desc {
                            Text(desc).font(bannerFont).bold()
                        }
                        HStack(spacing: 0) {
                            Text(dateLocation).font(.title2)
                        }
                        if let type = entry.type {
                            Text(type).font(.title2)
                        }
                        Spacer().frame(height: 5)
                        HStack {
                            if let score = entry.score {
                                Text(score)
                            }
                            
                            if let position = entry.position {
                                Spacer().frame(width: 50)
                                Text(position)
                            }
                        }
                        .font(defaultFont).bold()
                        .foregroundColor(theme.themeText)
                    }
                    
                }
                .lineLimit(1)
                .foregroundColor(theme.text)
                .containerBackground(theme.background, for: .widget)
                .minimumScaleFactor(0.75)
            }
        })
        .buttonStyle(RectangleButtonStyle())
        .ignoresSafeArea()
    }
    
    var dateLocation: String {
        let multiLocation = (entry.filters?.first == nil || entry.filters!.count > 1 || entry.filters!.first!.id == nullUUID)
        var dateLocation = (DayNumber(from: entry.date)).toNearbyString(brief: multiLocation)
        if let location = entry.location?.name, multiLocation {
            dateLocation += " at \(location)"
        }
        return dateLocation
    }
    
}
