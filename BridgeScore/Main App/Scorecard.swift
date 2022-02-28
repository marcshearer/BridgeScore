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
                remove(board: board)
            } else if board.changed {
                // Save any existing boards
                save(board: board)
            }
        }
        
        for (tableNumber, table) in tables {
            if tableNumber < 1 || tableNumber > scorecard.tables {
                // Remove any tables no longer in bounds
                remove(table: table)
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
    
    static public func updateScores(scorecard: ScorecardViewModel) {
        
        for tableNumber in 1...scorecard.tables {
            if Scorecard.updateTableScore(scorecard: scorecard, tableNumber: tableNumber) {
                Scorecard.current.tables[tableNumber]?.save()
            }
        }
        Scorecard.updateTotalScore(scorecard: scorecard)
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
            
            var newScore: Float?
            let type = scorecard.type
            let boards = scorecard.boardsTable
            let places = type.tablePlaces
            if count == 0 && type.tableAggregate != .manual {
                newScore = nil
            } else {
                let average = Utility.round(total / Float(count), places: type.boardPlaces)
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
                default:
                    break
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
        var newScore: Float?
        let type = scorecard.type
        let boards = scorecard.boards
        let places = type.matchPlaces
        if count == 0 && type.matchAggregate != .manual {
            newScore = nil
        } else {
            let average = Utility.round(total / Float(count), places: places)
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
            default:
                break
            }
        }
        if newScore != scorecard.score {
            scorecard.score = newScore
            changed = true
        }
        return changed
    }
    
    public static func declarerList(sitting: Seat) -> [ScrollPickerEntry] {
        return Seat.allCases.map{ScrollPickerEntry(title: $0.short, caption: { (seat) in
            switch seat {
                case .unknown:
                    return seat.string
                case sitting:
                    return "Self"
                case sitting.partner:
                    return "Partner"
                case sitting.leftOpponent:
                    return "Left Opp"
                case sitting.rightOpponent:
                    return "Right Opp"
                default:
                    return "Unknown"
                }
        }($0))}
    }
}
