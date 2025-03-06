//
//  Scorecard Entities.swift
//  BridgeScore
//
//  Created by Marc Shearer on 02/02/2025.
//

import AppIntents

struct CreateScorecardAppIntent: AppIntent, OpenIntent {
    
    static let title: LocalizedStringResource = "Create Scorecard"
    
    @Parameter(title: "Template", description: "The template to use for the Scorecard") var target: LayoutEntity
    @Parameter(title: "Templates", description: "Templates to choose from") var layouts: [LayoutEntity]
    @Parameter(title: "Force Details", description: "Force display of detail") var forceDisplayDetail: Bool
    
    init() {
        self.init(layouts: [], forceDisplayDetail: false)
    }

    init(allLayouts: Bool = true, layouts: [LayoutEntity] = [], forceDisplayDetail: Bool = false) {
        self.target = layouts.first ?? LayoutEntity()
        if allLayouts {
            self.layouts = []
        } else {
            self.layouts = layouts
        }
        self.forceDisplayDetail = forceDisplayDetail
    }
    
    // Note perform is in extension not visible to widget
    
    static var parameterSummary: some ParameterSummary {
        Summary("Create scorecard for \(\.$target)")
    }
}

struct LastScorecardAppIntent : AppIntent, OpenIntent {
    
    static let title: LocalizedStringResource = "Open Scorecard"
    
    @Parameter(title: "Scorecard", description: "Scorecard to Open") var target: ScorecardEntity

    init() {
        
    }
    
    init(id: UUID? = nil) {
        if let id = id {
            self.target = ScorecardEntity(id: id)
        }
    }
    
    // Note perform is in extension not visible to widget
    
    static let openAppWhenRun: Bool = true
    
}

struct StatsAppIntent: AppIntent, OpenIntent {
    
    static let title: LocalizedStringResource = "Statistics"
    
    @Parameter(title: "Location", description: "The main location to use for the Stats") var target: LocationEntity
    @Parameter(title: "Locations", description: "Locations to include in Stats") var locations: [LocationEntity]
    @Parameter(title: "Players", description: "Players to in include in Stats") var players: [PlayerEntity]
    @Parameter(title: "Event types", description: "Event types to include in Stats") var eventTypes: [WidgetEventType]
    @Parameter(title: "Date range", description: "Date range for Stats") var dateRange: WidgetDateRange
        
    init() {
        self.init(locations: [], players: [], eventTypes: [], dateRange: .all)
    }

    init(locations: [LocationEntity] = [], players: [PlayerEntity], eventTypes: [WidgetEventType], dateRange: WidgetDateRange) {
        target = locations.first ?? LocationEntity()
        self.locations = locations
        self.players = players
        self.eventTypes = eventTypes
        self.dateRange = dateRange
    }
    
    // Note perform is in extension not visible to widget
    
    static var parameterSummary: some ParameterSummary {
        Summary("Create scorecard for \(\.$locations) \(\.$players) \(\.$eventTypes) \(\.$dateRange)")
    }
}

struct LayoutEntity : AppEntity {
    public var id: UUID
    
    public init(id: UUID? = nil) {
        self.id = id ?? nullUUID
        if let layout = LayoutEntity.layouts(id: id).first {
            name = layout.desc
        } else {
            name = "Choose each time"
        }
    }
    
    static var defaultQuery = LayoutEntityQuery()
    
    @Property(title: "Template name") var name: String
    
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Template"
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    static func layouts(id layoutId: UUID? = nil) -> [LayoutMO] {
        var filter: NSPredicate?
        if let layoutId = layoutId {
            filter = NSPredicate(format: "%K = %@", #keyPath(LayoutMO.layoutId), layoutId as CVarArg)
        }
        return (CoreData.fetch(from: LayoutMO.tableName, filter: filter, sort: [("sequence16", .ascending)]) as! [LayoutMO])
    }
}


struct LayoutEntityQuery : EntityQuery {
    @IntentParameterDependency<CreateScorecardWidgetConfiguration>(
            \.$allLayouts
        )
    var createScorecard
    
    public func entities(for identifiers: [UUID]) async throws -> [LayoutEntity] {
        identifiers.map{LayoutEntity(id: $0)}
    }
}

extension LayoutEntityQuery: EnumerableEntityQuery {
    
