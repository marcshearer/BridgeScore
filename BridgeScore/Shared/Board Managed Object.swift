//
//  Board Managed Object.swift
//  BridgeScore
//
//  Created by Marc Shearer on 21/01/2022.
//

import CoreData

@objc(BoardMO)
public class BoardMO: NSManagedObject, ManagedObject, Identifiable {

    public static let tableName = "Board"
    
    public var id: (UUID, Int) { (self.scorecardId, self.board) }
    @NSManaged public var scorecardId: UUID
    @NSManaged public var board16: Int16
    @NSManaged public var dealer16: Int16
    @NSManaged public var vulnerability16: Int16
    @NSManaged public var contractLevel16: Int16
    @NSManaged public var contractSuit16: Int16
    @NSManaged public var contractDouble16: Int16
    @NSManaged public var declarer16: Int16
    @NSManaged public var made16: Int16
    @NSManaged public var madeEntered: Bool
    @NSManaged public var scoreValue: Float
    @NSManaged public var scoreEntered: Bool
    @NSManaged public var comment: String
    @NSManaged public var responsible16: Int16
    @NSManaged public var hand: String
    @NSManaged public var optimumContractLevel16: Int16
    @NSManaged public var optimumContractSuit16: Int16
    @NSManaged public var optimumContractDouble16: Int16
    @NSManaged public var optimumDeclarer16: Int16
    @NSManaged public var optimumMade16: Int16
    @NSManaged public var optimumNsPoints16: Int16
    @NSManaged public var optimumEntered: Bool
    
    convenience init() {
        self.init(context: CoreData.context)
    }
    
    public var board: Int {
        get { Int(self.board16) }
        set { self.board16 = Int16(newValue)}
    }
    
    public var dealer: Seat? {
        get { dealer16 == Seat.unknown.rawValue ? nil : Seat(rawValue: Int(dealer16)) }
        set { self.dealer16 = Int16(newValue?.rawValue ?? Seat.unknown.rawValue) }
    }
    
    public var vulnerability: Vulnerability? {
        get { vulnerability16 == Vulnerability.unknown.rawValue ? nil : Vulnerability(rawValue: Int(vulnerability16)) }
        set { self.vulnerability16 = Int16(newValue?.rawValue ?? Vulnerability.unknown.rawValue) }
    }

    public var declarer: Seat {
        get { Seat(rawValue: Int(declarer16)) ?? .unknown }
        set { self.declarer16 = Int16(newValue.rawValue) }
    }
    
    public var responsible: Responsible {
        get { Responsible(rawValue: Int(responsible16)) ?? .unknown }
        set { self.responsible16 = Int16(newValue.rawValue) }
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
    
    public var score: Float? {
        get { scoreEntered ? self.scoreValue : nil}
        set {
            if let newValue = newValue {
                self.scoreValue = newValue
                self.scoreEntered = true
            } else {
                self.scoreValue = 0
                self.scoreEntered = false
            }
        }
    }

    private var contractLevel: ContractLevel {
        get { ContractLevel(rawValue: Int(contractLevel16)) ?? .blank }
        set { self.contractLevel16 = Int16(newValue.rawValue) }
    }
    
    private var contractSuit: Suit {
        get { Suit(rawValue: Int(contractSuit16)) ?? .blank }
        set { self.contractSuit16 = Int16(newValue.rawValue) }
    }

    private var contractDouble: ContractDouble {
        get { ContractDouble(rawValue: Int(contractDouble16)) ?? .undoubled }
        set { self.contractDouble16 = Int16(newValue.rawValue) }
    }
    
    public var contract: Contract {
        get { Contract(level: contractLevel, suit: contractSuit, double: contractDouble) }
        set {
            contractLevel = newValue.level
            contractSuit = newValue.suit
            contractDouble = newValue.double
        }
    }
    
    private var optimumContractLevel: ContractLevel {
        get { ContractLevel(rawValue: Int(optimumContractLevel16)) ?? .blank }
        set { self.optimumContractLevel16 = Int16(newValue.rawValue) }
    }
    
    private var optimumContractSuit: Suit {
        get { Suit(rawValue: Int(optimumContractSuit16)) ?? .blank }
        set { self.optimumContractSuit16 = Int16(newValue.rawValue) }
    }

    private var optimumContractDouble: ContractDouble {
        get { ContractDouble(rawValue: Int(optimumContractDouble16)) ?? .undoubled }
        set { self.optimumContractDouble16 = Int16(newValue.rawValue) }
    }
    
    private var optimumContract: Contract {
        get { Contract(level: optimumContractLevel, suit: optimumContractSuit, double: optimumContractDouble) }
        set {
            optimumContractLevel = newValue.level
            optimumContractSuit = newValue.suit
            optimumContractDouble = newValue.double
        }
    }
    
    private var optimumDeclarer: Pair {
        get { Pair(rawValue: Int(optimumDeclarer16)) ?? .unknown }
        set { self.optimumDeclarer16 = Int16(newValue.rawValue) }
    }
    
    private var optimumMade: Int {
        get { Int(self.optimumMade16) }
        set { self.optimumMade16 = Int16(newValue)}
    }
    
    private var optimumNsPoints: Int {
        get { Int(self.optimumNsPoints16) }
        set { self.optimumNsPoints16 = Int16(newValue)}
    }
    
    public var optimumScore: OptimumScore? {
        get { optimumEntered ? OptimumScore(contract: optimumContract, declarer: optimumDeclarer, made: optimumMade, nsPoints: optimumNsPoints) : nil}
        set {
            if let newValue = newValue {
                self.optimumContract = newValue.contract
                self.optimumDeclarer = newValue.declarer
                self.optimumMade = newValue.made
                self.optimumNsPoints = newValue.nsPoints
                self.optimumEntered = true
            } else {
                self.optimumContract = Contract()
                self.optimumDeclarer = .unknown
                self.optimumMade = 0
                self.optimumNsPoints = 0
                self.optimumEntered = false
            }
        }
    }

    public override var description: String {
        "Board: \(self.board) of Scorecard: \(MasterData.shared.scorecard(id: self.scorecardId)?.desc ?? "")"
    }
    public override var debugDescription: String { self.description }
}
