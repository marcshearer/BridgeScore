//
//  Traveller Managed Object.swift
//  BridgeScore
//
//  Created by Marc Shearer on 24/03/2022.
//

import CoreData

@objc(TravellerMO)
public class TravellerMO: NSManagedObject, ManagedObject, Identifiable {

    public static let tableName = "Traveller"
    
    public var id: (UUID, Int, [Seat:Int], Int16) { (self.scorecardId, self.board, self.rankingNumber, self.northSection16) }
    @NSManaged public var scorecardId: UUID
    @NSManaged public var board16: Int16
    @NSManaged public var dealer16: Int16
    @NSManaged public var vulnerability16: Int16
    @NSManaged public var contractLevel16: Int16
    @NSManaged public var contractSuit16: Int16
    @NSManaged public var contractDouble16: Int16
    @NSManaged public var declarer16: Int16
    @NSManaged public var made16: Int16
    @NSManaged public var nsScore: Float
    @NSManaged public var nsXImps: Float
    @NSManaged public var northValue: Int16
    @NSManaged public var northEntered: Bool
    @NSManaged public var southValue: Int16
    @NSManaged public var southEntered: Bool
    @NSManaged public var eastValue: Int16
    @NSManaged public var eastEntered: Bool
    @NSManaged public var westValue: Int16
    @NSManaged public var westEntered: Bool
    @NSManaged public var northSection16: Int16
    @NSManaged public var southSection16: Int16
    @NSManaged public var eastSection16: Int16
    @NSManaged public var westSection16: Int16
    @NSManaged public var lead: String
    @NSManaged public var playData: String
    
    convenience init() {
        self.init(context: CoreData.context)
    }
    
    public var board: Int {
        get { Int(self.board16) }
        set { self.board16 = Int16(newValue) }
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
    
    public var made: Int {
        get { Int(self.made16) }
        set { self.made16 = Int16(newValue) }
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

    public var section: [Seat:Int] {
        get {
            var result: [Seat:Int] = [:]
            if northEntered { result[.north] = Int(northValue) }
            if southEntered { result[.south] = Int(southValue) }
            if eastEntered { result[.east] = Int(eastValue) }
            if westEntered { result[.west] = Int(westValue) }
            return result
        }
        set {
            if let value = newValue[.north] {
                northValue = Int16(value)
                northEntered = true
            } else {
                northValue = 0
                northEntered = false
            }
            if let value = newValue[.south] {
                southValue = Int16(value)
                southEntered = true
            } else {
                southValue = 0
                southEntered = false
            }
            if let value = newValue[.east] {
                eastValue = Int16(value)
                eastEntered = true
            } else {
                eastValue = 0
                eastEntered = false
            }
            if let value = newValue[.west] {
                westValue = Int16(value)
                westEntered = true
            } else {
                westValue = 0
                westEntered = false
            }
        }
    }
    
    public var rankingNumber: [Seat:Int] {
        get {
            var result: [Seat:Int] = [:]
            result[.north] = Int(northSection16)
            result[.south] = Int(southSection16)
            result[.east] = Int(eastSection16)
            result[.west] = Int(westSection16)
            return result
        }
        set {
            northSection16 = Int16(newValue[.north] ?? 0)
            southSection16 = Int16(newValue[.south] ?? 0)
            eastSection16 = Int16(newValue[.east] ?? 0)
            westSection16 = Int16(newValue[.west] ?? 0)
        }
    }
    
    public override var description: String {
        "Traveller: \(self.board), North \(self.rankingNumber[.north] ?? 0) South \(self.rankingNumber[.south] ?? 0) East \(self.rankingNumber[.east] ?? 0) West \(self.rankingNumber[.west] ?? 0)of Section \(self.section) of Scorecard: \(MasterData.shared.scorecard(id: self.scorecardId)?.desc ?? "")"
    }
    public override var debugDescription: String { self.description }
}
