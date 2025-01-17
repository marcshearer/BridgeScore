//
//  Import BBO.swift
//  BridgeScore
//
//  Created by Marc Shearer on 20/03/2022.
//

import CoreData
import SwiftUI
import CoreMedia
import UniformTypeIdentifiers
import AudioToolbox

class ImportBBO {
    
    public class func importNames() {
        
        let entity = BBONameMO.entity()
        let recordType = entity.name!
        let elementName = recordType
        let groupName = "data"
        let fileURL = ImportedScorecard.importsURL.appendingPathComponent("BBOName.json")
        if let fileContents = try? Data(contentsOf: fileURL, options: []) {
            if let fileDictionary = try? JSONSerialization.jsonObject(with: fileContents, options: []) as? [String:Any?] {
                if let contents = fileDictionary[groupName] as? [[String:Any?]] {
                    var fileOK = true
                    CoreData.update {
                        for record in contents {
                            if let keys = record[elementName] as? [String:String],
                               let bboName = keys["bboName"],
                               let name = keys["name"]  {
                                if let bboNameMO = MasterData.shared.bboName(id: bboName) {
                                    bboNameMO.name = name
                                } else {
                                    let bboNameMO = NSManagedObject(entity: entity, insertInto: CoreData.context) as! BBONameMO
                                    bboNameMO.bboName = bboName.lowercased()
                                    bboNameMO.name = name
                                }
                            } else {
                                fileOK = false
                            }
                        }
                    }
                    try! CoreData.context.save()
                    MasterData.shared.load()
                    MessageBox.shared.show(fileOK ? "File imported successfully" : "File imported with errors")
                } else {
                    MessageBox.shared.show("File contains invalid JSON")
                }
            } else {
                MessageBox.shared.show("File contains invalid JSON")
            }
        } else {
            MessageBox.shared.show("Unable to open import file 'imports/BBOName.json")
        }
    }
    
    public class func createImportedScorecardFrom(fileURL: URL, scorecard: ScorecardViewModel) -> ImportedBBOScorecard? {
        // Version for lookup of directory
        if let contents = try? String(contentsOf: fileURL) {
            let lines = contents.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
            let imported = ImportedBBOScorecard(lines: lines, scorecard: scorecard)
            if let pbnURL = URL(string: fileURL.absoluteString.replacingOccurrences(of: ".csv", with: ".pbn")) {
                if let contents = try? String(contentsOf: pbnURL) {
                    let lines = contents.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
                    imported.importOptimum(lines: lines, scorecard: scorecard)
                }
            }
            return imported
        } else {
            return nil
        }
    }
    
    public class func createImportedScorecardFrom(droppedFiles fileData: [ImportFileData], scorecard: ScorecardViewModel) -> [ImportedBBOScorecard] {
        // Version for drop of files
        var result: [ImportedBBOScorecard] = []
        for file in fileData {
            if let contents = file.contents {
                let lines = contents.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
                let imported = ImportedBBOScorecard(lines: lines, scorecard: scorecard)
                imported.date = file.date
                if let pbnData = file.associated {
                    let lines = pbnData.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
                    imported.importOptimum(lines: lines, scorecard: scorecard)
                }
                result.append(imported)
            }
        }
        return result
    }
}

