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
    @Published public var contract = Contract()
    @Published public var declarer: Seat = .unknown
    @Published public var made: Int = 0
    @Published public var score: Float?
    @Published public var comment: String = ""
    @Published public var responsible: Participant = .unknown
    
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
                self.board != mo.board ||
                self.contract != mo.contract ||
                self.declarer != mo.declarer ||
                self.made != mo.made ||
                self.score != mo.score ||
                self.comment != mo.comment ||
                self.responsible != mo.responsible {
                    result = true
            }
        }
        return result
    }
    
    public init(scorecard: ScorecardViewModel, board: Int) {
        self.scorecard = scorecard
        self.board = board
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
            self.contract = mo.contract
            self.declarer = mo.declarer
            self.made = mo.made
            self.score = mo.score
            self.comment = mo.comment
            self.responsible = mo.responsible
        }
    }
    
    public func updateMO() {
        if let mo = boardMO {
            mo.scorecardId = scorecard.scorecardId
            mo.board = board
            mo.contract = contract
            mo.declarer = declarer
            mo.made = made
            mo.score = score
            mo.comment = comment
            mo.responsible = responsible
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
    
    public var dealer: Seat {
        Seat(rawValue: ((board - 1) % 4) + 1) ?? .unknown
    }
    
    public var vulnerability: Vulnerability {
        Vulnerability(board: board)
    }
    
    public func points(seat: Seat) -> Int {
        var points = 0
        let multiplier = (seat == declarer || seat == declarer.partner ? 1 : -1)

        if contract.level != .passout {
            
            let level = contract.level
            let suit = contract.suit
            let double = contract.double
            var gameMade = false
            let vulnerable = vulnerability.isVulnerable(seat: declarer)
            let tricks = level.rawValue + made
            
            if made >= 0 {
                
                // Add in base points for making contract
                let madePoints = suit.trickPoints(tricks: level.rawValue) * double.multiplier
                gameMade = (madePoints >= 100)
                points += madePoints
                
                // Add in any overtricks
                if made >= 1 {
                    if double == .undoubled {
                        points += suit.overTrickPoints(tricks: made)
                    } else {
                        points += made * (100 * (vulnerable ? 2 : 1)) * (double.multiplier / 2)
                    }
                }
                
                // Add in the insult
                if double != .undoubled {
                    points += 50 * (double.multiplier / 2)
                }
                
                // Add in any game bonus or part score bonus
                if gameMade {
                    points += (vulnerable ? 500 : 300)
                } else {
                    points += 50
                }
                
                // Add in any slam bonus
                if tricks == 13 {
                    points += (vulnerable ? 1500 : 1000)
                } else if tricks == 12 {
                    points += (vulnerable ? 750 : 500)
                }
            } else {
                
                // Subtract points for undertricks
                if double == .undoubled {
                    points = (vulnerable ? 100 : 50) * made
                } else {
                    // Subtract first trick
                    points -= (vulnerable ? 200 : 100) * (double.multiplier / 2)
                    
                    // Subtract second and third undertricks
                    points += (vulnerable ? 300 : 200) * (double.multiplier / 2) * min(0, max(-2, made + 1))
                    
                    // Subtract all other undertricks
                    points += 300 * (double.multiplier / 2) * min(0, made + 3)
                }
            }
        }
        
        return points * multiplier
    }
    
    public var description: String {
        return "Scorecard: \(scorecard.desc), Board: \(board)"
    }
    
    public var debugDescription: String { self.description }
}
