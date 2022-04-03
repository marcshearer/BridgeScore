//
//  Import BBO Names.swift
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
                                    bboNameMO.bboName = bboName
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
            return ImportedBBOScorecard(lines: lines, scorecard: scorecard)
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
                confirmDetails
            }
        }
    }
        
    var fileList: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("Choose file to import"), backImage: Banner.crossImage)
            Spacer().frame(height: 16)
            if let files = try? FileManager.default.contentsOfDirectory(at: ImportBBO.importsURL, includingPropertiesForKeys: nil).filter({$0.relativeString.right(4) == ".csv"}) {
                ForEach(files, id: \.self) { (file) in
                    VStack {
                        Spacer().frame(height: 8)
                        HStack {
                            let components = file.relativeString.components(separatedBy: "/")
                            let subComponents = components.last!.components(separatedBy: ".")
                            Spacer().frame(width: 16)
                            Text(subComponents.first!)
                                .font(.title2)
                                .minimumScaleFactor(0.5)
                            Spacer()
                        }
                        Spacer().frame(height: 8)
                    }
                    .background((file == selected ? Palette.alternate : Palette.background).background)
                    .onTapGesture {
                        selected = file
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
                                if let imported = ImportBBO.importScorecard(fileURL: file, scorecard: scorecard) {
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
    
    var confirmDetails: some View {
        @OptionalStringBinding(importedBBOScorecard.title) var titleBinding
        @OptionalStringBinding(Utility.dateString(importedBBOScorecard.date, format: "EEEE d MMMM yyyy")) var dateBinding
        @OptionalStringBinding(importedBBOScorecard.partner?.name) var partnerBinding
        @OptionalStringBinding("\(importedBBOScorecard.boardCount ?? 0)") var boardCountBinding
        @OptionalStringBinding("\(importedBBOScorecard.boardsTable ?? 0)") var boardsTableBinding
        
        
        return VStack(spacing: 0) {
            Banner(title: Binding.constant("Confirm Import Details"), backImage: Banner.crossImage, backAction: {selected = nil ; return false})
            Spacer().frame(height: 16)
            
            if scorecard.tables > 1 && scorecard.resetNumbers {
                InsetView(title: "Import Settings") {
                    VStack(spacing: 0) {
                
                        StepperInput(title: "Import for table", field: $importedBBOScorecard.table, label: stepperLabel, minValue: Binding.constant(1), maxValue: Binding.constant(scorecard.tables))
                        
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

            if !importedBBOScorecard.warnings.isEmpty {
                InsetView(title: "Warnings") {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 16)
                        ForEach(importedBBOScorecard.warnings, id: \.self) { (warning) in
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
                        importedBBOScorecard.importScorecard()
                        completion?()
                        presentationMode.wrappedValue.dismiss()
                    }
                    Spacer()
                }
                Spacer().frame(height: 16)
            }
            .onAppear {
                if let error = importedBBOScorecard.error {
                    MessageBox.shared.show(error, okAction: {
                        selected = nil
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

class ImportedBBOScorecard: ImportedScorecard {
    enum Phase {
        case heading
        case rankingHeader
        case ranking
        case travellerHeader
        case traveller
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
                    if columns.count > 1 {
                        initTraveller(columns)
                    }
                }
            }
        }
        if !lines.isEmpty {
            combineRankings()
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
            type = ScoreType(bboScoringType: columns.element(1))
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
                    importedRanking.players[.south] = names[1].lowercased()
                    importedRanking.players[.east] = names[0].lowercased()
                    importedRanking.players[.west] = names[1].lowercased()
                }
            case "name1":
                importedRanking.players[.north] = columns.element(index)?.lowercased()
            case "name2":
                importedRanking.players[.south] = columns.element(index)?.lowercased()
            case "name3":
                importedRanking.players[.east] = columns.element(index)?.lowercased()
            case "name4":
                importedRanking.players[.west] = columns.element(index)?.lowercased()
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
            case "north", "south", "east", "west":
                let seat = Seat(string: heading.left(1).uppercased())
                if let ranking = rankings.first(where: {$0.players[seat] == columns.element(index)?.lowercased()}) {
                    importedTraveller.ranking[seat] = ranking.number
                    importedTraveller.section[seat] = ranking.section
                } else {
                    fatalError()
                }
                /*
            case "nspair":
                if let string = columns.element(index)?.replacingOccurrences(of: "NS", with: "") {
                    importedTraveller.ranking[.north] = Int(string)
                    importedTraveller.ranking[.south] = Int(string)
                }
            case "ewpair":
                if let string = columns.element(index)?.replacingOccurrences(of: "EW", with: "") {
                    importedTraveller.ranking[.east] = Int(string)
                    importedTraveller.ranking[.west] = Int(string)
                }
            case "east":
                if let string = columns.element(index) {
                    importedTraveller.ranking[.east] = Int(string)
                }
            case "west":
                if let string = columns.element(index) {
                    importedTraveller.ranking[.west] = Int(string)
                }
                 */
            case "contract":
                let contract = Contract()
                if let string = columns.element(index) {
                    if let level = Int(string.left(1)) {
                        contract.level = ContractLevel(rawValue: level) ?? .passout
                        contract.suit = ContractSuit(string: string.left(2).right(1))
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
                    importedTraveller.points = Int(string)
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
    
    private func combineRankings() {
        if let scorecard = scorecard {
            if scorecard.type.players == 4 && rankings.first!.players[.north] == rankings.first!.players[.east] {
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
                    }
                }
                for removeIndex in remove.reversed() {
                    rankings.remove(at: removeIndex)
                }
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
