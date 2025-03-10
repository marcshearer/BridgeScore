//
//  Scorecard.swift
//  BridgeScore
//
//  Created by Marc Shearer on 23/01/2022.
//

import UIKit

enum ScorecardItemType {
    case table
    case board
}

class Scorecard {
    
    public static let current = Scorecard()
    
    @Published private(set) var scorecard: ScorecardViewModel?
    @Published private(set) var boards: [Int:BoardViewModel] = [:]   // Board number
    @Published private(set) var tables: [Int:TableViewModel] = [:]   // Table number
    @Published private(set) var rankingList: [RankingViewModel] = []
    @Published private(set) var rankingTableList: [RankingTableViewModel] = []
    @Published private(set) var travellerList: [TravellerViewModel] = []
    @Published private(set) var analysisList: [Int:[Pair:Analysis]] = [:] // Board number, Sitting
    @Published private(set) var overrideList: [Int:AnalysisOverride] = [:] // Board number
    
    public func rankings(session: Int? = nil, section: Int? = nil, way: Pair? = nil, number: Int? = nil, player: (bboName: String, name: String)? = nil) -> [RankingViewModel] {
        var result = rankingList
        if let session = session {
            if scorecard?.isMultiSession ?? false {
                result = result.filter({$0.session == session})
            }
        }
        if let section = section {
            result = result.filter({$0.section == section})
        }
        if let number = number {
            result = result.filter({$0.number == number})
        }
        if let way = way {
            result = result.filter({$0.way == way})
        }
        if let player = player {
            result = result.filter({$0.players.contains(where: {$0.value.lowercased() == player.bboName.lowercased() || $0.value.lowercased() == player.name.lowercased()})})
        }
        return result
    }
    
    public func ranking(session: Int, section: Int, way: Pair, number: Int) -> RankingViewModel? {
        let resultList = rankingList.filter({(!(scorecard?.isMultiSession ?? false) || $0.session == session) && $0.section == section && ($0.way == .unknown || $0.way == way) && $0.number == number})
        return resultList.count == 1 ? resultList.first : nil
    }
    
    public func rankingTable(number: Int, section: Int, way: Pair, table: Int) -> RankingTableViewModel? {
        let resultList = rankingTableList.filter({$0.table == table && $0.section == section && ($0.way == .unknown || $0.way == way) && $0.number == number})
        return resultList.count == 1 ? resultList.first : nil
    }
    
    public func travellers(board: Int? = nil, seat: Seat? = nil, rankingNumber: Int? = nil, section: Int? = nil, session: Int? = nil) -> [TravellerViewModel] {
        var result = travellerList
        if let board = board {
            result = result.filter({$0.boardIndex == board})
        }
        if let session = session {
            result = result.filter({Scorecard.current.boards[$0.boardIndex]?.session == session})
        }
        if let seat = seat {
            if let section = section {
                result = result.filter({$0.section[seat] == section})
            }
            if let rankingNumber = rankingNumber {
                result = result.filter({$0.rankingNumber[seat] == rankingNumber})
            }
        }
        return result
    }
    
    public func traveller(board: Int, seat: Seat, rankingNumber: Int, section: Int) -> TravellerViewModel? {
        let resultList = travellerList.filter{$0.boardIndex == board && $0.rankingNumber[seat] == rankingNumber && $0.section[seat] == section}
        return resultList.count == 1 ? resultList.first : nil
    }
    
    public func analysis(board: BoardViewModel, traveller: TravellerViewModel, sitting: Seat) -> Analysis {
        if let analysis = analysisList[board.boardIndex]?[sitting.pair] {
            return analysis
        } else {
            var override = overrideList[board.boardIndex]
            if override == nil {
                override = AnalysisOverride(board: board)
                overrideList[board.boardIndex] = override
            }
            let analysis = Analysis(override: override!, board: board, traveller: traveller, sitting: sitting.pair)
            if analysisList[board.boardIndex] == nil {
                analysisList[board.boardIndex] = [:]
            }
            analysisList[analysis.board.boardIndex]![analysis.sitting] = analysis
            return analysis
        }
    }
    
    public var isImported: Bool {
        !rankingList.isEmpty || !travellerList.isEmpty
    }
    
    public var isSensitive: Bool {
        return boards.compactMap{$0.value}.firstIndex(where: {$0.comment != "" || $0.responsible != .unknown }) != nil
    }
    
    public var hasData: Bool {
        return (boards.compactMap{$0.value}.firstIndex(where: {$0.hasData}) != nil) || (tables.compactMap{$0.value}.firstIndex(where: {$0.hasData}) != nil)
    }
    
