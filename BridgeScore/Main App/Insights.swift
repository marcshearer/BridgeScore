//
//  Insights.swift
//  BridgeScore
//
//  Created by Marc Shearer on 25/04/2026.
//

import CoreData

class Insights {
    
    static func build() {
        initialise() // TODO Remove
        let cutoff = cutoff(date: "18/04/2026") // TODO Remove
        
        let boardMOs = CoreData.fetch(from: BoardMO.tableName) as! [BoardMO]
        for boardMO in boardMOs {
            if let scorecard = MasterData.shared.scorecard(id: boardMO.scorecardId), boardMO.contract.level != .blank, boardMO.madeEntered {
                if scorecard.importSource != .none  && scorecard.date >= cutoff {

                    // Setup board
                    let board = BoardViewModel(scorecard: scorecard, boardMO: boardMO)
                    let boardFilter = NSPredicate(format: "scorecardId = %@ and boardIndex16 = %i", boardMO.scorecardId as NSUUID, boardMO.boardIndex)

                    // Load existing board summary
                    var boardSummary: BoardSummaryViewModel
                    if let boardSummaryMO = (CoreData.fetch(from: BoardSummaryMO.tableName, filter: boardFilter) as! [BoardSummaryMO]).first {
                        // Existing
                        boardSummary = BoardSummaryViewModel(scorecard: scorecard, boardSummaryMO: boardSummaryMO)
                    } else {
                        // New
                        boardSummary = BoardSummaryViewModel(scorecard: scorecard, boardIndex: board.boardIndex)
                    }
            
                    // Load table
                    let tableNumber = ((board.boardIndex - 1) / scorecard.boardsTable) + 1
                    let tableFilter = NSPredicate(format: "scorecardId = %@ and table16 = %i", boardMO.scorecardId as NSUUID, tableNumber)
                    let tableMOs = CoreData.fetch(from: TableMO.tableName, filter: tableFilter) as! [TableMO]
                    if let tableMO = tableMOs.first {
                        let table = TableViewModel(scorecard: scorecard, tableMO: tableMO)
                        
                        // Load travellers
                        let travellerMOs = CoreData.fetch(from: TravellerMO.tableName, filter: boardFilter) as! [TravellerMO]
                        var travellers: [TravellerViewModel] = []
                        var excluded = false
                        for travellerMO in travellerMOs {
                            let traveller = TravellerViewModel(scorecard: scorecard, travellerMO: travellerMO)
                            if !excluded && traveller.contract == board.contract && traveller.made == board.made && traveller.declarer == board.declarer {
                                // Exclude one with same results as board assuming it is us
                                excluded = true
                            } else {
                                travellers.append(traveller)
                            }
                        }
                        
                        // Load Double Dummy (offsetting it by seat player)
                        let sitting = table.sitting
                        var doubleDummys: [SeatPlayer:[Suit:DoubleDummyViewModel]] = [:]
                        let doubleDummyMOs = CoreData.fetch(from: DoubleDummyMO.tableName, filter: boardFilter) as! [DoubleDummyMO]
                        for doubleDummyMO in doubleDummyMOs {
                            let doubleDummy = DoubleDummyViewModel(scorecard: scorecard, doubleDummyMO: doubleDummyMO)
                            // Add to double dummy MO dicionary
                            let seatPlayer = sitting.seatPlayer(doubleDummy.declarer)
                            if doubleDummys[seatPlayer] == nil {
                                doubleDummys[seatPlayer] = [:]
                            }
                            doubleDummys[seatPlayer]![doubleDummy.suit] = doubleDummy
                        }
                        
                        // Got everything - Build the board summary and save it
                        buildBoardSummary(boardSummary: boardSummary, scorecard: scorecard, board: board, table: table, travellers: travellers, doubleDummys: doubleDummys)
                        
                        if boardSummary.isNew || boardSummary.changed {
                            boardSummary.save()
                        }
                    }
                }
            }
        }
    }
    
