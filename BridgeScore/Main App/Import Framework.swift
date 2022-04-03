//
//  Import Framework.swift
//  BridgeScore
//
//  Created by Marc Shearer on 20/03/2022.
//

import CoreData

class ImportedScorecard: NSObject {
    var title: String?
    var boardCount: Int?
    var date: Date?
    var partner: PlayerViewModel?
    var type: ScoreType?
    var rankings: [ImportedRanking] = []
    var myRanking: ImportedRanking?
    var myRankingSeat: Seat?
    var myName: String!
    var travellers: [Int:[ImportedTraveller]] = [:]
    var warnings: [String] = []
    var error: String?
    var scorecard: ScorecardViewModel!
    var boardsTable: Int?
    var table: Int = 1

    // MARK: - Import to main data structures =================================================================== -
        
    public func importScorecard(rebuild: Bool = false) {
        // Update date
        if let date = date {
            scorecard?.date = date
        }
        
        // Update partner
        if let partner = partner {
            scorecard?.partner = partner
        }
        
        if travellers.count > 0 {
            if !(scorecard?.resetNumbers ?? false) {
                    // Update number of boards / tables
                if let boardCount = boardCount {
                    scorecard?.boards = boardCount
                }
                if let boardsTable = boardsTable {
                    scorecard?.boardsTable = boardsTable
                }
                Scorecard.current.addNew()
            }
        
            
            if let myRanking = myRanking {
                    // Update position
                if !(scorecard?.resetNumbers ?? false) {
                    if let position = myRanking.ranking {
                        scorecard?.position = position
                    }
                }
                
                    // Update score
                if !(scorecard?.resetNumbers ?? false) && !(scorecard?.manualTotals ?? false) {
                    if let score = myRanking.score {
                        scorecard?.score = score
                    }
                }
            }
        }
        
        // Update field entry size
        scorecard?.entry = rankings.count
        
        // Update boards and tables
        
        if let scorecard = scorecard {
            if travellers.count > 0 {
                if Scorecard.current.match(scorecard: scorecard) {
                    if scorecard.resetNumbers {
                        importTable(tableNumber: table, boardOffset: (table - 1) * scorecard.boardsTable)
                        importRankings(table: table)
                    } else {
                        for tableNumber in 1...scorecard.tables {
                            importTable(tableNumber: tableNumber)
                        }
                        importRankings()
                    }
                }
                Scorecard.updateScores(scorecard: scorecard)
                if scorecard.entry == 2 && scorecard.type.boardScoreType != .percent && scorecard.score != nil && scorecard.maxScore != nil {
                    scorecard.position = (scorecard.score! >= (scorecard.maxScore! / 2) ? 1 : 2)
                }
            } else {
                importRankings()
            }
          
            // Rebuild ranking totals if necessary
            if rebuild {
                rebuildRankingTotals()
            }
            
            Scorecard.current.saveAll(scorecard: scorecard)
        }
    }
    
    private func importTable(tableNumber: Int, boardOffset: Int = 0) {
        if let scorecard = scorecard,
            let myRanking = myRanking,
            let myNumber = myRanking.number {
            
            let mySection = myRanking.section
            let table = Scorecard.current.tables[tableNumber]
            
            for tableBoardNumber in 1...scorecard.boardsTable {
                
                let boardNumber = ((tableNumber - 1) * scorecard.boardsTable) + tableBoardNumber
                
                if let lines = travellers[boardNumber - boardOffset],
                    let myLine = myTravellerLine(lines: lines, myNumber: myNumber, mySection: mySection) {
                    
                    let mySeat = seat(line: myLine, ranking: myRanking, name: myName) ?? .unknown
                    var versus = ""
                    for seat in Seat.validCases {
                        let otherNumber = myLine.ranking[seat] ?? myNumber
                        if otherNumber != myNumber {
                            if let ranking = otherRanking(number: otherNumber, section: mySection), let otherName = ranking.players[seat]  {
                                if versus != "" {
                                    versus += " & "
                                }
                                versus += MasterData.shared.realName(bboName: otherName) ?? "Unknown" // Try bbo lookup but will fail on other imports and return itself
                            }
                        }
                    }
                    table?.versus = versus
                    table?.sitting = mySeat
                                        
                    importBoard(myLine: myLine, boardNumber: boardNumber, myRanking: myRanking)
                    importTravellers(boardNumber: boardNumber, boardOffset: boardOffset)
                }
            }
        }
    }
    
