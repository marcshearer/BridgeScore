//
//  import PBN.swift
//  BridgeScore
//
//  Created by Marc Shearer on 18/09/2023.
//

import CoreData
import SwiftUI
import CoreMedia
import UniformTypeIdentifiers

class ImportUsebio {
    
    static let filterSessionId: String? = nil // Set to a session id e.g. "2" to import that session only
    
    public class func createImportScorecardFrom(fileURL: URL, scorecard: ScorecardViewModel, completion: @escaping (ImportedUsebioScorecard?, String?)->()) {
        
        if let data = try? Data(contentsOf: fileURL) {
            let importedScorecard = ImportedUsebioScorecard(data: data, filterSessionId: filterSessionId, scorecard: scorecard)
            importedScorecard.parse { (error) in
                if error == nil {
                    completion(importedScorecard, nil)
                } else {
                    completion(nil, error)
                }
            }
        } else {
            completion(nil, nil)
        }
    }
    
    public class func createImportedScorecardFrom(droppedFiles fileData: ImportFileData, scorecard: ScorecardViewModel, completion: @escaping (ImportedUsebioScorecard?, String?)->()) -> [ImportedUsebioScorecard] {
        // Version for drop of files
        if let data = fileData.contents?.data(using: .utf8) {
            let importedScorecard = ImportedUsebioScorecard(data: data, filterSessionId: filterSessionId, scorecard: scorecard)
            importedScorecard.parse { (error) in
                if error == nil {
                    completion(importedScorecard, nil)
                } else {
                    completion(nil, error)
                }
            }
            return [importedScorecard]
        } else {
            completion(nil, nil)
            return []
        }
    }
    
    public static func parse(_ line: String) -> (key: String, value: String) {
        let line = line.trim()
        if line.left(1) == "<" && line.right(1) == ">" {
            let components = line.replacingOccurrences(of: ">", with: "<").mid(1, line.count - 2).components(separatedBy: "<")
            if components.count == 3 {
                return(components[0].ltrim().rtrim(), components[1])
            }
        }
        return ("", "")
    }
}

