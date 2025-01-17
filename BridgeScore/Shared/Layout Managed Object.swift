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
    @NSManaged public var eventType16: Int16
    @NSManaged public var boardScoreType16: Int16
    @NSManaged public var boardScoreVpType16: Int16
    @NSManaged public var aggregateType16: Int16
    @NSManaged public var aggregateVpType16: Int16
    @NSManaged public var headToHead: Bool
    @NSManaged public var manualTotals: Bool
    @NSManaged public var sessions16: Int16
    @NSManaged public var resetNumbers: Bool
    @NSManaged public var regularDay16: Int16
    @NSManaged public var displayDetail: Bool
    
    public convenience init() {
        self.init(context: CoreData.context)
        self.layoutId = UUID()
        self.type = ScorecardType()
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
        get {
            let eventType = EventType(rawValue: Int(self.eventType16)) ?? .unknown
            let boardScoreVpType = VpType(rawValue: Int(boardScoreVpType16)) ?? .unknown
            let boardScoreType = ScoreType(rawValue: Int(self.boardScoreType16), vpType: boardScoreVpType) ?? .unknown
            let aggregateVpType = VpType(rawValue: Int(aggregateVpType16)) ?? .unknown
            let aggregateType = AggregateType(rawValue: Int(self.aggregateType16), vpType: aggregateVpType) ?? .unknown
            return ScorecardType(eventType: eventType, boardScoreType: boardScoreType, aggregateType: aggregateType, headToHead: headToHead)
        }
        set {
            eventType16 = Int16(newValue.eventType.rawValue)
            boardScoreType16 = Int16(newValue.boardScoreType.rawValue)
            if case let .vp(boardScoreVpType) = newValue.boardScoreType {
                boardScoreVpType16 = Int16(boardScoreVpType.rawValue)
            }
            aggregateType16 = Int16(newValue.aggregateType.rawValue)
            if case let .vp(aggregateVpType) = newValue.aggregateType {
                aggregateVpType16 = Int16(aggregateVpType.rawValue)
            }
            headToHead = newValue.headToHead
        }
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
