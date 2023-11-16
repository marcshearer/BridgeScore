    //
    //  Ranking Table Managed Object.swift
    //  BridgeScore
    //
    //  Created by Marc Shearer on 15/11/2023.
    //

    import CoreData

    @objc(RankingTableMO)
    public class RankingTableMO: NSManagedObject, ManagedObject, Identifiable {

        public static let tableName = "RankingTable"
        
        public var id: (UUID, Int) { (self.scorecardId, self.table) }
        @NSManaged public var scorecardId: UUID
        @NSManaged public var number16: Int16
        @NSManaged public var section16: Int16
        @NSManaged public var way16: Int16
        @NSManaged public var table16: Int16
        @NSManaged public var nsScoreValue: Float
        @NSManaged public var nsScoreEntered: Bool
        
        convenience init() {
            self.init(context: CoreData.context)
        }
        
        public var number: Int {
            get { Int(self.number16) }
            set { self.number16 = Int16(newValue)}
        }
        
        public var section: Int {
            get { Int(self.section16) }
            set { self.section16 = Int16(newValue)}
        }
        
        public var way: Pair {
            get { Pair(rawValue: Int(way16)) ?? .unknown }
            set { self.way16 = Int16(newValue.rawValue) }
        }
               
        public var table: Int {
            get { Int(self.table16) }
            set { self.table16 = Int16(newValue)}
        }
        
        public var nsScore: Float? {
            get { nsScoreEntered ? self.nsScoreValue : nil}
            set {
                if let newValue = newValue {
                    self.nsScoreValue = newValue
                    self.nsScoreEntered = true
                } else {
                    self.nsScoreValue = 0
                    self.nsScoreEntered = false
                }
            }
        }
        
        public override var description: String {
            "Ranking Table: \(self.table) for \(self.number) of Scorecard: \(MasterData.shared.scorecard(id: self.scorecardId)?.desc ?? "")"
        }
        public override var debugDescription: String { self.description }
    }