struct ImportBBOScorecard: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var scorecard: ScorecardViewModel
    var completion: (()->())? = nil
    private let uttypes = [UTType.data]
    @State private var selected: String? = nil
    @State private var importedBBOScorecards: [ImportedBBOScorecard] = []
    @State private var importSequence = Int.max
    @State private var dropZoneEntered = false
    @State private var droppedFiles: [(filename: String, contents: String)] = []
    @State private var importedBBOScorecard: ImportedBBOScorecard? = nil
    var importedScorecard: Binding<ImportedScorecard> {
        Binding {
            importedBBOScorecard! as ImportedScorecard
        } set: { (newValue) in
            self.importedScorecard.wrappedValue = importedBBOScorecard! as ImportedScorecard
        }
    }
    
    var body: some View {
        StandardView("Detail") {
            if selected == nil {
                if MyApp.target == .macOS {
                    dropZone
                } else {
                    fileList
                }
            } else {
                if importSequence < importedBBOScorecards.count {
                    let suffix = (scorecard.isMultiSession && (scorecard.sessions > 1) && importedBBOScorecards.count > 1 ? " (\(importSequence + 1) of \(importedBBOScorecards.count))" : "")
                    importedBBOScorecard?.confirmDetails(importedScorecard: importedScorecard, suffix: suffix, onError: {
                        presentationMode.wrappedValue.dismiss()
                    }, completion: {
                        importedBBOScorecard!.importScorecard()
                        completion?()
                        if scorecard.importNext >= scorecard.sessions {
                            importedBBOScorecard!.prepareForNext()
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            MessageBox.shared.show("Session \(scorecard.importNext) imported successfully", okText: "Continue", okAction: {
                                importedBBOScorecard!.prepareForNext()
                                if importSequence >= importedBBOScorecards.count - 1 {
                                    selected = nil
                                } else {
                                    // Get ready for next session
                                    importSequence += 1
                                    importedBBOScorecard = importedBBOScorecards[importSequence]
                                    importedBBOScorecard?.session = scorecard.importNext
                                }
                            })
                        }
                    })
                }
            }
        }
        .onChange(of: importSequence) {
            if importSequence < importedBBOScorecards.count {
                importedBBOScorecards[importSequence].lastMinuteValidate()
                importedBBOScorecard = importedBBOScorecards[importSequence]
            }
        }
    }
    
    var dropZone: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("Drop BBO Files"), backImage: Banner.crossImage)
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
                                Text("Drop \(scorecard.isMultiSession ? "(multiple) " : "")CSV and PBN Import Files Here").font(bannerFont)
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
                    if checkImport() {
                        let fileData = processDroppedFiles()
                        let imported = ImportBBO.createImportedScorecardFrom(droppedFiles: fileData, scorecard: scorecard)
                        if !imported.isEmpty {
                            importedBBOScorecards = imported
                            selected = droppedFiles.first!.filename
                            importSequence = 0
                        }
                    }
                    droppedFiles = []
                }
            }
        }
    }
    
    func processDroppedFiles() -> [ImportFileData] {
        let fileData = decompose(droppedFiles.map{URL(string: $0.filename)!})
        // Process files in name order since first component is session number - hence chronological
        for (index, file) in fileData.sorted(by: {$0.text < $1.text}).enumerated() {
            // Add content
            file.contents = droppedFiles[index].contents
        }
        // Now combine pbn content
        let csvFileData = fileData.filter({$0.fileType?.lowercased() == "csv"})
        for file in csvFileData {
            if let number = file.number, let date = file.date {
                if let pbnFile = fileData.first(where: {$0.number == number && $0.text == file.text && $0.date == date && $0.fileType?.lowercased() == "pbn"}) {
                    file.associated = pbnFile.contents
                }
            }
        }
        return csvFileData
    }
    
    
    var fileList: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("Choose file to import"), backImage: Banner.crossImage)
            Spacer().frame(height: 16)
            if let files = try? FileManager.default.contentsOfDirectory(at: ImportedScorecard.importsURL, includingPropertiesForKeys: nil).filter({$0.relativeString.right(4) == ".csv"}) {
                let baseDate = Date(timeIntervalSinceReferenceDate: 0)
                let unfiltered: [ImportFileData] = decompose(files)
                let fileData = unfiltered.filter({Date.startOfDay(from: $0.date ?? baseDate) == Date.startOfDay(from: scorecard.date)}).sorted(by: {($0.number ?? 0) > ($1.number ?? 0)})
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
                    .background((fileData[index].fileName == selected ? Palette.alternate : Palette.background).background)
                    .onTapGesture {
                        selected = fileData[index].fileName
                        if checkImport() {
                            if let imported = ImportBBO.createImportedScorecardFrom(fileURL:  fileData[index].path, scorecard: scorecard) {
                                importSequence = 0
                                importedBBOScorecards = [imported]
                            } else {
                                selected = nil
                            }
                        }
                    }
                }
            }
            Spacer()
        }
    }
    
    func checkImport() -> Bool {
        var result = false
        if let scorer = scorecard.scorer {
            if scorer.bboName == "" {
                MessageBox.shared.show("In order to import a scorecard the player defined as yourself must have a BBO name", okAction: {
                    presentationMode.wrappedValue.dismiss()
                })
            } else if scorecard.partner?.bboName ?? "" == "" {
                MessageBox.shared.show("In order to import a scorecard your partner must have a BBO name", okAction: {
                    presentationMode.wrappedValue.dismiss()
                })
            } else {
                result = true
            }
        } else {
            MessageBox.shared.show("In order to import a scorecard a player must be defined as yourself", okAction: {
                presentationMode.wrappedValue.dismiss()
            })
        }
        return result
    }
    
    func decompose(_ paths: [URL]) -> [ImportFileData] {
        var result: [ImportFileData] = []
        
        for path in paths {
            let (name, fileType) = ImportedScorecard.fileName(path.relativeString)
            var components = name.components(separatedBy: "_")
            var number: Int?
            number = Int(components.first!)
            if number != nil {
                components.removeFirst()
            }
            var date: Date?
            date = Utility.dateFromString(components.last!, format: "yyyy-MM-dd", localized: false)
            if date != nil {
                components.removeLast()
            }
            result.append(ImportFileData(path, name, number, components.joined(separator: " "), date, fileType))
        }
        return result
    }
}

