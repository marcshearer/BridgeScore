//
//  Ranking View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 24/03/2022.
//

import Combine
import SwiftUI
import CoreData

public class RankingViewModel : ObservableObject, Identifiable, CustomDebugStringConvertible {

    // Properties in core data model
    @Published private(set) var scorecard: ScorecardViewModel
    @Published public var table: Int = 0
    @Published public var section: Int = 0
    @Published public var number: Int = 0
    @Published public var ranking: Int = 0
    @Published public var score: Float = 0
    @Published public var points: Float = 0
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var rankingMO: RankingMO?
    
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = true
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.rankingMO {
            if self.scorecard.scorecardId != mo.scorecardId ||
                self.table != mo.table ||
                self.section != mo.section ||
                self.number != mo.number ||
                self.ranking != mo.ranking ||
                self.score != mo.score ||
                self.points != mo.points {
                    result = true
            }
        } else {
            result = true
        }
        return result
    }
    
    public init(scorecard: ScorecardViewModel, table: Int, section: Int, number: Int) {
        self.scorecard = scorecard
        self.table = table
        self.section = section
        self.number = number
        self.setupMappings()
    }
    
    public convenience init(scorecard: ScorecardViewModel, rankingMO: RankingMO) {
        self.init(scorecard: scorecard, table: rankingMO.table, section: rankingMO.section, number: rankingMO.number)
        self.rankingMO = rankingMO
        self.revert()
    }
        
    private func setupMappings() {
    }
    
    private func revert() {
        if let mo = self.rankingMO {
            if let scorecard = MasterData.shared.scorecard(id: mo.scorecardId) {
                self.scorecard = scorecard
            }
            self.table = mo.table
            self.section = mo.section
            self.number = mo.number
            self.ranking = mo.ranking
            self.score = mo.score
            self.points = mo.points
        }
    }
    
    public func updateMO() {
        if let mo = rankingMO {
            mo.scorecardId = scorecard.scorecardId
            mo.table = table
            mo.section = section
            mo.number = number
            mo.ranking = ranking
            mo.score = score
            mo.points = points
        } else {
            fatalError("No managed object")
        }
    }
    
    public func save() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.save(ranking: self)
        }
    }
    
    public func insert() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.insert(ranking: self)
        }
    }
    
    public func remove() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.remove(ranking: self)
        }
    }
    
    public var isNew: Bool {
        return self.rankingMO == nil
    }
    
    public var description: String {
        return "Scorecard: \(scorecard.desc), Table: \(table) Section: \(section), Number: \(number)"
    }
    
    public var debugDescription: String { self.description }
}
