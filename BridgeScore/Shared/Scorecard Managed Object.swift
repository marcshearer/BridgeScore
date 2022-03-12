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
    @NSManaged public var partnerId: UUID!
    @NSManaged public var boards16: Int16
    @NSManaged public var boardsTable16: Int16
    @NSManaged public var type16: Int16
    @NSManaged public var manualTotals: Bool
    @NSManaged public var resetNumbers: Bool
    @NSManaged public var scoreValue: Float
    @NSManaged public var scoreEntered: Bool
    @NSManaged public var maxScoreValue: Float
    @NSManaged public var maxScoreEntered: Bool
    @NSManaged public var position16: Int16
    @NSManaged public var entry16: Int16
    @NSManaged public var drawingData: Data
    @NSManaged public var drawingWidthFloat: Float
    
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
    
    public var position: Int {
        get { Int(self.position16) }
        set { self.position16 = Int16(newValue)}
    }
    
    public var entry: Int {
        get { Int(self.entry16) }
        set { self.entry16 = Int16(newValue)}
    }
    
    public var type: Type {
        get { Type(rawValue: Int(type16)) ?? .percent }
        set { self.type16 = Int16(newValue.rawValue) }
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
    
    public var drawingWidth: CGFloat {
        get { CGFloat(self.drawingWidthFloat) }
        set { self.drawingWidthFloat = Float(newValue)}
    }
    
    public var drawing: PKDrawing {
        get { (try? PKDrawing(data: self.drawingData)) ?? PKDrawing() }
        set { self.drawingData = newValue.dataRepresentation() }
    }
    
    public override var description: String {
        "Scorecard: \(self.desc)"
    }
    public override var debugDescription: String { self.description }
}
