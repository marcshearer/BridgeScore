//
//  Location Managed Object.swift
//  BridgeScore
//
//  Created by Marc Shearer on 21/01/2022.
//

import CoreData

@objc(LocationMO)
public class LocationMO: NSManagedObject, ManagedObject, Identifiable {

    public static let tableName = "Location"
    
    public var id: UUID { self.locationId }
    @NSManaged public var locationId: UUID
    @NSManaged public var sequence16: Int16
    @NSManaged public var name: String
    @NSManaged public var retired: Bool

    convenience init() {
        self.init(context: CoreData.context)
        self.locationId = UUID()
    }
    
    public var sequence: Int {
        get { Int(self.sequence16) }
        set { self.sequence16 = Int16(newValue)}
    }
    
    public override var description: String {
        "Location: \(self.name)"
    }
    public override var debugDescription: String { self.description }

}