    static func buildBoardSummary(boardSummary: BoardSummaryViewModel, scorecard: ScorecardViewModel, board: BoardViewModel, table: TableViewModel, travellers:  [TravellerViewModel], doubleDummys: [SeatPlayer:[Suit:DoubleDummyViewModel]]) {
        
        boardSummary.partner = scorecard.partner
        boardSummary.location = scorecard.location
        boardSummary.date = scorecard.date
        boardSummary.session = scorecard.sessions == 1 ? 0 : board.session
        boardSummary.boardNumber = board.boardNumber
        
        boardSummary.vulnerability = SeatVulnerability(boardNumber: board.boardNumber, sitting: table.sitting)
        boardSummary.eventType = scorecard.type.eventType
        boardSummary.boardScoreType = scorecard.type.boardScoreType
        boardSummary.contract = board.contract
        boardSummary.declarer = SeatPlayer(sitting: table.sitting, seat: board.declarer)
        boardSummary.made = board.made
        boardSummary.score = Int(board.score ?? 0)
        boardSummary.fieldSize = travellers.count + 1
        boardSummary.suitType = SuitType(suit: board.contract.suit)
        boardSummary.levelType = LevelType(level: board.contract.level, suit: board.contract.suit)
        
        var suitTravellers: [PairType:[TravellerViewModel]] = [:]
        var suitTricks: [PairType: [Int]] = [:]
        if travellers.count > 0 {
            for pairType in PairType.validCases {
                let match = table.sitting.pair.offset(by: pairType)
                let declareTravellers = travellers.filter({$0.declarer.pair == match})
                let suit = mode(in: declareTravellers.map{$0.contract.suit}) ?? .blank
                boardSummary.suit[pairType] = suit
                boardSummary.declare[pairType] = Int((declareTravellers.count * 100) / travellers.count)
                suitTravellers[pairType] = (suit == .blank ? [] : declareTravellers.filter({$0.contract.suit == suit}))
                suitTricks[pairType] = suitTravellers[pairType]!.map({$0.contract.tricks + $0.made})
                if pairType == .we && suitTricks[pairType]!.count > 0 {
                    boardSummary.gameOdds = (suitTricks[pairType]!.count(where: {$0 >= suit.gameTricks}) * 100) / suitTricks[pairType]!.count
                    boardSummary.slamOdds = (suitTricks[pairType]!.count(where: {$0 >= Values.smallSlamLevel.tricks}) * 100) / suitTricks[pairType]!.count
                }
                boardSummary.medianTricks[pairType] = median(in: suitTricks[pairType]!) ?? -1
                boardSummary.modeTricks[pairType] = mode(in: suitTricks[pairType]!) ?? -1
                boardSummary.ddTricks[pairType] = doubleDummys[pairType.seatPlayers.first!]?[suit]?.tricks ?? -1
            }
            // Consider competition
            boardSummary.compContract = Contract()
            boardSummary.compDeclarer = .unknown
            boardSummary.compDdMade = nil
            boardSummary.compMakeOdds = 0
            boardSummary.compDdScore = 0
            if boardSummary.declare[.we]! >= 20 && boardSummary.declare[.they]! >= 20 && boardSummary.suit[.we] != .noTrumps && boardSummary.levelType == .partScore {
                // Competitive auction where we have a suit
                if boardSummary.declarer.pairType == .we && (board.made ?? 1) < 0 {
                    // We went off - consider not competing - assume they are in 1 less of their suit
                    if let contract = Contract(lower: boardSummary.contract, suit: boardSummary.suit[.they]!) {
                        boardSummary.compContract = contract
                        boardSummary.compDeclarer = .they
                        boardSummary.compMakeOdds = (suitTricks[.they]!.count(where: {$0 >= contract.tricks}) * 100) / suitTricks[.they]!.count
                        if let ddTricks = boardSummary.ddTricks[.they], ddTricks > 0 {
                            boardSummary.compDdMade = ddTricks - contract.tricks
                        }
                    }
                } else if boardSummary.declarer.pairType == .they && (board.made ?? 1) >= 0 {
                    // They made - consider competing - assume we are in 1 higher of our suit
                    if let contract = Contract(higher: boardSummary.contract, suit: boardSummary.suit[.we]!) {
                        boardSummary.compContract = contract
                        boardSummary.compDeclarer = .we
                        boardSummary.compMakeOdds = (suitTricks[.we]!.count(where: {$0 >= contract.tricks}) * 100) / suitTricks[.we]!.count
                        if let ddTricks = boardSummary.ddTricks[.we] , ddTricks > 0 {
                            boardSummary.compDdMade = ddTricks - contract.tricks
                        }
                    }
                }
                if boardSummary.compDeclarer != .unknown {
                    if boardSummary.boardScoreType == .percent {
                        let makePoints = points(boardSummary: boardSummary, board: board, table: table, made: 0)
                        boardSummary.compMakeScore = rescoreMps(from: makePoints, travellers: travellers, vulnerability: board.vulnerability, seat: table.sitting)
                        if let ddMade = boardSummary.compDdMade {
                            let ddPoints = points(boardSummary: boardSummary, board: board, table: table, made: ddMade)
                            boardSummary.compDdScore = rescoreMps(from: ddPoints, travellers: travellers, vulnerability: board.vulnerability, seat: table.sitting)
                        }
                    }
                }
            }
        }
        let deal = Deal(cards: board.hand, playData: travellers.first?.playData ?? "")
        if !deal.isEmpty {
            for seatPlayer in SeatPlayer.validCases {
                let seat = table.sitting.offset(by: seatPlayer.offset)
                boardSummary.points[seatPlayer] = deal.hands[seat]?.hcp ?? 0
            }
        }
        
        var longestFit: [PairType:Int] = [:]
        var longestDD: [PairType:Int] = [:]
        boardSummary.totalTricks = 0
        boardSummary.totalTricksDd = 0
        for pairType in PairType.validCases {
            for suit in Suit.validCases {
                var suitFit = 0
                for seatPlayer in pairType.seatPlayers {
                    if let hand = deal.hands[table.sitting.seatPlayer(seatPlayer)] {
                        suitFit += hand.cards.filter{$0.suit == suit}.count
                    }
                }
                if suitFit > longestFit[pairType] ?? 0 {
                    longestFit[pairType] = suitFit
                    longestDD[pairType] = doubleDummys[pairType.seatPlayers.first!]?[suit]?.tricks ?? 0
                }
            }
            boardSummary.fit[pairType] = longestFit[pairType] ?? 0
            boardSummary.totalTricks += longestFit[pairType] ?? 0
            boardSummary.totalTricksDd += longestDD[pairType] ?? 0
        }
    }
    
