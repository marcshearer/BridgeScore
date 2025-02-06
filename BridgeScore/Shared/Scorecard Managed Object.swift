//
//  Scorecard Managed Object.swift
//  BridgeScore
//
//  Created by Marc Shearer on 21/01/2022.
//

import CoreData
import CoreGraphics
import PencilKit

@objc(ScorecardMO)
public class ScorecardMO: NSManagedObject, ManagedObject, Identifiable {

    public static let tableName = "Scorecard"
    
    public var id: UUID { self.scorecardId }
    @NSManaged public var scorecardId: UUID
    @NSManaged public var date: Date
    @NSManaged public var locationId: UUID!
    @NSManaged public var desc: String
    @NSManaged public var comment: String
    @NSManaged public var sequence16: Int16
    @NSManaged public var scorerId: UUID!
    @NSManaged public var partnerId: UUID!
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
    @NSManaged public var scoreValue: Float
    @NSManaged public var scoreEntered: Bool
    @NSManaged public var maxScoreValue: Float
    @NSManaged public var maxScoreEntered: Bool
    @NSManaged public var position16: Int16
    @NSManaged public var entry16: Int16
    @NSManaged public var importSource16: Int16
    @NSManaged public var importNext16: Int16
    
    convenience init() {
        self.init(context: CoreData.context)
        self.scorecardId = UUID()
        self.date = Date(timeIntervalSinceReferenceDate: 0)
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
    
    public var position: Int {
        get { Int(self.position16) }
        set { self.position16 = Int16(newValue)}
    }
    
    public var sequence: Int {
        get { Int(self.sequence16) }
        set { self.sequence16 = Int16(newValue)}
    }
    
    public var entry: Int {
        get { Int(self.entry16) }
        set { self.entry16 = Int16(newValue)}
    }
    
#if !widget
    public var importSource: ImportSource {
        get { ImportSource(rawValue: Int(self.importSource16)) ?? .none }
        set { self.importSource16 = Int16(newValue.rawValue)}
    }
#endif
    
    public var importNext: Int {
        get { Int(self.importNext16) }
        set { self.importNext16 = Int16(newValue)}
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
    
    public var maxScore: Float? {
        get { maxScoreEntered ? self.maxScoreValue : nil}
        set {
            if let newValue = newValue {
                self.maxScoreValue = newValue
                self.maxScoreEntered = true
            } else {
                self.maxScoreValue = 0
                self.maxScoreEntered = false
            }
        }
    }
    
    public override var description: String {
        "Scorecard: \(self.desc)"
    }
    public override var debugDescription: String { self.description }
}