    func importBoard(myLine: ImportedTraveller, boardNumber: Int, myRanking: ImportedRanking) {
        let board = Scorecard.current.boards[boardNumber]
        board?.contract = myLine.contract ?? Contract()
        board?.declarer = myLine.declarer ?? .unknown
        board?.made = myLine.made
        if let nsScore = myLine.nsScore, let scorecard = scorecard {
            board?.score = (myLine.ranking[.north] == myRanking.number || myLine.ranking[.south] == myRanking.number ? nsScore : ( (scorecard.type.boardScoreType == .percent ? 100 - nsScore : (nsScore == 0 ? 0 : -nsScore))))
        }
    }
    
    func importRankings(table: Int? = nil) {
        Scorecard.current.removeRankings(table: table)
        if let scorecard = scorecard {
            let sortedRankings = rankings.sorted(by: {($0.ranking ?? 0) < ($1.ranking ?? 0)})
            for (index, bboRanking) in sortedRankings.enumerated() {
                
                let section = bboRanking.section
                if let number = bboRanking.number {
                    let ranking = RankingViewModel(scorecard: scorecard, table: table ?? 0, section: section, number: number)
                    
                    // Sort out ties
                    if index > 0 && sortedRankings[index - 1].score == ranking.score {
                        ranking.ranking = sortedRankings[index - 1].ranking!
                    } else {
                        ranking.ranking = bboRanking.ranking ?? 0
                    }
                    ranking.players = bboRanking.players
                    ranking.score = bboRanking.score ?? 0
                    ranking.points = bboRanking.bboPoints ?? 0
                    ranking.xImps = bboRanking.xImps
                    
                    Scorecard.current.insert(ranking: ranking)
                }
            }
        }
    }
    
    func importTravellers(boardNumber: Int, boardOffset: Int = 0) {
        Scorecard.current.removeTravellers(board: boardNumber)
        if let scorecard = scorecard, let importedTravellers = travellers[boardNumber - boardOffset] {
            for importedTraveller in importedTravellers {
                if let board = importedTraveller.board {
                    
                    let traveller = TravellerViewModel(scorecard: scorecard, board: board + boardOffset, section: importedTraveller.section, ranking: importedTraveller.ranking)
                    
                    traveller.contract = importedTraveller.contract ?? Contract()
                    traveller.declarer = importedTraveller.declarer ?? .unknown
                    traveller.made = importedTraveller.made ?? 0
                    traveller.nsScore = importedTraveller.nsScore ?? 0
                    traveller.nsXImps = importedTraveller.nsXImps ?? 0
                    traveller.lead = importedTraveller.lead ?? ""
                    traveller.playData = importedTraveller.playData ?? ""
                    
                    Scorecard.current.insert(traveller: traveller)
                }
            }
        }
    }
    
    // MARK: - Utility Routines ======================================================================== -
    
    func myTravellerLine(lines: [ImportedTraveller], myNumber: Int, mySection: Int) -> ImportedTraveller? {
        var result: ImportedTraveller?
        
        for seat in Seat.validCases {
            if let line = lines.first(where: {$0.ranking[seat] == myNumber}) {
                if myRanking?.players[seat]?.lowercased() == myName{
                    result = line
                    break
                }
            }
        }
        
        return result
    }
    
    func matchingTraveller(_ first: ImportedTraveller, _ second: ImportedTraveller) -> Bool {
        return first.board == second.board && first.ranking[.north] == second.ranking[.east]
    }
    
    func otherRanking(number: Int, section: Int) -> ImportedRanking? {
        return rankings.first(where: {$0.number == number && $0.section == section})
    }
    
    func seat(line: ImportedTraveller, ranking: ImportedRanking, name: String) -> Seat? {
        var result: Seat?
        
        for seat in Seat.validCases {
            if line.ranking[seat] == ranking.number {
                if ranking.players[seat]?.lowercased() == name {
                    result = seat
                    break
                }
            }
        }
        
        return result
    }
    
