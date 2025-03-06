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
            CreateScorecardWidgetEntryView(entry: CreateScorecardWidgetEntry(date: Date(), allLayouts: configuration.allLayouts, layouts: configuration.layouts, forceDisplayDetail: configuration.forceDisplayDetail, palette: configuration.palette, title: configuration.title, titlePosition: configuration.titlePosition))
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
    
    @Parameter(title: "All templates: ", default: true) var allLayouts: Bool
    @Parameter(title: "Specific templates: ") var layouts: [LayoutEntity]?
    @Parameter(title: "Display parameters: ", default: false) var forceDisplayDetail: Bool
    @Parameter(title: "Colour scheme: ") var palette: PaletteEntity?
    @Parameter(title: "Title: ") var title: String?
    @Parameter(title: "Title position: ", default: .top) var titlePosition: WidgetTitlePosition
    
    public static var parameterSummary: some ParameterSummary {
        When(\.$allLayouts, .equalTo, true) {
            Summary("Create scorecard \(\.$allLayouts) \(\.$forceDisplayDetail) \(\.$palette) \(\.$title) \(\.$titlePosition)")
        } otherwise: {
            Summary("Create scorecard \(\.$allLayouts) \(\.$layouts) \(\.$forceDisplayDetail) \(\.$palette) \(\.$title) \(\.$titlePosition)")
        }
    }
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
        return Timeline(entries: [CreateScorecardWidgetEntry(date: Date(), allLayouts: configuration.allLayouts, layouts: configuration.layouts, forceDisplayDetail: configuration.forceDisplayDetail, palette: configuration.palette, title: configuration.title, titlePosition: configuration.titlePosition)], policy: .atEnd)
    }
    
    func snapshot(for configuration: CreateScorecardWidgetConfiguration, in context: Context) async -> CreateScorecardWidgetEntry {
        return CreateScorecardWidgetEntry(date: Date(), allLayouts: configuration.allLayouts, layouts: configuration.layouts, forceDisplayDetail: configuration.forceDisplayDetail, palette: configuration.palette, title: configuration.title, titlePosition: configuration.titlePosition)
    }
}

struct CreateScorecardWidgetEntry: TimelineEntry {
    var date: Date
    var allLayouts: Bool = true
    var layouts: [LayoutEntity]? = nil
    var forceDisplayDetail: Bool = false
    var palette: PaletteEntity? = nil
    var title: String?
    var titlePosition: WidgetTitlePosition = .top
    
    init(date: Date? = nil, allLayouts: Bool = true, layouts: [LayoutEntity]? = nil, forceDisplayDetail: Bool = false, palette: PaletteEntity? = nil, title: String? = nil, titlePosition: WidgetTitlePosition = .top) {
        if let date = date {
            self.allLayouts = allLayouts
            self.layouts = layouts
            self.forceDisplayDetail = forceDisplayDetail
            self.palette = palette ?? paletteEntityList.first!
            self.title = title
            self.titlePosition = titlePosition
            self.date = date
        } else {
            self.date = Date(timeIntervalSinceReferenceDate: 0)
        }
    }
}

struct CreateScorecardWidgetEntryView : View {
    var entry: CreateScorecardWidgetProvider.Entry

    var body: some View {
        let paletteEntity = entry.palette ?? paletteEntityList.first!
        let theme = PaletteColor(paletteEntity.detailPalette)
        let layout = entry.layouts?.first ?? LayoutEntity()
        VStack(spacing: 0) {
            Button(intent: CreateScorecardAppIntent(allLayouts: entry.allLayouts, layouts: entry.layouts ?? [], forceDisplayDetail: entry.forceDisplayDetail), label: {
                WidgetContainer(label: entry.title ?? layout.name, palette: PaletteColor(paletteEntity.containerPalette), titlePosition: entry.titlePosition) {
                    VStack(spacing: 0) {
                        Spacer()
                        HStack(spacing: 0) {
                            Spacer()
                            Image(systemName: "plus").font(widgetBigFont).bold()
                            Spacer()
                        }
                        Spacer()
                    }
                    .foregroundColor(theme.text)
                    .containerBackground(theme.background, for: .widget)
                    .minimumScaleFactor(0.75)
                }
            })
            .buttonStyle(RectangleButtonStyle())
            .ignoresSafeArea()
        }
    }
}

struct CreateScoreardShortcuts: AppShortcutsProvider {
    
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: CreateScorecardAppIntent(),
                    phrases: ["Create \(\.$target) with \(.applicationName)"],
                    shortTitle: "Create scorecard",
                    systemImageName: "plus.square")
    }
}