    public func allEntities() async throws -> [LayoutEntity] {
        if let createScorecard = createScorecard, createScorecard.allLayouts {
            return []
        } else {
            return LayoutEntity.layouts().map{LayoutEntity(id: $0.layoutId)}
        }
    }
}

struct LocationEntity : AppEntity {
    public var id: UUID
    
    public init(id: UUID? = nil) {
        self.id = id ?? nullUUID
        if let location = LocationEntity.locations(id: id).first {
            name = location.name
        } else {
            name = "All locations"
        }
    }
    
    static var defaultQuery = LocationEntityQuery()
    
    @Property(title: "Location name") var name: String
    
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Location"
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    static func locations(id locationId: UUID? = nil) -> [LocationMO] {
        var filter: NSPredicate?
        if let locationId = locationId {
            filter = NSPredicate(format: "%K = %@", #keyPath(LocationMO.locationId), locationId as CVarArg)
        } else {
            filter = NSPredicate(format: "retired = false" )
        }
        return (CoreData.fetch(from: LocationMO.tableName, filter: filter, sort: [("sequence16", .ascending)]) as! [LocationMO])
    }
}


struct LocationEntityQuery : EntityQuery {
    public func entities(for identifiers: [UUID]) async throws -> [LocationEntity] {
        identifiers.map({LocationEntity(id: $0)})
    }
    
    public func suggestedEntities() async throws -> [LocationEntity] {
        return LocationEntity.locations().map{LocationEntity(id: $0.locationId)}
    }
}

extension LocationEntityQuery: EnumerableEntityQuery {
    
    public func allEntities() async throws -> [LocationEntity] {
        return LocationEntity.locations().map{LocationEntity(id: $0.locationId)}
    }
}

struct PlayerEntity : AppEntity {
    public var id: UUID
    
    public init(id: UUID? = nil) {
        self.id = id ?? nullUUID
        if let player = PlayerEntity.players(id: id).first {
            name = player.name
        } else {
            name = "All players"
        }
    }
    
    static var defaultQuery = PlayerEntityQuery()
    
    @Property(title: "Player name") var name: String
    
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Player"
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    static func players(id playerId: UUID? = nil) -> [PlayerMO] {
        var filter: NSPredicate?
        if let playerId = playerId {
            filter = NSPredicate(format: "%K = %@", #keyPath(PlayerMO.playerId), playerId as CVarArg)
        } else {
            filter = NSPredicate(format: "retired = false" )
        }
        return (CoreData.fetch(from: PlayerMO.tableName, filter: filter, sort: [("sequence16", .ascending)]) as! [PlayerMO])
    }
}


struct PlayerEntityQuery : EntityQuery {
    public func entities(for identifiers: [UUID]) async throws -> [PlayerEntity] {
        identifiers.map({PlayerEntity(id: $0)})
    }
    
    public func suggestedEntities() async throws -> [PlayerEntity] {
        return PlayerEntity.players().map{PlayerEntity(id: $0.playerId)}
    }
}

extension PlayerEntityQuery: EnumerableEntityQuery {
    
    public func allEntities() async throws -> [PlayerEntity] {
        return PlayerEntity.players().map{PlayerEntity(id: $0.playerId)}
    }
}

struct ScorecardEntityDetails {
    var date: Date? = nil
    var location: LocationEntity? = nil
    var score: String? = nil
    var position: String? = nil
    var scorecardId: UUID? = nil
    var notFound: Bool = true
}

struct ScorecardEntity : AppEntity {
    public var id: UUID
    
    public init(id: UUID) {
        self.id = id
        if let scorecard = ScorecardEntity.scorecard(id: id) {
            desc = scorecard.desc
        } else {
            desc = "Invalid Scorecard"
        }
    }
    
    static var defaultQuery = ScorecardEntityQuery()
    
    @Property(title: "Scorecard desc")
    var desc: String
    
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Scorecard"
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(desc)")
    }
    
