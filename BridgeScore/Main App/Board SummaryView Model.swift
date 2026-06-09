//
//  Board SummaryView Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 25/04/2026.
//

import Combine
import SwiftUI
import CoreData

public class BoardSummaryViewModel : NSObject, ObservableObject, Identifiable {
    // Properties in core data model
    @Published private(set) var scorecard: ScorecardViewModel
    @Published public var boardIndex: Int
    @Published public var session: Int = 0
    @Published public var boardNumber: Int = 0
    @Published public var location: LocationViewModel?
    @Published public var partner: PlayerViewModel?
    @Published public var date: Date = Date()
    @Published public var vulnerability: SeatVulnerability = .unknown
    @Published public var eventType: EventType = .unknown
    @Published public var boardScoreType: ScoreType = .unknown
    @Published public var contract = Contract()
    @Published public var declarer: SeatPlayer = .player
    @Published public var made: Int? = nil
    @Published public var contDdTricks: Int = 0
    @Published public var contMedianTricks: Int = 0
    @Published public var contModeTricks: Int = 0
    @Published public var score: Int = 0
    @Published public var fieldSize: Int = 0
    @Published public var gameOdds: Int = 0
    @Published public var slamOdds: Int = 0
    @Published public var compContract = Contract()
    @Published public var compDeclarer: PairType = .we
    @Published public var compDdTricks: Int? = nil
    @Published public var compDdScore: Int = 0
    @Published public var compMakeScore: Int = 0
    @Published public var compMakeOdds: Int = 0
    @Published public var suit: [PairType:Suit] = [:]
    @Published public var declare: [PairType:Int] = [:]
    @Published public var medianTricks: [PairType:Int] = [:]
    @Published public var modeTricks: [PairType:Int] = [:]
    @Published public var ddTricks: [PairType:Int] = [:]
    @Published public var fit: [PairType:Int] = [:]
    @Published public var points: [SeatPlayer:Int] = [:]
    @Published public var totalTricks: Int = 0
    @Published public var totalTricksDd: Int = 0
    @Published public var passout: Int = 0
    @Published public var partScore: [PairType:Int] = [:]
    @Published public var game: [PairType:Int] = [:]
    @Published public var smallSlam: [PairType:Int] = [:]
    @Published public var grandSlam: [PairType:Int] = [:]
    
    public var id: (UUID, Int) { (self.scorecard.id, self.boardIndex) }
    public var isCompetitive: Bool { self.compContract.isValid }
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var boardSummaryMO: BoardSummaryMO?
    
    public init(scorecard: ScorecardViewModel, boardIndex: Int) {
        self.scorecard = scorecard
        self.boardIndex = boardIndex
        super.init()
    }
    
    public convenience init(scorecard: ScorecardViewModel, boardSummaryMO: BoardSummaryMO) {
        self.init(scorecard: scorecard, boardIndex: boardSummaryMO.boardIndex)
        self.boardSummaryMO = boardSummaryMO
        self.revert()
    }
        