    public func load(scorecard: ScorecardViewModel) {
        let scorecardFilter = NSPredicate(format: "scorecardId = %@", scorecard.scorecardId as NSUUID)
        
        // Load boards
        let boardMOs = CoreData.fetch(from: BoardMO.tableName, filter: scorecardFilter) as! [BoardMO]
        
        boards = [:]
        for boardMO in boardMOs {
            boards[boardMO.boardIndex] = BoardViewModel(scorecard: scorecard, boardMO: boardMO)
        }
        
        // Load double dummies
        let doubleDummyMOs = CoreData.fetch(from: DoubleDummyMO.tableName, filter: scorecardFilter) as! [DoubleDummyMO]
        
        for doubleDummyMO in doubleDummyMOs {
            if let board = boards[doubleDummyMO.boardIndex] {
                // Add to double dummy MO dicionary
                if board.doubleDummy[doubleDummyMO.declarer] == nil {
                    board.doubleDummy[doubleDummyMO.declarer] = [:]
                }
                board.doubleDummy[doubleDummyMO.declarer]![doubleDummyMO.suit] = DoubleDummyViewModel(scorecard: scorecard, doubleDummyMO: doubleDummyMO)
                // Add to double dummy dictionary
                if board.doubleDummyMO[doubleDummyMO.declarer] == nil {
                    board.doubleDummyMO[doubleDummyMO.declarer] = [:]
                }
                board.doubleDummyMO[doubleDummyMO.declarer]![doubleDummyMO.suit] = doubleDummyMO
            }
        }
        
        // Load override tricks
        let overrideMOs = CoreData.fetch(from: OverrideMO.tableName, filter: scorecardFilter) as! [OverrideMO]
        
        for overrideMO in overrideMOs {
            if let board = boards[overrideMO.boardIndex] {
                // Add to override tricks MO dicionary
                if board.override[overrideMO.declarer] == nil {
                    board.override[overrideMO.declarer] = [:]
                }
                board.override[overrideMO.declarer]![overrideMO.suit] = OverrideViewModel(scorecard: scorecard, overrideMO: overrideMO)
                // Add to override tricks dictionary
                if board.overrideMO[overrideMO.declarer] == nil {
                    board.overrideMO[overrideMO.declarer] = [:]
                }
                board.overrideMO[overrideMO.declarer]![overrideMO.suit] = overrideMO
            }
        }
        
        // Load tables
        let tableMOs = CoreData.fetch(from: TableMO.tableName, filter: scorecardFilter) as! [TableMO]
        
        tables = [:]
        for tableMO in tableMOs {
            tables[tableMO.table] = TableViewModel(scorecard: scorecard, tableMO: tableMO)
        }
        
        // Load rankings
        let rankingMOs = CoreData.fetch(from: RankingMO.tableName, filter: scorecardFilter) as! [RankingMO]
        
        rankingList = []
        for rankingMO in rankingMOs {
            rankingList.append(RankingViewModel(scorecard: scorecard, rankingMO: rankingMO))
        }
        
        // Load ranking table MOs
        let rankingTableMOs = CoreData.fetch(from: RankingTableMO.tableName, filter: scorecardFilter) as! [RankingTableMO]
        
        rankingTableList = []
        for rankingTableMO in rankingTableMOs {
            rankingTableList.append(RankingTableViewModel(scorecard: scorecard, rankingTableMO: rankingTableMO))
        }
        
        // Load travellers
        let travellerMOs = CoreData.fetch(from: TravellerMO.tableName, filter: scorecardFilter) as! [TravellerMO]
        
        travellerList = []
        for travellerMO in travellerMOs {
            travellerList.append(TravellerViewModel(scorecard: scorecard, travellerMO: travellerMO))
        }
        
        // Empty analysis
        analysisList = [:]
        overrideList = [:]
        
        self.scorecard = scorecard
        addNew()
    }
    
    public func clear() {
        boards = [:]
        tables = [:]
        rankingList = []
        travellerList = []
        analysisList = [:]
        overrideList = [:]
        scorecard = nil
    }
    
    
    private var lastItemType: ScorecardItemType?
    private var lastItemNumber: Int?
    
    public func interimSave(itemType: ScorecardItemType? = nil, itemNumber: Int? = nil) {
        if itemType == nil || itemType != lastItemType || itemNumber != lastItemNumber {
            if let lastItemNumber = lastItemNumber {
                switch lastItemType {
                case .table:
                    if let table = tables[lastItemNumber] {
                        if table.isNew || table.changed {
                            save(table: table)
                        }
                    }
                case .board:
                    if let board = boards[lastItemNumber] {
                        if board.isNew || board.changed {
                            save(board: board)
                        }
                    }
                default:
                    break
                }
            }
            lastItemType = itemType
            lastItemNumber = itemNumber
        }
    }
    
