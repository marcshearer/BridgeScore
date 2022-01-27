//
//  Scorecard Managed Object.swift
//  BridgeScore
//
//  Created by Marc Shearer on 21/01/2022.
//

import CoreData

@objc(ScorecardMO)
public class ScorecardMO: NSManagedObject, ManagedObject, Identifiable {

    public static let tableName = "Scorecard"
    
    public var id: UUID { self.scorecardId }
    @NSManaged public var scorecardId: UUID
    @NSManaged public var date: Date
    @NSManaged public var locationId: UUID?
    @NSManaged public var desc: String
    @NSManaged public var comment: String
    @NSManaged public var partnerId: UUID?
    @NSManaged public var boards16: Int16
    @NSManaged public var boardsTable16: Int16
    @NSManaged public var type16: Int16
    @NSManaged public var tableTotal: Bool
    @NSManaged public var totalScore: Float
    
    convenience init() {
        self.init(context: CoreData.context)
        self.scorecardId = UUID()
    }
    
    public var boards: Int {
        get { Int(self.boards16) }
        set { self.boards16 = Int16(newValue)}
    }
    
    public var boardsTable: Int {
        get { Int(self.boardsTable16) }
        set { self.boardsTable16 = Int16(newValue)}
    }
    
    public var type: Type {
        get { Type(rawValue: Int(type16)) ?? .percent }
        set { self.type16 = Int16(newValue.rawValue) }
    }
}
