//
//  BridgeScore_Widget.swift
//  BridgeScore Widget
//
//  Created by Marc Shearer on 29/01/2025.
//

import WidgetKit
import SwiftUI
import AppIntents

struct Provider: AppIntentTimelineProvider {
    
    init() {
        // Set up core data stack
        CoreData.context = PersistenceController.shared.container.viewContext
        MyApp.shared.start()
    }
    
    func placeholder(in context: Context) -> BridgeScoreWidgetEntry {
        BridgeScoreWidgetEntry()
    }
    
    func timeline(for configuration: BridgeScoreConfiguration, in context: Context) async -> Timeline<BridgeScoreWidgetEntry> {
        if let id = configuration.filter?.id {
            return Timeline(entries: [BridgeScoreWidgetEntry(filter: LocationEntity(id: id), palette: configuration.palette)], policy: .atEnd)
        } else {
            return Timeline(entries: [BridgeScoreWidgetEntry()], policy: .atEnd)
        }
    }
    
    func snapshot(for configuration: BridgeScoreConfiguration, in context: Context) async -> BridgeScoreWidgetEntry {
        return BridgeScoreWidgetEntry(filter: configuration.filter, palette: configuration.palette)
    }
}

struct BridgeScoreWidgetEntry: TimelineEntry {
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
            let type = scorecardMO.type.matchScoreType
            self.type = scorecardMO.type.brief
            if let score = scorecardMO.score {
                self.score = "\(type.prefix(score: score))\(score.toString(places: min(1,type.places)))\(type.suffix)"
            }
            let position = scorecardMO.position
            let entry = scorecardMO.entry
            if let position = position.ordinal, entry != 0 {
                self.position = "\(position) of \(entry)"
            }
        } else {
            self.date = Date()
        }
    }
}

struct BridgeScoreWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        let paletteEntity = entry.palette ?? paletteEntityList.first!
        let theme = PaletteColor(paletteEntity.detailPalette)
        let label = (entry.filter == nil || (entry.filter!.id == nullUUID) ? "Most recent" : entry.filter!.name)
        BridgeScoreWidgetContainer(label: label, palette: PaletteColor(paletteEntity.containerPalette)) {
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

struct BridgeScoreWidgetContainer<Content>: View where Content: View {
    var label: String
    var palette: PaletteColor
    var content: ()->Content
    let titleWidth: CGFloat = 40
    
    var body: some View {
        HStack {
            HStack {
                ZStack {
                    Rectangle()
                        .foregroundColor(palette.background)
                        .frame(width: titleWidth)
                    HStack(spacing: 0) {
                        Spacer()
                        Spacer().frame(width: 20)
                        Text(label)
                            .foregroundColor(palette.text)
                            .font(.title2).bold()
                            .minimumScaleFactor(0.5)
                        Spacer().frame(width: 20)
                        Spacer()
                    }
                    .fixedSize()
                    .frame(height: titleWidth)
                    .rotationEffect(.degrees(270))
                    .ignoresSafeArea()
                }
                .ignoresSafeArea()
                .frame(width: titleWidth)
                Spacer()
            }
            .frame(width: titleWidth)
            Spacer()
            content()
            Spacer()
        }
    }
}

struct BridgeScoreWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: widgetKind,
            intent: BridgeScoreConfiguration.self,
            provider: Provider()
        ) { (configuration) in
            BridgeScoreWidgetEntryView(entry: BridgeScoreWidgetEntry(filter: configuration.filter, palette: configuration.palette))
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Latest Scorecard")
        .description("Displays the latest Scorecard for a location")
    }
}
