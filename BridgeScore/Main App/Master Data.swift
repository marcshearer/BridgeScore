//
//  Master Data.swift
//  BridgeScore
//
//  Created by Marc Shearer on 23/01/2022
//

import Foundation
import CoreData

class MasterData: ObservableObject {
    
    public static let shared = MasterData()
    
    @Published private(set) var layouts: [LayoutViewModel] = []                  // Layout Id
    @Published private(set) var players: [PlayerViewModel] = []                  // Player Id
    @Published private(set) var locations: [LocationViewModel] = []              // Location Id
    @Published private(set) var scorecards: [ScorecardViewModel] = []            // Scorecard Id
   
    public func load() {
        
        /// **Builds in-memory mirror of layouts, scorecards, players and locations with pointers to managed objects**
        /// Note that this infers that there will only ever be 1 instance of the app accessing the database
    
        // Read current data
        let layoutMOs = CoreData.fetch(from: LayoutMO.tableName, sort: (key: #keyPath(LayoutMO.sequence16), direction: .ascending)) as! [LayoutMO]
        let playerMOs = CoreData.fetch(from: PlayerMO.tableName, sort: (key: #keyPath(PlayerMO.sequence16), direction: .ascending)) as! [PlayerMO]
        let locationMOs = CoreData.fetch(from: LocationMO.tableName, sort: (key: #keyPath(LocationMO.sequence16), direction: .ascending)) as! [LocationMO]
        let scorecardMOs = CoreData.fetch(from: ScorecardMO.tableName, sort: (key: #keyPath(ScorecardMO.date), direction: .descending)) as! [ScorecardMO]
        
        // Setup players
        self.players = []
        for playerMO in playerMOs {
            players.append(PlayerViewModel(playerMO: playerMO))
        }
        if players.count == 0 {
            // No players - create defaults
            for player in DefaultData.players {
                self.insert(player: player)
            }
        }
        
        // Setup locations
        self.locations = []
        for locationMO in locationMOs {
            locations.append(LocationViewModel(locationMO: locationMO))
        }
        if locations.count == 0 {
            // No locations - create defaults
            for location in DefaultData.locations {
                self.insert(location: location)
            }
        }
        
        // Setup layouts
        self.layouts = []
        for layoutMO in layoutMOs {
            self.layouts.append(LayoutViewModel(layoutMO: layoutMO))
        }
        if layouts.count == 0 {
            // No layouts - create defaults
            let layouts = DefaultData.layouts(players: players, locations: locations)
            for layout in layouts {
                self.insert(layout: layout)
            }
        }
  
        // Setup scorecards
        self.scorecards = []
        for scorecardMO in scorecardMOs {
            scorecards.append(ScorecardViewModel(scorecardMO: scorecardMO))
        }
    }
}

extension MasterData {
    
    /// Methods for layouts
    
    public func insert(layout: LayoutViewModel) {
        assert(layout.layoutMO == nil, "Cannot insert a layout which already has a managed object")
        assert(self.layout(id: layout.layoutId) == nil, "Layout already exists and cannot be created")
        assert(self.layout(id: layout.layoutId)?.desc == nil, "Layout must have a non-blank description")
        CoreData.update {
            layout.layoutMO = LayoutMO()
            layout.updateMO()
            let index = self.layouts.firstIndex(where: {$0.sequence > layout.sequence}) ?? layouts.endIndex
            self.layouts.insert(layout, at: index)
        }
    }
    
    public func remove(layout: LayoutViewModel) {
        assert(layout.layoutMO != nil, "Cannot remove a layout which doesn't already have a managed object")
        assert(self.layout(id: layout.layoutId) != nil, "Layout does not exist and cannot be deleted")
        CoreData.update {
            CoreData.context.delete(layout.layoutMO!)
            if let index = self.layouts.firstIndex(where: {$0 == layout}) {
                self.layouts.remove(at: index)
            }
        }
    }
    
    public func save(layout: LayoutViewModel) {
        assert(layout.layoutMO != nil, "Cannot save a layout which doesn't already have managed objects")
        assert(self.layout(id: layout.layoutId) != nil, "Layout does not exist and cannot be updated")
        if layout.changed {
            CoreData.update {
                layout.updateMO()
            }
            if let index = self.layouts.firstIndex(where: {$0 == layout}) {
                self.layouts[index] = layout
            }
        }
    }
    
    public func move(layouts indexSet: IndexSet, to index: Int) {
        self.layouts.move(fromOffsets: indexSet, toOffset: index)
        self.updateLayoutSequence()
    }
    
    public func updateLayoutSequence() {
        var last = 0
        for layout in self.layouts {
            if layout.sequence != last + 1 {
                layout.sequence = last + 1
                layout.save()
            }
            last = layout.sequence
        }
    }
    
    public func layout(id layoutId: UUID?) -> LayoutViewModel? {
        return (layoutId == nil ? nil : self.layouts.first(where: {$0.layoutId == layoutId}))
    }
}

extension MasterData {
    
    /// Methods for scorecards
    
    public func insert(scorecard: ScorecardViewModel) {
        assert(scorecard.scorecardMO == nil, "Cannot insert a scorecard which already has a managed object")
        assert(self.scorecard(id: scorecard.scorecardId) == nil, "Scorecard already exists and cannot be created")
        assert(self.scorecard(id: scorecard.scorecardId)?.desc == nil, "Scorecard must have a non-blank description")
        CoreData.update {
            scorecard.scorecardMO = ScorecardMO()
            scorecard.updateMO()
            let index = self.scorecards.firstIndex(where: {$0.date < scorecard.date}) ?? scorecards.endIndex
            self.scorecards.insert(scorecard, at: index)
        }
    }
    
    public func remove(scorecard: ScorecardViewModel) {
        assert(scorecard.scorecardMO != nil, "Cannot remove a scorecard which doesn't already have a managed object")
        assert(self.scorecard(id: scorecard.scorecardId) != nil, "Scorecard does not exist and cannot be deleted")
        CoreData.update {
            CoreData.context.delete(scorecard.scorecardMO!)
            if let index = self.scorecards.firstIndex(where: {$0 == scorecard}) {
                self.scorecards.remove(at: index)
            }
        }
    }
    
    public func save(scorecard: ScorecardViewModel) {
        assert(scorecard.scorecardMO != nil, "Cannot save a scorecard which doesn't already have managed objects")
        assert(self.scorecard(id: scorecard.scorecardId) != nil, "Scorecard does not exist and cannot be updated")
        if scorecard.changed {
            CoreData.update {
                scorecard.updateMO()
            }
            if let index = self.scorecards.firstIndex(where: {$0 == scorecard}) {
                self.scorecards[index] = scorecard
            }
        }
    }
       
    public func scorecard(id scorecardId: UUID?) -> ScorecardViewModel? {
        return (scorecardId == nil ? nil : self.scorecards.first(where: {$0.scorecardId == scorecardId}))
    }
}

extension MasterData {
    
    /// Methods for players
    
    public func insert(player: PlayerViewModel) {
        assert(player.playerMO == nil, "Cannot insert a player which already has a managed object")
        assert(self.player(id: player.playerId) == nil, "Player already exists and cannot be created")
        assert(self.player(id: player.playerId)?.name == nil, "Player must have a non-blank name")
        CoreData.update {
            player.playerMO = PlayerMO()
            player.updateMO()
            let index = self.players.firstIndex(where: {$0.sequence > player.sequence}) ?? players.endIndex
            self.players.insert(player, at: index)
        }
    }
    
    public func remove(player: PlayerViewModel) {
        assert(player.playerMO != nil, "Cannot remove a player which doesn't already have a managed object")
        assert(self.player(id: player.playerId) != nil, "Player does not exist and cannot be deleted")
        CoreData.update {
            CoreData.context.delete(player.playerMO!)
            if let index = self.players.firstIndex(where: {$0 == player}) {
                self.players.remove(at: index)
            }
        }
    }
    
    public func save(player: PlayerViewModel) {
        assert(player.playerMO != nil, "Cannot save a player which doesn't already have managed objects")
        assert(self.player(id: player.playerId) != nil, "Player does not exist and cannot be updated")
        if player.changed {
            CoreData.update {
                player.updateMO()
            }
            if let index = self.players.firstIndex(where: {$0 == player}) {
                self.players[index] = player
            }
        }
    }
    
    public func move(players indexSet: IndexSet, to index: Int) {
        self.players.move(fromOffsets: indexSet, toOffset: index)
        self.updatePlayerSequence()
    }
    
    public func updatePlayerSequence() {
        var last = 0
        for player in self.players {
            if player.sequence != last + 1 {
                player.sequence = last + 1
                player.save()
            }
            last = player.sequence
        }
    }
    
    public func player(id playerId: UUID?) -> PlayerViewModel? {
        return (playerId == nil ? nil : self.players.first(where: {$0.playerId == playerId}))
    }
}

extension MasterData {
    
    /// Methods for locations
    
    public func insert(location: LocationViewModel) {
        assert(location.locationMO == nil, "Cannot insert a location which already has a managed object")
        assert(self.location(id: location.locationId) == nil, "Location already exists and cannot be created")
        assert(self.location(id: location.locationId)?.name == nil, "Location must have a non-blank name")
        CoreData.update {
            location.locationMO = LocationMO()
            location.updateMO()
            let index = self.locations.firstIndex(where: {$0.sequence > location.sequence}) ?? locations.endIndex
            self.locations.insert(location, at: index)
        }
    }
    
    public func remove(location: LocationViewModel) {
        assert(location.locationMO != nil, "Cannot remove a location which doesn't already have a managed object")
        assert(self.location(id: location.locationId) != nil, "Location does not exist and cannot be deleted")
        CoreData.update {
            CoreData.context.delete(location.locationMO!)
            if let index = self.locations.firstIndex(where: {$0 == location}) {
                self.locations.remove(at: index)
            }
        }
    }
    
    public func save(location: LocationViewModel) {
        assert(location.locationMO != nil, "Cannot save a location which doesn't already have managed objects")
        assert(self.location(id: location.locationId) != nil, "Location does not exist and cannot be updated")
        if location.changed {
            CoreData.update {
                location.updateMO()
            }
            if let index = self.locations.firstIndex(where: {$0 == location}) {
                self.locations[index] = location
            }
        }
    }
    
    public func move(locations indexSet: IndexSet, to index: Int) {
        self.locations.move(fromOffsets: indexSet, toOffset: index)
        self.updateLocationSequence()
    }
    
    public func updateLocationSequence() {
        var last = 0
        for location in self.locations {
            if location.sequence != last + 1 {
                location.sequence = last + 1
                location.save()
            }
            last = location.sequence
        }
    }
    
    public func location(id locationId: UUID?) -> LocationViewModel? {
        return (locationId == nil ? nil : self.locations.first(where: {$0.locationId == locationId}))
    }
}
