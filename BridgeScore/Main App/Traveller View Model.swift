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
    @Published public var boardIndex: Int = 0
    @Published public var contract = Contract()
    @Published public var declarer: Seat = .unknown
    @Published public var made: Int = 0
    @Published public var nsScore: Float = 0
    @Published public var nsXImps: Float = 0
    @Published public var rankingNumber: [Seat:Int] = [:]
    @Published public var section: [Seat:Int] = [:]
    @Published public var lead: String = ""
    @Published public var playData: String = ""
    @Published public var biddingRejected: Bool = false
    @Published public var playRejected: Bool = false

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
        
    public var madeString: String {
        Scorecard.madeString(made: made)
    }
    
    public var tricksMade: Int {
        contract.tricks + made
    }
    
    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.travellerMO {
            if self.scorecard.scorecardId != mo.scorecardId ||
                self.boardIndex != mo.boardIndex ||
                self.contract != mo.contract ||
                self.declarer != mo.declarer ||
                self.made != mo.made ||
                self.nsScore != mo.nsScore ||
                self.nsXImps != mo.nsXImps ||
                self.rankingNumber != mo.rankingNumber ||
                self.section != mo.section ||
                self.lead != mo.lead ||
                self.playData != mo.playData ||
                self.biddingRejected == mo.biddingRejected ||
                self.playRejected == mo.playRejected {
                    result = true
            }
        } else {
            result = true
        }
        return result
    }
    
    public init(scorecard: ScorecardViewModel, board: Int, section: [Seat:Int], ranking: [Seat:Int]) {
        self.scorecard = scorecard
        self.boardIndex = board
        self.section = section
        self.rankingNumber = ranking
        super.init()
        self.setupMappings()
    }
    
    public convenience init(scorecard: ScorecardViewModel, travellerMO: TravellerMO) {
        self.init(scorecard: scorecard, board: travellerMO.boardIndex, section: travellerMO.section, ranking: travellerMO.rankingNumber)
        self.travellerMO = travellerMO
        self.revert()
    }
        
    private func setupMappings() {
    }
    
    internal func revert() {
        if let mo = self.travellerMO {
            if let scorecard = MasterData.shared.scorecard(id: mo.scorecardId) {
                self.scorecard = scorecard
            }
            self.boardIndex = mo.boardIndex
            self.contract = mo.contract
            self.declarer = mo.declarer
            self.made = mo.made
            self.nsScore = mo.nsScore
            self.nsXImps = mo.nsXImps
            self.rankingNumber = mo.rankingNumber
            self.section = mo.section
            self.lead = mo.lead
            self.playData = mo.playData
            self.biddingRejected = mo.biddingRejected
            self.playRejected = mo.playRejected
        }
    }
    
    public func updateMO() {
        if let mo = travellerMO {
            mo.scorecardId = scorecard.scorecardId
            mo.boardIndex = boardIndex
            mo.contract = contract
            mo.declarer = declarer
            mo.made = made
            mo.nsScore = nsScore
            mo.nsXImps = nsXImps
            mo.rankingNumber = rankingNumber
            mo.section = section
            mo.lead = lead
            mo.playData = playData
            mo.biddingRejected = biddingRejected
            mo.playRejected = playRejected
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
    
    public var boardNumber: Int {
        assert(self.scorecard == Scorecard.current.scorecard, "Not the current scorecard")
        return Scorecard.current.boards[boardIndex]!.boardNumber
    }
    
    public func ranking(seat: Seat) -> RankingViewModel? {
        assert(self.scorecard == Scorecard.current.scorecard, "Only valid when this scorecard is current")
        let session = ((boardIndex - 1) / (scorecard.boardsSession)) + 1
        return Scorecard.current.ranking(session: session, section: section[seat] ?? 0, way: seat.pair, number: rankingNumber[seat] ?? 0)
    }
    
    public var isSelf: Bool {
        var result = false
        for seat in Seat.validCases {
            if let ranking = ranking(seat: seat) {
                if let scorer = scorecard.scorer, let player = ranking.players[seat]?.lowercased() {
                    if player == scorer.bboName.lowercased() || player == scorer.name.lowercased() {
                        result = true
                    }
                }
            }
        }
        return result
    }

    public var isTeam: Bool {
        var result = false
        for seat in Seat.validCases {
            if let ranking = ranking(seat: seat) {
                if let scorer = scorecard.scorer, let player = ranking.players[seat.leftOpponent]?.lowercased() {
                    if player == scorer.bboName.lowercased() || player == scorer.name.lowercased() {
                        result = true
                    }
                }
            }
        }
        return result
    }
    
    public func points(sitting: Seat = .north) -> Int {
        return Scorecard.points(contract: self.contract, vulnerability: Vulnerability(board: self.boardNumber), declarer: self.declarer, made: self.made, seat: sitting)
    }

    public var bids: [Contract?] {
        var result: [Contract?] = []
        var lastBid: Contract?
        if playData != "" {
            let tokens = playData.removingPercentEncoding!.components(separatedBy: "|")
            for (index, token) in tokens.enumerated() {
                if token == "mb" {
                    let bid = tokens[index + 1]
                    var contract: Contract? = nil
                    switch bid.uppercased() {
                    case "P":
                        break
                    case "D":
                        lastBid?.double = .doubled
                    case "R":
                        lastBid?.double = .redoubled
                    default:
                        contract = Contract(string: bid)
                        lastBid = contract
                    }
                    result.append(contract)
                }
            }
        }
        return result
    }
    
    public override var description: String {
        "Traveller: Board: \(self.boardIndex), North: \(self.rankingNumber[.north] ?? 0) South: \(self.rankingNumber[.south] ?? 0) East: \(self.rankingNumber[.east] ?? 0) West: \(self.rankingNumber[.west] ?? 0) of Section \(self.section) of Scorecard: \(MasterData.shared.scorecard(id: self.scorecard.scorecardId)?.desc ?? "")"
    }
    
    public override var debugDescription: String { self.description }
    
    public static func == (lhs: TravellerViewModel, rhs: TravellerViewModel) -> Bool {
        // Just checks vital bits
        return lhs.boardIndex == rhs.boardIndex && lhs.section == rhs.section && lhs.rankingNumber == rhs.rankingNumber
        
    }
}