class ImportedBBOScorecard: ImportedScorecard {
    enum Phase {
        case heading
        case rankingHeader
        case ranking
        case travellerHeader
        case traveller
        case finished
    }
    
    private(set) var bboId: String?
    private(set) var bboUrl: String?
    private var translateNumber: [Int:Int] = [:]
    
    private var phase: Phase = .heading
    private var rankingHeadings: [String] = []
    private var travellerHeadings: [String] = []
    private var section: Int = 1
    
    // MARK: - Initialise from import file ============================================================ -
    
    init(lines: [String] = [], scorecard: ScorecardViewModel? = nil) {
        super.init()
        self.importSource = .bbo
        self.scorecard = scorecard
        let scorer = scorecard!.scorer
        myName = scorer!.bboName.lowercased()
        for line in lines {
            let columns = columns(line)
            if !columns.isEmpty {
                switch phase {
                case .heading:
                    initHeading(columns)
                case .rankingHeader:
                    rankingHeadings = columns
                    phase = .ranking
                case .ranking:
                    if columns.first!.lowercased() == "#travellerlines" {
                        phase = .travellerHeader
                    } else if columns.first!.lowercased() == "#ranking" {
                        phase = .rankingHeader
                        section += 1
                    } else {
                        initRanking(columns)
                    }
                case .travellerHeader:
                    travellerHeadings = columns
                    phase = .traveller
                case .traveller:
                    if columns.first!.left(1) == "#" {
                        phase = .finished
                    } else if columns.count > 1 {
                        initTraveller(columns)
                    }
                case .finished:
                    break
                }
            }
            if phase == .finished {
                break
            }
        }
        if !lines.isEmpty {
            combineRankings()
            scoreTravellers()
            recalculateTravellers()
            validate()
        }
    }
    
