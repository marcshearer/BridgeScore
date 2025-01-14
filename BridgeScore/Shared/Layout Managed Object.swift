//
//  Layout Managed Object.swift
//  BridgeScore
//
//  Created by Marc Shearer on 21/01/2022.
//

import CoreData

@objc(LayoutMO)
public class LayoutMO: NSManagedObject, ManagedObject, Identifiable {

    public static let tableName = "Layout"
    
    public var id: UUID { self.layoutId }
    @NSManaged public var layoutId: UUID
    @NSManaged public var sequence16: Int16
    @NSManaged public var desc: String
    @NSManaged public var locationId: UUID
    @NSManaged public var scorecardDesc: String
    @NSManaged public var partnerId: UUID
    @NSManaged public var boards16: Int16
    @NSManaged public var boardsTable16: Int16
    @NSManaged public var type16: Int16
    @NSManaged public var manualTotals: Bool
    @NSManaged public var sessions16: Int16
    @NSManaged public var resetNumbers: Bool
    @NSManaged public var regularDay16: Int16
    
    public convenience init() {
        self.init(context: CoreData.context)
        self.layoutId = UUID()
        self.type = .percent
    }
    
    public var sequence: Int {
        get { Int(self.sequence16) }
        set { self.sequence16 = Int16(newValue)}
    }
    
    public var boards: Int {
        get { Int(self.boards16) }
        set { self.boards16 = Int16(newValue)}
    }
    
    public var boardsTable: Int {
        get { Int(self.boardsTable16) }
        set { self.boardsTable16 = Int16(newValue)}
    }
    
    public var sessions: Int {
        get { Int(self.sessions16) }
        set { self.sessions16 = Int16(newValue)}
    }
        
    public var type: ScorecardType {
        get { ScorecardType(rawValue: Int(type16)) ?? .percent }
        set { self.type16 = Int16(newValue.rawValue) }
    }
    
    public var regularDay: RegularDay {
        get { RegularDay(rawValue: Int(regularDay16)) ?? .none }
        set { self.regularDay16 = Int16(newValue.rawValue) }
    }
    
    public override var description: String {
        "Layout: \(self.desc)"
    }
    public override var debugDescription: String { self.description }
}
