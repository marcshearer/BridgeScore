//
//  Import Framework.swift
//  BridgeScore
//
//  Created by Marc Shearer on 20/03/2022.
//

import CoreData
import SwiftUI

public enum ImportSource: Int, Equatable, CaseIterable {
    case none = 0
    case bbo = 1
    case bridgeWebs = 2
    case pbn = 3
    
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
        case .pbn:
            return "Import PBN file"
        }
    }
    
    var from: String {
        switch self {
        case .none:
            return ""
        case .bbo:
            return "BBO"
        case .bridgeWebs:
            return "BridgeWebs"
        case .pbn:
            return "PBN file"
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
    var boards: [Int:ImportedBoard] = [:]
    var warnings: [String] = []
    var error: String?
    var scorecard: ScorecardViewModel!
    var boardsTable: Int?
    var table: Int = 1
    var format: ImportFormat = .pairs
    var hand: String?
    var dealer: Seat?
    var vulnerability: Vulnerability?
    var doubleDummyTricks: [Seat:[Suit:Int]] = [:]
    var identifySelf = false
    
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
                    if boardsTable > 0 {
                        scorecard?.boardsTable = boardsTable
                    }
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
                        if seat != mySeat && (scorecard.type.players == 1 || seat.pair != mySeat.pair) {
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
                    
                    importBoard(myLine: myLine, boardNumber: boardNumber, boardOffset: boardOffset, myRanking: myRanking)
                } else {
                    table?.versus = "Sitout"
                }
                importTravellers(boardNumber: boardNumber, boardOffset: boardOffset)
            }
        }
    }
    
    func importBoard(myLine: ImportedTraveller, boardNumber: Int, boardOffset: Int, myRanking: ImportedRanking) {
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
        if let board = board, let importedBoard = boards[boardNumber - boardOffset] {
            board.hand = importedBoard.hand ?? ""
            board.optimumScore = importedBoard.optimumScore
            board.doubleDummy = [:]
            for declarer in Seat.validCases {
                board.doubleDummy[declarer] = [:]
                for suit in Suit.validCases {
                    if let made = importedBoard.doubleDummy[declarer]?[suit] {
                        board.doubleDummy[declarer]![suit] = DoubleDummyViewModel(scorecard: scorecard, board: board.board, declarer: declarer, suit: suit, made: made)
                    }
                }
            }
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
    
    func  scoreTravellers() {
        for (board, boardTravellers) in travellers {
            for traveller in boardTravellers {
                if traveller.contract?.level == .passout {
                    traveller.nsPoints = 0
                } else if let contract = traveller.contract, let declarer = traveller.declarer, let tricks = traveller.made {
                    traveller.nsPoints = Scorecard.points(contract: contract, vulnerability: Vulnerability(board: board), declarer: declarer, made: tricks, seat: .north)
                }
            }
        }
    }
    
    func recalculateTravellers() {
        // BBO etc sometimes exports cross imps on boards rather than team imp differences - recalculate them
        for (board, boardTravellers) in travellers {
            for traveller in boardTravellers {
                if scorecard!.type.players == 4 {
                    if let contract = traveller.contract, let declarer = traveller.declarer, let made = traveller.made {
                        if let otherTraveller = boardTravellers.first(where: {matchingTraveller($0, traveller)}), let otherContract = otherTraveller.contract, let otherDeclarer = otherTraveller.declarer, let otherMade = otherTraveller.made {
                            let vulnerability =  Vulnerability(board: board)
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
                    if traveller.nsMps == nil || traveller.totalMps == nil {
                        traveller.totalMps = (boardTravellers.count - 1) * 2
                        traveller.nsMps = 0
                        for otherTraveller in boardTravellers {
                            if otherTraveller != traveller {
                                if traveller.nsPoints! == otherTraveller.nsPoints! {
                                    traveller.nsMps! += 1
                                } else if traveller.nsPoints! > otherTraveller.nsPoints! {
                                    traveller.nsMps! += 2
                                }
                            }
                        }
                    }
                    traveller.nsScore = Utility.round(Float(traveller.nsMps!) / Float(traveller.totalMps!) * 100, places: scorecard.type.boardPlaces)
                } else if scorecard.type.boardScoreType == .aggregate {
                    traveller.nsScore = Float(traveller.nsPoints ?? 0)
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
        if scorecard.type.players == 4 {
            // First rebuild cross imps on each traveller
            for (boardNumber, _) in Scorecard.current.boards {
                let boardTravellers = Scorecard.current.travellers(board: boardNumber)
                for traveller in boardTravellers {
                    let otherTravellers = boardTravellers.filter{!($0 == traveller)}
                    let points = traveller.points(sitting: .north)
                    let nsXImps = otherTravellers.map({Float(BridgeImps(points: points - $0.points(sitting: .north)).imps)}).reduce(0,+) / Float(otherTravellers.count)
                    traveller.nsXImps = nsXImps
                    traveller.save()
                }
            }
            // Now put the total back on the ranking
            for ranking in Scorecard.current.rankingList {
                for pair in Pair.validCases {
                    let xImps = Scorecard.current.travellers(seat: pair.first, rankingNumber: ranking.number, section: ranking.section).map{$0.nsXImps * Float(pair.sign)}.reduce(0,+)
                    ranking.xImps[pair] = xImps
                    ranking.save()
                }
            }
        }
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
            if ranking.number == myRanking?.number && (myRanking?.way == .unknown || ranking.way == myRanking?.way) {
                myGroup = true
                if !scorecard.resetNumbers {
                    scorecard.position = ranking.ranking
                }
            }
            if ranking.way != .unknown && scorecard.type.players == 4 {
                // Shouldn't have a way on teams rankings
                ranking.way = .unknown
            }
        }
        if myGroup && !scorecard.resetNumbers {
            scorecard.entry = groupEntry
        }
    }
    
  // MARK: - Validation ======================================================================== -
    
    func validate() {
        // Find self and partner
        if !identifySelf {
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
    
    public func confirmDetails(importedScorecard: Binding<ImportedScorecard>, onError: @escaping ()->(), completion: @escaping ()->()) -> some View {
        @OptionalStringBinding(importedScorecard.wrappedValue.title) var titleBinding
        @OptionalStringBinding(Utility.dateString(importedScorecard.wrappedValue.date, format: "EEEE d MMMM yyyy")) var dateBinding
        @OptionalStringBinding(importedScorecard.wrappedValue.partner?.name) var partnerBinding
        @OptionalStringBinding("\(importedScorecard.wrappedValue.boardCount ?? 0)") var boardCountBinding
        @OptionalStringBinding("\(importedScorecard.wrappedValue.boardsTable ?? 0)") var boardsTableBinding

        
        return VStack(spacing: 0) {
            Banner(title: Binding.constant("Confirm Import Details"), backImage: Banner.crossImage)
            Spacer().frame(height: 16)
            
            if scorecard.tables > 1 && scorecard.resetNumbers {
                InsetView(title: "Import Settings") {
                    VStack(spacing: 0) {
                
                        StepperInput(title: "Import for table", field: importedScorecard.table, label: stepperLabel, minValue: Binding.constant(1), maxValue: Binding.constant(scorecard.tables))
                        
                        Spacer().frame(height: 16)
                    }
                }
            }
            
            InsetView(title: "BBO Import Details") {
                VStack(spacing: 0) {
                    
                    Input(title: "Title", field: titleBinding, clearText: false)
                    .disabled(true)
                    Input(title: "Date", field: dateBinding, clearText: false)
                    .disabled(true)
                    Input(title: "Partner", field: partnerBinding, clearText: false)
                    .disabled(true)
                    
                    Spacer().frame(height: 8)
                    Separator()
                    Spacer().frame(height: 8)

                    Input(title: (scorecard.resetNumbers ? "Boards / Table" : "Total Boards"), field: boardCountBinding, clearText: false)
                    .disabled(true)
                    if !scorecard.resetNumbers {
                        Input(title: "Boards / Table", field: boardsTableBinding, clearText: false)
                        .disabled(true)
                    }
                    
                    Spacer()
                }
            }

            if !importedScorecard.wrappedValue.warnings.isEmpty {
                InsetView(title: "Warnings") {
                    ScrollView {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 16)
                            ForEach(importedScorecard.wrappedValue.warnings, id: \.self) { (warning) in
                                HStack {
                                    Spacer().frame(width: 8)
                                    Text(warning)
                                    Spacer()
                                }
                                .frame(height: 30)
                            }
                            Spacer().frame(height: 16)
                        }
                    }
                }
            }
            
            VStack {
                Spacer().frame(height: 16)
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                                Text("Confirm")
                            Spacer()
                        }
                        Spacer()
                    }
                    .foregroundColor(Palette.highlightButton.text)
                    .background(Palette.highlightButton.background)
                    .frame(width: 120, height: 40)
                    .cornerRadius(10)
                    .onTapGesture {
                        Utility.mainThread {
                            completion()
                        }
                    }
                    Spacer()
                }
                Spacer().frame(height: 16)
            }
            .onAppear {
                if let error = importedScorecard.wrappedValue.error {
                    MessageBox.shared.show(error, okAction: {
                        onError()
                    })
                }
            }
        }
        .background(Palette.alternate.background)
    }
    
    private func stepperLabel(value: Int) -> String {
        return "Table \(value) of \(scorecard.tables)"
    }
}

class ImportedRanking : Identifiable, Equatable {
    public var id = UUID()
    public var number: Int?
    public var section: Int = 1
    public var full: String?
    public var players: [Seat:String] = [:]
    public var score: Float?
    public var xImps: [Pair:Float] = [:]
    public var ranking: Int?
    public var bboPoints: Float?
    public var way: Pair? = .unknown
    
    convenience init(number: Int, name: String) {
        self.init()
        self.number = number
        self.full = name
        for seat in Seat.validCases {
            players[seat] = "\(name) - \(seat.string.capitalized)"
        }
    }
    
    static func == (lhs: ImportedRanking, rhs: ImportedRanking) -> Bool {
        return lhs.id == rhs.id
    }
}

class ImportedTraveller: Equatable {
    public var board: Int?
    public var ranking: [Seat: Int] = [:]
    public var section: [Seat: Int] = [:]
    public var contract: Contract?
    public var declarer: Seat?
    public var made: Int?
    public var lead: String?
    public var nsPoints: Int?
    public var nsMps: Int?
    public var totalMps: Int?
    public var nsScore: Float?
    public var nsXImps: Float?
    public var playData: String?
       
    convenience init(board: Int) {
        self.init()
        self.board = board
    }

    static func == (lhs: ImportedTraveller, rhs: ImportedTraveller) -> Bool {
        return (lhs.ranking == rhs.ranking && lhs.section == rhs.section)
    }
}

class ImportedBoard {
    public var boardNumber: Int
    public var hand: String?
    public var doubleDummy: [Seat:[Suit:Int]] = [:]
    public var optimumScore: OptimumScore?
    
    init(boardNumber: Int) {
        self.boardNumber = boardNumber
    }
}
