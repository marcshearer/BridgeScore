//
//  Override Tricks View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 05/10/2023.
//

import Combine
import SwiftUI
import CoreData

public class OverrideTricksViewModel : ObservableObject, Identifiable, CustomDebugStringConvertible {

    // Properties in core data model
    @Published private(set) var scorecard: ScorecardViewModel
    @Published public var board: Int
    @Published public var declarer: Seat = .unknown
    @Published public var suit: Suit = .blank
    @Published public var made: Int = -1
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Check if view model matches managed object
    public func changed(_ mo: DoubleDummyMO) -> Bool {
        var result = false
        if self.scorecard.scorecardId != mo.scorecardId ||
            self.board != mo.board ||
            self.declarer != mo.declarer ||
            self.suit != mo.suit ||
            self.made != mo.made {
            result = true
        }
        return result
    }
    
    public init(scorecard: ScorecardViewModel, board: Int, declarer: Seat, suit: Suit, made: Int) {
        self.scorecard = scorecard
        self.board = board
        self.declarer = declarer
        self.suit = suit
        self.made = made
        self.setupMappings()
    }
    
    public convenience init(scorecard: ScorecardViewModel, overrideTricksMO: OverrideTricksMO) {
        self.init(scorecard: scorecard, board: overrideTricksMO.board, declarer: overrideTricksMO.declarer, suit: overrideTricksMO.suit, made: overrideTricksMO.made)
        self.revert(overrideTricksMO)
    }
        
    private func setupMappings() {
    }
    
    private func revert(_ mo: OverrideTricksMO) {
        if let scorecard = MasterData.shared.scorecard(id: mo.scorecardId) {
            self.scorecard = scorecard
        }
        self.board = mo.board
        self.declarer = mo.declarer
        self.suit = mo.suit
        self.made = mo.made
    }
    
    public func updateMO(_ mo: OverrideTricksMO) {
        mo.scorecardId = scorecard.scorecardId
        mo.board = board
        mo.declarer = declarer
        mo.suit = suit
        mo.made = made
    }
        
    public var description: String {
        "Override Tricks: Board: \(self.board) of Scorecard: \(scorecard.desc), Declarer: \(self.declarer.string) ,Suit: \(self.suit.string)"
    }
    
    public var debugDescription: String { self.description }
}
