//
//  Player Managed Object.swift
//  BridgeScore
//
//  Created by Marc Shearer on 21/01/2022.
//

import CoreData

@objc(PlayerMO)
public class PlayerMO: NSManagedObject, ManagedObject, Identifiable {

    public static let tableName = "Player"
    
    public var id: UUID { self.playerId }
    @NSManaged public var playerId: UUID
    @NSManaged public var sequence16: Int16
    @NSManaged public var name: String
    
    convenience init() {
        self.init(context: CoreData.context)
        self.playerId = UUID()
    }
    
    public var sequence: Int {
        get { Int(self.sequence16) }
        set { self.sequence16 = Int16(newValue)}
    }
    
}
