//
//  Override Tricks View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 05/10/2023.
//

import Combine
import SwiftUI
import CoreData

public class OverrideViewModel : ObservableObject, Identifiable, Equatable, CustomDebugStringConvertible {

    // Properties in core data model
    @Published private(set) var scorecard: ScorecardViewModel
    @Published public var boardIndex: Int
    @Published public var declarer: Pair = .unknown
    @Published public var suit: Suit = .blank
    @Published public var made: Int?
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Check if view model matches managed object
    public func changed(_ mo: OverrideMO) -> Bool {
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
    
    public init(scorecard: ScorecardViewModel, board: Int, declarer: Pair, suit: Suit, made: Int?) {
        self.scorecard = scorecard
        self.boardIndex = board
        self.declarer = declarer
        self.suit = suit
        self.made = made
        self.setupMappings()
    }
    
    public convenience init(scorecard: ScorecardViewModel, overrideMO: OverrideMO) {
        self.init(scorecard: scorecard, board: overrideMO.boardIndex, declarer: overrideMO.declarer, suit: overrideMO.suit, made: overrideMO.made)
        self.revert(overrideMO)
    }
        
    private func setupMappings() {
    }
    
    private func revert(_ mo: OverrideMO) {
        if let scorecard = MasterData.shared.scorecard(id: mo.scorecardId) {
            self.scorecard = scorecard
        }
        self.boardIndex = mo.boardIndex
        self.declarer = mo.declarer
        self.suit = mo.suit
        self.made = mo.made
    }
    
    public func updateMO(_ mo: OverrideMO) {
        mo.scorecardId = scorecard.scorecardId
        mo.boardIndex = boardIndex
        mo.declarer = declarer
        mo.suit = suit
        mo.made = made
    }

    public static func == (lhs: OverrideViewModel, rhs: OverrideViewModel) -> Bool {
        lhs.scorecard.id == rhs.scorecard.id && lhs.boardIndex == rhs.boardIndex && lhs.suit == rhs.suit && lhs.declarer == rhs.declarer && lhs.made == rhs.made
    }
        
    public var description: String {
        "Override Tricks: Board index: \(self.boardIndex) of Scorecard: \(scorecard.desc), Declarer: \(self.declarer.string) ,Suit: \(self.suit.string)"
    }
    
    public var debugDescription: String { self.description }
}
