//
//  Import BridgeWebs.swift
//  BridgeScore
//
//  Created by Marc Shearer on 31/03/2022.
//

import CoreData
import SwiftUI
import UniformTypeIdentifiers

struct FileNameElement: Hashable {
    var desc: String
    var locationId: String?
    var event: String
    var date: Date? {
        Date(from: event.left(8), format: "yyyyMMdd")
    }
    var location: LocationViewModel? {
        MasterData.shared.locations.first(where: {$0.bridgeWebsId == locationId})
    }
    
    init(event: String, desc: String, locationId: String? = nil) {
        self.event = event
        self.desc = desc
        self.locationId = locationId
    }
}

struct ImportBridgeWebsScorecard: View {
    enum Phase {
        case getList
        case dropZone
        case select
        case getFile
        case confirm
        case importing
        case error
    }
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var scorecard: ScorecardViewModel
    var completion: (()->())? = nil
    private let uttypes = [UTType.data]
    @State private var available: [Data]? = nil
    @State private var downloadComplete = false
    @State private var downloadError = false
    @State private var downloadSequence: Int?
    @State private var importedBridgeWebsScorecard: ImportedBridgeWebsScorecard!
    @State private var fileList: [FileNameElement] = []
    @State private var parser: ImportedBridgeWebsScorecard!
    @State private var phase: Phase = .getList
    @State private var errorMessage: String? = nil
    @State private var selected: FileNameElement? = nil
    @State private var dropZoneEntered = false
    @State private var droppedText: [String] = []
    
    var body: some View {
        StandardView("Detail") {
            switch phase {
            case .getList:
                downloadingList
            case .dropZone:
                dropZone
            case .select:
                showFileList
            case .getFile:
                downloadingFile
            case .confirm:
                let importedScorecard = Binding.constant(importedBridgeWebsScorecard as ImportedScorecard)
                importedBridgeWebsScorecard.confirmDetails(importedScorecard: importedScorecard, onError: {
                    presentationMode.wrappedValue.dismiss()
                }, completion: {
                    phase = .importing
                })
            case .importing:
                importingFile
            case .error:
                showErrorMessage
            }
        }
    }
    
