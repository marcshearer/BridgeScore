//
//  Board Summary Managed Object.swift
//  BridgeScore
//
//  Created by Marc Shearer on 25/04/2026.
//

import CoreData

@objc(BoardSummaryMO)
public class BoardSummaryMO: NSManagedObject, ManagedObject, Identifiable {
    
    public static let tableName = "BoardSummary"
    
    public var id: (UUID, Int) { (self.scorecardId, self.boardIndex) }
    @NSManaged public var scorecardId: UUID
    @NSManaged public var boardIndex16: Int16 ; @IntProperty(\BoardSummaryMO.boardIndex16) public var boardIndex: Int
    @NSManaged public var locationId: UUID!
    @NSManaged public var partnerId: UUID!
    @NSManaged public var date: Date
    @NSManaged public var vulnerability16: Int16 ; @EnumProperty(\BoardSummaryMO.vulnerability16) public var vulnerability: SeatVulnerability
    @NSManaged public var eventType16: Int16 ; @EnumProperty(\BoardSummaryMO.eventType16) public var eventType: EventType
    @NSManaged public var boardScoreType16: Int16 ; @EnumProperty(\BoardSummaryMO.boardScoreType16) public var boardScoreType: ScoreType
    @NSManaged public var contractLevel16: Int16 ; @EnumProperty(\BoardSummaryMO.contractLevel16) public var contractLevel: ContractLevel
    @NSManaged public var contractSuit16: Int16 ; @EnumProperty(\BoardSummaryMO.contractSuit16) public var contractSuit: Suit
    @NSManaged public var contractDouble16: Int16 ; @EnumProperty(\BoardSummaryMO.contractDouble16) public var contractDouble: ContractDouble
    @NSManaged public var declarer16: Int16 ; @EnumProperty(\BoardSummaryMO.declarer16) public var declarer: SeatPlayer
    @NSManaged public var made16: Int16
    @NSManaged public var madeEntered: Bool
    @NSManaged public var score16: Int16 ; @IntProperty(\BoardSummaryMO.score16) public var score: Int
    @NSManaged public var fieldSize16: Int16 ; @IntProperty(\BoardSummaryMO.fieldSize16) public var fieldSize: Int
    @NSManaged public var gameOdds16: Int16 ; @IntProperty(\BoardSummaryMO.gameOdds16) public var gameOdds: Int
    @NSManaged public var slamOdds16: Int16 ; @IntProperty(\BoardSummaryMO.slamOdds16) public var slamOdds: Int
    @NSManaged public var compContractLevel16: Int16 ; @EnumProperty(\BoardSummaryMO.compContractLevel16) public var compContractLevel: ContractLevel
    @NSManaged public var compContractSuit16: Int16 ; @EnumProperty(\BoardSummaryMO.compContractSuit16) public var compContractSuit: Suit
    @NSManaged public var compContractDouble16: Int16 ; @EnumProperty(\BoardSummaryMO.compContractDouble16) public var compContractDouble: ContractDouble
    @NSManaged public var compDeclarer16: Int16 ; @EnumProperty(\BoardSummaryMO.compDeclarer16) public var compDeclarer: PairType
    @NSManaged public var compDdMade16: Int16
    @NSManaged public var compDdMadeEntered: Bool
    @NSManaged public var compDdScore16: Int16 ; @IntProperty(\BoardSummaryMO.compDdScore16) public var compDdScore: Int
    @NSManaged public var compMakeScore16: Int16 ; @IntProperty(\BoardSummaryMO.compMakeScore16) public var compMakeScore: Int
    @NSManaged public var compMakeOdds16: Int16 ; @IntProperty(\BoardSummaryMO.compMakeOdds16) public var compMakeOdds: Int
    @NSManaged public var suitWe16: Int16 ; @EnumProperty(\BoardSummaryMO.suitWe16) public var suitWe: Suit
    @NSManaged public var suitThey16: Int16 ; @EnumProperty(\BoardSummaryMO.suitThey16) public var suitThey: Suit
    @NSManaged public var declareWe16: Int16 ; @IntProperty(\BoardSummaryMO.declareWe16) public var declareWe: Int
    @NSManaged public var declareThey16: Int16 ; @IntProperty(\BoardSummaryMO.declareThey16) public var declareThey: Int
    @NSManaged public var medianTricksWe16: Int16 ; @IntProperty(\BoardSummaryMO.medianTricksWe16) public var medianTricksWe: Int
    @NSManaged public var medianTricksThey16: Int16 ; @IntProperty(\BoardSummaryMO.medianTricksThey16) public var medianTricksThey: Int
    @NSManaged public var modeTricksWe16: Int16 ; @IntProperty(\BoardSummaryMO.modeTricksWe16) public var modeTricksWe: Int
    @NSManaged public var modeTricksThey16: Int16 ; @IntProperty(\BoardSummaryMO.modeTricksThey16) public var modeTricksThey: Int
    @NSManaged public var ddTricksWe16: Int16 ; @IntProperty(\BoardSummaryMO.ddTricksWe16) public var ddTricksWe: Int
    @NSManaged public var ddTricksThey16: Int16 ; @IntProperty(\BoardSummaryMO.ddTricksThey16) public var ddTricksThey: Int
    @NSManaged public var pointsPlayer16: Int16 ; @IntProperty(\BoardSummaryMO.pointsPlayer16) public var pointsPlayer: Int
    @NSManaged public var pointsPartner16: Int16 ; @IntProperty(\BoardSummaryMO.pointsPartner16) public var pointsPartner: Int
    @NSManaged public var pointsLhOpponent16: Int16 ; @IntProperty(\BoardSummaryMO.pointsLhOpponent16) public var pointsLhOpponent: Int
    @NSManaged public var pointsRhOpponent16: Int16 ; @IntProperty(\BoardSummaryMO.pointsRhOpponent16) public var pointsRhOpponent: Int
    @NSManaged public var suitType16: Int16 ; @EnumProperty(\BoardSummaryMO.suitType16) public var suitType: SuitType
    @NSManaged public var level16: Int16 ; @EnumProperty(\BoardSummaryMO.level16) public var levelType: LevelType
    @NSManaged public var fitWe16: Int16 ; @IntProperty(\BoardSummaryMO.fitWe16) public var fitWe: Int
    @NSManaged public var fitThey16: Int16 ; @IntProperty(\BoardSummaryMO.fitThey16) public var fitThey: Int
    @NSManaged public var totalTricks16: Int16 ; @IntProperty(\BoardSummaryMO.totalTricks16) public var totalTricks: Int
    @NSManaged public var totalTricksDd16: Int16 ; @IntProperty(\BoardSummaryMO.totalTricksDd16) public var totalTricksDd: Int
    
    convenience init() {
        self.init(context: CoreData.context)
    }
    
    public var made: Int? {
        get { (self.madeEntered ? Int(self.made16) : nil) }
        set {
            if let newValue = newValue {
                self.made16 = Int16(newValue)
                self.madeEntered = true
            } else {
                self.made16 = 0
                self.madeEntered = false
            }
        }
    }
    
    public var compDdMade: Int? {
        get { (self.compDdMadeEntered ? Int(self.compDdMade16) : nil) }
        set {
            if let newValue = newValue {
                self.compDdMade16 = Int16(newValue)
                self.compDdMadeEntered = true
            } else {
                self.compDdMade16 = 0
                self.compDdMadeEntered = false
            }
        }
    }
    
    public var points: [SeatPlayer:Int] {
        get {
            [.player : pointsPlayer,
             .partner: pointsPartner,
             .lhOpponent: pointsLhOpponent,
             .rhOpponent: pointsRhOpponent]
        }
        set {
            pointsPlayer = newValue[.player] ?? 0
            pointsPartner = newValue[.partner] ?? 0
            pointsLhOpponent = newValue[.lhOpponent] ?? 0
            pointsRhOpponent = newValue[.rhOpponent] ?? 0
        }
    }
}