    public func saveAll(scorecard: ScorecardViewModel) {
        
        assert(self.scorecard == scorecard, "Not the current scorecard")
        
        for (boardIndex, board) in boards {
            if boardIndex < 1 || boardIndex > scorecard.boards {
                    // Remove any boards no longer in bounds
                if board.isNew {
                        // Not yet in core data - just remove from array
                    boards[board.boardIndex] = nil
                } else {
                    remove(board: board)
                }
            } else if board.changed {
                    // Save any existing boards
                save(board: board)
            }
        }
        
        for (tableNumber, table) in tables {
            if tableNumber < 1 || tableNumber > scorecard.tables {
                    // Remove any tables no longer in bounds
                if table.isNew {
                    // Not yet in core data - just remove from array
                    tables[table.table] = nil
                } else {
                    remove(table: table)
                }
            } else if table.changed {
                // Save any existing tables
                save(table: table)
            }
        }
        
        for (ranking) in rankingList {
            // Save any existing rankings
            save(ranking: ranking)
        }
        
        var removeList = IndexSet()
        for (index, rankingTable) in rankingTableList.reversed().enumerated() {
            if rankingTable.table < 1 || rankingTable.table > scorecard.tables {
                // Remove any tables no longer in bounds
                if rankingTable.isNew {
                    // Not yet in core data - just remove from array
                    removeList.insert(index)
                } else {
                    remove(rankingTable: rankingTable)
                }
            } else if rankingTable.changed {
                // Save any existing ranking tables
                save(rankingTable: rankingTable)
            }
        }
        rankingTableList.remove(atOffsets: removeList)
        
        removeList = IndexSet()
        for (index, traveller) in travellerList.reversed().enumerated() {
            if traveller.boardIndex < 1 || traveller.boardIndex > scorecard.boards {
                // Remove any travellers no longer in bounds
                if traveller.isNew {
                    // Not yet in core data - just remove from array
                    removeList.insert(index)
                } else {
                    remove(traveller: traveller)
                }
            } else if traveller.changed {
                // Save any existing travellers
                save(traveller: traveller)
            }
        }
        travellerList.remove(atOffsets: removeList)
    }
    
    public func removeAll(scorecard: ScorecardViewModel) {
        
        assert(self.scorecard == scorecard, "Not the current scorecard")
        
        for (_, board) in boards {
            if !board.isNew {
                remove(board: board)
            }
        }
        
        removeRankings()
        
        removeRankingTables()
        
        for traveller in travellerList {
            if !traveller.isNew {
                remove(traveller: traveller)
            }
        }
        
        clear()
    }
    
    public func removeRankings(session: Int? = nil) {
        for ranking in rankings(session: session).reversed() {
            if !ranking.isNew {
                remove(ranking: ranking)
            }
        }
    }
    
    public func removeRankingTables(table: Int? = nil) {
        for rankingTable in rankingTableList.filter({table == nil || $0.table == table}).reversed() {
            if !rankingTable.isNew {
                remove(rankingTable: rankingTable)
            }
        }
    }
    
    public func removeTravellers(board: Int) {
        let travellers = travellers(board: board)
        for traveller in travellers.reversed() {
            if !traveller.isNew {
                remove(traveller: traveller)
            }
        }
    }
    
    public func removeDoubleDummy(board: Int) {
        
    }
    
    public func addNew() {
        if let scorecard = scorecard {
            // Fill in any gaps in boards
            for boardIndex in 1...scorecard.boards {
                if boards[boardIndex] == nil {
                    boards[boardIndex] = BoardViewModel(scorecard: scorecard, boardIndex: boardIndex)
                } else {
                    boards[boardIndex]?.session = Scorecard.defaultSession(scorecard: scorecard, boardIndex: boardIndex)
                    boards[boardIndex]?.boardNumber = Scorecard.defaultBoardNumber(scorecard: scorecard, boardIndex: boardIndex)
                }
            }
            
            // Fill in any gaps in tables
            for tableNumber in 1...scorecard.tables {
                if tables[tableNumber] == nil {
                    tables[tableNumber] = TableViewModel(scorecard: scorecard, table: tableNumber)
                }
            }
        }
    }
    
    public func match(scorecard: ScorecardViewModel) -> Bool {
        return (self.scorecard == scorecard)
    }
    
    public func clearImport() {
        scorecard?.importSource = .none
        scorecard?.importNext = 1
        removeRankings()
        for boardIndex in 1...(scorecard?.boards ?? 0) {
            removeTravellers(board: boardIndex)
            if let board = Scorecard.current.boards[boardIndex] {
                board.override = [:]
                board.save()
            }
        }
    }
    
    
    // MARK: - Boards (including Double Dummies) ================================================ -
    
