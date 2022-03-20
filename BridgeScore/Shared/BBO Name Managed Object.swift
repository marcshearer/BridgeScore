//
//  BBOName Managed Object.swift
//  BridgeScore
//
//  Created by Marc Shearer on 16/03/2022.
//

import CoreData

@objc(BBONameMO)
public class BBONameMO: NSManagedObject, ManagedObject, Identifiable {

    public static let tableName = "BBOName"
    
    public var id: String { self.bboName }
    @NSManaged public var bboName: String
    @NSManaged public var name: String

    convenience init() {
        self.init(context: CoreData.context)
    }
    
    public override var description: String {
        "BBOName: \(self.name)"
    }
    public override var debugDescription: String { self.description }
}
