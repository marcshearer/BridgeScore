//
//  Board View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 12/02/2021.
//

import Combine
import SwiftUI
import CoreData

public class BoardViewModel : NSObject, ObservableObject, Identifiable {

    // Properties in core data model
    @Published private(set) var scorecard: ScorecardViewModel
    @Published public var board: Int
    @Published public var contract = Contract()
    @Published public var declarer: Seat = .unknown
    @Published public var made: Int? = nil
    @Published public var score: Float?
    @Published public var comment: String = ""
    @Published public var responsible: Responsible = .unknown
    @Published public var hand: String = ""
    @Published public var optimumScore: OptimumScore?
    @Published public var doubleDummy: [Seat:[Suit:DoubleDummyViewModel]] = [:]
    @Published public var override: [Pair:[Suit:OverrideViewModel]] = [:]
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var boardMO: BoardMO?
    @Published internal var doubleDummyMO: [Seat:[Suit:DoubleDummyMO]] = [:]
    @Published internal var overrideMO: [Pair:[Suit:OverrideMO]] = [:]
    
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = true
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    public var tableNumber: Int {
        assert(self.scorecard == Scorecard.current.scorecard, "Only valid when this scorecard is current")
        return ((board - 1) / (Scorecard.current.scorecard?.boardsTable ?? 1)) + 1
    }
    public var table: TableViewModel? {
        assert(self.scorecard == Scorecard.current.scorecard, "Only valid when this scorecard is current")
        let table = ((board - 1) / (Scorecard.current.scorecard?.boardsTable ?? 1)) + 1
        return Scorecard.current.tables[table]
    }
    public var vulnerability: Vulnerability {
        return Vulnerability(board: boardNumber)
    }
    public var dealer: Seat {
        return Seat(rawValue: ((board - 1) % 4) + 1) ?? .unknown
    }
    
    public var tricksMade: Int? {
        made == nil ? nil : contract.level.tricks + made!
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
                self.hand != mo.hand ||
                self.optimumScore != mo.optimumScore {
                    result = true
            }
            if !result {
                // Check double dummy entries match
                if doubleDummy.count != doubleDummyMO.count {
                    result = true
                } else {
                    for (declarer, suitDictionary) in doubleDummy {
                        if suitDictionary.count != doubleDummyMO[declarer]?.count {
                            result = true
                            break
                        } else {
                            for (suit, doubleDummy) in suitDictionary {
                                if let mo = doubleDummyMO[declarer]?[suit] {
                                    if doubleDummy.changed(mo) {
                                        result = true
                                        break
                                    }
                                } else {
                                    result = true
                                    break
                                }
                            }
                            if result == true {
                                break
                            }
                        }
                    }
                }
            }
            if !result {
                // Check override tricks entries match
                if override.count != overrideMO.count {
                    result = true
                } else {
                    for (declarer, suitDictionary) in override {
                        if suitDictionary.count != overrideMO[declarer]?.count {
                            result = true
                            break
                        } else {
                            for (suit, override) in suitDictionary {
                                if let mo = overrideMO[declarer]?[suit] {
                                    if override.changed(mo) {
                                        result = true
                                        break
                                    }
                                } else {
                                    result = true
                                    break
                                }
                            }
                            if result == true {
                                break
                            }
                        }
                    }
                }
            }
        } else {
            result = true
        }
        return result
    }
    
    public init(scorecard: ScorecardViewModel, board: Int) {
        self.scorecard = scorecard
        self.board = board
        super.init()
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
            self.hand = mo.hand
            self.optimumScore = mo.optimumScore
            self.doubleDummy = [:]
            for (declarer, suitDictionary) in doubleDummyMO {
                for (suit, mo) in suitDictionary {
                    if self.doubleDummy[declarer] == nil {
                        self.doubleDummy[declarer] = [:]
                    }
                    self.doubleDummy[declarer]![suit] = DoubleDummyViewModel(scorecard: scorecard, doubleDummyMO: mo)
                }
            }
            self.override = [:]
            for (declarer, suitDictionary) in overrideMO {
                for (suit, mo) in suitDictionary {
                    if self.override[declarer] == nil {
                        self.override[declarer] = [:]
                    }
                    self.override[declarer]![suit] = OverrideViewModel(scorecard: scorecard, overrideMO: mo)
                }
            }
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
            mo.optimumScore = optimumScore
            forEachDoubleDummy { (declarer, suit, doubleDummy) in
                if let mo = self.doubleDummyMO[declarer]?[suit] {
                    doubleDummy.updateMO(mo)
                }
            }
            forEachOverride { (declarer, suit, override) in
                if let mo = self.overrideMO[declarer]?[suit] {
                    override.updateMO(mo)
                }
            }
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
        self.responsible != .unknown ||
        self.optimumScore != nil ||
        !self.doubleDummy.isEmpty ||
        !self.override.isEmpty
    }
    
    public func forEachDoubleDummy(action: (Seat, Suit, DoubleDummyViewModel)->()) {
        for (declarer, suitDictionary) in doubleDummy {
            for (suit, doubleDummy) in suitDictionary {
                action(declarer, suit, doubleDummy)
            }
        }
    }

    public func forEachDoubleDummyMO(action: (Seat, Suit, DoubleDummyMO)->()) {
        for (declarer, suitDictionary) in doubleDummyMO {
            for (suit, mo) in suitDictionary {
                action(declarer, suit, mo)
            }
        }
    }
    
    public func forEachOverride(action: (Pair, Suit, OverrideViewModel)->()) {
        for (declarer, suitDictionary) in override {
            for (suit, override) in suitDictionary {
                action(declarer, suit, override)
            }
        }
    }

    public func forEachOverrideMO(action: (Pair, Suit, OverrideMO)->()) {
        for (declarer, suitDictionary) in overrideMO {
            for (suit, mo) in suitDictionary {
                action(declarer, suit, mo)
            }
        }
    }
    
    public var boardNumber: Int {
        Scorecard.boardNumber(scorecard: scorecard, board: board)
    }
    
    public func points(seat: Seat) -> Int? {
        return (made == nil ? nil : Scorecard.points(contract: contract, vulnerability: vulnerability, declarer: declarer, made: made!, seat: seat))
    }
    
    public override var description: String {
        return "Scorecard: \(scorecard.desc), Board: \(board)"
    }
    
    public override var debugDescription: String { self.description }
}