    public func insert(board: BoardViewModel) {
        assert(board.scorecard == scorecard, "Board is not in current scorecard")
        assert(board.isNew, "Cannot insert a board which already has a managed object")
        assert(boards[board.boardIndex] == nil, "Board already exists and cannot be created")
        assert(board.doubleDummy.isEmpty, "Board double dummies already exist")
        assert(board.override.isEmpty, "Board override tricks already exist")
        CoreData.update(updateLogic: {
            // Add board MO
            board.boardMO = BoardMO()
            board.updateMO()
            // Add double dummy MOs
            board.forEachDoubleDummy { (declarer, suit, doubleDummy) in
                if board.doubleDummyMO[declarer] == nil {
                    board.doubleDummyMO[declarer] = [:]
                }
                let mo = DoubleDummyMO()
                doubleDummy.updateMO(mo)
                // Add to double dummy MO dictionary
                board.doubleDummyMO[declarer]![suit] = mo
            }
            // Add override tricks MOs
            board.forEachOverride { (declarer, suit, override) in
                if board.override[declarer] == nil {
                    board.override[declarer] = [:]
                }
                let mo = OverrideMO()
                override.updateMO(mo)
                // Add to double dummy MO dictionary
                board.overrideMO[declarer]![suit] = mo
            }
            // Add to board dictionary
            boards[board.boardIndex] = board
        })
    }
    
    public func remove(board: BoardViewModel) {
        assert(board.scorecard == scorecard, "Board is not in current scorecard")
        assert(!board.isNew, "Cannot remove a board which doesn't already have a managed object")
        assert(boards[board.boardIndex] != nil, "Board does not exist and cannot be deleted")
        CoreData.update(updateLogic: {
            // Delete board MO
            CoreData.context.delete(board.boardMO!)
            // Delete double dummy MOs
            board.forEachDoubleDummyMO { (declarer, suit, mo) in
                CoreData.context.delete(mo)
            }
            // Delete override tricks MOs
            board.forEachOverrideMO { (declarer, suit, mo) in
                CoreData.context.delete(mo)
            }
            // Remove from double dummy dictionaries
            board.doubleDummyMO = [:]
            board.doubleDummy = [:]
            // Remove from override tricks dictionaries
            board.overrideMO = [:]
            board.override = [:]
            // Remove from boards dictionary
            boards[board.boardIndex] = nil
        })
    }
    
    public func save(board: BoardViewModel) {
        assert(board.scorecard == scorecard, "Board is not in current scorecard")
        assert(boards[board.boardIndex] != nil, "Board does not exist and cannot be updated")
        if board.isNew {
            CoreData.update(updateLogic: {
                // Create board MO
                board.boardMO = BoardMO()
                board.updateMO()
                // Create any double dummy MOs
                board.forEachDoubleDummy { (declarer, suit, doubleDummy) in
                    let mo = DoubleDummyMO()
                    doubleDummy.updateMO(mo)
                    // Add to double dummy MO dictionary
                    if board.doubleDummyMO[declarer] == nil {
                        board.doubleDummyMO[declarer] = [:]
                    }
                    board.doubleDummyMO[declarer]![suit] = mo
                }
                // Create any override tricks MOs
                board.forEachOverride { (declarer, suit, override) in
                    let mo = OverrideMO()
                    override.updateMO(mo)
                    // Add to double dummy MO dictionary
                    if board.overrideMO[declarer] == nil {
                        board.overrideMO[declarer] = [:]
                    }
                    board.overrideMO[declarer]![suit] = mo
                }
            })
        } else if board.changed {
            CoreData.update(updateLogic: {
                // Update board MO
                board.updateMO()
                // Update double dummy MOs
                board.forEachDoubleDummy { (declarer, suit, doubleDummy) in
                    let mo = board.doubleDummyMO[declarer]?[suit] ?? DoubleDummyMO()
                    doubleDummy.updateMO(mo)
                    if board.doubleDummyMO[declarer] == nil {
                        board.doubleDummyMO[declarer] = [:]
                    }
                    board.doubleDummyMO[declarer]![suit] = mo
                }
                // Remove any double dummy MOs which aren't in view model
                board.forEachDoubleDummyMO { (declarer, suit, mo) in
                    if board.doubleDummy[declarer]?[suit] == nil {
                        CoreData.context.delete(mo)
                        board.doubleDummyMO[declarer]![suit] = nil
                    }
                }
                // Update override tricks MOs
                board.forEachOverride { (declarer, suit, override) in
                    let mo = board.overrideMO[declarer]?[suit] ?? OverrideMO()
                    override.updateMO(mo)
                    if board.overrideMO[declarer] == nil {
                        board.overrideMO[declarer] = [:]
                    }
                    board.overrideMO[declarer]![suit] = mo
                }
                // Remove any override tricks MOs which aren't in view model
                board.forEachOverrideMO { (declarer, suit, mo) in
                    if board.override[declarer]?[suit] == nil {
                        CoreData.context.delete(mo)
                        board.overrideMO[declarer]![suit] = nil
                    }
                }
            })
        }
    }
    
    // MARK: - Tables ======================================================================== -
    
    public func insert(table: TableViewModel) {
        assert(table.scorecard == scorecard, "Table is not in current scorecard")
        assert(table.isNew, "Cannot insert a table which already has a managed object")
        assert(tables[table.table] == nil, "Table already exists and cannot be created")
        CoreData.update(updateLogic: {
            table.tableMO = TableMO()
            table.updateMO()
            tables[table.table] = table
        })
    }
    