    private func initHeading(_ columns: [String]) {
        switch columns.first!.lowercased() {
        case "#title":
            title = columns.element(1)
        case "#boardcount":
            if let string: String = columns.element(1) {
                boardCount = Int(string)
            }
        case "#tournament":
            bboId = columns.element(1)
            bboUrl = columns.element(2)
        case "#date":
            if let string = columns.element(1) {
                date = Date(from: string, format: "yyyy-MM-dd")
            }
        case "#scoringtype":
            type = ScoreType(importScoringType: columns.element(1))
        case "#ranking":
            phase = .rankingHeader
        default:
            break
        }
    }
    
    private func initRanking(_ columns: [String]) {
        let importedRanking = ImportedRanking()
        
        for (index, heading) in rankingHeadings.enumerated() {
            switch heading.lowercased() {
            case "#rank":
                if let string = columns.element(index) {
                    importedRanking.ranking = Int(string)
                }
            case "pair", "team":
                if let string = columns.element(index) {
                    importedRanking.number = Int(string)
                }
            case "name":
                if let combined = columns.element(index) {
                    let names = combined.components(separatedBy: "+")
                    importedRanking.players[.north] = names[0].lowercased()
                    if names.element(1) ?? "" != "" {
                        importedRanking.players[.south] = names[1].lowercased()
                    } else {
                        eventType = .individual
                    }
                }
            case "name1":
                importedRanking.players[.north] = columns.element(index)?.lowercased()
                eventType = .teams
            case "name2":
                importedRanking.players[.south] = columns.element(index)?.lowercased()
                eventType = .teams
            case "name3":
                importedRanking.players[.east] = columns.element(index)?.lowercased()
                eventType = .teams
            case "name4":
                importedRanking.players[.west] = columns.element(index)?.lowercased()
                eventType = .teams
            case "score", "imps":
                if let string = columns.element(index) {
                    importedRanking.score = Float(string)
                }
            case "section":
                    // Use section from class
                importedRanking.section = section
            case "bbo pts":
                if let string = columns.element(index) {
                    importedRanking.bboPoints = Float(string)
                }
            default:
                break
            }
        }
        rankings.append(importedRanking)
    }
    
    private func initTraveller(_ columns: [String]) {
        let importedTraveller = ImportedTraveller()
        
        for (index, heading) in travellerHeadings.enumerated() {
            switch heading.lowercased() {
            case "#board":
                if let string = columns.element(index) {
                    importedTraveller.board = Int(string)
                }
            case "nspair", "ewpair":
                let pair = Pair(string: heading.left(2).uppercased())
                if let string = columns.element(index)?.lowercased().replacingOccurrences(of: "\(pair)".lowercased(), with: ""),
                   let rankingNumber = Int(string),
                   let ranking = rankings.first(where: {$0.number == rankingNumber}) {
                    for seat in pair.seats {
                        importedTraveller.ranking[seat] = ranking.number
                        importedTraveller.section[seat] = ranking.section
                    }
                } else {
                    fatalError()
                }
            case "nplayer", "splayer", "eplayer", "wplayer":
                let seat = Seat(string: heading.left(1).uppercased())
                if let string = columns.element(index),
                   let rankingNumber = Int(string),
                   let ranking = rankings.first(where: {$0.number == rankingNumber}) {
                    importedTraveller.ranking[seat] = ranking.number
                    importedTraveller.section[seat] = ranking.section
                } else {
                    fatalError()
                }
            case "contract":
                let contract = Contract()
                if let string = columns.element(index) {
                    if let level = Int(string.left(1)) {
                        contract.level = ContractLevel(rawValue: level) ?? .passout
                        contract.suit = Suit(string: string.left(2).right(1))
                    } else {
                        contract.level = .passout
                    }
                    if string.right(2).lowercased() == "xx" {
                        contract.double = .redoubled
                    } else if string.right(1).lowercased() == "x" {
                        contract.double = .doubled
                    }
                }
                importedTraveller.contract = contract
            case "declarer":
                importedTraveller.declarer = Seat(string: columns.element(index) ?? "")
            case "tricks":
                if let string = columns.element(index), let tricks = Int(string) {
                    if let level = importedTraveller.contract?.level {
                        if level.rawValue > 0 {
                            importedTraveller.made = tricks - (level.rawValue + 6)
                        }
                    }
                }
            case "lead":
                importedTraveller.lead = columns.element(index)
            case "score":
                if let string = columns.element(index) {
                    importedTraveller.nsPoints = Int(string)
                }
            case "percent", "imps":
                if let string = columns.element(index) {
                    if let score = Float(string.replacingOccurrences(of: "%", with: "")) {
                        importedTraveller.nsScore = score
                    }
                }
            case "section":
                    // Ignore - set above from player name
                break
            case "playdata":
                importedTraveller.playData = columns.element(index)
            default:
                break
            }
        }
        
        if let board = importedTraveller.board {
            if travellers[board] == nil {
                travellers[board] = []
            }
            travellers[board]!.append(importedTraveller)
        }
    }
    
