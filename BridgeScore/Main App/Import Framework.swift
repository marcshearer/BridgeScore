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
    case usebio = 4
    
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
        case .usebio:
            return "Import Usebio file"
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
        case .usebio:
            return "Usebio file"
        }
    }
}

class ImportedScorecard: NSObject, ObservableObject {
    var id = UUID()
    var importSource: ImportSource?
    var title: String?
    var boardCount: Int?
    var date: Date?
    var location: LocationViewModel?
    var partner: PlayerViewModel?
    var type: ScoreType?
    var rankings: [ImportedRanking] = []
    var rankingTables: [ImportedRankingTable] = []
    var myRanking: ImportedRanking?
    var myRankingSeat: Seat?
    var myName: String!
    var travellers: [Int:[ImportedTraveller]] = [:] // Board Index
    var boards: [Int:ImportedBoard] = [:]
    @Published var warnings: [String] = []
    @Published var error: String?
    var scorecard: ScorecardViewModel!
    var boardsTable: Int?
    var session: Int? = nil
    var eventType: EventType = .pairs
    var hand: String?
    var dealer: Seat?
    var vulnerability: Vulnerability?
    var doubleDummyTricks: [Seat:[Suit:Int]] = [:]
    var identifySelf = false
    
    public static let documentsUrl: URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last! as URL
    public static let importsURL = documentsUrl.appendingPathComponent("imports")
    
    // MARK: - Import to main data structures =================================================================== -
        
    public override init() {
        super.init()
    }
    
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
        
            // Update location
        if let location = location {
            scorecard?.location = location
        }
        
            // Clear manual totals
        scorecard.manualTotals = false
        
        if travellers.count > 0 {
            if !(scorecard?.isMultiSession ?? false) {
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
                    if scorecard.isMultiSession, let session = session {
                        let tables = scorecard.sessionTables(session: session)
                        for tableNumber in tables {
                            importTable(tableNumber: tableNumber, boardOffset: (scorecard.resetNumbers ? (session - 1) * scorecard.boardsSession : 0))
                        }
                        importRankings(session: session)
                        for table in tables {
                            importRankingTables(table: table)
                        }
                    } else {
                        for tableNumber in 1...scorecard.tables {
                            importTable(tableNumber: tableNumber)
                        }
                        importRankings()
                        importRankingTables()
                    }
                }
            } else {
                importRankings()
            }
            
            rebuildRankingTotals()
            Scorecard.updateScores(scorecard: scorecard)
            
