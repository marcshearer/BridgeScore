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
                        MessageBox.shared.show("This will overwrite the data in the current scorecard. Are you sure you want to continue", cancelText: "Cancel", okText: "Overwrite", okDestructive: true, cancelAction: {
                            selected = nil
                        }, okAction: {
                            importedBBOScorecard.execute()
                            completion?()
                            MessageBox.shared.show("BBO Scorecard Import Complete", okAction: {
                                presentationMode.wrappedValue.dismiss()
                            })
                        })
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

class ImportedBBOScorecard {
    enum Phase {
        case heading
        case rankingHeader
        case ranking
        case travellerHeader
        case traveller
    }
    
    private(set) var title: String?
    private(set) var boardCount: Int?
    private(set) var bboId: String?
    private(set) var bboUrl: String?
    private(set) var date: Date?
    private(set) var partner: PlayerViewModel?
    private(set) var myRanking: ImportedBBOScorecardRanking?
    private(set) var type: ScoreType?
    private(set) var ranking: [ImportedBBOScorecardRanking] = []
    private(set) var traveller: [Int:[ImportedBBOBoardTravellerLine]] = [:]
    private(set) var warnings: [String] = []
    private(set) var error: String?
    private(set) var scorecard: ScorecardViewModel?
    private(set) var boardsTable: Int?
    public var table: Int = 1

    private var phase: Phase = .heading
    private var rankingHeadings: [String] = []
    private var travellerHeadings: [String] = []
    
    init(lines: [String] = [], scorecard: ScorecardViewModel? = nil) {
        self.scorecard = scorecard
        for line in lines {
            let columns = columns(line)
            if !columns.isEmpty {
                switch phase {
                case .heading:
                    importHeading(columns)
                case .rankingHeader:
                    rankingHeadings = columns
                    phase = .ranking
                case .ranking:
                    if columns.first!.lowercased() == "#travellerlines" {
                        phase = .travellerHeader
                    } else {
                        importRanking(columns)
                    }
                case .travellerHeader:
                    travellerHeadings = columns
                    phase = .traveller
                case .traveller:
                    if columns.count > 1 {
                        importTraveller(columns)
                    }
                }
            }
        }
        if !lines.isEmpty {
            validate()
        }
    }
    
    public func execute() {
        // Update date
        if let date = date {
            scorecard?.date = date
        }
        
        // Update partner
        if let partner = partner {
            scorecard?.partner = partner
        }
        
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
         
        if let myRanking = myRanking {
            // Update position
            if !(scorecard?.resetNumbers ?? false) {
                if let position = myRanking.ranking {
                    scorecard?.position = position
                }
            }
            
            // Update score
            if !(scorecard?.resetNumbers ?? false) && !(scorecard?.manualTotals ?? false) {
                if let score = myRanking.score {
                    scorecard?.score = score
                }
            }
        }

        // Update field entry size
        scorecard?.entry = ranking.count
        
        // Update boards and tables
        if let scorecard = scorecard {
            if Scorecard.current.match(scorecard: scorecard) {
                if scorecard.resetNumbers {
                    importTable(tableNumber: table, boardOffset: (table - 1) * scorecard.boardsTable)
                } else {
                    for tableNumber in 1...scorecard.tables {
                        importTable(tableNumber: tableNumber)
                    }
                }
            }
            Scorecard.updateScores(scorecard: scorecard)
            if scorecard.entry == 2 && scorecard.type.boardScoreType != .percent && scorecard.score != nil && scorecard.maxScore != nil {
                scorecard.position = (scorecard.score! >= (scorecard.maxScore! / 2) ? 1 : 2)
            }
            
            Scorecard.current.saveAll(scorecard: scorecard)
        }
    }
    
    private func importTable(tableNumber: Int, boardOffset: Int = 0) {
        if let scorecard = scorecard, let myRanking = myRanking, let myNumber = myRanking.number {
            
            let scorer = MasterData.shared.scorer
            let bboName = scorer!.bboName.lowercased()
            let table = Scorecard.current.tables[tableNumber]
            
            for tableBoardNumber in 1...scorecard.boardsTable {
                
                let boardNumber = ((tableNumber - 1) * scorecard.boardsTable) + tableBoardNumber
                let board = Scorecard.current.boards[boardNumber]
                
                if let lines = traveller[boardNumber - boardOffset], let myLine = myTravellerLine(lines: lines, myNumber: myNumber) {
                    
                    let otherPair = otherPair(line: myLine, myNumber: myNumber)
                    if let otherRanking = ranking.first(where: {$0.number == otherPair}), let mySeat = seat(line: myLine, ranking: myRanking, bboName: bboName) {
                        table?.sitting = mySeat
                        let left = MasterData.shared.realName(bboName: otherRanking.players[mySeat.leftOpponent]) ?? "Unknown"
                        let right = MasterData.shared.realName(bboName: otherRanking.players[mySeat.rightOpponent]) ?? "Unknown"
                        table?.versus = "\(left) & \(right)"
                    }
                    
                    board?.contract = myLine.contract ?? Contract()
                    board?.declarer = myLine.declarer ?? .unknown
                    board?.made = myLine.made
                    if let nsScore = myLine.nsScore {
                        board?.score = (nsScore == 0 ? 0 : (myLine.nsPair == myRanking.number ? nsScore : ( (scorecard.type.boardScoreType == .percent ? 100 - nsScore : -nsScore))))
                    }
                }
            }
        }
    }
    