    var downloadingList: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("Import from BridgeWebs"), backImage: Banner.crossImage)
            Spacer()
            Text("Checking for available files...")
                .font(defaultFont)
            Spacer()
        }
        .onAppear {
            if scorecard.location?.bridgeWebsId ?? "" == "" {
                errorMessage = "This location does not have a BridgeWebs Id set up."
                phase = .dropZone
            } else {
                getList()
            }
        }
    }
    
    var dropZone: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("Download BridgeWebs Files"), backImage: Banner.crossImage)
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
                                Text(errorMessage ?? "Error").font(bannerFont)
                                    .multilineTextAlignment(.center)
                                Spacer().frame(height: 50)
                                Text("Drop Results URL Here").font(bannerFont)
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
                    .onDrop(of: uttypes, delegate: ScorecardDropText(dropZoneEntered: $dropZoneEntered, droppedText: $droppedText))
                    Spacer().frame(height: 50)
                }
                Spacer().frame(width: 50)
            }
            .onChange(of: droppedText.count, initial: false) {
                if !droppedText.isEmpty {
                    for text in droppedText {
                        if let file = parseURL(text: text) {
                            selected = file
                            phase = .getFile
                            downloadFile(file: selected!)
                        }
                    }
                    droppedText = []
                }
            }
        }
    }
    
    var showFileList: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("Select File to Import"), backImage: Banner.crossImage)
            Spacer().frame(height: 16)
            ForEach(fileList, id: \.self) { (file) in
                VStack {
                    Spacer().frame(height: 8)
                    HStack {
                        Spacer().frame(width: 20)
                        Text(file.desc)
                            .font(.title2)
                            .minimumScaleFactor(0.5)
                        Spacer()
                    }
                    Spacer().frame(height: 8)
                }
                .background((file == selected ? Palette.alternate : Palette.background).background)
                .onTapGesture {
                    selected = file
                    phase = .getFile
                    downloadFile(file: selected!)
                }
            }
            Spacer()
        }
    }
    
    var downloadingFile: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("Import from BridgeWebs"), backImage: Banner.crossImage)
            Spacer()
            HStack {
                Spacer()
                Text("Downloading file...")
                    .font(defaultFont)
                Spacer()
            }
            Spacer()
        }
    }
    
    var showErrorMessage: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("Import from BridgeWebs"), backImage: Banner.crossImage)
            Spacer()
            HStack {
                Spacer()
                Text(errorMessage ?? "Error")
                .font(defaultFont)
                Spacer()
            }
            Spacer()
        }
    }
    
    var importingFile: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("Import from BridgeWebs"), backImage: Banner.crossImage)
            Spacer()
            Text("Importing file...")
                .font(defaultFont)
            Spacer()
        }
        .onAppear {
            Utility.executeAfter(delay: 0.1) {
                importedBridgeWebsScorecard.importScorecard()
                completion?()
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func parseURL(text: String) -> FileNameElement? {
        var result: FileNameElement?
        let match = "https://www.bridgewebs.com"
        var event: String?
        var locationId: String?
        if text.left(match.length).lowercased() == "https://www.bridgewebs.com" {
            let components = text.components(separatedBy: "&")
            if let eventComponent = components.first(where: {$0.lowercased().starts(with: "event=")}) {
                event = eventComponent.components(separatedBy: "=").last
            }
            if let locationComponent = components.first(where: {$0.lowercased().starts(with: "club=")}) {
                locationId = locationComponent.components(separatedBy: "=").last
            }
            if let event = event {
                result = FileNameElement(event: event, desc: "Dropped URL", locationId: locationId)
            }
        }
        return result
    }
    
    private func getList(_ urlString: String? = nil) {
        let urlString = urlString ?? "https://www.bridgewebs.com/cgi-bin/bwop/bw.cgi?club=\(scorecard.location!.bridgeWebsId)&pid=display_past"
        
        let url = URL(string: urlString)!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            if error != nil {
                errorMessage = "Error get list of available files\nCheck network connection"
                phase = .error
            } else if let data = data {
                fileList = []
                let listParser = ImportBridgeWebsListParser(data: data, date: scorecard.date)
                fileList = listParser.list
                if fileList.isEmpty && listParser.nextPage != nil {
                    getList(listParser.nextPage!)
                } else {
                    switch fileList.count {
                    case 0:
                        errorMessage = "No files available for this location on this date"
                        phase = .dropZone
                    case 1:
                        downloadFile(file: fileList[0])
                        phase = .getFile
                    default:
                        phase = .select
                    }
                }
            }
        }
        task.resume()
    }
    
    private func downloadFile(file: FileNameElement) {
        let urlString = "https://www.bridgewebs.com/cgi-bin/bwop/bw.cgi?xml=1&club=\(file.locationId ?? scorecard.location!.bridgeWebsId)&pid=xml_results_travs&msec=1&mod=Results&ekey=\(file.event)"
        
        let url = URL(string: urlString)!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            if error != nil {
                downloadError = true
            } else if let data = data {
                parser = ImportedBridgeWebsScorecard(scorecard: scorecard, title: file.desc, data: data, date: file.date, location: file.location, completion: completion)
            }
        }
        task.resume()
    }
    
    private func completion(importedScorecard: ImportedBridgeWebsScorecard?, message: String?) {
        if let importedScorecard = importedScorecard {
            self.importedBridgeWebsScorecard = importedScorecard
            phase = .confirm
        } else {
            errorMessage = message ?? "Error"
            phase = .error
        }
    }
    
    private func stepperLabel(value: Int) -> String {
        return "Table \(value) of \(scorecard.tables)"
    }
}

class ImportedBridgeWebsScorecard: ImportedScorecard, XMLParserDelegate {
    enum Zone: Int {
        case unknown = 0
        case rankings = 6
        case boards = 7
        case travellers = 3
    }
    
    enum Element {
        case unknown
        case view
        case columns
        case row
        case type
        case hand
        case session
        case board
        case vulnerability
        case dealer
    }
    
    private var namesElement: Bool
    private var data: Data!
    private var completion: (ImportedBridgeWebsScorecard?, String?)->()
    private var headings: [String] = []
    private var players: Int?
    private var zone = Zone.unknown
    private var element = Element.unknown
    private var parser: XMLParser!
    private let replacingSingleQuote = "@@replacingSingleQuote@@"
    private var session: Int?
    private var nextBoard: [Int:Int] = [:] // Session
    private var boardNumber: Int!
    private var tag: String?