    public static func scorecard(id scorecardId: UUID) -> ScorecardMO? {
        let filter = NSPredicate(format: "%K = %@", #keyPath(ScorecardMO.scorecardId), scorecardId as CVarArg)
        return (CoreData.fetch(from: ScorecardMO.tableName, filter: filter, limit: 1) as! [ScorecardMO]).first
    }
    
    public static func scorecards(locationIds: [UUID]? = [], playerIds: [UUID]? = [], eventTypes: [WidgetEventType]? = nil, dateRange: WidgetDateRange = .all, maxScoreEntered: Bool = false, limit: Int = 0, preData: Int? = nil) -> [ScorecardMO] {
        var filter: [NSPredicate] = []
        var limit = limit
        
        if dateRange == .all && preData != nil {
            return []
        } else {
            if let locationIds = locationIds, !locationIds.isEmpty {
                let locationIds = locationIds.map{$0 as CVarArg}
                filter.append(NSPredicate(format: "%K IN %@", #keyPath(ScorecardMO.locationId), locationIds))
            }
            if let playerIds = playerIds, !playerIds.isEmpty {
                let playerIds = playerIds.map{$0 as CVarArg}
                filter.append(NSPredicate(format: "%K IN %@", #keyPath(ScorecardMO.partnerId), playerIds))
            }
            if let eventTypes = eventTypes, !eventTypes.isEmpty {
                filter.append(NSPredicate(format: "eventType16 IN %@", eventTypes.map{$0.eventType.rawValue}))
                
            }
            if dateRange != .all {
                if let preData = preData {
                    filter.append(NSPredicate(format: "date < %@", dateRange.startDate as CVarArg))
                    limit = preData
                } else {
                    filter.append(NSPredicate(format: "date >= %@", dateRange.startDate as CVarArg))
                }
            }
            if maxScoreEntered {
                filter.append(NSPredicate(format: "scoreEntered = true and maxScoreEntered = true"))
            }
            
            return (CoreData.fetch(from: ScorecardMO.tableName, filter: filter, limit: limit, sort: [("date", .descending), ("sequence16", .descending)]) as! [ScorecardMO])
        }
    }
    
    public static func getLastScorecards(for locations: [LocationEntity]?, eventTypes: [WidgetEventType]? = nil, limit: Int = 1) -> [ScorecardMO] {
        return ScorecardEntity.scorecards(locationIds: locations?.map({$0.id}), eventTypes: eventTypes, limit: limit)
    }
}

struct ScorecardEntityQuery : EntityQuery {
    public func entities(for identifiers: [UUID]) async throws -> [ScorecardEntity] {
        identifiers.map({ScorecardEntity(id: $0)})
    }
    
    public func suggestedEntities() async throws -> [ScorecardEntity] {
        return ScorecardEntity.scorecards(limit: 10).map{ScorecardEntity(id: $0.scorecardId)}
    }
}

extension ScorecardEntityQuery: EnumerableEntityQuery {
    
    public func allEntities() async throws -> [ScorecardEntity] {
        return ScorecardEntity.scorecards().map{ScorecardEntity(id: $0.scorecardId)}
    }
}

let paletteEntityList: [PaletteEntity] = [
    PaletteEntity(name: "Default", barPalette: .widgetBar, detailPalette: .widgetDetail),
    PaletteEntity(name: "Inverse", barPalette: .widgetDetail, detailPalette: .widgetBar),
    PaletteEntity(name: "Standout", barPalette: .highlightTile, detailPalette: .widgetBar),
    PaletteEntity(name: "Full Default", barPalette: .widgetDetail, detailPalette: .widgetDetail),
    PaletteEntity(name: "Full Inverse", barPalette: .widgetBar, detailPalette: .widgetBar)
]

struct PaletteEntity : AppEntity {
    public var id: String
    var containerPalette: ThemeBackgroundColorName
    var detailPalette: ThemeBackgroundColorName
    
    public init(name: String, barPalette: ThemeBackgroundColorName, detailPalette: ThemeBackgroundColorName) {
        self.id = name
        self.containerPalette = barPalette
        self.detailPalette = detailPalette
    }
    
    public init?(id: String) {
        if let entity = PaletteEntity.color(id: id) {
            self.id = entity.id
            self.containerPalette = entity.containerPalette
            self.detailPalette = entity.detailPalette
        } else {
            return nil
        }
    }
    
    static var defaultQuery = PaletteEntityQuery()
        
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Color"
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(id)")
    }
    
    static func color(id: String) -> PaletteEntity? {
        return paletteEntityList.first(where: {$0.id == id})
    }
}


struct PaletteEntityQuery : EntityQuery {
    public func entities(for identifiers: [String]) async throws -> [PaletteEntity] {
        identifiers.map({PaletteEntity(id: $0)!})
    }
    
    public func suggestedEntities() async throws -> [PaletteEntity] {
        return paletteEntityList
    }
}

extension PaletteEntityQuery: EnumerableEntityQuery {
    
    public func allEntities() async throws -> [PaletteEntity] {
        return paletteEntityList
    }
}
