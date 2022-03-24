//
//  Traveller View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 24/03/2022.
//

import Combine
import SwiftUI
import CoreData

public class TravellerViewModel : ObservableObject, Identifiable, CustomDebugStringConvertible {

    // Properties in core data model
    @Published private(set) var scorecard: ScorecardViewModel
    @Published public var board: Int = 0
    @Published public var contract = Contract()
    @Published public var declarer: Seat = .unknown
    @Published public var made: Int = 0
    @Published public var nsScore: Float = 0
    @Published public var ranking: [Seat:Int] = [:]
    @Published public var section: Int = 0
    @Published public var lead: String = ""
    @Published public var playData: String = ""
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var travellerMO: TravellerMO?
    
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = true
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.travellerMO {
            if self.scorecard.scorecardId != mo.scorecardId ||
                self.board != mo.board ||
                self.contract != mo.contract ||
                self.declarer != mo.declarer ||
                self.made != mo.made ||
                self.nsScore != mo.nsScore ||
                self.ranking != mo.ranking ||
                self.section != mo.section ||
                self.lead != mo.lead ||
                self.playData != mo.playData {
                    result = true
            }
        } else {
            result = true
        }
        return result
    }
    
    public init(scorecard: ScorecardViewModel, board: Int, section: Int, ranking: [Seat:Int]) {
        self.scorecard = scorecard
        self.board = board
        self.section = section
        self.ranking = ranking
        self.setupMappings()
    }
    
    public convenience init(scorecard: ScorecardViewModel, travellerMO: TravellerMO) {
        self.init(scorecard: scorecard, board: travellerMO.board, section: travellerMO.section, ranking: travellerMO.ranking)
        self.travellerMO = travellerMO
        self.revert()
    }
        
    private func setupMappings() {
    }
    
    private func revert() {
        if let mo = self.travellerMO {
            if let scorecard = MasterData.shared.scorecard(id: mo.scorecardId) {
                self.scorecard = scorecard
            }
            self.board = mo.board
            self.contract = mo.contract
            self.declarer = mo.declarer
            self.made = mo.made
            self.nsScore = mo.nsScore
            self.ranking = mo.ranking
            self.section = mo.section
            self.lead = mo.lead
            self.playData = mo.playData
        }
    }
    
    public func updateMO() {
        if let mo = travellerMO {
            mo.scorecardId = scorecard.scorecardId
            mo.board = board
            mo.contract = contract
            mo.declarer = declarer
            mo.made = made
            mo.nsScore = nsScore
            mo.ranking = ranking
            mo.section = section
            mo.lead = lead
            mo.playData = playData
        } else {
            fatalError("No managed object")
        }
    }
    
    public func save() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.save(traveller: self)
        }
    }
    
    public func insert() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.insert(traveller: self)
        }
    }
    
    public func remove() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.remove(traveller: self)
        }
    }
    
    public var isNew: Bool {
        return self.travellerMO == nil
    }
    
    public var description: String {
        "Traveller: \(self.board), North \(self.ranking[.north] ?? 0) South \(self.ranking[.south] ?? 0) East \(self.ranking[.east] ?? 0) West \(self.ranking[.west] ?? 0)of Section \(self.section) of Scorecard: \(MasterData.shared.scorecard(id: self.scorecard.scorecardId)?.desc ?? "")"
    }
    
    public var debugDescription: String { self.description }
}
