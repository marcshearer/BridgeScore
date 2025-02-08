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
            LastScorecardWidgetEntryView(entry: LastScorecardWidgetEntry(date: Date(), allLocations: configuration.allLocations, filters: configuration.filters, eventTypes: configuration.eventTypes, offsetBy: configuration.offsetBy, palette: configuration.palette, title: configuration.title))
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
    
    @Parameter(title: "All locations: ", default: true) var allLocations: Bool
    @Parameter(title: "Filter locations: " ) var filters: [LocationEntity]?
    @Parameter(title: "Offset by: ", default: 0) var offsetBy: Int
    @Parameter(title: "Event types: ") var eventTypes: [WidgetEventType]?
    @Parameter(title: "Colour scheme: ") var palette: PaletteEntity?
    @Parameter(title: "Title: ") var title: String?
    
    public static var parameterSummary: some ParameterSummary {
        When(\.$allLocations, .equalTo, true) {
            Summary("Last scorecard \(\.$allLocations) \(\.$eventTypes) \(\.$offsetBy) \(\.$palette) \(\.$title)")
        } otherwise: {
            Summary("Last scorecard \(\.$allLocations) \(\.$filters) \(\.$eventTypes) \(\.$offsetBy) \(\.$palette) \(\.$title)")
        }
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
        return Timeline(entries: [LastScorecardWidgetEntry(date: Date(), allLocations: configuration.allLocations, filters: configuration.filters, eventTypes: configuration.eventTypes, offsetBy: configuration.offsetBy, palette: configuration.palette, title: configuration.title)], policy: .atEnd)
    }
    
    func snapshot(for configuration: LastScorecardWidgetConfiguration, in context: Context) async -> LastScorecardWidgetEntry {
        return LastScorecardWidgetEntry(date: Date(), allLocations: configuration.allLocations, filters: configuration.filters, eventTypes: configuration.eventTypes, offsetBy: configuration.offsetBy, palette: configuration.palette, title: configuration.title)
    }
}

struct LastScorecardWidgetEntry: TimelineEntry {
    var date: Date
    var desc: String?
    var allLocations: Bool = true
    var filters: [LocationEntity]? = nil
    var eventTypes: [WidgetEventType]? = nil
    var offsetBy: Int = 0
    var palette: PaletteEntity? = nil
    var title: String? = nil
    var location: LocationEntity? = nil
    var score: String? = nil
    var position: String? = nil
    var type: String? = nil
    var scorecardId: UUID? = nil
    var noDate: Bool = true
    
    init(date: Date? = nil, allLocations: Bool = true, filters: [LocationEntity]? = nil, eventTypes: [WidgetEventType]? = nil, offsetBy: Int = 0, palette: PaletteEntity? = nil, title: String? = nil) {
        if let date = date {
            self.date = date
            self.allLocations = allLocations
            self.filters = filters
            self.eventTypes = eventTypes
            self.offsetBy = offsetBy
            let palette = palette ?? paletteEntityList.first!
            self.palette = palette
            self.title = title
            let scorecardMOs = ScorecardEntity.getLastScorecards(for: (allLocations ? nil : filters), eventTypes: eventTypes, limit: offsetBy + 1)
            print("Offset: \(offsetBy) Title: '\(title ?? "none")' Filter count:\(filters != nil ? filters!.count : -2) Result count: \(scorecardMOs.count)")
            if scorecardMOs.count >= offsetBy + 1 {
                let scorecardMO = scorecardMOs[offsetBy]
                self.scorecardId = scorecardMO.scorecardId
                self.desc = scorecardMO.desc
                self.date = scorecardMO.date
                self.noDate = false
                self.location = LocationEntity(id: scorecardMO.locationId)
                let type = scorecardMO.type
                self.type = scorecardMO.type.brief
                if let score = scorecardMO.score {
                    self.score = type.scoreString(score: score, maxScore: scorecardMO.maxScore)
                    self.position = type.positionString(score: score, position: scorecardMO.position, entry: scorecardMO.entry)
                } else {
                    self.score = nil
                    self.position = nil
                }
            }
        } else {
            self.date = Date(timeIntervalSinceReferenceDate: 0)
        }
    }
}

struct LastScorecardWidgetEntryView : View {
    var entry: LastScorecardWidgetProvider.Entry

    var body: some View {
        let paletteEntity = entry.palette ?? paletteEntityList.first!
        let theme = PaletteColor(paletteEntity.detailPalette)
        let label = (entry.title != nil && entry.title != "" ? entry.title : (entry.location != nil ? entry.location!.name : (entry.allLocations ? "Most recent" : entry.filters!.first!.name)))
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
                            Spacer().frame(width: 8)
                            if let score = entry.score {
                                if (entry.position ?? "") == "" {
                                    Spacer()
                                }
                                Text(score)
                                if (entry.position ?? "") == "" {
                                    Spacer()
                                }
                                
                                if let position = entry.position {
                                    Spacer().frame(maxWidth: 50)
                                    Text(position)
                                }
                            } else {
                                Text("No score entered")
                            }
                            Spacer().frame(width: 8)
                        }
                        .font(defaultFont).bold()
                        .foregroundColor(theme.themeText)
                    }
                    
                }
                .onAppear{
                    print("Appearing - Offset: \(entry.offsetBy) Title: \(entry.title ?? "nil")")
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
        let multiLocation = (entry.allLocations || entry.filters!.count > 1)
        var dateLocation = (DayNumber(from: entry.date)).toNearbyString(brief: multiLocation)
        if let location = entry.location?.name, multiLocation {
            dateLocation += " at \(location)"
        }
        return dateLocation
    }
    
}