    init(scorecard: ScorecardViewModel, title: String, data: Data, date: Date?, location: LocationViewModel?, completion: @escaping (ImportedBridgeWebsScorecard?, String?)->()) {
        self.namesElement = false
        self.completion = completion
        super.init()
        self.importSource = .bridgeWebs
        self.scorecard = scorecard
        let scorer = MasterData.shared.scorer
        myName = scorer!.name.lowercased()
        self.title = title
        self.date = date ?? scorecard.date
        self.location = location ?? scorecard.location
        self.type = scorecard.type.boardScoreType
        let string = String(decoding: data, as: UTF8.self)
        let replacedQuote = string.replacingOccurrences(of: "&#39;", with: replacingSingleQuote)
        let replacedEGrave = replacedQuote.replacingOccurrences(of: "&#xe8;", with: "e")
        self.data = replacedEGrave.data(using: .utf8)
        parser = XMLParser(data: self.data)
        parser.delegate = self
        parser.parse()
    }
    
    private func initRanking(columns: [String]) {
        let importedRanking = ImportedRanking()
        for (index, heading) in headings.enumerated() {
            switch heading.lowercased() {
            case "item":
                if let string = columns.element(index) {
                    importedRanking.ranking = Int(string)
                }
            case "pair":
                if let components = columns.element(index)?.components(separatedBy: ":") {
                    if importedRanking.number == nil || importedRanking.way != nil {
                        // Don't overwrite if filled from team and don't have a pair direction
                        let (number, way) = splitPairId(id: components.first!)
                        if number != nil {
                            importedRanking.number = number
                            importedRanking.full = components.first!
                            format = .pairs
                            if way != nil {
                                importedRanking.way = way
                            }
                        }
                    }
                }
            case "team":
                if let components = columns.element(index)?.components(separatedBy: ":") {
                    if importedRanking.number == nil {
                        // Don't overwrite pair number
                        importedRanking.number = Int(components.first!)
                        if players ?? 0 > 2 {
                            format = .teams
                        }
                    }
                }
            case "way":
                if let string = columns.element(index), let bwValue = Int(string) {
                    importedRanking.way = (bwValue == 1 ? .ns : (bwValue == 2 ? .ew : .unknown))
                }
            case "name1":
                let sitting = importedRanking.way?.seats.first ?? .north
                importedRanking.players[sitting] = columns.element(index)
            case "name2":
                let sitting = importedRanking.way?.seats.first?.partner ?? .south
                let name2 = columns.element(index) ?? ""
                if name2 == "" {
                    format = .individual
                } else {
                    importedRanking.players[sitting] = name2
                }
            default:
                break
            }
        }
        rankings.append(importedRanking)
    }
    
    func initTraveller(columns: [String]) {
        
        let importedTraveller = ImportedTraveller()
        for seat in Seat.validCases {
            importedTraveller.section[seat] = 1
        }
        for (index, heading) in headings.enumerated() {
            switch heading.lowercased() {
            case "ns", "ew":
                let pair = Pair(string: heading.uppercased())
                if let string = columns.element(index) {
                    let (number, _) = splitPairId(id: string)
                    if number != nil {
                        for seat in pair.seats {
                            importedTraveller.ranking[seat] = number
                        }
                    }
                }
            case "n", "s", "e", "w":
                if let string = columns.element(index) {
                    let seat = Seat(string: heading.uppercased())
                    if let ranking = Int(string) {
                        importedTraveller.ranking[seat] = ranking
                    }
                }
            case "bid":
                let contract = Contract()
                if let string = columns.element(index) {
                    if let level = Int(string.left(1)) {
                        contract.level = ContractLevel(rawValue: level) ?? .passout
                        contract.suit = Suit(string: string.left(2).right(1))
                    } else {
                        contract.level = .passout
                    }
                    if string.right(2).lowercased() == "**" {
                        contract.double = .redoubled
                    } else if string.right(1).lowercased() == "*" {
                        contract.double = .doubled
                    }
                }
                importedTraveller.contract = contract
            case "ld":
                if let string = columns.element(index) {
                    if string == "" {
                        importedTraveller.lead = ""
                    } else {
                        importedTraveller.lead = string.right(string.count - 1) + string.left(1)
                    }
                }
            case "by":
                importedTraveller.declarer = Seat(string: columns.element(index) ?? "")
            case "tks":
                if let string = columns.element(index), let tricks = Int(string) {
                    if let level = importedTraveller.contract?.level {
                        if level.rawValue > 0 {
                            importedTraveller.made = tricks - (level.rawValue + 6)
                        }
                    }
                }
            case "+sc":
                if let string = columns.element(index), let value = Int(string) {
                    importedTraveller.nsPoints = value
                }
            case "-sc":
                if let string = columns.element(index), let value = Int(string) {
                    importedTraveller.nsPoints = -value
                }
            case "+":
                if let string = columns.element(index) {
                    if scorecard.type.boardScoreType == .percent {
                        if let value = Int(string) {
                            importedTraveller.nsMps = value
                            importedTraveller.totalMps = (importedTraveller.totalMps ?? 0) + value
                        }
                    } else {
                        importedTraveller.nsScore = (Float(string) ?? 0)
                    }
                }
            case "-":
                if let string = columns.element(index) {
                    if scorecard.type.boardScoreType == .percent {
                        if let value = Int(string) {
                            importedTraveller.totalMps = (importedTraveller.totalMps ?? 0) + value
                        }
                    } else {
                        importedTraveller.nsScore = -(Float(string) ?? 0)
                    }
                }
            case "ns x":
                if let string = columns.element(index) {
                    if let score = Float(string.replacingOccurrences(of: "%", with: "")) {
                        importedTraveller.nsScore = score
                    }
                }
                type = .xImp
            case "ew x":
                if let string = columns.element(index) {
                    if let score = Float(string.replacingOccurrences(of: "%", with: "")) {
                        importedTraveller.nsScore = -score
                    }
                }
                type = .xImp
            case "play":
                if let string = columns.element(index) {
                    importedTraveller.playData = string
                }

            default:
                break
            }
        }
        importedTraveller.board = boards[boardNumber]?.boardNumber
        if travellers[boardNumber] == nil {
            travellers[boardNumber] = []
        }
        if importedTraveller.ranking.count > 0 {
            travellers[boardNumber]!.append(importedTraveller)
        }
    }
    
