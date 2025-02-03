//
//  Open Scorecard Widget.swift
//  BridgeScore Widget
//
//  Created by Marc Shearer on 29/01/2025.
//

import WidgetKit
import SwiftUI
import AppIntents

struct OpenScorecardWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: openScorecardWidgetKind,
            intent: OpenScorecardWidgetConfiguration.self,
            provider: OpenScorecardWidgetProvider()
        ) { (configuration) in
            OpenScorecardWidgetEntryView(entry: OpenScorecardWidgetEntry(filter: configuration.filter, palette: configuration.palette))
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Latest Scorecard")
        .description("Displays the latest Scorecard for a location")
        .supportedFamilies([.systemMedium])
    }
}

public struct OpenScorecardWidgetConfiguration: WidgetConfigurationIntent {
    
    public static var title: LocalizedStringResource = "Scorecard Details"
    
    public init() { }
    
    @Parameter(title: "Location: ") var filter: LocationEntity?
    @Parameter(title: "Colour scheme") var palette: PaletteEntity?
    
    public static var parameterSummary: some ParameterSummary {
        Summary("Create scorecard for \(\.$filter) \(\.$palette)")
    }
}

struct OpenScorecardWidgetProvider: AppIntentTimelineProvider {
    
    init() {
        // Set up core data stack
        CoreData.context = PersistenceController.shared.container.viewContext
        MyApp.shared.start()
    }
    
    func placeholder(in context: Context) -> OpenScorecardWidgetEntry {
        OpenScorecardWidgetEntry()
    }
    
    func timeline(for configuration: OpenScorecardWidgetConfiguration, in context: Context) async -> Timeline<OpenScorecardWidgetEntry> {
        if let id = configuration.filter?.id {
            return Timeline(entries: [OpenScorecardWidgetEntry(filter: LocationEntity(id: id), palette: configuration.palette)], policy: .atEnd)
        } else {
            return Timeline(entries: [OpenScorecardWidgetEntry()], policy: .atEnd)
        }
    }
    
    func snapshot(for configuration: OpenScorecardWidgetConfiguration, in context: Context) async -> OpenScorecardWidgetEntry {
        return OpenScorecardWidgetEntry(filter: configuration.filter, palette: configuration.palette)
    }
}

struct OpenScorecardWidgetEntry: TimelineEntry {
    var date: Date
    var desc: String?
    var filter: LocationEntity? = nil
    var palette: PaletteEntity? = nil
    var location: LocationEntity? = nil
    var score: String? = nil
    var position: String? = nil
    var type: String? = nil
    var scorecardId: UUID? = nil
    var noDate: Bool = true
    
    init(date: Date? = nil, filter: LocationEntity? = nil, palette: PaletteEntity? = nil) {
        let palette = palette ?? paletteEntityList.first!
        self.filter = filter
        self.palette = palette
        if let scorecardMO = ScorecardEntity.getLastScorecard(for: filter) {
            self.scorecardId = scorecardMO.scorecardId
            self.desc = scorecardMO.desc
            self.date = scorecardMO.date
            self.noDate = false
            self.location = LocationEntity(id: scorecardMO.locationId)
            let type = scorecardMO.type
            let matchType = type.matchScoreType
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

struct OpenScorecardWidgetEntryView : View {
    var entry: OpenScorecardWidgetProvider.Entry

    var body: some View {
        let paletteEntity = entry.palette ?? paletteEntityList.first!
        let theme = PaletteColor(paletteEntity.detailPalette)
        let label = (entry.filter == nil || (entry.filter!.id == nullUUID) ? "Most recent" : entry.filter!.name)
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
    }
    
    var dateLocation: String {
        let noLocation = entry.filter == nil || (entry.filter!.id == nullUUID)
        var dateLocation = (DayNumber(from: entry.date)-14).toNearbyString(brief: noLocation)
        if let location = entry.location?.name, noLocation {
            dateLocation += " at \(location)"
        }
        return dateLocation
    }
    
}
