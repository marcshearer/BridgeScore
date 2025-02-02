//
//  Create Scorecard Widget.swift
//  BridgeScore
//
//  Created by Marc Shearer on 01/02/2025.
//

import WidgetKit
import SwiftUI
import AppIntents

struct CreateScorecardAppIntent: AppIntent, OpenIntent {

    static let title: LocalizedStringResource = "Create Scorecard"
    
    @Parameter(title: "Template", description: "The template to use for the Scorecard") var target: LayoutEntity
    
    func perform() async throws -> some IntentResult {
        let layoutId = target.id
        if let layoutMO = LayoutEntity.layouts(id: layoutId).first {
            let details = ScorecardDetails(action: .createScorecard, layout: layoutMO)
            Utility.mainThread {
                ScorecardListViewChange.send(details)
            }
        }
        return .result()
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Create scorecard for \(\.$target)")
    }
    
}

struct CreateScorecardWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: createScorecardWidgetKind,
            intent: CreateScorecardWidgetConfiguration.self,
            provider: CreateScorecardWidgetProvider()
        ) { (configuration) in
            CreateScorecardWidgetEntryView(entry: CreateScorecardWidgetEntry(layout: configuration.layout, forceDisplayDetail: configuration.forceDisplayDetail, palette: configuration.palette, titlePosition: configuration.titlePosition))
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
    
    @Parameter(title: "Template: ") var layout: LayoutEntity?
    @Parameter(title: "Edit parameters: ", default: false) var forceDisplayDetail: Bool
    @Parameter(title: "Palette: ") var palette: PaletteEntity?
    @Parameter(title: "Title position") var titlePosition: WidgetTitlePosition
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
        if let id = configuration.layout?.id {
            return Timeline(entries: [CreateScorecardWidgetEntry(layout: LayoutEntity(id: id), forceDisplayDetail: configuration.forceDisplayDetail, palette: configuration.palette, titlePosition: configuration.titlePosition)], policy: .atEnd)
        } else {
            return Timeline(entries: [CreateScorecardWidgetEntry()], policy: .atEnd)
        }
    }
    
    func snapshot(for configuration: CreateScorecardWidgetConfiguration, in context: Context) async -> CreateScorecardWidgetEntry {
        return CreateScorecardWidgetEntry(layout: configuration.layout, forceDisplayDetail: configuration.forceDisplayDetail, palette: configuration.palette, titlePosition: configuration.titlePosition)
    }
}

struct CreateScorecardWidgetEntry: TimelineEntry {
    var date: Date
    var layout: LayoutEntity? = nil
    var forceDisplayDetail: Bool = false
    var palette: PaletteEntity? = nil
    var titlePosition: WidgetTitlePosition = .top
    
    init(date: Date? = nil, layout: LayoutEntity? = nil, forceDisplayDetail: Bool = false, palette: PaletteEntity? = nil, titlePosition: WidgetTitlePosition = .top) {
        self.layout = layout
        self.forceDisplayDetail = forceDisplayDetail
        self.palette = palette ?? paletteEntityList.first!
        self.titlePosition = titlePosition
        self.date = Date()
    }
}

struct CreateScorecardWidgetEntryView : View {
    var entry: CreateScorecardWidgetProvider.Entry

    var body: some View {
        let paletteEntity = entry.palette ?? paletteEntityList.first!
        let theme = PaletteColor(paletteEntity.detailPalette)
        let label = (entry.layout == nil ? "Any Layout" : entry.layout!.name)
        
        WidgetContainer(label: label, palette: PaletteColor(paletteEntity.containerPalette), titlePosition: entry.titlePosition) {
            VStack(spacing: 0) {
                Image(systemName: "plus").font(bigFont).bold()
            }
            .foregroundColor(theme.text)
            .containerBackground(theme.background, for: .widget)
            .minimumScaleFactor(0.75)
        }
    }
}
