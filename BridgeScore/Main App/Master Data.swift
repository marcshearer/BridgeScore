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
    
    @Published private(set) var layouts: [UUID:LayoutViewModel] = [:]                  // Layout Id
    @Published private(set) var players: [UUID:PlayerViewModel] = [:]                  // Player Id
    @Published private(set) var locations: [UUID:LocationViewModel] = [:]              // Location Id
    @Published private(set) var scorecards: [UUID:ScorecardViewModel] = [:]            // Scorecard Id
   
    public func load() {
        
        /// **Builds in-memory mirror of layouts, scorecards, players and locations with pointers to managed objects**
        /// Note that this infers that there will only ever be 1 instance of the app accessing the database
    
        // Read current data
        let layoutMOs = CoreData.fetch(from: LayoutMO.tableName, sort: (key: #keyPath(LayoutMO.sequence16), direction: .ascending)) as! [LayoutMO]
        let playerMOs = CoreData.fetch(from: PlayerMO.tableName, sort: (key: #keyPath(PlayerMO.sequence16), direction: .ascending)) as! [PlayerMO]
        let locationMOs = CoreData.fetch(from: LocationMO.tableName, sort: (key: #keyPath(LocationMO.sequence16), direction: .ascending)) as! [LocationMO]
        let scorecardMOs = CoreData.fetch(from: ScorecardMO.tableName, sort: (key: #keyPath(ScorecardMO.date), direction: .descending)) as! [ScorecardMO]
        
        // Setup layouts
        self.layouts = [:]
        for layoutMO in layoutMOs {
            self.layouts[layoutMO.layoutId] = LayoutViewModel(layoutMO: layoutMO)
        }
        if layouts.count == 0 {
            // No layouts - create defaults
            for layout in DefaultData.layouts {
                self.insert(layout: layout)
            }
        }
        
        // Setup players
        self.players = [:]
        for playerMO in playerMOs {
            players[playerMO.playerId] = PlayerViewModel(playerMO: playerMO)
        }
        if players.count == 0 {
            // No players - create defaults
            for player in DefaultData.players {
                self.insert(player: player)
            }
        }
        
        // Setup locations
        self.locations = [:]
        for locationMO in locationMOs {
            locations[locationMO.locationId] = LocationViewModel(locationMO: locationMO)
        }
        if locations.count == 0 {
            // No locations - create defaults
            for location in DefaultData.locations {
                self.insert(location: location)
            }
        }
  
        // Setup scorecards
        self.scorecards = [:]
        for scorecardMO in scorecardMOs {
            scorecards[scorecardMO.scorecardId] = ScorecardViewModel(scorecardMO: scorecardMO)
        }
    }
}

extension MasterData {
    
    /// Methods for layouts
    
    public func insert(layout: LayoutViewModel) {
        assert(layout.layoutMO == nil, "Cannot insert a layout which already has a managed object")
        assert(self.layouts[layout.layoutId] == nil, "Layout already exists and cannot be created")
        assert(self.layouts[layout.layoutId]?.desc == nil, "Layout must have a non-blank description")
        CoreData.update(updateLogic: {
            layout.layoutMO = LayoutMO()
            self.updateMO(layout: layout)
            self.layouts[layout.layoutId] = layout
        })
    }
    
    public func remove(layout: LayoutViewModel) {
        assert(layout.layoutMO != nil, "Cannot remove a layout which doesn't already have a managed object")
        assert(self.layouts[layout.layoutId] != nil, "Layout does not exist and cannot be deleted")
        CoreData.update(updateLogic: {
            CoreData.context.delete(layout.layoutMO!)
            self.layouts[layout.layoutId] = nil
        })
    }
    
    public func save(layout: LayoutViewModel) {
        assert(layout.layoutMO != nil, "Cannot save a layout which doesn't already have managed objects")
        assert(self.layouts[layout.layoutId] != nil, "Layout does not exist and cannot be updated")
        if layout.changed {
            CoreData.update(updateLogic: {
                self.updateMO(layout: layout)
            })
            self.layouts[layout.layoutId] = layout
        }
    }
    
    public func layout(id layoutId: UUID?) -> LayoutViewModel? {
        return (layoutId == nil ? nil : self.layouts[layoutId!])
    }
    
    private func updateMO(layout: LayoutViewModel) {
        layout.layoutMO!.layoutId = layout.layoutId
        layout.layoutMO!.sequence = layout.sequence
        layout.layoutMO!.desc = layout.desc
        layout.layoutMO!.boards = layout.boards
        layout.layoutMO!.boardsTable = layout.boardsTable
        layout.layoutMO!.type = layout.type
        layout.layoutMO!.tableTotal = layout.tableTotal
    }
}

extension MasterData {
    
    /// Methods for scorecards
    
    public func insert(scorecard: ScorecardViewModel) {
        assert(scorecard.scorecardMO == nil, "Cannot insert a scorecard which already has a managed object")
        assert(self.scorecards[scorecard.scorecardId] == nil, "Scorecard already exists and cannot be created")
        assert(self.scorecards[scorecard.scorecardId]?.desc == nil, "Scorecard must have a non-blank description")
        CoreData.update(updateLogic: {
            scorecard.scorecardMO = ScorecardMO()
            self.updateMO(scorecard: scorecard)
            self.scorecards[scorecard.scorecardId] = scorecard
            print("Insert \(scorecard.scorecardId.uuidString)")
        })
    }
    
    public func remove(scorecard: ScorecardViewModel) {
        assert(scorecard.scorecardMO != nil, "Cannot remove a scorecard which doesn't already have a managed object")
        assert(self.scorecards[scorecard.scorecardId] != nil, "Scorecard does not exist and cannot be deleted")
        CoreData.update(updateLogic: {
            CoreData.context.delete(scorecard.scorecardMO!)
            self.scorecards[scorecard.scorecardId] = nil
        })
    }
    
    public func save(scorecard: ScorecardViewModel) {
        assert(scorecard.scorecardMO != nil, "Cannot save a scorecard which doesn't already have managed objects")
        assert(self.scorecards[scorecard.scorecardId] != nil, "Scorecard does not exist and cannot be updated")
        if scorecard.changed {
            CoreData.update(updateLogic: {
                self.updateMO(scorecard: scorecard)
            })
            self.scorecards[scorecard.scorecardId] = scorecard
        }
    }
    
    public func scorecard(id scorecardId: UUID?) -> ScorecardViewModel? {
        return (scorecardId == nil ? nil : self.scorecards[scorecardId!])
    }
    
    private func updateMO(scorecard: ScorecardViewModel) {
        scorecard.scorecardMO!.scorecardId = scorecard.scorecardId
        scorecard.scorecardMO!.date = scorecard.date
        scorecard.scorecardMO!.locationId = scorecard.location?.locationId
        scorecard.scorecardMO!.desc = scorecard.desc
        scorecard.scorecardMO!.comment = scorecard.comment
        scorecard.scorecardMO!.partnerId = scorecard.partner?.playerId
        scorecard.scorecardMO!.boards = scorecard.boards
        scorecard.scorecardMO!.boardsTable = scorecard.boardsTable
        scorecard.scorecardMO!.type = scorecard.type
        scorecard.scorecardMO!.tableTotal = scorecard.tableTotal
        scorecard.scorecardMO!.totalScore = scorecard.totalScore
        scorecard.scorecardMO!.drawing = scorecard.drawing
        scorecard.scorecardMO!.drawingWidth = scorecard.drawingWidth
    }
}

extension MasterData {
    
    /// Methods for players
    
    public func insert(player: PlayerViewModel) {
        assert(player.playerMO == nil, "Cannot insert a player which already has a managed object")
        assert(self.players[player.playerId] == nil, "Player already exists and cannot be created")
        assert(self.players[player.playerId]?.name == nil, "Player must have a non-blank name")
        CoreData.update(updateLogic: {
            player.playerMO = PlayerMO()
            self.updateMO(player: player)
            self.players[player.playerId] = player
        })
    }
    
    public func remove(player: PlayerViewModel) {
        assert(player.playerMO != nil, "Cannot remove a player which doesn't already have a managed object")
        assert(self.players[player.playerId] != nil, "Player does not exist and cannot be deleted")
        CoreData.update(updateLogic: {
            CoreData.context.delete(player.playerMO!)
            self.players[player.playerId] = nil
        })
    }
    
    public func save(player: PlayerViewModel) {
        assert(player.playerMO != nil, "Cannot save a player which doesn't already have managed objects")
        assert(self.players[player.playerId] != nil, "Player does not exist and cannot be updated")
        if player.changed {
            CoreData.update(updateLogic: {
                self.updateMO(player: player)
            })
            self.players[player.playerId] = player
        }
    }
    
    public func player(id playerId: UUID?) -> PlayerViewModel? {
        return (playerId == nil ? nil : self.players[playerId!])
    }
    
    private func updateMO(player: PlayerViewModel) {
        player.playerMO!.playerId = player.playerId
        player.playerMO!.sequence = player.sequence
        player.playerMO!.name = player.name
    }
}

extension MasterData {
    
    /// Methods for locations
    
    public func insert(location: LocationViewModel) {
        assert(location.locationMO == nil, "Cannot insert a location which already has a managed object")
        assert(self.locations[location.locationId] == nil, "Location already exists and cannot be created")
        assert(self.locations[location.locationId]?.name == nil, "Location must have a non-blank name")
        CoreData.update(updateLogic: {
            location.locationMO = LocationMO()
            self.updateMO(location: location)
            self.locations[location.locationId] = location
        })
    }
    
    public func remove(location: LocationViewModel) {
        assert(location.locationMO != nil, "Cannot remove a location which doesn't already have a managed object")
        assert(self.locations[location.locationId] != nil, "Location does not exist and cannot be deleted")
        CoreData.update(updateLogic: {
            CoreData.context.delete(location.locationMO!)
            self.locations[location.locationId] = nil
        })
    }
    
    public func save(location: LocationViewModel) {
        assert(location.locationMO != nil, "Cannot save a location which doesn't already have managed objects")
        assert(self.locations[location.locationId] != nil, "Location does not exist and cannot be updated")
        if location.changed {
            CoreData.update(updateLogic: {
                self.updateMO(location: location)
            })
            self.locations[location.locationId] = location
        }
    }
    
    public func location(id locationId: UUID?) -> LocationViewModel? {
        return (locationId == nil ? nil : self.locations[locationId!])
    }
    
    private func updateMO(location: LocationViewModel) {
        location.locationMO!.locationId = location.locationId
        location.locationMO!.sequence = location.sequence
        location.locationMO!.name = location.name
    }
}