    func initComplete() {
        boardCount = boardNumber
        combineRankings()
        updateWays()
        boardCount = travellers.count
        scoreTravellers()
        recalculateTravellers()
        validate()
        completion(self, nil)
    }
    
    // MARK: - Utility Routines ======================================================================== -
    
    private func combineRankings() {
        // Teams pairs as separate lines
        if players == 4 {
            var remove: [Int] = []
            for (index, ranking) in rankings.enumerated() {
                if index > 0 {
                    if let matchIndex = rankings.firstIndex(where: {$0.number == ranking.number}) {
                        if matchIndex < index {
                                // Add to previous ranking
                            rankings[matchIndex].players[.east] = ranking.players[.east] ?? ranking.players[.north]
                            rankings[matchIndex].players[.west] = ranking.players[.west] ?? ranking.players[.south]
                            remove.append(index)
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
                for seat in Seat.validCases {
                    for otherSeat in Seat.validCases {
                        ranking.players[seat] = ranking.players[otherSeat] ?? ranking.players[seat]
                    }
                }
            }
            if format != .teams {
                for seat in Seat.validCases {
                    ranking.players[seat] = ranking.players[seat] ?? ranking.players[seat.equivalent]
                }
            }
        }
        // Update scorecard type
        switch format {
        case .individual, .pairs:
            type = type ?? .percent
        case .teams:
            type = .imp
        }
    }
    
    private func splitPairId(id: String) -> (Int?, Pair?) {
        var way: Pair?
        var number: Int?
        number = Int(id)
        var components = id.components(separatedBy: ":")
        if components.count == 1 {
            // Note that have seen up to pairs 1E and 1F but might go further - not sure why it does this
            if number == nil && id.length >= 2 && "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(id.right(1).uppercased()) {
                // Pair is in format 1A, 2B etc
                components[0] = id.left(id.length - 1)
                components.append(id.right(1))
            }
        }
        number = Int(components[0])
        if components.count >= 2 {
            way = ("ACEGIKMOQSUWY".contains(components[1]) ? .ns : .ew)
        }
        return (number, way)
    }
    
    private func updateWays() {
        
        if Set(rankings.map{$0.way}).count == 1 {
            // Only one pair direction setup - remove them
            for ranking in rankings {
                ranking.way = .unknown
            }
        }
    }
        
    // MARK: - Parser Delegate ========================================================================== -

    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        switch elementName {
        case "view":
            element = .view
        case "cols":
            element = .columns
        case "rw":
            element = .row
        case "type":
            element = .type
        case "hand":
            element = .hand
        case "session":
            element = .session
        case "bd":
            element = .board
        case "dlr":
            element = .dealer
        case "vul":
            element = .vulnerability
        default:
            break
        }
        tag = elementName
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        element = .unknown
        tag = nil
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let string = string.replacingOccurrences(of: replacingSingleQuote, with: "'")
        switch element {
        case .view:
            if let view = Int(string) {
                zone = Zone(rawValue: view) ?? .unknown
                hand = nil
                dealer = nil
                vulnerability = nil
            }
        case .session:
            if let number = Int(string) {
                session = number
            }
        case .board:
            switch zone {
            case .travellers:
                if let number = Int(string) {
                    if let session = session {
                        if let next = nextBoard[session] {
                            nextBoard[session] = next + 1
                        } else {
                            nextBoard[session] = 1
                        }
                    } else {
                        boardNumber = number
                    }
                    if boards[boardNumber] == nil {
                        boards[boardNumber] = ImportedBoard(boardNumber: number)
                    }
                }
            default:
                break
            }
        case .columns:
            headings = string.components(separatedBy: ";")
        case .row:
            let values = string.components(separatedBy: ";")
            switch zone {
            case .rankings:
                initRanking(columns: values)
            case .travellers:
                initTraveller(columns: values)
            default:
                break
            }
        case .type:
            switch zone {
            case .rankings:
                switch string.lowercased() {
                case "s":
                    players = 2
                    format = .pairs
                case "4", "8":
                    players = 4
                    format = .teams
                default:
                    players = 2
                }
            default:
                break
            }
        case .hand:
            switch zone {
            case .travellers:
                if let board = boards[boardNumber] {
                    let elements = string.components(separatedBy: ";")
                    // First 16 elements are cards
                    board.hand = elements[0...15].joined(separator: ",")
                    // 17-20 are HCP of each hand
                    // 21-40 are double dummy tricks
                    board.doubleDummy = [:]
                    if elements.count >= 40 {
                        var index = 20
                        for declarer in [Seat.north, .south, .east, .west] {
                            board.doubleDummy[declarer] = [:]
                            for suit in [Suit.clubs, . diamonds, .hearts, .spades, .noTrumps] {
                                let made = Int(elements[index])
                                board.doubleDummy[declarer]![suit] = (made == 1 ? nil : made)
                                index += 1
                            }
                        }
                    }
                    // 41 is the optimum score
                    if elements.count >= 41 {
                        board.optimumScore = OptimumScore(string: elements[40], vulnerability: Vulnerability(board: boardNumber))
                    }
                        
                }
            default:
                break
            }
        case .dealer:
            switch zone {
            case .travellers:
                if let number = Int(string) {
                    if number != Seat.dealer(board: boardNumber).rawValue {
                        fatalError("Wrong dealer")
                    }
                }
            default:
                break
            }
        case .vulnerability:
            switch zone {
            case .travellers:
                if let number = Int(string) {
                    if number != Vulnerability(board: boardNumber).rawValue {
                        fatalError("Wrong vulnerability")
                    }
                }
            default:
                break
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("error")
    }
    
    func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        print("error")
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        initComplete()
    }
}

class ImportBridgeWebsListParser {
    fileprivate var list: [FileNameElement] = []
    fileprivate var nextPage: String?
    
    init(data: Data, date: Date) {
        let find = "eventLink ("
        let nextPageFind = "next page"
        let dateString = date.toString(format: "yyyyMMdd", localized: false)
        let string = String(decoding: data, as: UTF8.self)
        let lines = string.components(separatedBy: "\n")
        for line in lines.filter({$0.contains(find)}) {
            let start = line.position(find)! + find.length
            let string = line.right(line.length - start)
            if let end = string.position(",") {
                let event = string.left(end - 1).replacingOccurrences(of: "\'", with: "").ltrim().rtrim()
                let fileDate = event.left(8)
                if fileDate == dateString {
                    if let data = line.data(using: .utf8) {
                        if let desc = try? NSAttributedString(data: data, options: [
                            .documentType: NSAttributedString.DocumentType.html,
                            .characterEncoding: String.Encoding.utf8.rawValue],
                                                              documentAttributes: nil).string {
                            
                            list.append(FileNameElement(event: event, desc: desc))
                        }
                    }
                } else if fileDate < dateString {
                        // Gone past required date - quit
                    nextPage = nil
                    break
                }
            }
        }
        for line in lines.filter({$0.lowercased().contains(nextPageFind)}) {
            if let leftEnd = line.lowercased().position(nextPageFind) {
                let leftLine = line.left(leftEnd)
                if let start = leftLine.position("href=\"", backwards: true) {
                    let string = leftLine.right(leftLine.length - (start + 6))
                    if let end = string.position("\"") {
                        nextPage = "https://www.bridgewebs.com" + string.left(end)
                    }
                }
            }
        }
    }
}
