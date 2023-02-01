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
    @Published public var board: Int
    @Published public var dealer: Seat?
    @Published public var vulnerability: Vulnerability?
    @Published public var contract = Contract()
    @Published public var declarer: Seat = .unknown
    @Published public var made: Int? = nil
    @Published public var score: Float?
    @Published public var comment: String = ""
    @Published public var responsible: Responsible = .unknown
    @Published public var hand: String = ""
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var boardMO: BoardMO?
    
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = true
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    public var tableNumber: Int {
        assert(self.scorecard == Scorecard.current.scorecard, "Only valid when this scorecard is current")
        return ((board - 1) / (Scorecard.current.scorecard?.boardsTable ?? 1)) + 1
    }
    
    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.boardMO {
            if self.scorecard.scorecardId != mo.scorecardId ||
                self.board != mo.board ||
                self.dealer != mo.dealer ||
                self.vulnerability != mo.vulnerability ||
                self.contract != mo.contract ||
                self.declarer != mo.declarer ||
                self.made != mo.made ||
                self.score != mo.score ||
                self.comment != mo.comment ||
                self.responsible != mo.responsible ||
                self.hand != mo.hand {
                    result = true
            }
        } else {
            result = true
        }
        return result
    }
    
    public init(scorecard: ScorecardViewModel, board: Int) {
        self.scorecard = scorecard
        self.board = board
        self.dealer = Seat(rawValue: ((board - 1) % 4) + 1) ?? .unknown
        self.vulnerability = Vulnerability(board: boardNumber)
        self.setupMappings()
    }
    
    public convenience init(scorecard: ScorecardViewModel, boardMO: BoardMO) {
        self.init(scorecard: scorecard, board: boardMO.board)
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
            self.board = mo.board
            self.dealer = mo.dealer ?? Seat(rawValue: ((board - 1) % 4) + 1) ?? .unknown
            self.vulnerability = mo.vulnerability ?? Vulnerability(board: Scorecard.boardNumber(scorecard: scorecard, board: board))
            self.contract = mo.contract
            self.declarer = mo.declarer
            self.made = mo.made
            self.score = mo.score
            self.comment = mo.comment
            self.responsible = mo.responsible
            self.hand = mo.hand
        }
    }
    
    public func updateMO() {
        if let mo = boardMO {
            mo.scorecardId = scorecard.scorecardId
            mo.board = board
            mo.dealer = dealer
            mo.vulnerability = vulnerability
            mo.contract = contract
            mo.declarer = declarer
            mo.made = made
            mo.score = score
            mo.comment = comment
            mo.responsible = responsible
            mo.hand = hand
        } else {
            fatalError("No managed object")
        }
    }
    
    public func save() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.save(board: self)
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
    
    public var hasData: Bool {
        return self.contract.level != .blank ||
        self.declarer != .unknown ||
        self.made != 0 ||
        self.score != nil ||
        self.comment != "" ||
        self.responsible != .unknown
    }
    
    public var boardNumber: Int {
        Scorecard.boardNumber(scorecard: scorecard, board: board)
    }
    
    public func points(seat: Seat) -> Int? {
        return (made == nil ? nil : Scorecard.points(contract: contract, vulnerability: vulnerability!, declarer: declarer, made: made!, seat: seat))
    }
    
    public var description: String {
        return "Scorecard: \(scorecard.desc), Board: \(board)"
    }
    
    public var debugDescription: String { self.description }
}