            Scorecard.current.saveAll(scorecard: scorecard)
            scorecard.saveScorecard()
        }
    }
            
            
    func prepareForNext() {
        if let scorecard = scorecard {
            if scorecard.tables > 1 && scorecard.isMultiSession {
                scorecard.importNext += 1
            }
            scorecard.saveScorecard()
        }
    }
    
    private func importTable(tableNumber: Int, boardOffset: Int = 0) {
        var tableUpdated: Bool = false
        if let scorecard = scorecard,
            let myRanking = myRanking,
            let myPair = myRanking.way {
            
            let myNumber = myRanking.number
            let mySection = myRanking.section
            let table = Scorecard.current.tables[tableNumber]
            
            for tableBoardIndex in 1...scorecard.boardsTable {
                
                let boardIndex = ((tableNumber - 1) * scorecard.boardsTable) + tableBoardIndex
                
                if let lines = travellers[boardIndex - boardOffset], let myNumber = myNumber,
                   let myLine = myTravellerLine(lines: lines, myNumber: myNumber, myPair: myPair, mySection: mySection) {
                    
                    if !tableUpdated {
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
                        tableUpdated = true
                    }
                    
                    importBoard(myLine: myLine, boardIndex: boardIndex, boardOffset: boardOffset, myRanking: myRanking)
                } else {
                    table?.versus = "Sitout"
                }
                importTravellers(boardNumber: boardIndex, boardOffset: boardOffset)
            }
        }
    }
    
    func importBoard(myLine: ImportedTraveller, boardIndex: Int, boardOffset: Int, myRanking: ImportedRanking) {
        let board = Scorecard.current.boards[boardIndex]
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
        if let board = board, let importedBoard = boards[boardIndex - boardOffset] {
            board.hand = importedBoard.hand ?? ""
            board.optimumScore = importedBoard.optimumScore
            board.doubleDummy = [:]
            for declarer in Seat.validCases {
                board.doubleDummy[declarer] = [:]
                for suit in Suit.validCases {
                    if let made = importedBoard.doubleDummy[declarer]?[suit] {
                        board.doubleDummy[declarer]![suit] = DoubleDummyViewModel(scorecard: scorecard, board: board.boardIndex, declarer: declarer, suit: suit, made: made)
                    }
                }
            }
        }
    }
    
    func importRankings(session: Int? = nil) {
        Scorecard.current.removeRankings(session: session)
        if let scorecard = scorecard {
            let sortedRankings = rankings.sorted(by: {($0.ranking ?? 0) < ($1.ranking ?? 0)})
            for (index, importedRanking) in sortedRankings.enumerated() {
                
                let section = importedRanking.section
                
                if let number = importedRanking.number,
                   let way = importedRanking.way {
                    let ranking = RankingViewModel(scorecard: scorecard, session: session ?? 0, section: section, way: way, number: number)
                    
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
    
    func importRankingTables(table: Int? = nil) {
        Scorecard.current.removeRankingTables(table: table)
        if let scorecard = scorecard {
            for importedRankingTable in rankingTables {
                if let number = importedRankingTable.number, let way = importedRankingTable.way, let table = importedRankingTable.table, let score = importedRankingTable.score {
                    let rankingTable = RankingTableViewModel(scorecard: scorecard, number: number, section: importedRankingTable.section, way: way, table: table)
                    rankingTable.nsScore = score
                    Scorecard.current.insert(rankingTable: rankingTable)
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
    
    // MARK: - Shared file list routine
    
    static func fileList(scorecard: ScorecardViewModel, suffix: String, selected: URL?, decompose: ([URL]) -> [ImportFileData], completion: @escaping (URL)->()) -> some View {
        return VStack(spacing: 0) {
            Banner(title: Binding.constant("Choose file to import"), backImage: Banner.crossImage)
            Spacer().frame(height: 16)
            if let files = try? FileManager.default.contentsOfDirectory(at: ImportedScorecard.importsURL, includingPropertiesForKeys: nil).filter({$0.relativeString.uppercased().right(4) == "." + suffix.uppercased()}) {
                let fileData = decompose(files)
                if fileData.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("No import files found for this date")
                            .font(defaultFont)
                        Spacer()
                    }
                    Spacer()
                }
                ForEach(fileData.indices, id: \.self) { (index) in
                    VStack {
                        Spacer().frame(height: 8)
                        HStack {
                            Spacer().frame(width: 16)
                            HStack {
                                Text(fileData[index].date?.toString(format: "EEE d MMM yyyy", localized: false) ?? "")
                                Spacer()
                            }
                            .frame(width: 190)
                            Spacer().frame(width: 16)
                            Text((fileData[index].text).replacingOccurrences(of: "_", with: " "))
                            Spacer()
                            Spacer().frame(width: 16)
                        }
                        .font(.title2)
                        .minimumScaleFactor(0.5)
                        
                        Spacer().frame(height: 8)
                    }
                    .background((fileData[index].path == selected ? Palette.alternate : Palette.background).background)
                    .onTapGesture {
                        completion(fileData[index].path)
                    }
                }
            }
            Spacer()
        }
    }
        
    static func fileName(_ path: String) -> (String, String?) {
        let components = path.components(separatedBy: "/")
        var subComponents = components.last!.components(separatedBy: ".")
        let fileType = ((subComponents.last ?? "") == ""  ? nil : subComponents.last!)
        subComponents.removeLast()
        let text = subComponents.joined(separator: ".")
        return (text,fileType)
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
                if myRanking?.players[seat]?.lowercased() == myName {
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
                    if (traveller.nsMps == nil || traveller.totalMps == nil) && traveller.nsPoints != nil {
                        traveller.totalMps = (boardTravellers.count - 1) * 2
                        traveller.nsMps = 0
                        for otherTraveller in boardTravellers {
                            if otherTraveller != traveller {
                                if otherTraveller.nsPoints != nil {
                                    if traveller.nsPoints! == otherTraveller.nsPoints! {
                                        traveller.nsMps! += 1
                                    } else if traveller.nsPoints! > otherTraveller.nsPoints! {
                                        traveller.nsMps! += 2
                                    }
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
        if scorecard.type.boardScoreType == .percent && scorecard.type.isContinuousVp {
            // Don't re-score since don't have accurate formula / tables for this method
        } else {
            if scorecard.type.players == 4 {
                // First rebuild cross imps on each traveller
                for (boardNumber, _) in Scorecard.current.boards.filter({!scorecard.isMultiSession || $1.session == session}) {
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
                for ranking in Scorecard.current.rankingList.filter({!scorecard.isMultiSession || $0.session == session}) {
                    for pair in Pair.validCases {
                        let xImps = Scorecard.current.travellers(seat: pair.first, rankingNumber: ranking.number, section: ranking.section, session: (scorecard.isMultiSession ? session : nil)).map{$0.nsXImps * Float(pair.sign)}.reduce(0,+)
                        ranking.xImps[pair] = xImps
                        ranking.save()
                    }
                }
            }
            for ranking in Scorecard.current.rankingList.filter({!scorecard.isMultiSession || $0.session == session}) {
                var tableScores: Float = 0
                var tablesPlayed = 0
                for tableNumber in scorecard.sessionTables(session: session) {
                    if let table = Scorecard.current.tables[tableNumber] {
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
                var places: Int
                var aggregateType: AggregateType
                if session == nil {
                    aggregateType = scorecard.type.matchAggregate
                    places = scorecard.type.matchScoreType.places
                } else {
                    // Total tables for session
                    let tableScoreType = scorecard.type.tableScoreType
                    switch tableScoreType {
                    case .imp, .butlerImp, .xImp, .aggregate, .vp:
                        aggregateType = .total
                    case .percent:
                        aggregateType = .average
                    case .unknown:
                        aggregateType = .unknown
                    }
                    places = tableScoreType.places
                }
                ranking.score = aggregateType.aggregate(total: tableScores, count: tablesPlayed, boards: scorecard.boardsSession, places: places) ?? 0
            }
        }
        if let session = session { 
            updateRankingPositions(session: session)
            mergedSessionRankings()
        }
        updateRankingPositions(session: 0)
    }
    
    func mergedSessionRankings() {
        var lastRanking: RankingViewModel?
        var lastTotal:Float = 0
        var lastCount = 0
        
        Scorecard.current.removeRankings(session: 0)
        let rankings = Scorecard.current.rankingList.sorted(by: {NSObject.sort($0, $1, sortKeys: [("section", .ascending), ("number", .ascending), ("waySort", .ascending)])})
        for ranking in rankings {
            if let lastRanking = lastRanking, lastRanking.number == ranking.number && lastRanking.section == ranking.section && (lastRanking.way == ranking.way || scorecard.type.players == 4) {
                // Add this ranking to the list
                lastCount += 1
                lastTotal += ranking.score
                lastRanking.score = scorecard.type.matchAggregate.aggregate(total: lastTotal, count: lastCount, boards: scorecard.boardsSession * lastCount, places: scorecard.type.matchPlaces) ?? 0
                for pair in Pair.validCases {
                    if let pairXImps = ranking.xImps[pair] {
                        if lastRanking.xImps[pair] == nil {
                            lastRanking.xImps[pair] = pairXImps
                        } else {
                            lastRanking.xImps[pair]! += pairXImps
                        }
                    }
                }
            } else {
                // Save last ranking and set up a new one based on this ranking
                lastRanking?.insert()
                lastCount = 1
                lastTotal = ranking.score
                lastRanking = ranking.copied()
                lastRanking!.session = 0
            }
        }
        lastRanking?.insert()
    }
     
    func updateRankingPositions(session: Int?) {
        // Now reset ranking position on each ranking, set ties and fill in my position and field entry
        var position = 0
        var groupEntry = 0
        var myGroup = false
        Scorecard.current.scanRankings(session: session) { (ranking, newGrouping, lastRanking) in
            if newGrouping {
                if myGroup && (!scorecard.isMultiSession || session == 0) {
                    scorecard.entry = groupEntry
                }
                position = 0
                groupEntry = 0
                myGroup = false
            }
            position += 1
            groupEntry += 1
            ranking.ranking = position
            ranking.tie = false
            if !newGrouping && (ranking.score == lastRanking?.score) {
                lastRanking!.tie = true
                ranking.ranking = lastRanking!.ranking
                ranking.tie = true
            }
            if ranking.number == myRanking?.number && (myRanking?.way == .unknown || ranking.way == myRanking?.way) {
                myGroup = true
                if !scorecard.isMultiSession || session == 0 {
                    scorecard.position = ranking.ranking
                }
            }
            if ranking.way != .unknown && scorecard.type.players == 4 {
                // Shouldn't have a way on teams rankings
                ranking.way = .unknown
            }
        }
        if myGroup && (!scorecard.isMultiSession || session == 0) {
            scorecard.entry = groupEntry
        }
    }
    
  // MARK: - Validation ======================================================================== -
    
    func validate() {
        // Find self and partner
        if !identifySelf {
            myRanking = rankings.first(where: {$0.players.contains(where: {$0.value.lowercased() == myName})})
            if myRanking == nil {
                if let myBboName = scorecard.scorer?.bboName.lowercased() {
                    myRanking = rankings.first(where: {$0.players.contains(where: {$0.value.lowercased() == myBboName})})
                    if myRanking != nil {
                        // Results from BridgeWebs but bbo name not translated
                        myName = myBboName
                    }
                }
            }
            if let myRanking = myRanking {
                myRankingSeat = myRanking.players.first(where: {$0.value.lowercased() == myName})?.key
                if eventType != .individual {
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
        if type != scorecard?.type.boardScoreType || eventType.players != scorecard?.type.players {
            if type == scorecard?.type.boardScoreType && scorecard?.type.players == 1 {
                // Just force players to individual
                eventType = .individual
            } else {
                error = "Scoring type in imported scorecard must be consistent with current scorecard"
            }
        }
        
        var boards: Int
        if !(scorecard?.isMultiSession ?? false) {
            boards = scorecard!.boards
        } else {
            boards = scorecard!.boardsSession
        }
        
        // Check total number of boards
        if boardCount != boards {
            if scorecard?.isMultiSession ?? false {
                error = "Number of boards must equal current scorecard boards per session on partial imports"
            } else {
                warnings.append("Number of boards imported does not match current scorecard")
            }
        }
        checkBoardsPerTable(name: myName)
    }
    
    func lastMinuteValidate() {
        // Note this should be called after any previous imports have been action
        // It checks the data of the next import against the current state of the scorecard
        checkRankings()
    }
    
    public func confirmDetails(importedScorecard: Binding<ImportedScorecard>, suffix: String = "", onError: @escaping ()->(), completion: @escaping ()->()) -> some View {
        @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
        @OptionalStringBinding(importedScorecard.wrappedValue.title) var titleBinding
        @OptionalStringBinding(Utility.dateString(importedScorecard.wrappedValue.date, format: "EEEE d MMMM yyyy")) var dateBinding
        @OptionalStringBinding(importedScorecard.wrappedValue.partner?.name) var partnerBinding
        @OptionalStringBinding("\(importedScorecard.wrappedValue.boardCount ?? 0)") var boardCountBinding
        @OptionalStringBinding("\(importedScorecard.wrappedValue.boardsTable ?? 0)") var boardsTableBinding

        var editSession: Binding<Int> {
            Binding {
                self.scorecard.importNext
            } set: { (newValue) in
                self.scorecard.importNext = newValue
            }
        }
        
        return VStack(spacing: 0) {
            
            Banner(title: Binding.constant("Confirm Import Details\(suffix)"), backImage: Banner.crossImage)
            Spacer().frame(height: 16)
            
            if scorecard.isMultiSession {
                
                InsetView(title: "Import Settings") {
                    VStack(spacing: 0) {
                
                        StepperInput(title: "Import for session", field: editSession, label: sessionLabel, minValue: {1}, maxValue: { self.scorecard.sessions}, onChange: { (value) in
                            self.session = value
                        })
                        
                        Spacer().frame(height: 16)
                    }
                }
            }
            
            InsetView(title: "\((importSource ?? .none).from) Import Details") {
                VStack(spacing: 0) {
                    
                    Input(title: "Title", field: titleBinding, asText: true)
                    Input(title: "Date", field: dateBinding, asText: true)
                    Input(title: "Partner", field: partnerBinding, asText: true)
                    
                    Spacer().frame(height: 8)
                    Separator()
                    Spacer().frame(height: 8)

                    Input(title: (scorecard.isMultiSession ? "Boards / Session" : "Total Boards"), field: boardCountBinding, asText: true)
                    Input(title: "Boards / Table", field: boardsTableBinding, topSpace: 0, asText: true)
                    
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
        }
        .onAppear {
            if self.scorecard.isMultiSession {
                self.session = min(self.scorecard.importNext, self.scorecard.sessions)
            }
        }
        .background(Palette.alternate.background)
    }
    
    private func sessionLabel(value: Int) -> String {
        return "Session \(value) of \(scorecard.sessions)"
    }
    
    internal func checkRankings() {
        var minFound: Int?
        var errorMessage: String?
        var translate: [(from: Int, to: Int)] = []
        
        let existingRankings = Scorecard.current.rankingList.filter{$0.session == 0}
        if !existingRankings.isEmpty {
            for ranking in rankings {
                // Find existing ranking containing any player from this ranking
                var existingRanking: RankingViewModel?
                for seat in Seat.validCases {
                    existingRanking = existingRankings.filter{$0.players.contains(where: {$1 == ranking.players[seat]})}.first
                    if existingRanking != nil {
                        break
                    }
                }
                if let existingRanking = existingRanking {
                    // Check all players
                    var found = 0
                    for seat in Seat.validCases {
                        if existingRanking.players.contains(where: {$1 == ranking.players[seat]}) {
                            found += 1
                        } else {
                            // Not in this pair / team in existing rankings
                            // Check not in another pair / team in existing rankings
                            if !existingRankings.filter({$0.players.contains(where: {$1 == ranking.players[seat]})}).isEmpty {
                                // Give up
                                errorMessage = "Players in different \(scorecard.type.description)s"
                                break
                            }
                        }
                    }
                    if found < scorecard.type.players {
                        minFound = min(minFound ?? Int.max, found)
                    }
                    
                    if let rankingNumber = ranking.number, rankingNumber != existingRanking.number {
                        // Different pair / team numbers - need to translate!
                        translate.append((from: rankingNumber, to: existingRanking.number))
                    }
                } else  {
                    // All the members of this pair/team not in previous rankings - give up
                    errorMessage = "Entire \(scorecard.type.description) not found"
                    break
                }
            }
            if let errorMessage = errorMessage {
                error = "Unable to match \(scorecard.type.description)s (\(errorMessage))"
            } else {
                if let minFound = minFound {
                    warnings.append("Some \(scorecard.type.description)s have only \(minFound) players matching existing sessions")
                }
                if !translate.isEmpty {
                        // Carry out translation
                    for ranking in rankings {
                        for (from, to) in translate {
                            if ranking.number == from {
                                ranking.number = to
                                break
                            }
                        }
                    }
                    for rankingTable in rankingTables {
                        for (from, to) in translate {
                            if rankingTable.number == from {
                                rankingTable.number = to
                                break
                            }
                        }
                    }
                    for (_, boardTravellers) in travellers {
                        for traveller in boardTravellers {
                            for seat in Seat.validCases {
                                if let number = traveller.ranking[seat] {
                                    for (from, to) in translate {
                                        if number == from {
                                            traveller.ranking[seat] = to
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }
                    warnings.append("\(scorecard.type.description) numbers changed to match existing sessions")
                }
            }
        }
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

class ImportedRankingTable : Identifiable {
    public var id = UUID()
    public var number: Int?
    public var section: Int = 1
    public var way: Pair? = .unknown
    public var table: Int?
    public var score: Float?
    
    convenience init(number: Int, section: Int, way: Pair, table: Int, score: Float?) {
        self.init()
        self.number = number
        self.section = section
        self.way = way
        self.table = table
        self.score = score
    }
}

class ImportedTraveller: Equatable {
    public var board: Int?
    public var ranking: [Seat: Int] = [:]
    public var section: [Seat: Int] = [:]
    public var direction: Pair?
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

class ImportFileData {
    var path: URL
    var fileName: String
    var number: Int?
    var text: String
    var date: Date?
    var fileType: String?
    var contents: String?
    var associated: String?
    
    init(_ path: URL, _ fileName: String, _ number: Int? = nil, _ text: String, _ date: Date?, _ fileType: String?, contents: String? = nil) {
        self.path = path
        self.fileName = fileName
        self.number = number
        self.text = text
        self.date = date
        self.fileType = fileType
        self.contents = contents
    }
}
