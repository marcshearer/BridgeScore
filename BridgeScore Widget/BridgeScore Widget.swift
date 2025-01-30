//
//  BridgeScore_Widget.swift
//  BridgeScore Widget
//
//  Created by Marc Shearer on 29/01/2025.
//

import WidgetKit
import SwiftUI

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
        if let id = configuration.location?.id {
            return Timeline(entries: [BridgeScoreWidgetEntry(location: LocationEntity(id: id))], policy: .atEnd)
        } else {
            return Timeline(entries: [BridgeScoreWidgetEntry()], policy: .atEnd)
        }
    }
    
    func snapshot(for configuration: BridgeScoreConfiguration, in context: Context) async -> BridgeScoreWidgetEntry {
        return BridgeScoreWidgetEntry(location: configuration.location)
    }
}

struct BridgeScoreWidgetEntry: TimelineEntry {
    var date: Date
    var location: LocationEntity? = nil
    var score: String? = nil
    var position: String? = nil
    var scorecardId: UUID? = nil
    var notFound: Bool = true
    
    init(date: Date? = nil, location: LocationEntity? = nil) {
        self.notFound = (date == nil)
        self.date = date ?? Date()
        getLastScorecard(for: location)
    }
    
    mutating func getLastScorecard(for location: LocationEntity?) {
        // Find location
        var scorecardFilter: NSPredicate?
        if let location = location, let locationMO = CoreData.fetch(from: LocationMO.tableName, filter: NSPredicate(format: "name = %@", location.name)).first as? LocationMO {
            self.location = LocationEntity(id: locationMO.locationId)
            scorecardFilter = NSPredicate(format: "%K = %@", #keyPath(ScorecardMO.locationId), locationMO.locationId as CVarArg)
        } else {
            self.location = nil
        }
        if let scorecardMO = (CoreData.fetch(from: ScorecardMO.tableName, filter: scorecardFilter, limit: 1, sort: [("date", .descending)]) as? [ScorecardMO])?.first {
            self.notFound = false
            self.location = LocationEntity(id: scorecardMO.locationId)
            self.date = scorecardMO.date
            self.scorecardId = scorecardMO.scorecardId
            if let score = scorecardMO.score {
                let type = scorecardMO.type.matchScoreType
                self.score = "\(type.prefix(score: score))\(score.toString(places: type.places))\(type.suffix)"
            }
        }
    }
}

struct BridgeScoreWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            if let location = entry.location {
                Text(location.name).font(.headline)
            }
            if entry.notFound {
                Text("No Scorecard found").font(.title3)
            } else {
                Text(entry.date, style: .date)
                if let score = entry.score {
                    Text(score)
                }
                if let position = entry.position {
                    Text(position)
                }
                Button(intent: OpenScorecard(id: entry.scorecardId)) {
                    Text("Open Scorecard")
                }
            }
        }
        .containerBackground(.red.gradient, for: .widget)
    }
}

struct BridgeScoreWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: widgetKind,
            intent: BridgeScoreConfiguration.self,
            provider: Provider()
        ) { (config) in
            BridgeScoreWidgetEntryView(entry: BridgeScoreWidgetEntry(location: config.location))
        }
        .configurationDisplayName("Latest Scorecard")
        .description("Displays the latest Scorecard for a location")
    }
}
