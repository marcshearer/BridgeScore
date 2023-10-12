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
    @Published public var board: Int
    @Published public var declarer: Pair = .unknown
    @Published public var suit: Suit = .blank
    @Published public var made: Int?
    @Published public var rejected: Bool
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Check if view model matches managed object
    public func changed(_ mo: OverrideMO) -> Bool {
        var result = false
        if self.scorecard.scorecardId != mo.scorecardId ||
            self.board != mo.board ||
            self.declarer != mo.declarer ||
            self.suit != mo.suit ||
            self.made != mo.made ||
            self.rejected != mo.rejected {
            result = true
        }
        return result
    }
    
    public init(scorecard: ScorecardViewModel, board: Int, declarer: Pair, suit: Suit, made: Int?, rejected: Bool) {
        self.scorecard = scorecard
        self.board = board
        self.declarer = declarer
        self.suit = suit
        self.made = made
        self.rejected = rejected
        self.setupMappings()
    }
    
    public convenience init(scorecard: ScorecardViewModel, overrideMO: OverrideMO) {
        self.init(scorecard: scorecard, board: overrideMO.board, declarer: overrideMO.declarer, suit: overrideMO.suit, made: overrideMO.made, rejected: overrideMO.rejected)
        self.revert(overrideMO)
    }
        
    private func setupMappings() {
    }
    
    private func revert(_ mo: OverrideMO) {
        if let scorecard = MasterData.shared.scorecard(id: mo.scorecardId) {
            self.scorecard = scorecard
        }
        self.board = mo.board
        self.declarer = mo.declarer
        self.suit = mo.suit
        self.made = mo.made
        self.rejected = mo.rejected
    }
    
    public func updateMO(_ mo: OverrideMO) {
        mo.scorecardId = scorecard.scorecardId
        mo.board = board
        mo.declarer = declarer
        mo.suit = suit
        mo.made = made
        mo.rejected = rejected
    }

    public static func == (lhs: OverrideViewModel, rhs: OverrideViewModel) -> Bool {
        lhs.scorecard.id == rhs.scorecard.id && lhs.board == rhs.board && lhs.suit == rhs.suit && lhs.declarer == rhs.declarer && lhs.made == rhs.made && lhs.rejected == rhs.rejected
    }
        
    public var description: String {
        "Override Tricks: Board: \(self.board) of Scorecard: \(scorecard.desc), Declarer: \(self.declarer.string) ,Suit: \(self.suit.string)"
    }
    
    public var debugDescription: String { self.description }
}
