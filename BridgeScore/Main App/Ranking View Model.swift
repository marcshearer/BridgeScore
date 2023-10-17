//
//  Ranking View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 24/03/2022.
//

import Combine
import SwiftUI
import CoreData

@objcMembers public class RankingViewModel : NSObject, ObservableObject, Identifiable {

    // Properties in core data model
    @Published private(set) var scorecard: ScorecardViewModel
    @Published public var table: Int = 0
    @Published public var section: Int = 0
    @Published public var number: Int = 0
    @Published public var ranking: Int = 0
    @Published public var score: Float = 0
    @Published public var xImps: [Pair:Float ] = [:]
    @Published public var points: Float = 0
    @Published public var players: [Seat:String] = [:]
    @Published public var way: Pair = .unknown
    @Published public var tie: Bool = false
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var rankingMO: RankingMO?
    
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = true
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []

    public var waySort: Int { way.rawValue }

    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.rankingMO {
            if self.scorecard.scorecardId != mo.scorecardId ||
                self.table != mo.table ||
                self.section != mo.section ||
                self.way != mo.way ||
                self.tie != mo.tie ||
                self.number != mo.number ||
                self.ranking != mo.ranking ||
                self.score != mo.score ||
                self.xImps != mo.xImps ||
                self.points != mo.points ||
                self.players != mo.players {
                    result = true
            }
        } else {
            result = true
        }
        return result
    }
    
    public var isSelf: Bool {
        if let scorer = MasterData.shared.scorer {
            return players.map{$0.value}.contains(where: {$0.lowercased() == scorer.bboName.lowercased() || $0.lowercased() == scorer.name.lowercased()
            })
        } else {
            return false
        }
    }
    
    public init(scorecard: ScorecardViewModel, table: Int, section: Int, way: Pair, number: Int) {
        self.scorecard = scorecard
        self.table = table
        self.section = section
        self.number = number
        super.init()
        self.setupMappings()
    }
    
    public convenience init(scorecard: ScorecardViewModel, rankingMO: RankingMO) {
        self.init(scorecard: scorecard, table: rankingMO.table, section: rankingMO.section, way: rankingMO.way, number: rankingMO.number)
        self.rankingMO = rankingMO
        self.revert()
    }
        
    private func setupMappings() {
    }
    
    private func revert() {
        if let mo = self.rankingMO {
            if let scorecard = MasterData.shared.scorecard(id: mo.scorecardId) {
                self.scorecard = scorecard
            }
            self.table = mo.table
            self.section = mo.section
            self.way = mo.way
            self.tie = mo.tie
            self.number = mo.number
            self.ranking = mo.ranking
            self.score = mo.score
            self.xImps = mo.xImps
            self.points = mo.points
            self.players = mo.players
        }
    }
    
    public func updateMO() {
        if let mo = rankingMO {
            mo.scorecardId = scorecard.scorecardId
            mo.table = table
            mo.section = section
            mo.way = way
            mo.tie = self.tie
            mo.number = number
            mo.ranking = ranking
            mo.score = score
            mo.xImps = xImps
            mo.points = points
            mo.players = players
        } else {
            fatalError("No managed object")
        }
    }
    
    public func save() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.save(ranking: self)
        }
    }
    
    public func insert() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.insert(ranking: self)
        }
    }
    
    public func remove() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.remove(ranking: self)
        }
    }
    
    public var isNew: Bool {
        return self.rankingMO == nil
    }
    
    public func playerNames(board: BoardViewModel? = nil, separator: String = " & ", firstOnly: Bool = false, _ seatPlayers: SeatPlayer...) -> String {
        var names = ""
        if let board = board ?? Scorecard.current.boards[1] {
            if let sitting = board.table?.sitting {
                for seatPlayer in seatPlayers {
                    if var name = players[sitting.seatPlayer(seatPlayer)] {
                        if names != "" {
                            names += separator
                        }
                        let realName = MasterData.shared.realName(bboName: name) ?? name
                        names += firstOnly ? realName.components(separatedBy: " ").first! : realName
                    }
                }
            }
        }
        return names
    }
    
    override public var description: String {
        return "Scorecard: \(scorecard.desc), Table: \(table) Section: \(section), Number: \(number)"
    }
    
    override public var debugDescription: String { self.description }
}
