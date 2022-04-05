//
//  Import BridgeWebs.swift
//  BridgeScore
//
//  Created by Marc Shearer on 31/03/2022.
//

import CoreData
import SwiftUI
import CoreMedia

struct FileNameElement: Hashable {
    var file: String
    var desc: String
}

struct ImportBridgeWebsScorecard: View {
    enum Phase {
        case getList
        case select
        case getFile
        case confirm
        case importing
        case error
    }
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var scorecard: ScorecardViewModel
    var completion: (()->())? = nil
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

    var body: some View {
        StandardView("Detail") {
            switch phase {
            case .getList:
                downloadingList
            case .select:
                showFileList
            case .getFile:
                downloadingFile
            case .confirm:
                confirmDetails
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
                phase = .error
            } else {
                getList()
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
                    downloadFile(filename: selected!.file, title: selected!.desc)
                }
            }
            Spacer()
        }
    }
    
    var downloadingFile: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("Import from BridgeWebs"), backImage: Banner.crossImage)
            Spacer()
            Text("Downloading file...")
                .font(defaultFont)
            Spacer()
        }
    }
    
    var showErrorMessage: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("Import from BridgeWebs"), backImage: Banner.crossImage)
            Spacer()
            Text(errorMessage ?? "Error")
                .font(defaultFont)
            Spacer()
        }
    }
    
    var confirmDetails: some View {
        @OptionalStringBinding(importedBridgeWebsScorecard.title) var titleBinding
        @OptionalStringBinding(Utility.dateString(importedBridgeWebsScorecard.date, format: "EEEE d MMMM yyyy")) var dateBinding
        @OptionalStringBinding(importedBridgeWebsScorecard.partner?.name) var partnerBinding
        @OptionalStringBinding("\(importedBridgeWebsScorecard.boardCount ?? 0)") var boardCountBinding
        @OptionalStringBinding("\(importedBridgeWebsScorecard.boardsTable ?? 0)") var boardsTableBinding
        
        
        return VStack(spacing: 0) {
            Banner(title: Binding.constant("Confirm Import Details"), backImage: Banner.crossImage)
            Spacer().frame(height: 16)
            
            InsetView(title: "BridgeWebs Import Details") {
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

            if !importedBridgeWebsScorecard.warnings.isEmpty {
                InsetView(title: "Warnings") {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 16)
                        ForEach(importedBridgeWebsScorecard.warnings, id: \.self) { (warning) in
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
                            phase = .importing
                        }
                    }
                    Spacer()
                }
                Spacer().frame(height: 16)
            }
            .onAppear {
                if let error = importedBridgeWebsScorecard.error {
                    MessageBox.shared.show(error, okAction: {
                        presentationMode.wrappedValue.dismiss()
                    })
                }
            }
        }
        .background(Palette.alternate.background)
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
                importedBridgeWebsScorecard.importScorecard(rebuild: true)
                completion?()
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func getList() {
        let urlString = "https://www.bridgewebs.com/cgi-bin/bwop/bw.cgi?club=\(scorecard.location!.bridgeWebsId)&pid=display_past"
        
        let url = URL(string: urlString)!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            if error != nil {
                errorMessage = "Error get list of available files\nCheck network connection"
                phase = .error
            } else if let data = data {
                let listParser = ImportBridgeWebsListParser(data: data, date: scorecard.date)
                fileList = listParser.list
                switch fileList.count {
                case 0:
                    errorMessage = "No files available for this location on this date"
                    phase = .error
                case 1:
                    downloadFile(filename: fileList[0].file, title: fileList[0].desc)
                    phase = .getFile
                default:
                    phase = .select
                }
            }
        }
        task.resume()
    }
    
    private func downloadFile(filename: String, title: String) {
        let urlString = "https://www.bridgewebs.com/cgi-bin/bwop/bw.cgi?xml=1&club=\(scorecard.location!.bridgeWebsId)&pid=xml_results_travs&msec=1&mod=Results&ekey=\(filename)"
        
        let url = URL(string: urlString)!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            if error != nil {
                downloadError = true
            } else if let data = data {
                parser = ImportedBridgeWebsScorecard(scorecard: scorecard, title: title, data: data, completion: completion)
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
    }
    
    private var namesElement: Bool
    private var data: Data!
    private var completion: (ImportedBridgeWebsScorecard?, String?)->()
    private var headings: [String] = []
    private var zone = Zone.unknown
    private var element = Element.unknown
    private var parser: XMLParser!
    private let replacingSingleQuote = "@@replacingSingleQuote@@"
    private var board: Int!
    private var tag: String?

    init(scorecard: ScorecardViewModel, title: String, data: Data, completion: @escaping (ImportedBridgeWebsScorecard?, String?)->()) {
        self.namesElement = false
        self.completion = completion
        super.init()
        self.importSource = .bridgeWebs
        self.scorecard = scorecard
        let scorer = MasterData.shared.scorer
        myName = scorer!.name.lowercased()
        self.title = title
        self.date = scorecard.date
        self.type = scorecard.type.boardScoreType
        let string = String(decoding: data, as: UTF8.self)
        let replacedQuote = string.replacingOccurrences(of: "&#39;", with: replacingSingleQuote)
        self.data = replacedQuote.data(using: .utf8)
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
            case "no":
                if let string = columns.element(index) {
                    importedRanking.number = Int(string)
                }
            case "name1":
                importedRanking.players[.north] = columns.element(index)
            case "name2":
                let name2 = columns.element(index) ?? ""
                if name2 == "" {
                    format = .individual
                } else {
                    importedRanking.players[.south] = name2
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
                    // Strip out :1 and :2 from teams
                    let component = string.components(separatedBy: ":")
                    for seat in pair.seats {
                        importedTraveller.ranking[seat] = Int(component[0])
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
                        contract.suit = ContractSuit(string: string.left(2).right(1))
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
                    importedTraveller.lead = string
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
                if let string = columns.element(index) {
                    importedTraveller.points = Int(string) ?? 0
                }
            case "-sc":
                if let string = columns.element(index) {
                    importedTraveller.points = -(Int(string) ?? 0)
                }
            case "+":
                if let string = columns.element(index) {
                    importedTraveller.nsMps = (Float(string) ?? 0)
                    importedTraveller.totalMps = (importedTraveller.totalMps ?? 0) + (Float(string) ?? 0)
                }
            case "-":
                if let string = columns.element(index) {
                    importedTraveller.totalMps = (importedTraveller.totalMps ?? 0) + (Float(string) ?? 0)
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
        importedTraveller.board = board
        if travellers[board] == nil {
            travellers[board] = []
        }
        travellers[board]!.append(importedTraveller)
    }
    
    func initComplete() {
        boardCount = board
        combineRankings()
        recalculateTravellers()
        validate()
        completion(self, nil)
    }
    
    // MARK: - Utility Routines ======================================================================== -
    
    private func combineRankings() {
        // Teams pairs as separate lines
        var remove: [Int] = []
        var position = 0
        for (index, ranking) in rankings.enumerated() {
            if index > 0 && rankings[index - 1].number == ranking.number {
                // Add to previous ranking
                rankings[index - 1].players[.east] = ranking.players[.north]
                rankings[index - 1].players[.west] = ranking.players[.south]
                remove.append(index)
                format = .teams
            } else {
                position += 1
                ranking.ranking = position
            }
        }
        for removeIndex in remove.reversed() {
            rankings.remove(at: removeIndex)
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
        
    // MARK: - Parser Delegate ========================================================================== -

    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        switch elementName {
        case "view":
            element = .view
        case "cols":
            element = .columns
        case "rw":
            element = .row
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
        default:
            if zone == .travellers && tag == "bd" {
                if let number = Int(string) {
                    board = number
                }
            }
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
    
    init(data: Data, date: Date) {
        let find = "eventLink ("
        let dateString = date.toString(format: "yyyyMMdd", localized: false)
        let string = String(decoding: data, as: UTF8.self)
        let lines = string.components(separatedBy: "\n")
        for line in lines {
            if line.contains(find) {
                if let data = line.data(using: .utf8) {
                    if let desc = try? NSAttributedString(data: data, options: [
                        .documentType: NSAttributedString.DocumentType.html,
                        .characterEncoding: String.Encoding.utf8.rawValue],
                                                          documentAttributes: nil).string {
                        let start = line.position(find)! + find.length
                        let string = line.right(line.length - start)
                        if let end = string.position(",") {
                            let filename = string.left(end - 1).replacingOccurrences(of: "\'", with: "").ltrim().rtrim()
                            if filename.left(8) == dateString {
                                list.append(FileNameElement(file: filename, desc: desc))
                            }
                        }
                    }
                }
            }
        }
    }
}
