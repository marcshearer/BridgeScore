//
//  Double Dummy View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 05/09/2023.
//

import Combine
import SwiftUI
import CoreData

public class DoubleDummyViewModel : ObservableObject, Identifiable, CustomDebugStringConvertible {

    // Properties in core data model
    @Published private(set) var scorecard: ScorecardViewModel
    @Published public var boardIndex: Int
    @Published public var declarer: Seat = .unknown
    @Published public var suit: Suit = .blank
    @Published public var made: Int = -1
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Check if view model matches managed object
    public func changed(_ mo: DoubleDummyMO) -> Bool {
        var result = false
        if self.scorecard.scorecardId != mo.scorecardId ||
            self.boardIndex != mo.boardIndex ||
            self.declarer != mo.declarer ||
            self.suit != mo.suit ||
            self.made != mo.made {
            result = true
        }
        return result
    }
    
    public init(scorecard: ScorecardViewModel, board: Int, declarer: Seat, suit: Suit, made: Int) {
        self.scorecard = scorecard
        self.boardIndex = board
        self.declarer = declarer
        self.suit = suit
        self.made = made
        self.setupMappings()
    }
    
    public convenience init(scorecard: ScorecardViewModel, doubleDummyMO: DoubleDummyMO) {
        self.init(scorecard: scorecard, board: doubleDummyMO.boardIndex, declarer: doubleDummyMO.declarer, suit: doubleDummyMO.suit, made: doubleDummyMO.made)
        self.revert(doubleDummyMO)
    }
        
    private func setupMappings() {
    }
    
    private func revert(_ mo: DoubleDummyMO) {
        if let scorecard = MasterData.shared.scorecard(id: mo.scorecardId) {
            self.scorecard = scorecard
        }
        self.boardIndex = mo.boardIndex
        self.declarer = mo.declarer
        self.suit = mo.suit
        self.made = mo.made
    }
    
    public func updateMO(_ mo: DoubleDummyMO) {
        mo.scorecardId = scorecard.scorecardId
        mo.boardIndex = boardIndex
        mo.declarer = declarer
        mo.suit = suit
        mo.made = made
    }
        
    public var description: String {
        "Double Dummy: Board index: \(self.boardIndex) of Scorecard: \(scorecard.desc), Declarer: \(self.declarer.string) ,Suit: \(self.suit.string)"
    }
    
    public var debugDescription: String { self.description }
}
