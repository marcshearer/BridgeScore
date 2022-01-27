//
//  Scorecard View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 12/02/2021.
//

import Combine
import SwiftUI
import CoreData

public class ScorecardViewModel : ObservableObject, Identifiable, Equatable, CustomDebugStringConvertible {

    // Properties in core data model
    @Published private(set) var scorecardId: UUID
    @Published public var date: Date
    @Published public var location: LocationViewModel?
    @Published public var desc: String
    @Published public var comment: String = ""
    @Published public var partner: PlayerViewModel?
    @Published public var boards: Int = 0
    @Published public var boardsTable: Int = 0
    @Published public var type: Type = .percent
    @Published public var tableTotal: Bool = false
    @Published public var totalScore: Float = 0
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var scorecardMO: ScorecardMO?
    
    @Published public var descMessage: String = ""
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = false
    @Published internal var canExit: Bool = false
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.scorecardMO {
            if self.scorecardId != mo.scorecardId ||
                self.location?.locationId != mo.locationId ||
                self.desc != mo.desc ||
                self.comment != mo.comment ||
                self.partner?.playerId != mo.partnerId ||
                self.boards != mo.boards ||
                self.boardsTable != mo.boardsTable ||
                self.type != mo.type ||
                self.tableTotal != mo.tableTotal {
                    result = true
            }
        }
        return result
    }
    
    public init() {
        self.scorecardId = UUID()
        self.date = Date()
        self.desc = ""
        self.setupMappings()
    }
    
    public convenience init(layout: LayoutViewModel) {
        self.init()
        self.desc = layout.desc
        self.boards = layout.boards
        self.boardsTable = layout.boardsTable
        self.type = layout.type
        self.tableTotal = layout.tableTotal
    }
    
    public convenience init(scorecardMO: ScorecardMO) {
        self.init()
        self.scorecardMO = scorecardMO
        self.revert()
    }
    
    private func setupMappings() {
        $desc
            .receive(on: RunLoop.main)
            .map { (desc) in
                return (desc == "" ? "Scorecard description must not be left blank. Either enter a valid description or delete this scorecard" : (self.descExists(desc) ? "This description already exists on another scorecard. The description must be unique" : ""))
            }
        .assign(to: \.saveMessage, on: self)
        .store(in: &cancellableSet)
              
        $saveMessage
            .receive(on: RunLoop.main)
            .map { (saveMessage) in
                return (saveMessage == "")
            }
        .assign(to: \.canSave, on: self)
        .store(in: &cancellableSet)
        
        Publishers.CombineLatest3($desc, $scorecardMO, $canSave)
            .receive(on: RunLoop.main)
            .map { (desc, scorecardMO, canSave) in
                return (canSave || (scorecardMO == nil && desc == ""))
            }
        .assign(to: \.canExit, on: self)
        .store(in: &cancellableSet)
 
    }
    
    private func revert() {
        if let mo = self.scorecardMO {
            self.scorecardId = mo.scorecardId
            if let location = MasterData.shared.location(id: mo.locationId) {
                self.location = location
            }
            self.desc = mo.desc
            self.comment = mo.comment
            if let partner = MasterData.shared.player(id: mo.partnerId) {
                self.partner = partner
            }
            self.boards = mo.boards
            self.boardsTable = mo.boardsTable
            self.type = mo.type
            self.tableTotal = mo.tableTotal
        }
    }
    
    public static func == (lhs: ScorecardViewModel, rhs: ScorecardViewModel) -> Bool {
        return lhs.scorecardId == rhs.scorecardId
    }
    
    public func save() {
        if self.scorecardMO == nil {
            MasterData.shared.insert(scorecard: self)
        } else {
            MasterData.shared.save(scorecard: self)
        }
    }
    
    public func insert() {
        MasterData.shared.insert(scorecard: self)
    }
    
    public func remove() {
        MasterData.shared.remove(scorecard: self)
    }
    
    private func descExists(_ name: String) -> Bool {
        return !MasterData.shared.scorecards.compactMap{$1}.filter({$0.desc == desc && $0.scorecardId != self.scorecardId}).isEmpty
    }
    
    public var description: String {
        "Scorecard: \(self.desc)"
    }
    
    public var debugDescription: String { self.description }
}
