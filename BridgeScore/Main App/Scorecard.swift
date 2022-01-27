//
//  Scorecard.swift
//  BridgeScore
//
//  Created by Marc Shearer on 23/01/2022.
//

import Foundation

class Scorecard {
    
    public static let current = Scorecard()
    
    @Published private(set) var scorecard: ScorecardViewModel?
    @Published private(set) var boards: [Int:[Int:BoardViewModel]] = [:]                  // Match / Board

    public func load(scorecard: ScorecardViewModel) {
        let scorecardFilter = NSPredicate(format: "scorecardId = %@", scorecard.scorecardId as NSUUID)
        let boardMOs = CoreData.fetch(from: BoardMO.tableName, filter: scorecardFilter, sort: [ (key: #keyPath(BoardMO.match16), direction: .ascending), (#keyPath(BoardMO.board16), direction: .ascending)]) as! [BoardMO]
        
        self.boards = [:]
        for boardMO in boardMOs {
            if self.boards[boardMO.match] == nil {
                self.boards[boardMO.match] = [:]
            }
            self.boards[boardMO.match]![boardMO.board] = BoardViewModel(scorecard: scorecard, boardMO: boardMO)
        }
        
        self.scorecard = scorecard
    }
    
    public func match(scorecard: ScorecardViewModel) -> Bool {
        return (self.scorecard == scorecard)
    }
    
    public func insert(board: BoardViewModel) {
        assert(board.scorecard == self.scorecard, "Board is not in current scorecard")
        assert(board.boardMO == nil, "Cannot insert a board which already has a managed object")
        assert(self.boards[board.match]?[board.board] == nil, "Board already exists and cannot be created")
        CoreData.update(updateLogic: {
            board.boardMO = BoardMO()
            self.updateMO(board: board)
            if self.boards[board.match] == nil {
                self.boards[board.match] = [:]
            }
            self.boards[board.match]![board.board] = board
        })
    }
    
    public func remove(board: BoardViewModel) {
        assert(board.scorecard == self.scorecard, "Board is not in current scorecard")
        assert(board.boardMO != nil, "Cannot remove a board which doesn't already have a managed object")
        assert(self.boards[board.match]?[board.board] != nil, "Board does not exist and cannot be deleted")
        CoreData.update(updateLogic: {
            CoreData.context.delete(board.boardMO!)
            self.boards[board.match]?[board.board] = nil
        })
    }
    
    public func save(board: BoardViewModel) {
        assert(board.scorecard == self.scorecard, "Board is not in current scorecard")
        assert(board.boardMO != nil, "Cannot save a board which doesn't already have managed objects")
        assert(self.boards[board.match]?[board.board] != nil, "Board does not exist and cannot be updated")
        if board.changed {
            CoreData.update(updateLogic: {
                self.updateMO(board: board)
            })
        }
    }
    
    public func board(match: Int, board: Int) -> BoardViewModel? {
        return self.boards[match]?[board]
    }
    
    private func updateMO(board: BoardViewModel) {
        board.boardMO!.scorecardId = board.scorecard.scorecardId
        board.boardMO!.match = board.match
        board.boardMO!.board = board.board
        board.boardMO!.contract = board.contract
        board.boardMO!.declarer = board.declarer
        board.boardMO!.made = board.made
        board.boardMO!.score = board.score
        board.boardMO!.comment = board.comment
        board.boardMO!.responsible = board.responsible
        board.boardMO!.versus = board.versus
    }
    
}