    public func remove(table: TableViewModel) {
        assert(table.scorecard == scorecard, "Table is not in current scorecard")
        assert(!table.isNew, "Cannot remove a table which doesn't already have a managed object")
        assert(tables[table.table] != nil, "Table does not exist and cannot be deleted")
        CoreData.update(updateLogic: {
            CoreData.context.delete(table.tableMO!)
            tables[table.table] = nil
        })
    }
    
    public func save(table: TableViewModel) {
        assert(table.scorecard == scorecard, "Table is not in current scorecard")
        assert(tables[table.table] != nil, "Table does not exist and cannot be updated")
        if table.isNew {
            CoreData.update(updateLogic: {
                table.tableMO = TableMO()
                table.updateMO()
            })
        } else if table.changed {
            CoreData.update(updateLogic: {
                table.updateMO()
            })
        }
    }
    
    // MARK: - Rankings ======================================================================== -
    
    public func insert(ranking: RankingViewModel) {
        assert(ranking.scorecard == scorecard, "Ranking is not in current scorecard")
        assert(ranking.isNew, "Cannot insert a ranking which already has a managed object")
        assert(self.ranking(session: ranking.session, section: ranking.section, way: ranking.way,  number: ranking.number) == nil, "Ranking already exists and cannot be created")
        CoreData.update(updateLogic: {
            ranking.rankingMO = RankingMO()
            ranking.updateMO()
            rankingList.append(ranking)
        })
    }
    
    public func remove(ranking: RankingViewModel) {
        assert(ranking.scorecard == scorecard, "Ranking is not in current scorecard")
        assert(!ranking.isNew, "Cannot remove a ranking which doesn't already have a managed object")
        assert(self.ranking(session: ranking.session, section: ranking.section, way: ranking.way, number: ranking.number) != nil, "Ranking does not exist and cannot be deleted")
        CoreData.update(updateLogic: {
            CoreData.context.delete(ranking.rankingMO!)
            rankingList.removeAll(where: {$0.session == ranking.session && $0.section == ranking.section && $0.way == ranking.way && $0.number == ranking.number})
        })
    }
    
    public func save(ranking: RankingViewModel) {
        assert(ranking.scorecard == scorecard, "Ranking is not in current scorecard")
        assert(self.ranking(session: ranking.session, section: ranking.section, way: ranking.way, number: ranking.number) != nil, "Ranking does not exist and cannot be updated")
        if ranking.isNew {
            CoreData.update(updateLogic: {
                ranking.rankingMO = RankingMO()
                ranking.updateMO()
            })
        } else if ranking.changed {
            CoreData.update(updateLogic: {
                ranking.updateMO()
            })
        }
    }
    
    // MARK: - Ranking Tables =================================================================== -
    
    public func insert(rankingTable: RankingTableViewModel) {
        assert(rankingTable.scorecard == scorecard, "Ranking table is not in current scorecard")
        assert(rankingTable.isNew, "Cannot insert a ranking table which already has a managed object")
        assert(self.rankingTable(number: rankingTable.number, section: rankingTable.section, way: rankingTable.way, table: rankingTable.table) == nil, "Ranking table already exists and cannot be created")
        CoreData.update(updateLogic: {
            rankingTable.rankingTableMO = RankingTableMO()
            rankingTable.updateMO()
            rankingTableList.append(rankingTable)
        })
    }
    
    public func remove(rankingTable: RankingTableViewModel) {
        assert(rankingTable.scorecard == scorecard, "Ranking table is not in current scorecard")
        assert(!rankingTable.isNew, "Cannot remove a ranking table which doesn't already have a managed object")
        assert(self.rankingTable(number: rankingTable.number, section: rankingTable.section, way: rankingTable.way, table: rankingTable.table) != nil, "Ranking table does not exist and cannot be deleted")
        CoreData.update(updateLogic: {
            CoreData.context.delete(rankingTable.rankingTableMO!)
            rankingTableList.removeAll(where: {$0.table == rankingTable.table && $0.section == rankingTable.section && $0.way == rankingTable.way && $0.number == rankingTable.number})
        })
    }
    
    public func save(rankingTable: RankingTableViewModel) {
        assert(rankingTable.scorecard == scorecard, "Ranking table is not in current scorecard")
        assert(self.rankingTable(number: rankingTable.number, section: rankingTable.section, way: rankingTable.way, table: rankingTable.table) != nil, "Ranking table does not exist and cannot be updated")
        if rankingTable.isNew {
            CoreData.update(updateLogic: {
                rankingTable.rankingTableMO = RankingTableMO()
                rankingTable.updateMO()
            })
        } else if rankingTable.changed {
            CoreData.update(updateLogic: {
                rankingTable.updateMO()
            })
        }
    }
    
