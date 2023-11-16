    //
    //  Ranking Table View Model.swift
    //  BridgeScore
    //
    //  Created by Marc Shearer on 15/02/2022.
    //

    import Combine
    import SwiftUI
    import CoreData

    public class RankingTableViewModel : ObservableObject, Identifiable, CustomDebugStringConvertible {

        // Properties in core data model
        @Published private(set) var scorecard: ScorecardViewModel
        @Published public var number: Int
        @Published public var section: Int
        @Published public var way: Pair
        @Published public var table: Int
        @Published public var nsScore: Float?
        
        // Linked managed objects - should only be referenced in this and the Data classes
        @Published internal var rankingTableMO: RankingTableMO?
        
        @Published private(set) var saveMessage: String = ""
        @Published private(set) var canSave: Bool = true
        
        // Auto-cleanup
        private var cancellableSet: Set<AnyCancellable> = []
        
        // Check if view model matches managed object
        public var changed: Bool {
            var result = false
            if let mo = self.rankingTableMO {
                if self.scorecard.scorecardId != mo.scorecardId ||
                    self.number != mo.number ||
                    self.section != mo.section ||
                    self.way != mo.way ||
                    self.table != mo.table ||
                    self.nsScore != mo.nsScore {
                    result = true
                }
            } else {
                result = true
            }
            return result
        }
        
        public init(scorecard: ScorecardViewModel, number: Int, section: Int, way: Pair, table: Int) {
            self.scorecard = scorecard
            self.number = number
            self.section = section
            self.way = way
            self.table = table
            self.setupMappings()
        }
        
        public convenience init(scorecard: ScorecardViewModel, rankingTableMO: RankingTableMO) {
            self.init(scorecard: scorecard, number: rankingTableMO.number, section: rankingTableMO.section, way: rankingTableMO.way, table: rankingTableMO.table)
            self.rankingTableMO = rankingTableMO
            self.revert()
        }
            
        private func setupMappings() {
        }
        
        private func revert() {
            if let mo = self.rankingTableMO {
                if let scorecard = MasterData.shared.scorecard(id: mo.scorecardId) {
                    self.scorecard = scorecard
                }
                self.number = mo.number
                self.section = mo.section
                self.way = mo.way
                self.table = mo.table
                self.nsScore = mo.nsScore
            }
        }
        
        public func updateMO() {
            if let mo = rankingTableMO {
                mo.scorecardId = scorecard.scorecardId
                mo.number = number
                mo.section = section
                mo.way = way
                mo.table = table
                mo.nsScore = nsScore
            } else {
                fatalError("No managed object")
            }
        }
        
        public func save() {
            if Scorecard.current.match(scorecard: self.scorecard) {
                Scorecard.current.save(rankingTable: self)
            }
        }
        
        public func insert() {
            if Scorecard.current.match(scorecard: self.scorecard) {
                Scorecard.current.insert(rankingTable: self)
            }
        }
        
        public func remove() {
            if Scorecard.current.match(scorecard: self.scorecard) {
                Scorecard.current.remove(rankingTable: self)
            }
        }
        
        public var isNew: Bool {
            return self.rankingTableMO == nil
        }
        
        public var description: String {
            return "Scorecard: \(scorecard.desc), Ranking: \(number) Table: \(table)"
        }
        
        public var debugDescription: String { self.description }
    }
