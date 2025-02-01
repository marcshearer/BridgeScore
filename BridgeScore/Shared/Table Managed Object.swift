//
//  Table Managed Object.swift
//  BridgeScore
//
//  Created by Marc Shearer on 21/01/2022.
//

import CoreData

@objc(TableMO)
public class TableMO: NSManagedObject, ManagedObject, Identifiable {

    public static let tableName = "Table"
    
    public var id: (UUID, Int) { (self.scorecardId, self.table) }
    @NSManaged public var scorecardId: UUID
    @NSManaged public var table16: Int16
    @NSManaged public var scoreValue: Float
    @NSManaged public var scoreEntered: Bool
    @NSManaged public var versus: String
    @NSManaged public var sitting16: Int16
    @NSManaged public var partner: String
    
    convenience init() {
        self.init(context: CoreData.context)
    }
    
    public var table: Int {
        get { Int(self.table16) }
        set { self.table16 = Int16(newValue)}
    }
           
    public var sitting: Seat {
        get { Seat(rawValue: Int(sitting16)) ?? .unknown }
        set { self.sitting16 = Int16(newValue.rawValue) }
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
    
#if !widget
    public override var description: String {
        "Table: \(self.table) of Scorecard: \(MasterData.shared.scorecard(id: self.scorecardId)?.desc ?? "")"
    }
    public override var debugDescription: String { self.description }
#endif
}
