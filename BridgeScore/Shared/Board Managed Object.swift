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
    
    convenience init() {
        self.init(context: CoreData.context)
    }
    
    public var board: Int {
        get { Int(self.board16) }
        set { self.board16 = Int16(newValue)}
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

    public var contractLevel: ContractLevel {
        get { ContractLevel(rawValue: Int(contractLevel16)) ?? .blank }
        set { self.contractLevel16 = Int16(newValue.rawValue) }
    }
    
    public var contractSuit: Suit {
        get { Suit(rawValue: Int(contractSuit16)) ?? .blank }
        set { self.contractSuit16 = Int16(newValue.rawValue) }
    }

    public var contractDouble: ContractDouble {
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

    public override var description: String {
        "Board: \(self.board) of Scorecard: \(MasterData.shared.scorecard(id: self.scorecardId)?.desc ?? "")"
    }
    public override var debugDescription: String { self.description }
}
