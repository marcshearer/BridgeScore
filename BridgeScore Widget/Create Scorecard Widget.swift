//
//  Create Scorecard Widget.swift
//  BridgeScore
//
//  Created by Marc Shearer on 01/02/2025.
//

import WidgetKit
import SwiftUI
import AppIntents

struct CreateScorecardWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: createScorecardWidgetKind,
            intent: CreateScorecardWidgetConfiguration.self,
            provider: CreateScorecardWidgetProvider()
        ) { (configuration) in
            CreateScorecardWidgetEntryView(entry: CreateScorecardWidgetEntry(layouts: configuration.layouts, forceDisplayDetail: configuration.forceDisplayDetail, palette: configuration.palette, title: configuration.title, titlePosition: configuration.titlePosition))
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Create Scorecard")
        .description("Create Scorecard from Template")
        .supportedFamilies([.systemSmall])
    }
}

public struct CreateScorecardWidgetConfiguration: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "Create Scorecard"
    
    public init() { }
    
    @Parameter(title: "Templates: ") var layouts: [LayoutEntity]?
    @Parameter(title: "Edit parameters: ", default: false) var forceDisplayDetail: Bool
    @Parameter(title: "Palette: ") var palette: PaletteEntity?
    @Parameter(title: "Title: ") var title: String?
    @Parameter(title: "Title position: ", default: .top) var titlePosition: WidgetTitlePosition
}

struct CreateScorecardWidgetProvider: AppIntentTimelineProvider {
    
    init() {
        // Set up core data stack
        CoreData.context = PersistenceController.shared.container.viewContext
        MyApp.shared.start()
    }
    
    func placeholder(in context: Context) -> CreateScorecardWidgetEntry {
        CreateScorecardWidgetEntry()
    }
    
    func timeline(for configuration: CreateScorecardWidgetConfiguration, in context: Context) async -> Timeline<CreateScorecardWidgetEntry> {
        if let layouts = configuration.layouts {
            return Timeline(entries: [CreateScorecardWidgetEntry(layouts: layouts, forceDisplayDetail: configuration.forceDisplayDetail, palette: configuration.palette, title: configuration.title, titlePosition: configuration.titlePosition)], policy: .atEnd)
        } else {
            return Timeline(entries: [CreateScorecardWidgetEntry()], policy: .atEnd)
        }
    }
    
    func snapshot(for configuration: CreateScorecardWidgetConfiguration, in context: Context) async -> CreateScorecardWidgetEntry {
        return CreateScorecardWidgetEntry(layouts: configuration.layouts, forceDisplayDetail: configuration.forceDisplayDetail, palette: configuration.palette, title: configuration.title, titlePosition: configuration.titlePosition)
    }
}

struct CreateScorecardWidgetEntry: TimelineEntry {
    var date: Date
    var layouts: [LayoutEntity]? = nil
    var forceDisplayDetail: Bool = false
    var palette: PaletteEntity? = nil
    var title: String?
    var titlePosition: WidgetTitlePosition = .top
    
    init(date: Date? = nil, layouts: [LayoutEntity]? = nil, forceDisplayDetail: Bool = false, palette: PaletteEntity? = nil, title: String? = nil, titlePosition: WidgetTitlePosition = .top) {
        self.layouts = layouts
        self.forceDisplayDetail = forceDisplayDetail
        self.palette = palette ?? paletteEntityList.first!
        self.title = title
        self.titlePosition = titlePosition
        self.date = Date()
    }
}

struct CreateScorecardWidgetEntryView : View {
    var entry: CreateScorecardWidgetProvider.Entry

    var body: some View {
        let paletteEntity = entry.palette ?? paletteEntityList.first!
        let theme = PaletteColor(paletteEntity.detailPalette)
        let layout = entry.layouts?.first ?? LayoutEntity()
        VStack(spacing: 0) {
            WidgetContainer(label: entry.title ?? layout.name, palette: PaletteColor(paletteEntity.containerPalette), titlePosition: entry.titlePosition) {
                VStack(spacing: 0) {
                    Image(systemName: "plus").font(bigFont).bold()
                }
                .foregroundColor(theme.text)
                .containerBackground(theme.background, for: .widget)
                .minimumScaleFactor(0.75)
            }
        }
    }
}
