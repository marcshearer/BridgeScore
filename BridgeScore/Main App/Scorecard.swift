//
//  Scorecard.swift
//  BridgeScore
//
//  Created by Marc Shearer on 23/01/2022.
//

import UIKit

enum ScorecardEntity {
    case table
    case board
}

class Scorecard {
    
    public static let current = Scorecard()
    
    @Published private(set) var scorecard: ScorecardViewModel?
    @Published private(set) var boards: [Int:BoardViewModel] = [:]   // Board number
    @Published private(set) var tables: [Int:TableViewModel] = [:]   // Table number
    @Published private(set) var rankingList: [RankingViewModel] = []
    @Published private(set) var travellerList: [TravellerViewModel] = []
    
    public func rankings(table: Int? = nil, section: Int? = nil, way: Pair? = nil, number: Int? = nil, player: (bboName: String, name: String)? = nil) -> [RankingViewModel] {
        var result = rankingList
        if let table = table {
            if scorecard?.resetNumbers ?? false {
                result = result.filter({$0.table == table})
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
    
    public func ranking(table: Int, section: Int, way: Pair, number: Int) -> RankingViewModel? {
        let resultList = rankingList.filter({(!(scorecard?.resetNumbers ?? false) || $0.table == table) && $0.section == section && ($0.way == .unknown || $0.way == way) && $0.number == number})
        return resultList.count == 1 ? resultList.first : nil
    }
    
    public func travellers(board: Int? = nil, seat: Seat? = nil, rankingNumber: Int? = nil, section: Int? = nil) -> [TravellerViewModel] {
        var result = travellerList
        if let board = board {
            result = result.filter({$0.board == board})
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
        let resultList = travellerList.filter{$0.board == board && $0.rankingNumber[seat] == rankingNumber && $0.section[seat] == section}
        return resultList.count == 1 ? resultList.first : nil
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
            boards[boardMO.board] = BoardViewModel(scorecard: scorecard, boardMO: boardMO)
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
        
        // Load travellers
        let travellerMOs = CoreData.fetch(from: TravellerMO.tableName, filter: scorecardFilter) as! [TravellerMO]

        travellerList = []
        for travellerMO in travellerMOs {
            travellerList.append(TravellerViewModel(scorecard: scorecard, travellerMO: travellerMO))
        }
        
        self.scorecard = scorecard
        addNew()
    }
    
    public func clear() {
        boards = [:]
        tables = [:]
        rankingList = []
        travellerList = []
        scorecard = nil
    }
    
    
    private var lastEntity: ScorecardEntity?
    private var lastItemNumber: Int?
    
    public func interimSave(entity: ScorecardEntity? = nil, itemNumber: Int? = nil) {
        if entity == nil || entity != lastEntity || itemNumber != lastItemNumber {
            if let lastItemNumber = lastItemNumber {
                switch lastEntity {
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
            lastEntity = entity
            lastItemNumber = itemNumber
        }
    }
    
    public func saveAll(scorecard: ScorecardViewModel) {
        
        assert(self.scorecard == scorecard, "Not the current scorecard")
        
        for (boardNumber, board) in boards {
            if boardNumber < 1 || boardNumber > scorecard.boards {
                // Remove any boards no longer in bounds
                if board.isNew {
                    // Not yet in core data - just remove from array
                    boards[board.board] = nil
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
            // Save any existing travellers
            save(ranking: ranking)
        }
        
        var removeList = IndexSet()
        for (index, traveller) in travellerList.reversed().enumerated() {
            if traveller.board < 1 || traveller.board > scorecard.boards {
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
        
        for traveller in travellerList {
            if !traveller.isNew {
                remove(traveller: traveller)
            }
        }
        
        clear()
   }
    
    public func removeRankings(table: Int? = nil) {
        for ranking in rankings(table: table).reversed() {
            if !ranking.isNew {
                remove(ranking: ranking)
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
    
    public func addNew() {
        if let scorecard = scorecard {
            // Fill in any gaps in boards
            for boardNumber in 1...scorecard.boards {
                if boards[boardNumber] == nil {
                    boards[boardNumber] = BoardViewModel(scorecard: scorecard, board: boardNumber)
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
        removeRankings()
        for boardNumber in 1...(scorecard?.boards ?? 0) {
            removeTravellers(board: boardNumber)
        }
    }
    
    // MARK: - Boards ======================================================================== -
    
    public func insert(board: BoardViewModel) {
        assert(board.scorecard == scorecard, "Board is not in current scorecard")
        assert(board.isNew, "Cannot insert a board which already has a managed object")
        assert(boards[board.board] == nil, "Board already exists and cannot be created")
        CoreData.update(updateLogic: {
            board.boardMO = BoardMO()
            board.updateMO()
            boards[board.board] = board
        })
    }
    
    public func remove(board: BoardViewModel) {
        assert(board.scorecard == scorecard, "Board is not in current scorecard")
        assert(!board.isNew, "Cannot remove a board which doesn't already have a managed object")
        assert(boards[board.board] != nil, "Board does not exist and cannot be deleted")
        CoreData.update(updateLogic: {
            CoreData.context.delete(board.boardMO!)
            boards[board.board] = nil
        })
    }
    
    public func save(board: BoardViewModel) {
        assert(board.scorecard == scorecard, "Board is not in current scorecard")
        assert(boards[board.board] != nil, "Board does not exist and cannot be updated")
        if board.isNew {
            CoreData.update(updateLogic: {
                board.boardMO = BoardMO()
                board.updateMO()
            })
        } else if board.changed {
            CoreData.update(updateLogic: {
                board.updateMO()
            })
        }
    }
    
    // MARK: - Boards ======================================================================== -

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
        assert(self.ranking(table: ranking.table, section: ranking.section, way: ranking.way,  number: ranking.number) == nil, "Ranking already exists and cannot be created")
        CoreData.update(updateLogic: {
            ranking.rankingMO = RankingMO()
            ranking.updateMO()
            rankingList.append(ranking)
        })
    }
    
    public func remove(ranking: RankingViewModel) {
        assert(ranking.scorecard == scorecard, "Ranking is not in current scorecard")
        assert(!ranking.isNew, "Cannot remove a ranking which doesn't already have a managed object")
        assert(self.ranking(table: ranking.table, section: ranking.section, way: ranking.way, number: ranking.number) != nil, "Ranking does not exist and cannot be deleted")
        CoreData.update(updateLogic: {
            CoreData.context.delete(ranking.rankingMO!)
            rankingList.removeAll(where: {$0.table == ranking.table && $0.section == ranking.section && $0.way == ranking.way && $0.number == ranking.number})
        })
    }
    
    public func save(ranking: RankingViewModel) {
        assert(ranking.scorecard == scorecard, "Ranking is not in current scorecard")
        assert(self.ranking(table: ranking.table, section: ranking.section, way: ranking.way, number: ranking.number) != nil, "Ranking does not exist and cannot be updated")
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
    
    // MARK: - Travellers ======================================================================== -

    public func insert(traveller: TravellerViewModel) {
        assert(traveller.scorecard == scorecard, "Traveller is not in current scorecard")
        assert(traveller.isNew, "Cannot insert a traveller which already has a managed object")
        assert(self.traveller(board: traveller.board, seat: .north, rankingNumber: traveller.rankingNumber[.north]!, section: traveller.section[.north]!) == nil, "Traveller already exists and cannot be created")
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
            travellerList.removeAll(where: {$0.board == traveller.board && $0.rankingNumber[.north] == traveller.rankingNumber[.north] && $0.section[.north] == traveller.section[.north]})
        })
    }
    
    public func save(traveller: TravellerViewModel) {
        assert(traveller.scorecard == scorecard, "Traveller is not in current scorecard")
        assert(self.traveller(board: traveller.board, seat: .north, rankingNumber: traveller.rankingNumber[.north]!, section: traveller.section[.north]!) != nil, "Traveller does not exist and cannot be updated")
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
    
    public static func boardNumber(scorecard: ScorecardViewModel, board: Int) -> Int {
        return scorecard.resetNumbers ? ((board - 1) % scorecard.boardsTable) + 1 : board
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
            for index in 1...boards {
                let boardNumber = ((tableNumber - 1) * boards) + index
                if let board = Scorecard.current.boards[boardNumber] {
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
                    newScore = Scorecard.aggregate(total: total, count: count, boards: count, subsidiaryPlaces: type.boardPlaces, places: places, type: type.tableAggregate)
                }
            }
            if newScore != table.score {
                table.score = newScore
                changed = true
            }
        }
        return changed
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
                    let weight = scorecard.type.matchAggregate == .average ? scored : 1
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
                newScore = Scorecard.aggregate(total: total, count: count, boards: completedBoards, subsidiaryPlaces: type.tablePlaces, places: places, type: type.matchAggregate)
            }
        }
        if newScore != scorecard.score {
            scorecard.score = newScore
            if let newScore = newScore {
                if scorecard.entry == 2 {
                    scorecard.position = (newScore >= scorecard.type.invertScore(score: newScore) ? 1 : 2)
                }
            }
            changed = true
        }
        if !scorecard.manualTotals && count != 0 {
            scorecard.maxScore = type.maxScore(tables: count)
        }
        return changed
    }
    
    static func aggregate(total: Float, count: Int, boards: Int, subsidiaryPlaces: Int, places: Int, type: AggregateType) -> Float? {
        var result: Float?
        let average = (count == 0 ? 0 : Utility.round(total / Float(count), places: subsidiaryPlaces))
        switch type {
        case .average:
            result = Utility.round(average, places: places)
        case .total:
            result = Utility.round(total, places: places)
        case .continuousVp:
            result = BridgeImps(Int(Utility.round(total))).vp(boards: boards, places: places)
        case .discreteVp:
            result = Float(BridgeImps(Int(Utility.round(total))).discreteVp(boards: boards))
        case .acblDiscreteVp:
            result = Float(BridgeImps(Int(Utility.round(total))).acblDiscreteVp(boards: boards))
        case .percentVp:
            if let vps = BridgeMatchPoints(average).vp(boards: boards) {
                result = Float(vps)
            }
        }
        return result
    }
    
    public func scanRankings(action: (RankingViewModel, Bool, RankingViewModel?)->()) {
        var lastRanking: RankingViewModel?
        var newGrouping: Bool
        
        for ranking in Scorecard.current.rankingList.sorted(by: {NSObject.sort($0, $1, sortKeys: [("table", .ascending), ("section", .ascending), ("waySort", .ascending), ("score", .descending)])}) {
            newGrouping = false
            if lastRanking?.table != ranking.table {
                newGrouping = true
            }
            if lastRanking?.section != ranking.section {
                newGrouping = true
            }
            if lastRanking?.way != ranking.way {
                newGrouping = true
            }
            action(ranking, newGrouping, newGrouping ? nil : lastRanking)
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
                let madePoints = suit.trickPoints(tricks: level.rawValue) * double.multiplier
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
    
    static func showHand(from parentView: UIView, board: BoardViewModel, traveller: TravellerViewModel, sitting: Seat = .south, completion: (()->())? = nil) {
        
        var playData = ""
        var linData = traveller.playData.removingPercentEncoding ?? ""
        if linData != "" {
            // Got lin data - just replace names
            var nameString = ""
            let seats: [Seat] = [.south, .west, .north, .east]
            for seat in seats {
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
            playData += "&v=\(board.vulnerability?.short.lowercased() ?? "-")"
            playData += "&b=\(board.board)"
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
