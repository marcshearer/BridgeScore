//
//  Board View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 12/02/2021.
//

import Combine
import SwiftUI
import CoreData

public class BoardViewModel : ObservableObject, Identifiable, CustomDebugStringConvertible {

    // Properties in core data model
    @Published private(set) var scorecard: ScorecardViewModel
    @Published public var match: Int
    @Published public var board: Int
    @Published public var contract: String = ""
    @Published public var declarer: Position = .scorer
    @Published public var made: Int = 0
    @Published public var score: Float = 0
    @Published public var comment: String = ""
    @Published public var responsible: Position = .scorer
    @Published public var versus: String = ""
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var boardMO: BoardMO?
    
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = true
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.boardMO {
            if self.scorecard.scorecardId != mo.scorecardId ||
                self.match != mo.match ||
                self.board != mo.board ||
                self.contract != mo.contract ||
                self.declarer != mo.declarer ||
                self.made != mo.made ||
                self.score != mo.score ||
                self.comment != mo.comment ||
                self.responsible != mo.responsible ||
                self.versus != mo.versus {
                    result = true
            }
        }
        return result
    }
    
    public init(scorecard: ScorecardViewModel, match: Int, board: Int) {
        self.scorecard = scorecard
        self.match = match
        self.board = board
        self.setupMappings()
    }
    
    public convenience init(scorecard: ScorecardViewModel, boardMO: BoardMO) {
        self.init(scorecard: scorecard, match: boardMO.match, board: boardMO.board)
        self.boardMO = boardMO
        self.revert()
    }
        
    private func setupMappings() {
    }
    
    private func revert() {
        if let mo = self.boardMO {
            if let scorecard = MasterData.shared.scorecard(id: mo.scorecardId) {
                self.scorecard = scorecard
            }
            self.match = mo.match
            self.board = mo.board
            self.contract = mo.contract
            self.declarer = mo.declarer
            self.made = mo.made
            self.score = mo.score
            self.comment = mo.comment
            self.responsible = mo.responsible
            self.versus = mo.versus
        }
    }
    
    public func save() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            if self.boardMO == nil {
                Scorecard.current.insert(board: self)
            } else {
                Scorecard.current.save(board: self)
            }
        }
    }
    
    public func insert() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.insert(board: self)
        }
    }
    
    public func remove() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.remove(board: self)
        }
    }
    
    public var isNew: Bool {
        return self.boardMO == nil
    }
    
    public var description: String {
        return "Scorecard: \(scorecard.desc), Match: \(match) Board: \(board)"
    }
    
    public var debugDescription: String { self.description }
}