    public var changed: Bool {
        var result = false
        if let mo = boardSummaryMO {
            if self.scorecard.scorecardId != mo.scorecardId ||
                self.boardIndex != mo.boardIndex ||
                self.session != mo.session ||
                self.boardNumber != mo.boardNumber ||
                self.location?.locationId != mo.locationId ||
                self.partner?.playerId != mo.partnerId ||
                self.date != mo.date ||
                self.vulnerability != mo.vulnerability ||
                self.eventType != mo.eventType ||
                self.boardScoreType != mo.boardScoreType ||
                self.contract != Contract(level: mo.contractLevel, suit: mo.contractSuit, double: mo.contractDouble) ||
                self.declarer != mo.declarer ||
                self.made != (mo.madeEntered ? mo.made : nil) ||
                self.contDdTricks != mo.contDdTricks ||
                self.contMedianTricks != mo.contMedianTricks ||
                self.contModeTricks != mo.contModeTricks ||
                self.score != mo.score ||
                self.fieldSize != mo.fieldSize ||
                self.gameOdds != mo.gameOdds ||
                self.slamOdds != mo.slamOdds ||
                self.compContract != Contract(level: mo.compContractLevel, suit: mo.compContractSuit, double: mo.compContractDouble) ||
                self.compDeclarer != mo.compDeclarer ||
                self.compDdTricks != (mo.compDdTricksEntered ? mo.compDdTricks : nil) ||
                self.compDdScore != mo.compDdScore ||
                self.compMakeScore != mo.compMakeScore ||
                self.compMakeOdds != mo.compMakeOdds ||
                self.suit[.we] != mo.suitWe ||
                self.suit[.they] != mo.suitThey ||
                self.declare[.we] != mo.declareWe ||
                self.declare[.they] != mo.declareThey ||
                self.medianTricks[.we] != mo.medianTricksWe ||
                self.medianTricks[.they] != mo.medianTricksThey ||
                self.modeTricks[.we] != mo.modeTricksWe ||
                self.modeTricks[.they] != mo.modeTricksThey ||
                self.ddTricks[.we] != mo.ddTricksWe ||
                self.ddTricks[.they] != mo.ddTricksThey ||
                self.fit[.we] != mo.fitWe ||
                self.fit[.they] != mo.fitThey ||
                self.points != mo.points ||
                self.totalTricks != mo.totalTricks ||
                self.totalTricksDd != mo.totalTricksDd ||
                self.passout != mo.passout ||
                self.partScore[.we] != mo.partScoreWe ||
                self.game[.we] != mo.gameWe ||
                self.smallSlam[.we] != mo.smallSlamWe ||
                self.grandSlam[.we] != mo.grandSlamWe ||
                self.partScore[.they] != mo.partScoreThey ||
                self.game[.they] != mo.gameThey ||
                self.smallSlam[.they] != mo.smallSlamThey ||
                self.grandSlam[.they] != mo.grandSlamThey {
                result = true
            }
        }
        return result
    }
    
    public func revert() {
        if let mo = self.boardSummaryMO {
            if let scorecard = MasterData.shared.scorecard(id: mo.scorecardId) {
                self.scorecard = scorecard
            }
            if let location = MasterData.shared.location(id: mo.locationId) {
                self.location = location
            }
            if let partner = MasterData.shared.player(id: mo.partnerId) {
                self.partner = partner
            }
            self.boardIndex = mo.boardIndex
            self.session = mo.session
            self.boardNumber = mo.boardNumber
            self.date = mo.date
            self.vulnerability = mo.vulnerability
            self.eventType = mo.eventType
            self.boardScoreType = mo.boardScoreType
            self.contract = Contract(level: mo.contractLevel, suit: mo.contractSuit, double: mo.contractDouble)
            self.declarer = mo.declarer
            self.made = mo.made
            self.contDdTricks = mo.contDdTricks
            self.contMedianTricks = mo.contMedianTricks
            self.contModeTricks = mo.contModeTricks
            self.score = mo.score
            self.fieldSize = mo.fieldSize
            self.gameOdds = mo.gameOdds
            self.slamOdds = mo.slamOdds
            self.compContract = Contract(level: mo.compContractLevel, suit: mo.compContractSuit, double: mo.compContractDouble)
            self.compDeclarer = mo.compDeclarer
            self.compDdTricks = (mo.compDdTricksEntered ? mo.compDdTricks : nil)
            self.compDdScore = mo.compDdScore
            self.compMakeScore = mo.compMakeScore
            self.compMakeOdds = mo.compMakeOdds
            self.suit[.we] = mo.suitWe
            self.suit[.they] = mo.suitThey
            self.declare[.we] = mo.declareWe
            self.declare[.they] = mo.declareThey
            self.medianTricks[.we] = mo.medianTricksWe
            self.medianTricks[.they] = mo.medianTricksThey
            self.modeTricks[.we] = mo.modeTricksWe
            self.modeTricks[.they] = mo.modeTricksThey
            self.ddTricks[.we] = mo.ddTricksWe
            self.ddTricks[.they] = mo.ddTricksThey
            self.fit[.we] = mo.fitWe
            self.fit[.they] = mo.fitThey
            self.points = mo.points
            self.totalTricks = mo.totalTricks
            self.totalTricksDd = mo.totalTricksDd
            self.passout = mo.passout
            self.partScore[.we] = mo.partScoreWe
            self.game[.we] = mo.gameWe
            self.smallSlam[.we] = mo.smallSlamWe
            self.grandSlam[.we] = mo.grandSlamWe
            self.partScore[.they] = mo.partScoreThey
            self.game[.they] = mo.gameThey
            self.smallSlam[.they] = mo.smallSlamThey
            self.grandSlam[.they] = mo.grandSlamThey
        }
    }
    