struct ImportUsebioScorecard: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var scorecard: ScorecardViewModel
    var completion: (()->())? = nil
    @State private var selected: URL? = nil
    @State private var importedUsebioScorecard: ImportedUsebioScorecard!
    @State private var identifySelf = false
    @State private var importing: Bool = false
    private let uttypes = [UTType.data]
    @State private var dropZoneEntered = false
    @State private var droppedFiles: [(filename: String, contents: String)] = []
    
    var body: some View {
        StandardView("Detail") {
            if selected == nil {
                if MyApp.target == .macOS {
                    dropZone
                } else {
                    fileList
                }
            } else if !importing {
                let importedScorecard = Binding.constant(importedUsebioScorecard as ImportedScorecard)
                importedUsebioScorecard.confirmDetails(importedScorecard: importedScorecard, onError: {
                    presentationMode.wrappedValue.dismiss()
                }, completion: {
                    importing = true
                })
            } else {
                importingFile
            }
        }
    }
    
    var dropZone: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("Drop Usebio File"), backImage: Banner.crossImage)
            HStack {
                Spacer().frame(width: 50)
                VStack {
                    Spacer().frame(height: 50)
                    ZStack {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .foregroundColor(dropZoneEntered ? Palette.contrastTile.background : Palette.background.background)
                        HStack {
                            Spacer().frame(width: 50)
                            Spacer()
                            VStack {
                                Spacer()
                                Text("Drop Usebio XML Import File Here").font(bannerFont)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            Spacer()
                            Spacer().frame(width: 50)
                        }
                        .overlay(RoundedRectangle(cornerRadius: 30)
                            .strokeBorder(style: StrokeStyle(lineWidth: 5, dash: [10, 5]))
                            .foregroundColor(Palette.gridLine))
                    }
                    .onDrop(of: uttypes, delegate: ScorecardDropFiles(dropZoneEntered: $dropZoneEntered, droppedFiles: $droppedFiles))
                    Spacer().frame(height: 50)
                }
                Spacer().frame(width: 50)
            }
            .onChange(of: droppedFiles.count, initial: false) {
                if !droppedFiles.isEmpty {
                    let fileData = processDroppedFile(droppedFile: droppedFiles.first!)
                    let imported = ImportUsebio.createImportedScorecardFrom(droppedFiles: fileData, scorecard: scorecard) { (imported, error) in
                        if let imported = imported {
                            self.selected = URL(string: droppedFiles.first!.filename)
                            importedUsebioScorecard = imported
                            identifySelf = imported.identifySelf
                        } else {
                            MessageBox.shared.show(error ?? "Unable to import scorecard", okAction: {
                                presentationMode.wrappedValue.dismiss()
                            })
                        }
                        droppedFiles = []
                    }
                }
            }
        }
    }
    
    func processDroppedFile(droppedFile: (filename: String, contents: String)) -> ImportFileData {
        return ImportFileData(droppedFile.filename, nil, "", nil, nil, contents: droppedFile.contents)
    }
    
    var fileList: some View {
        ImportedScorecard.fileList(scorecard: scorecard, suffix: "xml", selected: selected, decompose: decompose) { selected in
            if scorecard.scorer != nil {
                ImportUsebio.createImportScorecardFrom(fileURL: selected, scorecard: scorecard) { (imported, error) in
                    if let imported = imported {
                        self.selected = selected
                        importedUsebioScorecard = imported
                        identifySelf = imported.identifySelf
                    } else {
                        MessageBox.shared.show(error ?? "Unable to import scorecard", okAction: {
                            presentationMode.wrappedValue.dismiss()
                        })
                    }
                }
            } else {
                MessageBox.shared.show("In order to import a scorecard a player must be defined as yourself", okAction: {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }
    
    var importingFile: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("Import Usebio File"), backImage: Banner.crossImage)
            Spacer()
            Text("Importing file...")
                .font(defaultFont)
            Spacer()
        }
        .onAppear {
            Utility.executeAfter(delay: 0.1) {
                importedUsebioScorecard.importScorecard()
                completion?()
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    func decompose(_ paths: [URL]) -> [(URL, Int?, String, Date?)] {
        var result: [(path: URL, number: Int?, text: String, date: Date?)] = []
        
        for path in paths {
            var text: String?
            var date: Date?
            
            if let contents = try? String(contentsOf: path) {
                if contents.uppercased().contains("<USEBIO VERSION") {
                    let lines = contents.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
                    if let line = lines.filter({$0.ltrim().uppercased().starts(with: "<EVENT_DESCRIPTION>")}).first {
                        text = ImportUsebio.parse(line).value
                    }
                    if let line = lines.filter({$0.ltrim().starts(with: "<DATE>")}).first {
                        let dateString = ImportUsebio.parse(line).value
                        if dateString != "" {
                            date = Date(from: dateString.replacingOccurrences(of: ".", with: "/"), format: "dd/MM/yyyy")
                        }
                    }
                }
            }
            if let text = text, let date = date {
                result.append((path, 1, text, date))
            }
        }
        let baseDate = Date(timeIntervalSinceReferenceDate: 0)
        return result.filter({Date.startOfDay(from: $0.date ?? baseDate) == Date.startOfDay(from: scorecard.date)}).sorted(by: {($0.number ?? 0) > ($1.number ?? 0)})
    }
}

enum ImportedRankingItemType {
    case team
    case pair
    case player
}

class ImportedUsebioRanking {
    var itemType: ImportedRankingItemType
    var currentPair: Pair = .ns
    var currentSeat: Seat = .north
    var ranking: ImportedRanking
    
    init(itemType: ImportedRankingItemType, number: Int, name: String) {
        self.itemType = itemType
        self.ranking = ImportedRanking(number: number, name: name)
    }
}

class ImportedUsebioRankingTable {
    var table: Int?
    var ranking: [Seat:Int] = [:]
    var section: [Seat:Int] = [:]
    var rankingTable: [Pair:ImportedRankingTable] = [:]
}

class ImportedUsebioBoard {
    var boardNumber: Int!
    var travellers: [ImportedTraveller] = []
}

class ImportedUsebioScorecard: ImportedScorecard, XMLParserDelegate {
    private var data: Data!
    private var parser: XMLParser!
    private let replacingSingleQuote = "@@replacingSingleQuote@@"
    private var root: Node?
    private var current: Node?
    private var filterSessionId: String?
    private var usebioVersion: String?
    private var currentRanking: ImportedUsebioRanking!
    private var currentMatch: ImportedUsebioRankingTable!
    private var currentBoard: ImportedUsebioBoard!
    private var completion: ((String?)->())?
    
    init(data: Data, filterSessionId: String? = nil, scorecard: ScorecardViewModel? = nil) {
        super.init()
        self.importSource = .pbn
        let string = String(decoding: data, as: UTF8.self)
        let replacedQuote = string.replacingOccurrences(of: "&#39;", with: replacingSingleQuote)
        self.data = replacedQuote.data(using: .utf8)
        self.filterSessionId = filterSessionId
        
            // Set values to match scorecard
        if let scorecard = scorecard {
            type = scorecard.type.boardScoreType
            var boards: Int
            if scorecard.tables == 1 || !scorecard.resetNumbers {
                boards = scorecard.boards
            } else {
                boards = scorecard.boardsTable
            }
            boardCount = boards
            switch scorecard.type.players {
            case 1:
                format = .individual
            case 4:
                format = .teams
            default:
                format = .pairs
            }
        }
        
        self.scorecard = scorecard
        let scorer = scorecard!.scorer
        myName = scorer!.name.lowercased()
        
    }
    
    public func parse(completion: ((String?)->())? = nil) {
        self.completion = completion
        root = Node(name: "MAIN", process: processMain)
        current = root
        parser = XMLParser(data: self.data)
        parser.delegate = self
        parser.parse()
    }
    
    private func parseComplete() {
        if error == nil {
            combineRankings()
            scoreTravellers()
            recalculateTravellers()
            validate()
        }
        completion?(error)
    }
    
    // MARK: Processors
    
    private func processMain(name: String, attributes: [String : String]) {
        switch name {
        case "USEBIO":
            current = current?.add(child: Node(name: name, attributes: attributes, process: processUsebio))
            usebioVersion = current?.attributes["Version"]
        default:
            current = current?.add(child: Node(name: name))
        }
    }
    
    func processUsebio(name: String, attributes: [String : String]) {
        switch name {
        case "EVENT":
            if let eventType = EventType(attributes["EVENT_TYPE"] ?? "INVALID") {
                format = eventType.format ?? format
            }
            current = current?.add(child: Node(name: name, attributes: attributes, process: processEvent))
        default:
            current = current?.add(child: Node(name: name))
        }
    }
    
    func processEvent(name: String, attributes: [String : String]) {
        switch name {
        case "EVENT_DESCRIPTION":
            current = current?.add(child: Node(name: name, completion: { [self] (value) in
                title = value
            }))
        case "DATE":
            current = current?.add(child: Node(name: name, completion: { [self] (value) in
                date = Date(timeInterval: TimeInterval(12*60*60), since: Utility.dateFromString(value, format: "dd/MM/yyyy")!)
            }))
        case "BOARD_SCORING_METHOD":
            current = current?.add(child: Node(name: name, completion: { [self] (value) in
                if let matchScoring = ScoringMethod(value) {
                    type = matchScoring.scoreType
                }
            }))
        case "BOARDS_PLAYED":
            current = current?.add(child: Node(name: name, completion: { (value) in
                // boardCount = Int(value) // Presupposes that all play all boards
            }))
        case "BOARDS_PER_ROUND":
            current = current?.add(child: Node(name: name, completion: { [self] (value) in
                boardsTable = Int(value)
            }))
        case "PARTICIPANTS":
            current = current?.add(child: Node(name: name, process: processParticipants))
        case "MATCH":
            currentMatch = ImportedUsebioRankingTable()
            current = current?.add(child: Node(name: name, process: processMatch))
        case "SESSION":
            var matched = true
            if let filterSessionId = filterSessionId {
                if let id = attributes["SESSION_ID"] {
                    if id.uppercased() != filterSessionId.uppercased() {
                        matched = false
                    }
                }
            }
            if matched {
                current = current?.add(child: Node(name: name, process: processEvent))
            } else {
                current = current?.add(child: Node(name: name))
            }
        case "SECTION":
            current = current?.add(child: Node(name: name, process: processEvent))
        case "BOARD":
            if currentMatch == nil {
                currentMatch = ImportedUsebioRankingTable()
            }
            currentBoard = ImportedUsebioBoard()
            current = current?.add(child: Node(name: name, process: processBoard))
        default:
            current = current?.add(child: Node(name: name))
        }
    }
    
    func processParticipants(name: String, attributes: [String : String]) {
        switch name {
        case "TEAM":
            let number = Int(attributes["TEAM_ID"] ?? "?") ?? 0
            let name = attributes["TEAM_NAME"] ?? ""
            currentRanking = ImportedUsebioRanking(itemType: .team, number: number, name: name)
            rankings.append(currentRanking.ranking)
            current = current?.add(child: Node(name: name, process: processTeam))
        case "PAIR":
            currentRanking = ImportedUsebioRanking(itemType: .pair, number: 0, name: "")
            rankings.append(currentRanking.ranking)
            current = current?.add(child: Node(name: name, process: processPair, completion: { [self] (_) in
                currentRanking.currentPair = .ew
                currentRanking.currentSeat = .east
            }))
        case "PLAYER":
            currentRanking = ImportedUsebioRanking(itemType: .player, number: 0, name: "name")
            rankings.append(currentRanking.ranking)
            current = current?.add(child: Node(name: name, process: processPlayer, completion: { [self] (_) in
                currentRanking.currentSeat = currentRanking.currentSeat.offset(by: 1)
                currentRanking.currentPair = currentRanking.currentSeat.pair
            }))
            fatalError("Individuals not completed yet")
        default:
            current = current?.add(child: Node(name: name))
        }
    }
    
    func processTeam(name: String, attributes: [String : String]) {
        switch name {
        case "PAIR":
            current = current?.add(child: Node(name: name, process: processPair, completion: { [self] (_) in
                currentRanking.currentPair = .ew
                currentRanking.currentSeat = .east
            }))
        case "PLAYER":
            current = current?.add(child: Node(name: name, process: processPlayer, completion: { [self] (_) in
                currentRanking.currentSeat = currentRanking.currentSeat.offsetNsEw(by: 1)
                currentRanking.currentPair = currentRanking.currentSeat.pair
            }))
        case "TOTAL_SCORE":
            current = current?.add(child: Node(name: name, completion: { [self] (value) in
                currentRanking.ranking.score = Float(value)
            }))
        default:
            processParticipant(name: name, attributes: attributes)
        }
    }
    
    func processPair(name: String, attributes: [String : String]) {
        let ranking = currentRanking.ranking
        switch name {
        case "PAIR_NUMBER":
            current = current?.add(child: Node(name: name, completion: { [self] (value) in
                if currentRanking.itemType == .pair {
                    ranking.number = Int(value)
                    ranking.full = value
                }
            }))
        case "TOTAL_SCORE":
            current = current?.add(child: Node(name: name, completion: { [self] (value) in
                if currentRanking.itemType == .pair {
                    ranking.score = Float(value)
                }
            }))
        case "PLAYER":
            current = current?.add(child: Node(name: name, process: processPlayer, completion: { [self] (_) in
                currentRanking.currentSeat = currentRanking.currentSeat.partner
            }))
        case "DIRECTION":
            current = current?.add(child: Node(name: name, completion: { [self] (value) in
                let way = Pair(string: value)
                ranking.way = way
                currentRanking.currentPair = way
                currentRanking.currentSeat = way.first
            }))
        default:
            processParticipant(name: name, attributes: attributes)
        }
    }
    
    func processPlayer(name: String, attributes: [String : String]) {
        let ranking = currentRanking.ranking
        let seat: Seat = currentRanking.currentSeat
        switch name {
        case "PLAYER_NUMBER":
            current = current?.add(child: Node(name: name, completion: { [self] (value) in
                if currentRanking.itemType == .player {
                    ranking.number = Int(value)
                    ranking.full = value
                }
            }))
        case "PLAYER_NAME":
            current = current?.add(child: Node(name: name, completion: { (value) in
                ranking.players[seat] = value
            }))
        case "TOTAL_SCORE":
            current = current?.add(child: Node(name: name, completion: { [self] (value) in
                if currentRanking.itemType == .player {
                    ranking.score = Float(value)
                }
            }))
        default:
            processParticipant(name: name, attributes: attributes)
        }
    }
    
    func processParticipant(name: String, attributes: [String : String]) {
        let ranking = currentRanking.ranking
        switch name {
        case "PLACE":
            current = current?.add(child: Node(name: name, completion: { (value) in
                ranking.ranking = Int(value.replacingOccurrences(of: "=", with: ""))
            }))
        case "TOTAL_SCORE", "PERCENTAGE":
            current = current?.add(child: Node(name: name, completion: { (value) in
                ranking.score = Float(value)
            }))
        default:
            current = current?.add(child: Node(name: name))
        }
    }
    
    func processMatch(name: String, attributes: [String : String]) {
        switch name {
        case "ROUND_NUMBER":
            current = current?.add(child: Node(name: name, completion: { [self] (value) in
                currentMatch.table = Int(value)!
            }))
        case "TEAM", "NS_PAIR_NUMBER":
            if currentMatch.ranking[.north] == nil {
                current = current?.add(child: Node(name: name, completion: { [self] (value) in
                    currentMatch.ranking[.north] = Int(value)
                    currentMatch.ranking[.south] = Int(value)
                }))
            }
        case "OPPOSING_TEAM", "EW_PAIR_NUMBER":
            if currentMatch.ranking[.east] == nil {
                current = current?.add(child: Node(name: name, completion: { [self] (value) in
                    currentMatch.ranking[.east] = Int(value)
                    currentMatch.ranking[.west] = Int(value)
                }))
            }
        case "BOARD":
            currentBoard = ImportedUsebioBoard()
            current = current?.add(child: Node(name: name, process: processBoard))
        case "NS_SCORE", "EW_SCORE":
            current = current?.add(child: Node(name: name, completion: { [self] (value) in
                let pair: Pair = (name == "NS_SCORE" ? .ns : .ew)
                if let rankingTable = currentMatch.rankingTable[pair], let score = Float(value) {
                    rankingTable.score = score
                } else {
                    if let number = currentMatch.ranking[pair.first], let table = currentMatch.table, let score = Float(value) {
                        currentMatch.rankingTable[pair] = ImportedRankingTable(number: number, section: 1, way: pair, table: table, score: score)
                        rankingTables.append(currentMatch.rankingTable[pair]!)
                    }
                }
            }))
        default:
            current = current?.add(child: Node(name: name))
        }
    }
    
    private func processBoard(name: String, attributes: [String : String]) {
        switch name {
        case "BOARD_NUMBER":
            current = current?.add(child: Node(name: name, completion: { [self] (value) in
                currentBoard.boardNumber = Int(value)
            }))
        case "TRAVELLER_LINE":
            let board = currentBoard.boardNumber!
            let traveller = ImportedTraveller(board: board)
            // Setup default rankings as not often given pair numbers on traveller
            let invert = (currentBoard.travellers.count > 0)
            for seat in Seat.validCases {
                traveller.ranking[seat] = currentMatch.ranking[invert ? seat.equivalent : seat]
                traveller.section[seat] = currentMatch.section[invert ? seat.equivalent : seat] ?? 1
            }
            currentBoard.travellers.append(traveller)
            if travellers[board] == nil {
                travellers[board] = []
            }
            travellers[board]!.append(traveller)
            current = current?.add(child: Node(name: name, process: processTravellerLine))
        default:
            current = current?.add(child: Node(name: name))
        }
    }

    private func processTravellerLine(name: String, attributes: [String : String]) {
        let traveller = currentBoard.travellers.last!
        switch name {
        case "DIRECTION":
            current = current?.add(child: Node(name: name, completion: { (value) in
                traveller.direction = value.uppercased() == "NS" ? .ns : .ew
            }))
        case "NS_PAIR_NUMBER":
            current = current?.add(child: Node(name: name, completion: { [self] (value) in
                let invert = (traveller.direction == .ew)
                for seat in Pair.ns.seats {
                    traveller.ranking[seat] = currentMatch.ranking[invert ? seat.equivalent : seat] ?? Int(value)
                    traveller.section[seat] = currentMatch.section[invert ? seat.equivalent : seat] ?? 1
                }
            }))
        case "EW_PAIR_NUMBER":
            current = current?.add(child: Node(name: name, completion: { [self] (value) in
                let invert = (traveller.direction == .ew)
                for seat in Pair.ew.seats {
                    traveller.ranking[seat] = currentMatch.ranking[invert ? seat.equivalent : seat] ?? Int(value)
                    traveller.section[seat] = currentMatch.section[invert ? seat.equivalent : seat] ?? 1
                }
            }))
        case "CONTRACT":
            current = current?.add(child: Node(name: name, completion: { (value) in
                traveller.contract = Contract(string: value)
            }))
        case "PLAYED_BY":
            current = current?.add(child: Node(name: name, completion: { (value) in
                traveller.declarer = Seat(string: value)
            }))
        case "LEAD":
            current = current?.add(child: Node(name: name, completion: { (value) in
                traveller.lead = value
            }))
        case "TRICKS":
            current = current?.add(child: Node(name: name, completion: { (value) in
                traveller.made = Int(value)! - (traveller.contract?.level.tricks ?? 0)
            }))
        case "SCORE":
            current = current?.add(child: Node(name: name, completion: { (value) in
                traveller.nsPoints = Int(value)
            }))
        case "NS_MATCH_POINTS":
            current = current?.add(child: Node(name: name, completion: { (value) in
                traveller.nsMps = Int(value)
            }))
        case "LIN_DATA":
            current = current?.add(child: Node(name: name, completion: { (value) in
                traveller.playData = value
            }))

        default:
            current = current?.add(child: Node(name: name))
        }
    }
    
    private func finalUpdates() {
    }
    
    // MARK: - Parser Delegate ========================================================================== -

    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if let process = current?.process {
            process(elementName, attributeDict)
        } else {
            self.current = self.current?.add(child: Node(name: elementName))
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        current?.completion?(current?.value ?? "")
        current = current?.parent
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        let string = string.replacingOccurrences(of: replacingSingleQuote, with: "'")
        current?.addValue(string: string)
    }
    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("error")
    }
    
    public func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        print("error")
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
        parseComplete()
    }
    
    // MARK: - Utility Routines
    
    private func combineRankings() {
        // Teams pairs as separate lines
        if scorecard.type.players == 4 {
            var remove: [Int] = []
            for (index, ranking) in rankings.enumerated() {
                if index > 0 {
                    if let matchIndex = rankings.firstIndex(where: {$0.number == ranking.number}) {
                        if matchIndex < index {
                            // Add to previous ranking
                            rankings[matchIndex].players[.east] = ranking.players[.east] ?? ranking.players[.north]
                            rankings[matchIndex].players[.west] = ranking.players[.west] ?? ranking.players[.south]
                            remove.append(index)
                            // Will have duplicate ranking tables - remove EW ones and set others to same as ranking
                            rankingTables.removeAll(where: {$0.way == .ew})
                            for rankingTable in rankingTables.filter({$0.number == ranking.number}) {
                                rankingTable.way = ranking.way
                            }
                            format = .teams
                        }
                    }
                }
            }
            for removeIndex in remove.reversed() {
                rankings.remove(at: removeIndex)
            }
        }
        for ranking in rankings {
            if format == .individual {
                ranking.players[.south] = ranking.players[.north]
            }
            if format != .teams {
                ranking.players[.east] = ranking.players[.north]
                ranking.players[.west] = ranking.players[.south]
            }
        }
        switch format {
        case .individual, .pairs:
            type = type ?? .percent
        case .teams:
            type = .imp
        }
    }
    
    private func columns(_ line: String) -> [String] {
        var quoted = false
        var carried = ""
        let columns = line.components(separatedBy: ",")
        var result: [String] = []
        
            // Now merge any columns that were quoted
        for column in columns {
            if !quoted {
                if column.left(1) == "\"" {
                    carried = column.right(column.length - 1)
                    quoted = true
                } else {
                    result.append(column)
                }
            } else {
                if column.right(1) == "\"" {
                    carried = carried + "," + column.left(column.length - 1)
                    result.append(carried)
                    quoted = false
                } else {
                    carried = carried + "," + column
                }
            }
        }
        return result
    }
}

public enum EventType: String {
    case ko
    case ladder
    case mp_pairs
    case butler_pairs
    case individual
    case swiss_pairs
    case swiss_teams
    case teams_of_four
    case cross_imps
    case aggregate
    case swiss_pairs_cross_imps
    case swiss_pairs_butler_imps
    case pairs
    case teams
    case invalid
    
    init?(_ string: String) {
        self.init(rawValue: string.lowercased())
    }
    
    var string: String { "\(self)".replacingOccurrences(of: "_", with: " ").capitalized }
    
    var supported: Bool {
        return self == .swiss_pairs || self == .swiss_teams || self == .mp_pairs || self == .pairs || self == .cross_imps || self == .teams || self == .individual || self == .teams_of_four
    }
    
    var format: ImportFormat? {
        switch self {
        case .individual:
            return .individual
        case .mp_pairs, .butler_pairs, .swiss_pairs, .cross_imps, .aggregate, .swiss_pairs_cross_imps, .swiss_pairs_butler_imps, .pairs:
            return .pairs
        case .swiss_teams, .teams, .teams_of_four:
            return .teams
        default:
            return nil
        }
    }
    
    var requiresWinDraw: Bool {
        switch self {
        case .swiss_pairs, .swiss_pairs_cross_imps, .swiss_pairs_butler_imps, .swiss_teams:
            return true
        default:
            return false
        }
    }
}

public enum ScoringMethod: String {
    case vps
    case imps
    case match_points
    case percentage
    case cross_imps
    case aggregate
    
    init?(_ string: String) {
        self.init(rawValue: string.lowercased().replacing(" ", with: "_"))
    }
    
    var scoreType: ScoreType {
        switch self {
        case .vps:
            .vp
        case .imps:
            .imp
        case .match_points:
            .percent
        case .percentage:
            .percent
        case .cross_imps:
            .xImp
        case .aggregate:
            .aggregate
        }
    }
}

fileprivate class Node {
    var parent: Node?
    var child: Node? = nil
    let name: String
    let attributes: [String : String]
    var value: String
    var process: ((String, [String:String])->())?
    var completion: ((String)->())?
    
    init(name: String = "", attributes: [String : String] = [:], value: String = "", process: ((String,[String:String])->())? = nil, completion: ((String)->())? = nil) {
        self.name = name.uppercased()
        self.attributes = attributes
        self.value = value
        self.process = process
        self.completion = completion
    }
    
    public func addValue(string: String) {
        self.value += string
    }
    
    public func add(child: Node) -> Node {
        child.parent = self
        self.child = child
        return child
    }
}

