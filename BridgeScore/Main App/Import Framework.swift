//
//  Import Framework.swift
//  BridgeScore
//
//  Created by Marc Shearer on 20/03/2022.
//

import CoreData

public enum ImportSource: Int, Equatable, CaseIterable {
    case none = 0
    case bbo = 1
    case bridgeWebs = 2
    
    static var validCases: [ImportSource] {
        return ImportSource.allCases.filter({$0 != .none})
    }
    
    var string: String {
        switch self {
        case .none:
            return "No import"
        case .bbo:
            return "Import from BBO"
        case .bridgeWebs:
            return "Import from BridgeWebs"
        }
    }
}

enum ImportFormat {
    case individual
    case pairs
    case teams
    
    public var players: Int {
        switch self {
        case .individual:
            return 1
        case .pairs:
            return 2
        case.teams:
            return 4
        }
    }
}

class ImportedScorecard: NSObject {
    var importSource: ImportSource?
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
    var format: ImportFormat = .pairs

    // MARK: - Import to main data structures =================================================================== -
        
    public func importScorecard() {
        // Import source
        scorecard?.importSource = importSource!
        
        // Update date
        if let date = date {
            scorecard?.date = date
        }
        
        // Update partner
        if let partner = partner {
            scorecard?.partner = partner
        }
        
        // Clear manual totals
        scorecard.manualTotals = false
        
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
        }
        
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
                rebuildRankingTotals()
                Scorecard.updateScores(scorecard: scorecard)
            } else {
                importRankings()
            }
          
            Scorecard.current.saveAll(scorecard: scorecard)
        }
    }
    
    private func importTable(tableNumber: Int, boardOffset: Int = 0) {
        if let scorecard = scorecard,
            let myRanking = myRanking,
            let myNumber = myRanking.number,
            let myPair = myRanking.way {
            
            let mySection = myRanking.section
            let table = Scorecard.current.tables[tableNumber]
            
            for tableBoardNumber in 1...scorecard.boardsTable {
                
                let boardNumber = ((tableNumber - 1) * scorecard.boardsTable) + tableBoardNumber
                
                if let lines = travellers[boardNumber - boardOffset],
                   let myLine = myTravellerLine(lines: lines, myNumber: myNumber, myPair: myPair, mySection: mySection) {
                    
                    let mySeat = seat(line: myLine, ranking: myRanking, myPair: myPair, name: myName) ?? .unknown
                    var versus = ""
                    for seat in Seat.validCases {
                        if seat != mySeat && (scorecard.type.players == 1 || seat.pair != myPair) {
                            let otherNumber = myLine.ranking[seat] ?? myNumber
                            if let ranking = otherRanking(number: otherNumber, myPair: mySeat.pair, section: mySection), let otherName = ranking.players[seat]  {
                                if versus != "" {
                                    versus += " & "
                                }
                                let name = MasterData.shared.realName(bboName: otherName) ?? "Unknown" // Try bbo lookup but will fail on other imports and return itself
                                versus += name
                            }
                        }
                    }
                    table?.versus = versus
                    table?.sitting = mySeat
                    
                    importBoard(myLine: myLine, boardNumber: boardNumber, myRanking: myRanking)
                } else {
                    table?.versus = "Sitout"
                }
                importTravellers(boardNumber: boardNumber, boardOffset: boardOffset)
            }
        }
    }
    
    func importBoard(myLine: ImportedTraveller, boardNumber: Int, myRanking: ImportedRanking) {
        let board = Scorecard.current.boards[boardNumber]
        board?.contract = myLine.contract ?? Contract()
        board?.declarer = myLine.declarer ?? .unknown
        board?.made = myLine.made
        if let nsScore = myLine.nsScore, let scorecard = scorecard {
            var myPair: Pair
            if (myRanking.way ?? .unknown) != .unknown {
                myPair = myRanking.way!
            } else if myLine.ranking[.north] == myRanking.number || myLine.ranking[.south] == myRanking.number {
                myPair = .ns
            } else {
                myPair = .ew
            }
            board?.score = (myPair == .ns ? nsScore : scorecard.type.invertScore(score: nsScore))
        }
    }
    
    func importRankings(table: Int? = nil) {
        Scorecard.current.removeRankings(table: table)
        if let scorecard = scorecard {
            let sortedRankings = rankings.sorted(by: {($0.ranking ?? 0) < ($1.ranking ?? 0)})
            for (index, importedRanking) in sortedRankings.enumerated() {
                
                let section = importedRanking.section
                
                if let number = importedRanking.number,
                   let way = importedRanking.way {
                    let ranking = RankingViewModel(scorecard: scorecard, table: table ?? 0, section: section, way: way, number: number)
                    
                    // Sort out ties
                    if index > 0 && sortedRankings[index - 1].score == ranking.score {
                        ranking.ranking = sortedRankings[index - 1].ranking!
                    } else {
                        ranking.ranking = importedRanking.ranking ?? 0
                    }
                    ranking.players = importedRanking.players
                    ranking.score = importedRanking.score ?? 0
                    ranking.points = importedRanking.bboPoints ?? 0
                    ranking.xImps = importedRanking.xImps
                    ranking.way = importedRanking.way ?? .unknown
                    
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
    
    func myTravellerLine(lines: [ImportedTraveller], myNumber: Int, myPair: Pair? = .unknown, mySection: Int) -> ImportedTraveller? {
        var result: ImportedTraveller?
        var validSeats = Seat.validCases
        
        if myPair != .unknown {
            validSeats = myPair!.seats
        }
        for seat in validSeats {
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
    
    func otherRanking(number: Int, myPair: Pair, section: Int) -> ImportedRanking? {
        return rankings.first(where: {$0.number == number && $0.section == section && $0.way != myPair})
    }
    
    func seat(line: ImportedTraveller, ranking: ImportedRanking, myPair: Pair = .unknown, name: String) -> Seat? {
        var result: Seat?
        
        for seat in Seat.validCases {
            if myPair == .unknown || myPair.seats.contains(where: {$0 == seat}) {
                if line.ranking[seat] == ranking.number {
                    if ranking.players[seat]?.lowercased() == name {
                        result = seat
                        break
                    }
                }
            }
        }
        
        return result
    }
    
    func recalculateTravellers() {
        // BBO etc sometimes exports cross imps on boards rather than team imp differences - recalculate them
        for (board, boardTravellers) in travellers {
            for traveller in boardTravellers {
                if scorecard!.type.players == 4 {
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
                } else if scorecard.type.boardScoreType == .percent {
                    if let nsMps = traveller.nsMps, let totalMps = traveller.totalMps {
                        traveller.nsScore = Utility.round(Float(nsMps) / Float(totalMps) * 100, places: scorecard.type.boardPlaces)
                    }
                } else if scorecard.type.boardScoreType == .aggregate {
                    traveller.nsScore = Float(traveller.points ?? 0)
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
           let myNumber = myRanking.number,
           let myPair = myRanking.way {
            let mySection = myRanking.section
            for (_, lines) in travellers.sorted(by: {$0.key < $1.key}) {
                if let line = myTravellerLine(lines: lines, myNumber: myNumber, myPair: myPair, mySection: mySection) {
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
        for ranking in Scorecard.current.rankingList {
            var tableScores: Float = 0
            var tablesPlayed = 0
            for tableNumber in 1...scorecard.tables {
                if let table = Scorecard.current.tables[tableNumber] {
                    if !scorecard.resetNumbers || ranking.table == tableNumber {
                        let players = scorecard.type.players
                        var seats:[Seat] = []
                            // Need to pick up this person in all seats if individual
                            // North or East if pairs, and North only if teams since 1 of team will have sat north
                        if players == 1 { seats = Seat.validCases }
                        else if players == 2 {
                            if ranking.way == .unknown {
                                seats = [.north, .east]
                            } else {
                                seats = [ranking.way.seats.first!]
                            }
                        } else { seats = [.north] }
                        if let tableScore = table.score(ranking: ranking, seats: seats) {
                            tableScores += tableScore
                            tablesPlayed += 1
                        }
                    }
                }
            }
            if scorecard.resetNumbers {
                ranking.score = Scorecard.aggregate(total: tableScores, count: 1, boards: scorecard.boardsTable, subsidiaryPlaces: scorecard.type.boardPlaces, places: scorecard.type.tablePlaces, type: scorecard.type.tableAggregate) ?? 0
            } else {
                ranking.score = Scorecard.aggregate(total: tableScores, count: tablesPlayed, boards: scorecard.boards, subsidiaryPlaces: scorecard.type.tablePlaces, places: scorecard.type.matchPlaces, type: scorecard.type.matchAggregate) ?? 0
            }
        }
        
        // Now reset ranking position on each ranking, set ties and fill in my position and field entry
        var position = 0
        var groupEntry = 0
        var myGroup = false
        Scorecard.current.scanRankings { (ranking, newGrouping, lastRanking) in
            if newGrouping {
                if myGroup && !scorecard.resetNumbers {
                    scorecard.entry = groupEntry
                }
                position = 0
                groupEntry = 0
                myGroup = false
            }
            position += 1
            groupEntry += 1
            ranking.ranking = position
            if ranking.score == lastRanking?.score {
                lastRanking!.tie = true
                ranking.ranking = lastRanking!.ranking
                ranking.tie = true
            }
            if ranking.number == myRanking?.number {
                myGroup = true
                if !scorecard.resetNumbers {
                    scorecard.position = ranking.ranking
                }
            }
        }
        scorecard.entry = groupEntry
    }
    
  // MARK: - Validation ======================================================================== -
    
    func validate() {
        // Find self and partner
        myRanking = rankings.first(where: {$0.players.contains(where: {$0.value.lowercased() == myName})})
        if let myRanking = myRanking {
            myRankingSeat = myRanking.players.first(where: {$0.value.lowercased() == myName})?.key
            if format != .individual {
                let partnerName = myRanking.players[myRankingSeat!.partner]
                partner = MasterData.shared.players.first(where: {$0.bboName.lowercased() == partnerName?.lowercased() || $0.name.lowercased() == partnerName?.lowercased()})
                if partner != scorecard?.partner {
                    warnings.append("Partner in imported scorecard does not match current scorecard")
                }
            }
        } else {
            error = "Unable to find '\(myName ?? "name")' in imported scorecard"
        }
        
        // Check scoring type
        if type != scorecard?.type.boardScoreType || format.players != scorecard?.type.players {
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
    public var way: Pair? = .unknown
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
    public var nsMps: Float?
    public var totalMps: Float?
    public var nsScore: Float?
    public var nsXImps: Float?
    public var playData: String?
}

