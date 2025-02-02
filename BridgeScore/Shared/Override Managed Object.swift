//
//  Override Tricks Managed Object.swift
//  BridgeScore
//
//  Created by Marc Shearer on 05/10/2023.
//

import CoreData

@objc(OverrideMO)
public class OverrideMO: NSManagedObject, ManagedObject, Identifiable {
    
    public static let tableName = "Override"
    
    public var id: (UUID, Int) { (self.scorecardId, self.boardIndex) }
    @NSManaged public var scorecardId: UUID
    @NSManaged public var board16: Int16 // TODO: - Remove when converted
    @NSManaged public var boardIndex16: Int16
    @NSManaged public var declarer16: Int16
    @NSManaged public var suit16: Int16
    @NSManaged public var made16: Int16
    @NSManaged public var madeEntered: Bool
    
    convenience init() {
        self.init(context: CoreData.context)
    }
    
    public var boardIndex: Int {
        get { Int(self.boardIndex16) }
        set { self.boardIndex16 = Int16(newValue)}
    }
    
    public var declarer: Pair {
        get { Pair(rawValue: Int(declarer16)) ?? .unknown }
        set { self.declarer16 = Int16(newValue.rawValue) }
    }
    
    public var made: Int? {
        get { self.madeEntered ? Int(self.made16) : nil }
        set {
            self.made16 = Int16(newValue ?? 0)
            self.madeEntered = newValue != nil
        }
    }
    
    public var suit: Suit {
        get { Suit(rawValue: Int(suit16)) ?? .blank }
        set { self.suit16 = Int16(newValue.rawValue) }
    }

    public override var description: String {
        "Override Tricks: Board: \(self.boardIndex) of Scorecard: \(MasterData.shared.scorecard(id: self.scorecardId)?.desc ?? ""), Declarer: \(self.declarer.string) ,Suit: \(self.suit.string)"
    }

    public override var debugDescription: String { self.description }
}
