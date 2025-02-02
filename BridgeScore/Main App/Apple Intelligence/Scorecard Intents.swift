//
//  Scorecard Intents.swift
//  BridgeScore
//
//  Created by Marc Shearer on 24/01/2025.
//

import AppIntents

enum ScorecardDetailsAction {
    case openScorecard
    case createScorecard
}

struct ScorecardDetails {
    var action: ScorecardDetailsAction
    var layout: LayoutMO?
    var scorecard: ScorecardMO?
    var forceDisplayDetail: Bool
    
    init(action: ScorecardDetailsAction, scorecard: ScorecardMO? = nil, layout: LayoutMO? = nil, forceDisplayDetail: Bool = false) {
        self.action = action
        self.layout = layout
        self.scorecard = scorecard
        self.forceDisplayDetail = forceDisplayDetail
    }
}

struct LayoutEntity : AppEntity {
    public var id: UUID
    
    public init(id: UUID) {
        self.id = id
        if let layout = LayoutEntity.layouts(id: id).first {
            name = layout.desc
        } else {
            name = "Choose template"
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
    public func entities(for identifiers: [UUID]) async throws -> [LayoutEntity] {
        identifiers.map{LayoutEntity(id: $0)}
    }
}

extension LayoutEntityQuery: EnumerableEntityQuery {
    
    public func allEntities() async throws -> [LayoutEntity] {
        return LayoutEntity.layouts().map{LayoutEntity(id: $0.layoutId)}
    }
}

struct OpenScorecard : AppIntent, OpenIntent {
    
    static let title: LocalizedStringResource = "Open Scorecard"
    
    @Parameter(title: "Scorecard", description: "Scorecard to Open") var target: ScorecardEntity

    init() {
        
    }
    
    init(id: UUID? = nil) {
        if let id = id {
            self.target = ScorecardEntity(id: id)
        }
    }
    
    func perform() async throws -> some IntentResult {
        let scorecardId = target.id
        if let scorecardMO = ScorecardEntity.scorecards(id: scorecardId).first {
            let details = ScorecardDetails(action: .openScorecard, scorecard: scorecardMO)
            Utility.mainThread {
                ScorecardListViewChange.send(details)
            }
        }
        return .result()
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Create scorecard for \(\.$target)")
    }
    
    static let openAppWhenRun: Bool = true
    
}

struct LocationEntity : AppEntity {
    public var id: UUID
    
    public init(id: UUID) {
        self.id = id
        if let location = LocationEntity.locations(id: id).first {
            name = location.name
        } else {
            name = "Any location"
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
        return [LocationEntity(id: nullUUID)] + LocationEntity.locations().map{LocationEntity(id: $0.locationId)}
    }
}

extension LocationEntityQuery: EnumerableEntityQuery {
    
    public func allEntities() async throws -> [LocationEntity] {
        return [LocationEntity(id: nullUUID)] + LocationEntity.locations().map{LocationEntity(id: $0.locationId)}
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
        if let scorecard = ScorecardEntity.scorecards(id: id).first {
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
    
    public static func scorecards(id scorecardId: UUID? = nil, locationId: UUID? = nil, limit: Int = 0) -> [ScorecardMO] {
        var filter: NSPredicate?
        if let scorecardId = scorecardId {
            filter = NSPredicate(format: "%K = %@", #keyPath(ScorecardMO.scorecardId), scorecardId as CVarArg)
        } else if let locationId = locationId {
            filter = NSPredicate(format: "%K = %@", #keyPath(ScorecardMO.locationId), locationId as CVarArg)
        }
        return (CoreData.fetch(from: ScorecardMO.tableName, filter: filter, limit: limit, sort: [("date", .descending)]) as! [ScorecardMO])
    }
    
    public static func getLastScorecard(for location: LocationEntity?) -> ScorecardMO? {
        // Find location
        var locationId: UUID?
        if let location = location, let locationMO = LocationEntity.locations(id: location.id).first {
            locationId = locationMO.locationId
        }
        return ScorecardEntity.scorecards(locationId: locationId, limit: 1).first
    }

}

struct ScorecardEntityQuery : EntityQuery {
    public func entities(for identifiers: [UUID]) async throws -> [ScorecardEntity] {
        identifiers.map({ScorecardEntity(id: $0)})
    }
    
    public func suggestedEntities() async throws -> [ScorecardEntity] {
        return [ScorecardEntity(id: nullUUID)] + ScorecardEntity.scorecards().map{ScorecardEntity(id: $0.scorecardId)}
    }
}

extension ScorecardEntityQuery: EnumerableEntityQuery {
    
    public func allEntities() async throws -> [ScorecardEntity] {
        return [ScorecardEntity(id: nullUUID)] + ScorecardEntity.scorecards().map{ScorecardEntity(id: $0.scorecardId)}
    }
}

let paletteEntityList: [PaletteEntity] = [
    PaletteEntity(name: "Default", barPalette: .bannerButton, detailPalette: .filterUsed),
    PaletteEntity(name: "Inverse", barPalette: .filterUsed, detailPalette: .bannerButton),
    PaletteEntity(name: "Standout", barPalette: .highlightTile, detailPalette: .bannerButton),
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
