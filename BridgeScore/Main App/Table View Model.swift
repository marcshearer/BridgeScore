//
//  Table View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 15/02/2022.
//

import Combine
import SwiftUI
import CoreData

public class TableViewModel : ObservableObject, Identifiable, CustomDebugStringConvertible {

    // Properties in core data model
    @Published private(set) var scorecard: ScorecardViewModel
    @Published public var table: Int
    @Published public var sitting: Seat = .unknown
    @Published public var score: Float?
    @Published public var versus: String = ""
    @Published public var partner: String = ""
    @Published public var leftOpponent: String = ""
    @Published public var rightOpponent: String = ""
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var tableMO: TableMO?
    
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = true
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.tableMO {
            if self.scorecard.scorecardId != mo.scorecardId ||
                self.table != mo.table ||
                self.sitting != mo.sitting ||
                self.score != mo.score ||
                self.versus != mo.versus ||
                self.partner != mo.partner ||
                self.leftOpponent != mo.leftOpponent ||
                self.rightOpponent != mo.rightOpponent {
                    result = true
            }
        } else {
            result = true
        }
        return result
    }
    
    public init(scorecard: ScorecardViewModel, table: Int) {
        self.scorecard = scorecard
        self.table = table
        self.setupMappings()
    }
    
    public convenience init(scorecard: ScorecardViewModel, tableMO: TableMO) {
        self.init(scorecard: scorecard, table: tableMO.table)
        self.tableMO = tableMO
        self.revert()
    }
        
    private func setupMappings() {
    }
    
    private func revert() {
        if let mo = self.tableMO {
            if let scorecard = MasterData.shared.scorecard(id: mo.scorecardId) {
                self.scorecard = scorecard
            }
            self.table = mo.table
            self.sitting = mo.sitting
            self.score = mo.score
            self.versus = mo.versus
            self.partner = mo.partner
            self.leftOpponent = mo.leftOpponent
            self.rightOpponent = mo.rightOpponent
        }
    }
    
    public func updateMO() {
        if let mo = tableMO {
            mo.scorecardId = scorecard.scorecardId
            mo.table = table
            mo.sitting = sitting
            mo.score = score
            mo.versus = versus
            mo.partner = partner
            mo.leftOpponent = leftOpponent
            mo.rightOpponent = rightOpponent
        } else {
            fatalError("No managed object")
        }
    }
    
    public func save() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.save(table: self)
        }
    }
    
    public func insert() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.insert(table: self)
        }
    }
    
    public func remove() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.remove(table: self)
        }
    }
    
    public var isNew: Bool {
        return self.tableMO == nil
    }
    
    public var hasData: Bool {
        return self.sitting != .unknown ||
        (self.score != nil && scorecard.manualTotals) ||
        self.versus != ""
    }
    
    public var description: String {
        return "Scorecard: \(scorecard.desc), Match: \(table) Table: \(table)"
    }
    
    public var debugDescription: String { self.description }
}