    // MARK: - Travellers ======================================================================== -
    
    public func insert(traveller: TravellerViewModel) {
        assert(traveller.scorecard == scorecard, "Traveller is not in current scorecard")
        assert(traveller.isNew, "Cannot insert a traveller which already has a managed object")
        assert(self.traveller(board: traveller.boardIndex, seat: .north, rankingNumber: traveller.rankingNumber[.north]!, section: traveller.section[.north]!) == nil, "Traveller already exists and cannot be created")
        CoreData.update(updateLogic: {
            traveller.travellerMO = TravellerMO()
            traveller.updateMO()
            travellerList.append(traveller)
        })
    }
    
    public func remove(traveller: TravellerViewModel) {
        assert(traveller.scorecard == scorecard, "Traveller is not in current scorecard")
        assert(!traveller.isNew, "Cannot remove a traveller which doesn't already have a managed object")
        CoreData.update(updateLogic: {
            CoreData.context.delete(traveller.travellerMO!)
            travellerList.removeAll(where: {$0.boardIndex == traveller.boardIndex && $0.rankingNumber[.north] == traveller.rankingNumber[.north] && $0.section[.north] == traveller.section[.north]})
        })
    }
    
    public func save(traveller: TravellerViewModel) {
        assert(traveller.scorecard == scorecard, "Traveller is not in current scorecard")
        assert(self.traveller(board: traveller.boardIndex, seat: .north, rankingNumber: traveller.rankingNumber[.north]!, section: traveller.section[.north]!) != nil, "Traveller does not exist and cannot be updated")
        if traveller.isNew {
            CoreData.update(updateLogic: {
                traveller.travellerMO = TravellerMO()
                traveller.updateMO()
            })
        } else if traveller.changed {
            CoreData.update(updateLogic: {
                traveller.updateMO()
            })
        }
    }
    
    // MARK: - Utilities ======================================================================== -
    
    public static func defaultSession(scorecard: ScorecardViewModel, table: Int) -> Int {
        return scorecard.isMultiSession ? ((table - 1) / scorecard.tablesSession) + 1 : 1
    }
    
    public static func defaultSession(scorecard: ScorecardViewModel, boardIndex: Int) -> Int {
        let table = ((boardIndex - 1) / scorecard.boardsTable) + 1
        return defaultSession(scorecard: scorecard, table: table)
    }
    
    public static func defaultBoardNumber(scorecard: ScorecardViewModel, boardIndex: Int) -> Int {
        return (scorecard.isMultiSession && scorecard.resetNumbers) ? ((boardIndex - 1) % scorecard.boardsSession) + 1 : boardIndex
    }
        
    @discardableResult static public func updateScores(scorecard: ScorecardViewModel) -> Bool {
        var changed = false
        
        for tableNumber in 1...scorecard.tables {
            if Scorecard.updateTableScore(scorecard: scorecard, tableNumber: tableNumber) {
                changed = true
                Scorecard.current.tables[tableNumber]?.save()
            }
        }
        if Scorecard.updateTotalScore(scorecard: scorecard) {
            changed = true
        }
        return changed
    }
    
    @discardableResult static func updateTableScore(scorecard: ScorecardViewModel, tableNumber: Int) -> Bool {
        var changed = false
        let boards = scorecard.boardsTable
        var total: Float = 0
        var count: Int = 0
        if let table = Scorecard.current.tables[tableNumber] {
            // First check if any imported table scores since likely to be more precies
            var tableScore: Float?
            if let myRanking = myRanking(session: table.session),
                    let rankingTable = Scorecard.current.rankingTableList.first(where: {matchRanking(ranking: myRanking, tableNumber: tableNumber, rankingTable: $0)}),
                    let score = rankingTable.nsScore {
                tableScore = score
            }
            if let tableScore = tableScore {
                if !scorecard.manualTotals {
                    table.score = tableScore
                    changed = true
                }
            } else {
                for index in 1...boards {
                    let boardIndex = ((tableNumber - 1) * boards) + index
                    if let board = Scorecard.current.boards[boardIndex] {
                        if let score = board.score {
                            count += 1
                            total += score
                        }
                    }
                }
                
                var newScore = table.score
                let type = scorecard.type
                let places = type.tablePlaces
                if !scorecard.manualTotals {
                    if count == 0 {
                        newScore = nil
                    } else {
                        newScore = type.tableAggregate.aggregate(total: total, count: count, boards: count, places: places, boardScoreType: type.boardScoreType)
                    }
                }
                if newScore != table.score {
                    table.score = newScore
                    changed = true
                }
            }
        }
        return changed
    }
    
    static func matchRanking(ranking: RankingViewModel, tableNumber: Int, rankingTable: RankingTableViewModel) -> Bool {
        rankingTable.number == ranking.number && rankingTable.section == ranking.section && (ranking.way == .unknown || rankingTable.way == ranking.way) && rankingTable.table == tableNumber
    }
    