    static func points(boardSummary: BoardSummaryViewModel, board: BoardViewModel, table: TableViewModel, made: Int) -> Int {
        Scorecard.points(contract: boardSummary.compContract, vulnerability: board.vulnerability, declarer: table.sitting.pair.offset(by: boardSummary.compDeclarer).seats.first!, made: made, seat: table.sitting)
    }
    
    static func rescoreMps(from scorePoints: Int, travellers: [TravellerViewModel], vulnerability: Vulnerability, seat: Seat) -> Int {
        let points = travellers.map{travellerPoints(traveller: $0, vulnerability: vulnerability, seat: seat)}
        let totalMps = points.count * 2 // (field - 1 * 2) as points doesn't contain our score
        let mps = (points.count(where: {$0 < scorePoints}) * 2) + (points.count(where: {$0 == scorePoints}) * 1)
        return (mps * 100) / totalMps
    }
    
    static func travellerPoints(traveller: TravellerViewModel, vulnerability: Vulnerability, seat: Seat) -> Int {
        Scorecard.points(contract: traveller.contract, vulnerability: vulnerability, declarer: traveller.declarer, made: traveller.tricksMade - traveller.contract.tricks, seat: seat)
    }
    
    static func mode<T: Hashable>(in array: [T]) -> T? {
        let counts = array.reduce(into: [:]) { counts, element in
            counts[element, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
    
    static func median(in array: [Int]) -> Int? {
        if array.isEmpty {
            nil
        } else {
            array.sorted(by: {$0 < $1})[(array.count - 1) / 2]
        }
    }
    
    static func Load() -> [BoardSummaryExtension] {
        var boardSummaries: [BoardSummaryExtension] = []
        // TODO Remove
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: BoardSummaryMO.tableName)
        do {
            let count = try CoreData.context.count(for: fetchRequest)
            print("Total records: \(count)")
        } catch {
            print("Error counting records: \(error)")
        }
        let boardSummaryMOs = CoreData.fetch(from: BoardSummaryMO.tableName, sort: [("date", .descending), ("boardIndex16", .ascending)]) as! [BoardSummaryMO]
        for boardSummaryMO in boardSummaryMOs {
            if let scorecard = MasterData.shared.scorecard(id: boardSummaryMO.scorecardId) {
                let boardSummary = BoardSummaryExtension(scorecard: scorecard, boardSummaryMO: boardSummaryMO)
                boardSummaries.append(boardSummary)
            }
        }
        return boardSummaries
    }
    
    private static func initialise() {
        let records = CoreData.fetch(from: BoardSummaryMO.tableName)
        for record in records {
            CoreData.context.delete(record)
            try! CoreData.context.save()
        }
    }
    
    private static func cutoff(date: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.date(from: date)!
    }
}

class BoardSummaryExtension : BoardSummaryViewModel {
    var board: BoardViewModel?
    var traveller: TravellerViewModel?
    var seat: Seat?
    
    init(scorecard: ScorecardViewModel, boardSummaryMO: BoardSummaryMO) {
        super.init(scorecard: scorecard, boardIndex: boardSummaryMO.boardIndex)
        self.boardSummaryMO = boardSummaryMO
        self.revert()
    }
}