    public func updateMO() {
        if let mo = boardSummaryMO {
            mo.scorecardId = scorecard.scorecardId
            mo.locationId = self.location!.locationId
            mo.partnerId = self.partner!.playerId
            mo.boardIndex = boardIndex
            mo.session = session
            mo.boardNumber = boardNumber
            mo.date = date
            mo.vulnerability = vulnerability
            mo.eventType = eventType
            mo.boardScoreType = boardScoreType
            mo.contractLevel = contract.level
            mo.contractSuit = contract.suit
            mo.contractDouble = contract.double
            mo.declarer = declarer
            mo.made = made
            mo.contDdTricks = contDdTricks
            mo.contMedianTricks = contMedianTricks
            mo.contModeTricks = contModeTricks
            mo.score = score
            mo.fieldSize = fieldSize
            mo.gameOdds = gameOdds
            mo.slamOdds = slamOdds
            mo.compContractLevel = compContract.level
            mo.compContractSuit = compContract.suit
            mo.compContractDouble = compContract.double
            mo.compDeclarer = compDeclarer
            mo.compDdTricks = compDdTricks
            mo.compDdScore = compDdScore
            mo.compMakeScore = compMakeScore
            mo.compMakeOdds = compMakeOdds
            mo.suitWe = suit[.we] ?? .blank
            mo.suitThey = suit[.they] ?? .blank
            mo.declareWe = declare[.we] ?? 0
            mo.declareThey = declare[.they] ?? 0
            mo.medianTricksWe = medianTricks[.we] ?? 0
            mo.medianTricksThey = medianTricks[.they] ?? 0
            mo.modeTricksWe = modeTricks[.we] ?? 0
            mo.modeTricksThey = modeTricks[.they] ?? 0
            mo.ddTricksWe = ddTricks[.we] ?? 0
            mo.ddTricksThey = ddTricks[.they] ?? 0
            mo.fitWe = fit[.we] ?? 0
            mo.fitThey = fit[.they] ?? 0
            mo.points = points
            mo.totalTricks = totalTricks
            mo.totalTricksDd = totalTricksDd
            mo.passout = passout
            mo.partScoreWe = partScore[.we] ?? 0
            mo.gameWe = game[.we] ?? 0
            mo.smallSlamWe = smallSlam[.we] ?? 0
            mo.grandSlamWe = grandSlam[.we] ?? 0
            mo.partScoreThey = partScore[.they] ?? 0
            mo.gameThey = game[.they] ?? 0
            mo.smallSlamThey = smallSlam[.they] ?? 0
            mo.grandSlamThey = grandSlam[.they] ?? 0
            
            
        } else {
            fatalError("No managed object")
        }
    }
    
    public func save() {
        if self.isNew {
            self.boardSummaryMO = BoardSummaryMO()
        }
        CoreData.update {
            self.updateMO()
        }
    }
    
    public func insert() {
        CoreData.update {
            self.boardSummaryMO = BoardSummaryMO()
            self.updateMO()
        }
    }
    
    public func remove() {
        CoreData.context.delete(self.boardSummaryMO!)
    }
    
    public var isNew: Bool {
        return self.boardSummaryMO == nil
    }
    
    public override var description: String {
        return "Scorecard: \(scorecard.desc), Board index: \(boardIndex)"
    }
    
    public override var debugDescription: String { self.description }
}