    @discardableResult static func updateTotalScore(scorecard: ScorecardViewModel) -> Bool {
        var changed = false
        var total: Float = 0
        var count = 0
        var completedBoards = 0
        for tableNumber in 1...scorecard.tables {
            if let table = Scorecard.current.tables[tableNumber] {
                if let score = table.score {
                    // Weight it to number of boards completed if averaging
                    let scored = table.scoredBoards
                    let weight = (scorecard.type.matchAggregate ~= .average ? scored : 1)
                    total += score * Float(weight)
                    completedBoards += scored
                    count += weight
                }
            }
        }
        var newScore = scorecard.score
        let type = scorecard.type
        let places = type.matchPlaces
        if !scorecard.manualTotals {
            if count == 0 {
                newScore = nil
            } else {
                newScore = type.matchAggregate.aggregate(total: total, count: count, boards: completedBoards, places: places, boardScoreType: type.boardScoreType)
            }
        }
        if newScore != scorecard.score {
            scorecard.score = newScore
            if let newScore = newScore {
                if scorecard.entry == 2 {
                    scorecard.position = (newScore >= scorecard.type.invertScore(score: newScore, type: scorecard.type.matchScoreType) ? 1 : 2)
                }
            }
            changed = true
        }
        if !scorecard.manualTotals && count != 0 {
            scorecard.maxScore = type.maxScore(tables: count)
        }
        return changed
    }
    
    public static func madeString(made: Int) -> String {
        return made == 0 ? "=" : String(format: "%+d", made)
    }
    
    public func scanRankings(session: Int? = nil, action: (RankingViewModel, Bool, RankingViewModel?)->()) {
        var lastRanking: RankingViewModel?
        var newGrouping: Bool
        
        for ranking in Scorecard.current.rankingList.filter({ $0.session == (session ?? $0.session) }).sorted(by: {NSObject.sort($0, $1, sortKeys: [("session", .ascending), ("section", .ascending), ("waySort", .ascending), ("score", .descending)])}) {
            newGrouping = false
            if lastRanking?.session != ranking.session {
                newGrouping = true
            }
            if lastRanking?.section != ranking.section {
                newGrouping = true
            }
            if lastRanking?.way != ranking.way && scorecard?.type.players != 4 {
                newGrouping = true
            }
            action(ranking, newGrouping, lastRanking)
            lastRanking = ranking
        }
    }
    
    public static func declarerList(sitting: Seat) -> [(Seat, ScrollPickerEntry)] {
        return Seat.allCases.map{($0, ScrollPickerEntry(title: $0.short, caption: $0.player(sitting: sitting)))}
    }
    
    public static func orderedDeclarerList(sitting: Seat) -> [(Seat, ScrollPickerEntry)] {
        let orderedList: [Seat] = [sitting.partner, sitting.leftOpponent, .unknown, sitting.rightOpponent, sitting.self]
        return orderedList.map{($0, ScrollPickerEntry(title: $0.short, caption: $0.player(sitting: sitting)))}
    }
    
    public static func madePoints(contract: Contract) -> Int {
        return contract.suit.trickPoints(tricks: contract.level.rawValue) * contract.double.multiplier
    }
    
    public static func points(contract: Contract, vulnerability: Vulnerability, declarer: Seat, made: Int, seat: Seat) -> Int {
        var points = 0
        let multiplier = (seat == declarer || seat == declarer.partner ? 1 : -1)
        
        if contract.level != .passout {
            
            let level = contract.level
            let suit = contract.suit
            let double = contract.double
            var gameMade = false
            let values = Values(vulnerability.isVulnerable(seat: declarer))
            
            if made >= 0 {
                
                    // Add in base points for making contract
                let madePoints = Scorecard.madePoints(contract: contract)
                gameMade = (madePoints >= values.gamePoints)
                points += madePoints
                
                    // Add in any overtricks
                if made >= 1 {
                    if double == .undoubled {
                        points += suit.overTrickPoints(tricks: made)
                    } else {
                        points += made * (values.doubledOvertrick) * (double.multiplier / 2)
                    }
                }
                
                    // Add in the insult
                if double != .undoubled {
                    points += values.insult * (double.multiplier / 2)
                }
                
                    // Add in any game bonus or part score bonus
                if gameMade {
                    points += (values.gameBonus)
                } else {
                    points += values.partScoreBonus
                }
                
                    // Add in any slam bonus
                if level.rawValue == 7 {
                    points += values.grandSlamBonus
                } else if level.rawValue == 6 {
                    points += values.smallSlamBonus
                }
            } else {
                
                    // Subtract points for undertricks
                if double == .undoubled {
                    points = values.firstUndertrick * made
                } else {
                        // Subtract first trick
                    points -= values.firstUndertrick * double.multiplier
                    
                        // Subtract second and third undertricks
                    points += values.nextTwoDoubledUndertricks * (double.multiplier / 2) * min(0, max(-2, made + 1))
                    
                        // Subtract all other undertricks
                    points += values.subsequentDoubledUndertricks * (double.multiplier / 2) * min(0, made + 3)
                }
            }
        }
        
        return points * multiplier
    }
    
