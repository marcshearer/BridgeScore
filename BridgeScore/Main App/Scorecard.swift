//
//  Scorecard.swift
//  BridgeScore
//
//  Created by Marc Shearer on 23/01/2022.
//

import Foundation

enum ScorecardEntity {
    case table
    case board
}

class Scorecard {
    
    public static let current = Scorecard()
    
    @Published private(set) var scorecard: ScorecardViewModel?
    @Published private(set) var boards: [Int:BoardViewModel] = [:]   // Board number
    @Published private(set) var tables: [Int:TableViewModel] = [:]   // Table number
    
    public var isSensitive: Bool {
        return boards.compactMap{$0.value}.firstIndex(where: {$0.comment != "" || $0.responsible != .unknown }) != nil
    }
    
    public var hasData: Bool {
        return (boards.compactMap{$0.value}.firstIndex(where: {$0.hasData}) != nil) || (tables.compactMap{$0.value}.firstIndex(where: {$0.hasData}) != nil)
    }

    public func load(scorecard: ScorecardViewModel) {
        let scorecardFilter = NSPredicate(format: "scorecardId = %@", scorecard.scorecardId as NSUUID)

        // Load boards
        let boardMOs = CoreData.fetch(from: BoardMO.tableName, filter: scorecardFilter, sort: [ (#keyPath(BoardMO.board16), direction: .ascending)]) as! [BoardMO]
        
        boards = [:]
        for boardMO in boardMOs {
            boards[boardMO.board] = BoardViewModel(scorecard: scorecard, boardMO: boardMO)
        }

        // Load tables
        let tableMOs = CoreData.fetch(from: TableMO.tableName, filter: scorecardFilter, sort: [ (#keyPath(TableMO.table16), direction: .ascending)]) as! [TableMO]
        
        tables = [:]
        for tableMO in tableMOs {
            tables[tableMO.table] = TableViewModel(scorecard: scorecard, tableMO: tableMO)
        }
        
        self.scorecard = scorecard
        
        addNew()
    }
    
    public func clear() {
        boards = [:]
        tables = [:]
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
    }
    
    public func removeAll(scorecard: ScorecardViewModel) {
        
        assert(self.scorecard == scorecard, "Not the current scorecard")
        
        for (_, board) in boards {
            if !board.isNew {
                remove(board: board)
            }
        }
        
        for (_, table) in tables {
            if !table.isNew {
                remove(table: table)
            }
        }
        
        clear()
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
            let boards = scorecard.boardsTable
            let places = type.tablePlaces
            if !scorecard.manualTotals {
                if count == 0 {
                    newScore = nil
                } else {
                    let average = (count == 0 ? 0 : Utility.round(total / Float(count), places: type.boardPlaces))
                    switch type.tableAggregate {
                    case .average:
                        newScore = Utility.round(average, places: places)
                    case .total:
                        newScore = Utility.round(total, places: places)
                    case .continuousVp:
                        newScore = BridgeImps(Int(Utility.round(total))).vp(boards: boards, places: places)
                    case .discreteVp:
                        newScore = Float(BridgeImps(Int(Utility.round(total))).discreteVp(boards: boards))
                    case .percentVp:
                        if let vps = BridgeMatchPoints(average).vp(boards: boards) {
                            newScore = Float(vps)
                        }
                    }
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
        var count: Int = 0
        for tableNumber in 1...scorecard.tables {
            if let table = Scorecard.current.tables[tableNumber] {
                if let score = table.score {
                    count += 1
                    total += score
                }
            }
        }
        var newScore = scorecard.score
        let type = scorecard.type
        let boards = scorecard.boards
        let places = type.matchPlaces
        if !scorecard.manualTotals {
            if count == 0 {
                newScore = nil
            } else {
                let average = (count == 0 ? 0 : Utility.round(total / Float(count), places: places))
                switch type.matchAggregate {
                case .average:
                    newScore = average
                case .total:
                    newScore = Utility.round(total, places: places)
                case .continuousVp:
                    newScore = BridgeImps(Int(Utility.round(total))).vp(boards: boards, places: places)
                case .discreteVp:
                    newScore = Float(BridgeImps(Int(Utility.round(total))).discreteVp(boards: boards))
                case .percentVp:
                    if let vps = BridgeMatchPoints(average).vp(boards: boards) {
                        newScore = Float(vps)
                    }
                }
            }
        }
        if newScore != scorecard.score {
            scorecard.score = newScore
            changed = true
        }
        if !scorecard.manualTotals && count != 0 {
            scorecard.maxScore = type.maxScore(tables: count)
        }
        return changed
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
}
