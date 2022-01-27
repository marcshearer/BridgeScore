//
//  Board Managed Object.swift
//  BridgeScore
//
//  Created by Marc Shearer on 21/01/2022.
//

import CoreData

@objc(BoardMO)
public class BoardMO: NSManagedObject, ManagedObject, Identifiable {

    public static let tableName = "Board"
    
    public var id: (UUID, Int, Int) { (self.scorecardId, self.match, self.board) }
    @NSManaged public var scorecardId: UUID
    @NSManaged public var match16: Int16
    @NSManaged public var board16: Int16
    @NSManaged public var contract: String
    @NSManaged public var declarer16: Int16
    @NSManaged public var made16: Int16
    @NSManaged public var score: Float
    @NSManaged public var comment: String
    @NSManaged public var responsible16: Int16
    @NSManaged public var versus: String
    
    convenience init() {
        self.init(context: CoreData.context)
        self.scorecardId = scorecardId
        self.board = board
    }
    
    public var match: Int {
        get { Int(self.match16) }
        set { self.match16 = Int16(newValue)}
    }
    
    public var board: Int {
        get { Int(self.board16) }
        set { self.board16 = Int16(newValue)}
    }
    
    public var made: Int {
        get { Int(self.made16) }
        set { self.made16 = Int16(newValue)}
    }
    
    public var declarer: Position {
        get { Position(rawValue: Int(declarer16)) ?? .scorer }
        set { self.declarer16 = Int16(newValue.rawValue) }
    }
    
    public var responsible: Position {
        get { Position(rawValue: Int(responsible16)) ?? .scorer }
        set { self.responsible16 = Int16(newValue.rawValue) }
    }

}
