//
//  Scorecard Intents.swift
//  BridgeScore
//
//  Created by Marc Shearer on 24/01/2025.
//

import AppIntents

struct CreateScorecard : AppIntent, OpenIntent {

    static let title: LocalizedStringResource = "Create Scorecard"
    
    @Parameter(title: "Template", description: "The template to use for the Scorecard") var target: LayoutEntity
    
    func perform() async throws -> some IntentResult {
        let layoutId = target.id
        if let layout = MasterData.shared.layouts.first(where: {$0.layoutId == layoutId}) {
            let details = ScorecardDetails(layout: layout, newScorecard: true)
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

struct LayoutEntity : AppEntity {
    public var id: UUID
    
    public init(id: UUID) {
        self.id = id
        if let layout = MasterData.shared.layouts.first(where : {$0.layoutId == id}) {
            name = layout.desc
        } else {
            name = "Unknown"
        }
    }
    
    static var defaultQuery = LayoutEntityQuery()
    
    @Property(title: "Template name") var name: String
    
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Template"
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}


struct LayoutEntityQuery : EntityQuery {
    public func entities(for identifiers: [UUID]) async throws -> [LayoutEntity] {
        identifiers.map{LayoutEntity(id: $0)}
    }
}

extension LayoutEntityQuery: EnumerableEntityQuery {
    
    public func allEntities() async throws -> [LayoutEntity] {
        return MasterData.shared.layouts.map{LayoutEntity(id: $0.layoutId)}
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
        if let scorecard = MasterData.shared.scorecards.first(where: {$0.scorecardId == scorecardId}) {
            let details = ScorecardDetails(scorecard: scorecard)
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
        if let location = MasterData.shared.locations.first(where : {$0.locationId == id}) {
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
}


struct LocationEntityQuery : EntityQuery {
    public func entities(for identifiers: [UUID]) async throws -> [LocationEntity] {
        identifiers.map({LocationEntity(id: $0)})
    }
    
    public func suggestedEntities() async throws -> [LocationEntity] {
        return [LocationEntity(id: nullUUID)] + MasterData.shared.locations.map{LocationEntity(id: $0.locationId)}
    }
}

extension LocationEntityQuery: EnumerableEntityQuery {
    
    public func allEntities() async throws -> [LocationEntity] {
        return [LocationEntity(id: nullUUID)] + MasterData.shared.locations.map{LocationEntity(id: $0.locationId)}
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
        if let scorecard = MasterData.shared.scorecards.first(where : {$0.scorecardId == id}) {
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
    
    public static func getLastScorecard(for location: LocationEntity?) -> ScorecardMO? {
        // Find location
        var scorecardFilter: NSPredicate?
        if let location = location, let locationMO = CoreData.fetch(from: LocationMO.tableName, filter: NSPredicate(format: "name = %@", location.name)).first as? LocationMO {
            scorecardFilter = NSPredicate(format: "%K = %@", #keyPath(ScorecardMO.locationId), locationMO.locationId as CVarArg)
        }
        return (CoreData.fetch(from: ScorecardMO.tableName, filter: scorecardFilter, limit: 1, sort: [("date", .descending)]) as? [ScorecardMO])?.first
    }

}


struct ScorecardEntityQuery : EntityQuery {
    public func entities(for identifiers: [UUID]) async throws -> [ScorecardEntity] {
        identifiers.map({ScorecardEntity(id: $0)})
    }
    
    public func suggestedEntities() async throws -> [ScorecardEntity] {
        return [ScorecardEntity(id: nullUUID)] + MasterData.shared.scorecards.map{ScorecardEntity(id: $0.scorecardId)}
    }
}

extension ScorecardEntityQuery: EnumerableEntityQuery {
    
    public func allEntities() async throws -> [ScorecardEntity] {
        return [ScorecardEntity(id: nullUUID)] + MasterData.shared.scorecards.map{ScorecardEntity(id: $0.scorecardId)}
    }
}

public struct BridgeScoreConfiguration: WidgetConfigurationIntent {
    
    public static var title: LocalizedStringResource = "Scorecard Details"
    
    public init() {
        
    }
    
    @Parameter(title: "Location: ") var filter: LocationEntity?
}