    public func importOptimum(lines: [String], scorecard: ScorecardViewModel) {
        var found = false
        var boardNumber: Int?
        
        for line in lines {
            if line.left(7) == "[Board " {
                boardNumber = Int(line.mid(7, line.count - 7).replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "]", with: ""))
                if let boardNumber = boardNumber {
                    if boards[boardNumber] == nil {
                        boards[boardNumber] = ImportedBoard(boardNumber: boardNumber)
                    }
                }
            } else if let boardNumber = boardNumber {
                if line.left(20) == "[OptimumResultTable " {
                    found = true
                } else if line.left(14) == "[OptimumScore " {
                    found = false
                    let optimumScoreString = line.mid(14, line.count - 14).replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "]", with: "")
                    boards[boardNumber]!.optimumScore = OptimumScore(string: optimumScoreString, vulnerability: Vulnerability(board: boardNumber))
                } else if line.left(1) == "[" {
                    found = false
                } else if found {
                    let components = line.replacingOccurrences(of: "  ", with: " ").components(separatedBy: " ")
                    if components.count >= 3 {
                        let declarer = Seat(string: components[0])
                        let suit = Suit(string: components[1].left(1))
                        let made = Int(components[2])
                        if declarer != .unknown && suit != .blank && made != nil {
                            if boards[boardNumber]!.doubleDummy[declarer] == nil {
                                boards[boardNumber]!.doubleDummy[declarer] = [:]
                            }
                            boards[boardNumber]!.doubleDummy[declarer]![suit] = made
                        }
                    }
                }
            }
        }
    }
    
    private func combineRankings() {
            // Teams pairs as separate lines
        var remove: [Int] = []
        for (index, bboRanking) in rankings.enumerated() {
            if bboRanking.ranking == nil && index > 0 {
                    // Add to previous ranking
                rankings[index - 1].players[.east] = bboRanking.players[.north]
                rankings[index - 1].players[.west] = bboRanking.players[.south]
                if let number = bboRanking.number {
                    translateNumber[number] = rankings[index - 1].number
                    remove.append(index)
                }
                eventType = .teams
            }
        }
        for removeIndex in remove.reversed() {
            rankings.remove(at: removeIndex)
        }
        for ranking in rankings {
            if eventType == .individual {
                ranking.players[.south] = ranking.players[.north]
            }
            if eventType != .teams {
                ranking.players[.east] = ranking.players[.north]
                ranking.players[.west] = ranking.players[.south]
            }
        }
        for (_, boardTravellers) in travellers {
            for traveller in boardTravellers {
                for seat in Seat.validCases {
                    if let number = traveller.ranking[seat] {
                        if let toNumber = translateNumber[number] {
                            traveller.ranking[seat] = toNumber
                        }
                    }
                }
            }
        }
        type = (type == .xImp && eventType == .teams ? .imp : type)
    }
    
        // MARK: - Utility routines ==================================================================== -
    
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