    public static func made(contract: Contract, vulnerability: Vulnerability, declarer: Seat, points: Int) -> Int? {
        var result: Int?
        if contract.level != .passout && contract.level != .blank && points != 0 {
            var from: Int
            var to: Int
            if points > 0 {
                // Made
                from = 0
                to = 13 - contract.level.tricks
            } else {
                // Went off
                from = -(contract.level.tricks)
                to = -1
            }
            for tricks in from...to {
                if self.points(contract: contract, vulnerability: vulnerability, declarer: declarer, made: tricks, seat: declarer) == points {
                    result = tricks
                }
            }
        }
        return result
    }
    
    public static func getBoardTraveller(boardIndex: Int, equivalentSeat: Bool = false) -> (BoardViewModel, TravellerViewModel, Seat)? {
        var result: (BoardViewModel, TravellerViewModel, Seat)?
        if let nextBoard = Scorecard.current.boards[boardIndex] {
            if !Scorecard.current.travellerList.isEmpty {
                if let myRanking = myRanking(session: nextBoard.session) {
                    var seat = nextBoard.table!.sitting
                    if equivalentSeat {
                        seat = seat.equivalent
                    }
                    if let nextTraveller = Scorecard.current.traveller(board: nextBoard.boardIndex, seat: seat, rankingNumber: myRanking.number, section: myRanking.section) {
                        result = (nextBoard, nextTraveller, seat)
                    }
                }
            }
        }
        return result
    }
    
    public static func myRanking(session: Int?) -> RankingViewModel? {
        var result: RankingViewModel?
        if let scorer = Scorecard.current.scorecard?.scorer {
            let rankings = Scorecard.current.rankings(session: (Scorecard.current.scorecard!.isMultiSession ? session : nil), player: (bboName:scorer.bboName, name: scorer.name))
            if let myRanking = rankings.first {
                result = myRanking
            }
        }
        return result
    }
        
    public static func commentAvailableText(exists: Bool) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: exists ? "text.bubble" : "bubble")
        return NSAttributedString(attachment: attachment)
    }
    
    static func bboShowHand(from parentView: UIView, board: BoardViewModel, traveller: TravellerViewModel, completion: (()->())? = nil) {
        
        var playData = ""
        var linData = traveller.playData.removingPercentEncoding ?? ""
        if linData != "" {
            // Got lin data - just replace names
            var nameString = ""
            for seat in [Seat.south, Seat.west, Seat.north, Seat.east] {
                var name = "Unknown"
                if let ranking = traveller.ranking(seat: seat) {
                    name = (ranking.players[seat] ?? name)
                    if Scorecard.current.scorecard?.importSource == .bbo {
                        if let realName = MasterData.shared.realName(bboName: name) {
                            name = realName
                        }
                    }
                }
                nameString += name
                if seat != .east {
                    nameString += ","
                }
            }
            if let pnPosition = linData.position("|pn|") {
                if let nextSeparator = linData.right(linData.length - pnPosition - 4).position("|") {
                    if nextSeparator > 0 {
                        linData = linData.left(pnPosition + 4) + nameString + linData.right(linData.length - pnPosition - nextSeparator - 4)
                    }
                }
            }
            playData = "?bbo=y&tbt=y&lin=/\(linData.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"
        } else if board.hand != "" {
                // Try to construct from hand
            playData = "?d=\(board.declarer.short.lowercased())"
            for seat in Seat.validCases {
                var name = "Unknown"
                if let ranking = traveller.ranking(seat: seat) {
                    name = (ranking.players[seat] ?? name).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
                }
                playData += "&\(seat.short.lowercased())n=\(name)"
            }
            playData += "&v=\(board.vulnerability.short.lowercased())"
            playData += "&b=\(board.boardIndex)"
            let suits = board.hand.components(separatedBy: ",")
            for seat in Seat.validCases {
                playData += "&\(seat.short.lowercased())="
                for suit in 0...3 {
                    playData += "shdc".mid(suit, 1)
                    let suit = suits[((seat.rawValue - 1) * 4) + suit]
                    playData += (suit == "--" ? "" : suit)
                }
            }
            playData += "&a=\(traveller.contract.level.short)\(traveller.contract.suit.short)\(traveller.declarer.short)"
        }
        
        if playData != "" {
            if let url = URL(string: "https://www.bridgebase.com/tools/handviewer.html\(playData)") {
                let webView = ScorecardWebView(frame: CGRect())
                webView.show(from: parentView.superview?.superview ?? parentView, url: url, completion: completion)
            }
        } else {
            completion?()
        }
        
    }
}
