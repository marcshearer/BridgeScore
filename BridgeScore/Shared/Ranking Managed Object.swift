//
//  Ranking Managed Object.swift
//  BridgeScore
//
//  Created by Marc Shearer on 24/03/2022.
//


import CoreData

@objc(RankingMO)
public class RankingMO: NSManagedObject, ManagedObject, Identifiable {

    public static let tableName = "Ranking"
    
    public var id: (UUID, Int, Int, Int) { (self.scorecardId, self.session, self.section, self.number) }
    @NSManaged public var scorecardId: UUID
    @NSManaged public var session16: Int16
    @NSManaged public var section16: Int16
    @NSManaged public var number16: Int16
    @NSManaged public var ranking16: Int16
    @NSManaged public var score: Float
    @NSManaged public var nsXImps: Float
    @NSManaged public var ewXImps: Float
    @NSManaged public var points: Float
    @NSManaged public var north: String
    @NSManaged public var south: String
    @NSManaged public var east: String
    @NSManaged public var west: String
    @NSManaged public var way16: Int16
    @NSManaged public var tie: Bool

    convenience init() {
        self.init(context: CoreData.context)
    }
    
    public var session: Int {
        get { Int(self.session16) }
        set { self.session16 = Int16(newValue) }
    }
    
    public var section: Int {
        get { Int(self.section16) }
        set { self.section16 = Int16(newValue) }
    }
    
    public var way: Pair {
        get { Pair(rawValue: Int(way16)) ?? .unknown }
        set { self.way16 = Int16(newValue.rawValue) }
    }
    
    public var number: Int {
        get { Int(self.number16) }
        set { self.number16 = Int16(newValue) }
    }
    
    public var ranking: Int {
        get { Int(self.ranking16) }
        set { self.ranking16 = Int16(newValue) }
    }
    
    public var players: [Seat: String] {
        get {
            var result: [Seat:String] = [:]
            if north != "" { result[.north] = north }
            if south != "" { result[.south] = south }
            if east != "" { result[.east] = east }
            if west != "" { result[.west] = west }
            return result
        }
        set {
            if let value = newValue[.north] {
                north = value
            } else {
                north = ""
            }
            if let value = newValue[.south] {
                south = value
            } else {
                south = ""
            }
            if let value = newValue[.east] {
                east = value
           } else {
                east = ""
            }
            if let value = newValue[.west] {
                west = value
            } else {
                west = ""
            }
        }
    }
    
    public var xImps: [Pair: Float] {
        get {
            var result: [Pair:Float] = [:]
            result[.ns] = nsXImps
            result[.ew] = ewXImps
            return result
        }
        set {
            nsXImps = newValue[.ns] ?? 0
            ewXImps = newValue[.ew] ?? 0
        }
    }

    public override var description: String {
        return "Scorecard: \(MasterData.shared.scorecard(id: self.scorecardId)?.desc ?? ""), Table: \(session) Section: \(section), Number: \(number)"
    }
    
    public override var debugDescription: String { self.description }
}
