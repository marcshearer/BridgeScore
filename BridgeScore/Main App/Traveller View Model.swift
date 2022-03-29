//
//  Traveller View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 24/03/2022.
//

import Combine
import SwiftUI
import CoreData

@objcMembers public class TravellerViewModel : NSObject, ObservableObject, Identifiable {

    // Properties in core data model
    @Published private(set) var scorecard: ScorecardViewModel
    @Published public var board: Int = 0
    @Published public var contract = Contract()
    @Published public var declarer: Seat = .unknown
    @Published public var made: Int = 0
    @Published public var nsScore: Float = 0
    @Published public var nsXImps: Float = 0
    @Published public var rankingNumber: [Seat:Int] = [:]
    @Published public var section: Int = 0
    @Published public var lead: String = ""
    @Published public var playData: String = ""
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var travellerMO: TravellerMO?
    
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = true
    
    public var contractLevel: Int { contract.level.rawValue }
    public var minRankingNumber: Int { min(rankingNumber[.north] ?? Int.max,
                                           rankingNumber[.south] ?? Int.max,
                                           rankingNumber[.east] ?? Int.max,
                                           rankingNumber[.west] ?? Int.max) }
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.travellerMO {
            if self.scorecard.scorecardId != mo.scorecardId ||
                self.board != mo.board ||
                self.contract != mo.contract ||
                self.declarer != mo.declarer ||
                self.made != mo.made ||
                self.nsScore != mo.nsScore ||
                self.nsXImps != mo.nsXImps ||
                self.rankingNumber != mo.rankingNumber ||
                self.section != mo.section ||
                self.lead != mo.lead ||
                self.playData != mo.playData {
                    result = true
            }
        } else {
            result = true
        }
        return result
    }
    
    public init(scorecard: ScorecardViewModel, board: Int, section: Int, ranking: [Seat:Int]) {
        self.scorecard = scorecard
        self.board = board
        self.section = section
        self.rankingNumber = ranking
        super.init()
        self.setupMappings()
    }
    
    public convenience init(scorecard: ScorecardViewModel, travellerMO: TravellerMO) {
        self.init(scorecard: scorecard, board: travellerMO.board, section: travellerMO.section, ranking: travellerMO.rankingNumber)
        self.travellerMO = travellerMO
        self.revert()
    }
        
    private func setupMappings() {
    }
    
    private func revert() {
        if let mo = self.travellerMO {
            if let scorecard = MasterData.shared.scorecard(id: mo.scorecardId) {
                self.scorecard = scorecard
            }
            self.board = mo.board
            self.contract = mo.contract
            self.declarer = mo.declarer
            self.made = mo.made
            self.nsScore = mo.nsScore
            self.nsXImps = mo.nsXImps
            self.rankingNumber = mo.rankingNumber
            self.section = mo.section
            self.lead = mo.lead
            self.playData = mo.playData
        }
    }
    
    public func updateMO() {
        if let mo = travellerMO {
            mo.scorecardId = scorecard.scorecardId
            mo.board = board
            mo.contract = contract
            mo.declarer = declarer
            mo.made = made
            mo.nsScore = nsScore
            mo.nsXImps = nsXImps
            mo.rankingNumber = rankingNumber
            mo.section = section
            mo.lead = lead
            mo.playData = playData
        } else {
            fatalError("No managed object")
        }
    }
    
    public func save() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.save(traveller: self)
        }
    }
    
    public func insert() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.insert(traveller: self)
        }
    }
    
    public func remove() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.remove(traveller: self)
        }
    }
    
    public var isNew: Bool {
        return self.travellerMO == nil
    }
    
    public func ranking(seat: Seat) -> RankingViewModel? {
        assert(self.scorecard == Scorecard.current.scorecard, "Only valid when this scorecard is current")
        let sectionRankings = Scorecard.current.rankings.flatMap{$0.1.flatMap{$0.1.flatMap{$0.1}}}
        return sectionRankings.first(where: {$0.number == rankingNumber[seat] && $0.section == section})
    }
    
    public var isSelf: Bool {
        var result = false
        for seat in Seat.validCases {
            if let ranking = ranking(seat: seat) {
                if ranking.players[seat] == MasterData.shared.scorer?.bboName.lowercased() {
                    result = true
                }
            }
        }
        return result
    }

    public var isTeam: Bool {
        var result = false
        for seat in Seat.validCases {
            if let ranking = ranking(seat: seat) {
                if ranking.players[seat.leftOpponent] == MasterData.shared.scorer?.bboName.lowercased() {
                    result = true
                }
            }
        }
        return result
    }
    
    public override var description: String {
        "Traveller: \(self.board), North \(self.rankingNumber[.north] ?? 0) South \(self.rankingNumber[.south] ?? 0) East \(self.rankingNumber[.east] ?? 0) West \(self.rankingNumber[.west] ?? 0) of Section \(self.section) of Scorecard: \(MasterData.shared.scorecard(id: self.scorecard.scorecardId)?.desc ?? "")"
    }
    
    public override var debugDescription: String { self.description }
}
