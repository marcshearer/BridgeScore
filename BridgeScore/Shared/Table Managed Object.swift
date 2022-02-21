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
    @NSManaged public var score: Float
    @NSManaged public var versus: String
    @NSManaged public var sitting16: Int16
    
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
}