    func recalculateTravellers() {
        // BBO etc sometimes exports cross imps on boards rather than team imp differences - recalculate them
        if scorecard!.type.players == 4 {
            for (board, boardTravellers) in travellers {
                for traveller in boardTravellers {
                    if let contract = traveller.contract, let declarer = traveller.declarer, let made = traveller.made {
                        if let otherTraveller = boardTravellers.first(where: {matchingTraveller($0, traveller)}), let otherContract = otherTraveller.contract, let otherDeclarer = otherTraveller.declarer, let otherMade = otherTraveller.made {
                            let vulnerability = Vulnerability(board: board)
                            let nsPoints = Scorecard.points(contract: contract, vulnerability: vulnerability, declarer: declarer, made: made, seat: .north)
                            let ewPoints = Scorecard.points(contract: otherContract, vulnerability: vulnerability, declarer: otherDeclarer, made: otherMade, seat: .east)
                            let balance = nsPoints + ewPoints
                            let nsImps = BridgeImps(points: balance)
                            traveller.nsXImps = traveller.nsScore
                            traveller.nsScore = Float(nsImps.imps ?? 0)
                            for pair in Pair.validCases {
                                let seat = pair.seats.first!
                                if let ranking = rankings.first(where: {$0.number == traveller.ranking[seat]}) {
                                    ranking.xImps[pair] = (ranking.xImps[pair] ?? 0) + (traveller.nsXImps ?? 0) * Float(pair.sign)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func checkBoardsPerTable(name: String) {
        // Check boards per table
        var lastVersus: Int? = nil
        var lastBoards: Int = 0
        var boardsTableError = false
        if let myRanking = myRanking,
           let myNumber = myRanking.number {
            let mySection = myRanking.section
            for (_, lines) in travellers.sorted(by: {$0.key < $1.key}) {
                if let line = myTravellerLine(lines: lines, myNumber: myNumber, mySection: mySection) {
                    if let mySeat = seat(line: line, ranking: myRanking, name: name) {
                        let thisVersus = line.ranking[mySeat.leftOpponent]
                        if lastVersus != thisVersus && lastVersus != nil {
                            if lastBoards != scorecard?.boardsTable {
                                boardsTableError = true
                            }
                            lastBoards = 0
                        }
                        lastVersus = thisVersus
                        lastBoards += 1
                    }
                }
            }
        }
        boardsTable = lastBoards
        if boardsTableError || lastBoards != scorecard?.boardsTable {
            warnings.append("Imported number of boards per table does not match current scorecard")
        }
    }
    
    func rebuildRankingTotals() {
        // Note this works on the main data structures after the import rather than the imported layer
        for ranking in Scorecard.current.flatRankings {
            var tableScores: Float = 0
            for tableNumber in 1...scorecard.tables {
                if let table = Scorecard.current.tables[tableNumber] {
                    tableScores += table.score(ranking: ranking, seat: .north)
                }
            }
            ranking.score = 0
            ranking.score += Scorecard.aggregate(total: tableScores, count: scorecard.tables, places: scorecard.type.matchPlaces, type: scorecard.type.matchAggregate) ?? 0
        }
    }
    
  // MARK: - Validation ======================================================================== -±
    
    func validate() {
        // Find self and partner
        myRanking = rankings.first(where: {$0.players.contains(where: {$0.value.lowercased() == myName})})
        if let myRanking = myRanking {
            myRankingSeat = myRanking.players.first(where: {$0.value.lowercased() == myName})?.key
            let partnerName = myRanking.players[myRankingSeat!.partner]
            partner = MasterData.shared.players.first(where: {$0.bboName.lowercased() == partnerName?.lowercased() || $0.name.lowercased() == partnerName?.lowercased()})
            if partner != scorecard?.partner {
                warnings.append("Partner in imported scorecard does not match current scorecard")
            }
        } else {
            warnings.append("Unable to find '\(myName ?? "name")' in imported scorecard")
        }
        
        // Check scoring type
        if type != scorecard?.type.boardScoreType {
            error = "Scoring type in imported scorecard must be consistent with current scorecard"
        }
        
        var boards: Int
        if scorecard?.tables == 1 || !(scorecard?.resetNumbers ?? false) {
            boards = scorecard!.boards
        } else {
            boards = scorecard!.boardsTable
        }
        
        // Check total number of boards
        if boardCount != boards {
            if scorecard?.resetNumbers ?? false {
                error = "Number of boards must equal current scorecard boards per table on partial imports"
            } else {
                warnings.append("Number of boards imported does not match current scorecard")
            }
        }
        checkBoardsPerTable(name: myName)
    }
}

class ImportedRanking {
    public var number: Int?
    public var section: Int = 1
    public var players: [Seat:String] = [:]
    public var score: Float?
    public var xImps: [Pair:Float] = [:]
    public var ranking: Int?
    public var bboPoints: Float?
}

class ImportedTraveller {
    public var board: Int?
    public var ranking: [Seat: Int] = [:]
    public var section: [Seat: Int] = [:]
    public var contract: Contract?
    public var declarer: Seat?
    public var made: Int?
    public var lead: String?
    public var points: Int?
    public var nsScore: Float?
    public var nsXImps: Float?
    public var playData: String?
}

