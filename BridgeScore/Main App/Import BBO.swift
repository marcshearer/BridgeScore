//
//  Import BBO.swift
//  BridgeScore
//
//  Created by Marc Shearer on 20/03/2022.
//

import CoreData
import SwiftUI
import CoreMedia

class ImportBBO {
    
    fileprivate static let documentsUrl:URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last! as URL
    fileprivate static let importsURL = documentsUrl.appendingPathComponent("imports")
  
    public class func importNames() {
        
        let entity = BBONameMO.entity()
        let recordType = entity.name!
        let elementName = recordType
        let groupName = "data"
        let fileURL = importsURL.appendingPathComponent("BBOName.json")
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
    
    public class func importScorecard(fileURL: URL, scorecard: ScorecardViewModel) -> ImportedBBOScorecard? {
        
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
}

struct ImportBBOScorecard: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var scorecard: ScorecardViewModel
    var completion: (()->())? = nil
    @State private var selected: URL? = nil
    @State private var importedBBOScorecard: ImportedBBOScorecard = ImportedBBOScorecard()
    
    var body: some View {
        StandardView("Detail") {
            if selected == nil {
                fileList
            } else {
                let importedScorecard = Binding.constant(importedBBOScorecard as ImportedScorecard)
                importedBBOScorecard.confirmDetails(importedScorecard: importedScorecard, onError: {
                    presentationMode.wrappedValue.dismiss()
                }, completion: {
                    importedBBOScorecard.importScorecard()
                    completion?()
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }
        
    var fileList: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("Choose file to import"), backImage: Banner.crossImage)
            Spacer().frame(height: 16)
            if let files = try? FileManager.default.contentsOfDirectory(at: ImportBBO.importsURL, includingPropertiesForKeys: nil).filter({$0.relativeString.right(4) == ".csv"}) {
                let fileData: [(path: URL, number: Int?, text: String, date: Date?)] = decompose(files)
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
                        selected = fileData[index].path
                        if let scorer = MasterData.shared.scorer {
                            if scorer.bboName == "" {
                                MessageBox.shared.show("In order to import a scorecard the player defined as yourself must have a BBO name", okAction: {
                                    presentationMode.wrappedValue.dismiss()
                                })
                            } else if scorecard.partner?.bboName ?? "" == "" {
                                MessageBox.shared.show("In order to import a scorecard your partner must have a BBO name", okAction: {
                                    presentationMode.wrappedValue.dismiss()
                                })
                            } else {
                                if let imported = ImportBBO.importScorecard(fileURL: selected!, scorecard: scorecard) {
                                    importedBBOScorecard = imported
                                }
                            }
                        } else {
                            MessageBox.shared.show("In order to import a scorecard a player must be defined as yourself", okAction: {
                                presentationMode.wrappedValue.dismiss()
                            })
                        }
                    }
                }
            }
            Spacer()
        }
    }
    
    func decompose(_ paths: [URL]) -> [(URL, Int?, String, Date?)] {
        var result: [(path: URL, number: Int?, text: String, date: Date?)] = []
        
        for path in paths {
            var components = fileName(path.relativeString).components(separatedBy: "_")
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
            result.append((path, number, components.joined(separator: " "), date))
        }
        let baseDate = Date(timeIntervalSinceReferenceDate: 0)
        return result.filter({Date.startOfDay(from: $0.date ?? baseDate) == Date.startOfDay(from: scorecard.date)}).sorted(by: {($0.number ?? 0) > ($1.number ?? 0)})
    }
    
    func fileName(_ path: String) -> String {
        let components = path.components(separatedBy: "/")
        var subComponents = components.last!.components(separatedBy: ".")
        subComponents.removeLast()
        let text = subComponents.joined(separator: ".")
        return text
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
        let scorer = MasterData.shared.scorer
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
                        format = .individual
                    }
                }
            case "name1":
                importedRanking.players[.north] = columns.element(index)?.lowercased()
                format = .teams
            case "name2":
                importedRanking.players[.south] = columns.element(index)?.lowercased()
                format = .teams
            case "name3":
                importedRanking.players[.east] = columns.element(index)?.lowercased()
                format = .teams
            case "name4":
                importedRanking.players[.west] = columns.element(index)?.lowercased()
                format = .teams
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
                format = .teams
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
        type = (type == .xImp && format == .teams ? .imp : type)
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