    private func validate() {
        // Find self and partner
        let scorer = MasterData.shared.scorer
        let bboName = scorer?.bboName.lowercased()
        myRanking = ranking.first(where: {$0.players.contains(where: {$0.value == bboName})})
        if let myRanking = myRanking {
            let seat = myRanking.players.first(where: {$0.value == bboName})?.key
            let partnerBBOName = myRanking.players[seat!.partner]
            partner = MasterData.shared.players.first(where: {$0.bboName.lowercased() == partnerBBOName})
            if partner != scorecard?.partner {
                warnings.append("Partner in imported scorecard does not match current scorecard")
            }
        } else {
            warnings.append("Unable to find self in imported scorecard")
        }
        
        // Check scoring type
        if type != scorecard?.type.boardScoreType {
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
        
        // Check boards per table
        var lastVersus: Int? = nil
        var lastBoards: Int = 0
        var boardsTableError = false
        if let myNumber = myRanking?.number {
            for (_, lines) in traveller.sorted(by: {$0.key < $1.key}) {
                if let line = myTravellerLine(lines: lines, myNumber: myNumber) {
                    let otherPair = otherPair(line: line, myNumber: myNumber)
                    if lastVersus != otherPair && lastVersus != nil {
                        if lastBoards != scorecard?.boardsTable {
                            boardsTableError = true
                        }
                        lastBoards = 0
                    }
                    lastVersus = otherPair
                    lastBoards += 1
                }
            }
        }
        boardsTable = lastBoards
        if boardsTableError || lastBoards != scorecard?.boardsTable {
            warnings.append("Imported number of boards per table does not match current scorecard")
        }
    }

    private func myTravellerLine(lines: [ImportedBBOBoardTravellerLine], myNumber: Int) -> ImportedBBOBoardTravellerLine? {
        var result: ImportedBBOBoardTravellerLine?
        let scorer = MasterData.shared.scorer
        let bboName = scorer?.bboName.lowercased()
        if let line = lines.first(where: {$0.nsPair == myNumber}) {
            if myRanking?.players[.north] == bboName || myRanking?.players[.south] == bboName {
                result = line
            }
        }
        if result == nil {
            if let line = lines.first(where: {$0.ewPair == myNumber}) {
                if myRanking?.players[.east] == bboName || myRanking?.players[.west] == bboName {
                    result = line
                }
            }
        }
        return result
    }
    
    private func seat(line: ImportedBBOBoardTravellerLine, ranking: ImportedBBOScorecardRanking, bboName: String) -> Seat? {
        var result: Seat?
        if line.ewPair == ranking.number {
            if ranking.players[.east] == bboName {
                result = .east
            } else if ranking.players[.west] == bboName {
                result = .west
            }
        } else if line.nsPair == ranking.number {
            if ranking.players[.north] == bboName {
                result = .north
            } else if ranking.players[.south] == bboName {
                result = .south
            }
        }
        return result
    }
    
    private func otherPair(line: ImportedBBOBoardTravellerLine, myNumber: Int) -> Int {
        return (line.nsPair == myNumber ? line.ewPair! : line.nsPair!)
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
    
    private func importHeading(_ columns: [String]) {
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
    
    private func importRanking(_ columns: [String]) {
        let importedRanking = ImportedBBOScorecardRanking()
        
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
                if let string = columns.element(index) {
                    importedRanking.section = Int(string)
                }
            case "bbo pts":
                if let string = columns.element(index) {
                    importedRanking.bboPoints = Float(string)
                }
            default:
                break
            }
        }
        ranking.append(importedRanking)
    }
    
    private func importTraveller(_ columns: [String]) {
        let importedTraveller = ImportedBBOBoardTravellerLine()
        var north: String?
        var south: String?
        var east: String?
        var west: String?

        for (index, heading) in travellerHeadings.enumerated() {
            switch heading.lowercased() {
            case "#board":
                if let string = columns.element(index) {
                    importedTraveller.board = Int(string)
                }
            case "north":
                north = columns.element(index)?.lowercased()
            case "south":
                south = columns.element(index)?.lowercased()
            case "east":
                east = columns.element(index)?.lowercased()
            case "west":
                west = columns.element(index)?.lowercased()
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
                    } else if string.right(2).lowercased() == "x" {
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
                if let string = columns.element(index) {
                    importedTraveller.section = Int(string)
                }
            case "playdata":
                importedTraveller.playData = columns.element(index)
            default:
                break
            }
        }
        importedTraveller.nsPair = ranking.first(where: {$0.players[.north] == north && $0.players[.south] == south})?.number
        importedTraveller.ewPair = ranking.first(where: {$0.players[.east] == east && $0.players[.west] == west})?.number
       
        if let board = importedTraveller.board {
            if traveller[board] == nil {
                traveller[board] = []
            }
            traveller[board]!.append(importedTraveller)
        }
    }
}

class ImportedBBOScorecardRanking {
    public var number: Int?
    public var section: Int?
    public var players: [Seat:String] = [:]
    public var score: Float?
    public var ranking: Int?
    public var bboPoints: Float?
}

class ImportedBBOBoard {
    public var board: Int?
    public var traveller: [ImportedBBOBoardTravellerLine]?
}

class ImportedBBOBoardTravellerLine {
    public var board: Int?
    public var nsPair: Int?
    public var ewPair: Int?
    public var section: Int?
    public var contract: Contract?
    public var declarer: Seat?
    public var made: Int?
    public var lead: String?
    public var points: Int?
    public var nsScore: Float?
    public var playData: String?
}
