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
    
    public var id: (UUID, Int, Int, Int) { (self.scorecardId, self.table, self.section, self.number) }
    @NSManaged public var scorecardId: UUID
    @NSManaged public var table16: Int16
    @NSManaged public var section16: Int16
    @NSManaged public var number16: Int16
    @NSManaged public var ranking16: Int16
    @NSManaged public var score: Float
    @NSManaged public var points: Float
    
    convenience init() {
        self.init(context: CoreData.context)
    }
    
    public var table: Int {
        get { Int(self.table16) }
        set { self.table16 = Int16(newValue) }
    }
    
    public var section: Int {
        get { Int(self.section16) }
        set { self.section16 = Int16(newValue) }
    }
    
    public var number: Int {
        get { Int(self.number16) }
        set { self.number16 = Int16(newValue) }
    }
    
    public var ranking: Int {
        get { Int(self.ranking16) }
        set { self.ranking16 = Int16(newValue) }
    }
    
    public override var description: String {
        return "Scorecard: \(MasterData.shared.scorecard(id: self.scorecardId)?.desc ?? ""), Table: \(table) Section: \(section), Number: \(number)"
    }
    public override var debugDescription: String { self.description }
}
