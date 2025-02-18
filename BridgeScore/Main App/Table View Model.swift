//
//  Table View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 15/02/2022.
//

import Combine
import SwiftUI
import CoreData

public class TableViewModel : ObservableObject, Identifiable, CustomDebugStringConvertible {

    // Properties in core data model
    @Published private(set) var scorecard: ScorecardViewModel
    @Published public var table: Int
    @Published public var sitting: Seat = .unknown
    @Published public var score: Float?
    @Published public var versus: String = ""
    @Published public var partner: String = ""
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var tableMO: TableMO?
    
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = true
    
    public var session: Int {
        get { ((table - 1) / scorecard.tablesSession) + 1 }
    }
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.tableMO {
            if self.scorecard.scorecardId != mo.scorecardId ||
                self.table != mo.table ||
                self.sitting != mo.sitting ||
                self.score != mo.score ||
                self.versus != mo.versus ||
                self.partner != mo.partner {
                result = true
            }
        } else {
            result = true
        }
        return result
    }
    
    public init(scorecard: ScorecardViewModel, table: Int) {
        self.scorecard = scorecard
        self.table = table
        self.setupMappings()
    }
    
    public convenience init(scorecard: ScorecardViewModel, tableMO: TableMO) {
        self.init(scorecard: scorecard, table: tableMO.table)
        self.tableMO = tableMO
        self.revert()
    }
        
    private func setupMappings() {
    }
    
    private func revert() {
        if let mo = self.tableMO {
            if let scorecard = MasterData.shared.scorecard(id: mo.scorecardId) {
                self.scorecard = scorecard
            }
            self.table = mo.table
            self.sitting = mo.sitting
            self.score = mo.score
            self.versus = mo.versus
            self.partner = mo.partner
        }
    }
    
    public func updateMO() {
        if let mo = tableMO {
            mo.scorecardId = scorecard.scorecardId
            mo.table = table
            mo.sitting = sitting
            mo.score = score
            mo.versus = versus
            mo.partner = partner
        } else {
            fatalError("No managed object")
        }
    }
    
    public func save() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.save(table: self)
        }
    }
    
    public func insert() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.insert(table: self)
        }
    }
    
    public func remove() {
        if Scorecard.current.match(scorecard: self.scorecard) {
            Scorecard.current.remove(table: self)
        }
    }
    
    public var isNew: Bool {
        return self.tableMO == nil
    }
    
    public var hasData: Bool {
        return self.sitting != .unknown ||
        (self.score != nil && scorecard.manualTotals) ||
        self.versus != ""
    }
    
    public var boards: [BoardViewModel] {
        assert(self.scorecard == Scorecard.current.scorecard, "Only valid when this scorecard is current")
        var result: [BoardViewModel] = []
        for tableBoard in 1...Scorecard.current.scorecard!.boardsTable {
            let boardIndex = ((table - 1) * scorecard.boardsTable) + tableBoard
            result.append(Scorecard.current.boards[boardIndex]!)
        }
        return result
    }
    
    public var scoredBoards: Int {
        return boards.filter({$0.score != nil}).count
    }
    
    public var players: [Seat:String] {
        var result: [Seat:String] = [:]
        if let scorer = scorecard.scorer {
            let boardIndex = ((table - 1) * scorecard.boardsTable) + 1
            let rankings = Scorecard.current.rankings(session: (scorecard.isMultiSession ? session : nil), player: (bboName: scorer.bboName.lowercased(), name: scorer.name))
            if rankings.count == 1 {
                let myRanking = rankings.first!
                if let myTraveller = Scorecard.current.traveller(board: boardIndex, seat: sitting, rankingNumber: myRanking.number, section: myRanking.section) {
                    for seat in Seat.validCases {
                        result[seat] = myTraveller.ranking(seat: seat)?.players[seat]
                    }
                }
            }
        }
        return result
    }
    
    public func score(ranking: RankingViewModel, seats: [Seat]) -> Float? {
        var tableTotal: Float? = nil
        var tableScore: Float? = nil
        var boards: Int = 0
        if let rankingTable = Scorecard.current.rankingTableList.first(where: {$0.number == ranking.number && $0.section == ranking.section && (ranking.way == .unknown || $0.way == ranking.way) && $0.table == table}), let score = rankingTable.nsScore {
            tableScore = score
        }
        if tableScore == nil {
            for tableBoard in 1...scorecard.boardsTable {
                let boardIndex = ((table - 1) * scorecard.boardsTable) + tableBoard
                for seat in seats {
                    if let traveller = Scorecard.current.traveller(board: boardIndex, seat: seat, rankingNumber: ranking.number, section: ranking.section) {
                        tableTotal = (tableTotal ?? 0) + (seat.pair == .ns ? traveller.nsScore : scorecard.type.invertScore(score: traveller.nsScore))
                        boards += 1
                    }
                }
            }
            let type = scorecard.type
            tableScore = (tableTotal == nil ? nil : type.tableAggregate.aggregate(total: tableTotal!, count: boards, boards: boards, places: type.tablePlaces, boardScoreType: type.boardScoreType) ?? 0)
        }
        return tableScore
    }
    
    public var description: String {
        return "Scorecard: \(scorecard.desc), Match: \(table) Table: \(table)"
    }
    
    public var debugDescription: String { self.description }
}
