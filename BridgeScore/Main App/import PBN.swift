//
//  import PBN.swift
//  BridgeScore
//
//  Created by Marc Shearer on 18/09/2023.
//

import CoreData
import SwiftUI
import CoreMedia

class ImportPBN {
    
    fileprivate static let documentsUrl:URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last! as URL
    fileprivate static let importsURL = documentsUrl.appendingPathComponent("imports")
      
    public class func importScorecard(fileURL: URL, scorecard: ScorecardViewModel) -> ImportedPBNScorecard? {
        
        if let contents = try? String(contentsOf: fileURL) {
            let lines = contents.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
            var csvLines: [String] = []
            if let csvURL = URL(string: fileURL.absoluteString.replacingOccurrences(of: ".pbn", with: ".csv")) {
                if let contents = try? String(contentsOf: csvURL) {
                    csvLines = contents.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
                }
            }
            let imported = ImportedPBNScorecard(lines: lines, csvLines: csvLines, scorecard: scorecard)
            return imported
        } else {
            return nil
        }
    }
    
    public static func parse(_ line: String) -> (key: String, value: String) {
        let line = line.ltrim().rtrim()
        if line.left(1) == "[" && line.right(1) == "]" {
            let components = line.mid(1, line.count - 2).components(separatedBy: "\"")
            if components.count == 3 {
                return(components[0].ltrim().rtrim(), components[1])
            }
        }
        return ("", "")
    }
}

struct ImportPBNScorecard: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var scorecard: ScorecardViewModel
    var completion: (()->())? = nil
    @State private var selected: URL? = nil
    @State private var importedPBNScorecard: ImportedPBNScorecard = ImportedPBNScorecard()
    @State private var identifySelf = false
    
    var body: some View {
        StandardView("Detail") {
            if selected == nil {
                ImportPBNScorecard.fileList(scorecard: scorecard, selected: selected) { selected in
                    if MasterData.shared.scorer != nil {
                        self.selected = selected
                        if let imported = ImportPBN.importScorecard(fileURL: selected, scorecard: scorecard) {
                            importedPBNScorecard = imported
                            identifySelf = imported.identifySelf
                        } else {
                            MessageBox.shared.show("Unable to import scorecard", okAction: {
                                presentationMode.wrappedValue.dismiss()
                            })
                        }
                    } else {
                        MessageBox.shared.show("In order to import a scorecard a player must be defined as yourself", okAction: {
                            presentationMode.wrappedValue.dismiss()
                        })
                    }
                }
            } else {
                let importedScorecard = Binding.constant(importedPBNScorecard as ImportedScorecard)
                importedPBNScorecard.confirmDetails(importedScorecard: importedScorecard, onError: {
                    presentationMode.wrappedValue.dismiss()
                }, completion: {
                    importedPBNScorecard.importScorecard()
                    completion?()
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
        .fullScreenCover(isPresented: $identifySelf, onDismiss: {
            if importedPBNScorecard.error != nil {
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            VStack {
                IdentifySelfView(imported: importedPBNScorecard, identifySelf: $identifySelf)
                    .background(.clear)
            }
            .cornerRadius(16)
            .background(BackgroundBlurView())
        }
    }
        
    static func fileList(scorecard: ScorecardViewModel, selected: URL?, completion: @escaping (URL)->()) -> some View {
        return VStack(spacing: 0) {
            Banner(title: Binding.constant("Choose file to import"), backImage: Banner.crossImage)
            Spacer().frame(height: 16)
            if let files = try? FileManager.default.contentsOfDirectory(at: ImportPBN.importsURL, includingPropertiesForKeys: nil).filter({$0.relativeString.right(4) == ".pbn"}) {
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
                        completion(fileData[index].path)
                    }
                }
            }
            Spacer()
        }
        
        func decompose(_ paths: [URL]) -> [(URL, Int?, String, Date?)] {
            var result: [(path: URL, number: Int?, text: String, date: Date?)] = []
            
            for path in paths {
                var text: String?
                var date: Date?
                
                if let contents = try? String(contentsOf: path) {
                    let lines = contents.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
                    if let line = lines.filter({$0.starts(with: "[Event ")}).first {
                        text = ImportPBN.parse(line).value
                    }
                    if let line = lines.filter({$0.starts(with: "[Date ")}).first {
                        let dateString = ImportPBN.parse(line).value
                        if dateString != "" {
                            date = Date(from: dateString.replacingOccurrences(of: ".", with: "/"), format: "yyyy/MM/dd")
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
        
        func fileName(_ path: String) -> String {
            let components = path.components(separatedBy: "/")
            var subComponents = components.last!.components(separatedBy: ".")
            subComponents.removeLast()
            let text = subComponents.joined(separator: ".")
            return text
        }
    }
}

struct IdentifySelfView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var imported: ImportedPBNScorecard
    @Binding var identifySelf: Bool
    @State var sitting: Seat = .unknown
    @State var ranking: ImportedRanking?
    
    
    var body: some View {
        let type = Scorecard.current.scorecard!.type
        let description = type.description.lowercased()
        let needSitting = type.players == 4

        VStack {
            VStack {
                HStack {
                    Spacer()
                    VStack {
                        Spacer().frame(height: 10)
                        Text("No \(description) names have been provided")
                        Text("You must identify your \(description) number\(needSitting ? " and seat" : "")")
                        Spacer().frame(height: 10)
                    }
                    Spacer()
                }
                .font(inputTitleFont).bold()
                .palette(.contrastTile)
                
                Spacer()
                HStack {
                    Spacer().frame(width: 20)
                    VStack {
                        Spacer().frame(height: 20)
                        LeadingText("\(description.capitalized) number:")
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible())], spacing: 0) {
                                ForEach(imported.rankings.sorted(by: {($0.number ?? 0) < ($1.number ?? 0)})) { ranking in
                                    VStack {
                                        Spacer()
                                        HStack{
                                            HStack {
                                                Spacer().frame(width: 20)
                                                Text("\(ranking.number ?? 0)")
                                                Spacer()
                                            }.frame(width: 60)
                                            Text(ranking.full ?? "")
                                            Spacer()
                                        }
                                        Spacer()
                                        Separator()
                                    }
                                    .frame(height: 30)
                                    .background(ranking == self.ranking ? Palette.tile.background : Palette.background.background)
                                    .foregroundColor(Palette.background.text)
                                    .onTapGesture {
                                        self.ranking = ranking
                                    }
                                }
                            }
                        }.overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Palette.contrastTile.background, lineWidth: 2)
                        )
                        if needSitting {
                            Spacer().frame(height: 30)
                            HStack {
                                Text("Sitting: ")
                                Spacer().frame(width:30)
                                Picker("Sitting ", selection: $sitting) {
                                    ForEach(Seat.validCases) { seat in
                                        Text(seat.string)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 300)
                                Spacer()
                            }
                        }
                        Spacer().frame(height: 20)
                        Separator(padding: false, thickness: 2, color: Palette.contrastTile.background)
                        Spacer().frame(height: 20)
                        HStack {
                            Spacer()
                            button("Confirm", disabled: { (needSitting && sitting == .unknown) || self.ranking == nil }) {
                                identifySelf = false
                                if !needSitting {
                                    sitting = .north
                                }
                                if let ranking = ranking {
                                    updateRanking(imported: imported, ranking: ranking, sitting: sitting)
                                }
                                presentationMode.wrappedValue.dismiss()
                            }
                            Spacer().frame(width: 50)
                            button("Cancel") {
                                imported.error = "Unable to identify players"
                                identifySelf = false
                                presentationMode.wrappedValue.dismiss()
                            }
                            Spacer()
                        }
                        Spacer().frame(height: 10)
                    }
                    Spacer().frame(width: 20)
                }
                Spacer()
            }
            .frame(width: 500, height: 600)
            .cornerRadius(16)
            .background(Palette.background.background)
        }
        .background(.clear)
    }
    
    private func updateRanking(imported: ImportedScorecard, ranking: ImportedRanking, sitting: Seat) {
        let type = Scorecard.current.scorecard!.type
        ranking.players[sitting] = MasterData.shared.scorer?.name
        if type.players == 1 {
            ranking.players[sitting.partner] = MasterData.shared.scorer?.name
        } else {
            ranking.players[sitting.partner] = Scorecard.current.scorecard?.partner?.name
        }
        if type.players != 4 {
            ranking.players[sitting.leftOpponent] = ranking.players[sitting]
            ranking.players[sitting.rightOpponent] = ranking.players[sitting.partner]
        }
        imported.myRanking = ranking
    }
    
    private func button(_ text: String, disabled: (()->(Bool))? = { false }, action: @escaping ()->()) -> some View {
        VStack {
            let enabled = !(disabled?() ?? false)
            let color = enabled ? Palette.enabledButton : Palette.disabledButton
            Button {
                action()
            } label: {
                HStack {
                    Spacer()
                    Text(text)
                    Spacer()
                }.frame(width: 100, height: 40)
                    .foregroundColor(color.text)
                    .background(color.background)
                    .cornerRadius(8)
            }.disabled(!enabled)
        }
    }
}

class ImportedPBNScorecard: ImportedScorecard {
    enum Phase {
        case heading
        case board
        case optimumResult
        case traveller
        case finished
    }
    
    private var translateNumber: [Int:Int] = [:]

    private var phase: Phase = .heading
    private var rankingHeadings: [String] = []
    private var travellerHeadings: [String] = []
    private var optimumResultHeadings: [String] = []
    private var section: Int = 1
    private var board: Int?
    
  // MARK: - Initialise from import file ============================================================ -
    
    init(lines: [String] = [], csvLines: [String] = [], scorecard: ScorecardViewModel? = nil) {
        super.init()
        self.importSource = .pbn
        self.identifySelf = csvLines.isEmpty
        
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
        let scorer = MasterData.shared.scorer
        myName = scorer!.name.lowercased()
        
        for line in csvLines {
            let columns = line.components(separatedBy: ",")
            if rankingHeadings.isEmpty {
                rankingHeadings = columns
            } else {
                initRanking(columns: columns)
            }
        }
        
        for line in lines {
            if line == "" {
                phase = .heading
            } else {
                let (key, value) = ImportPBN.parse(line)
                if key != "" && (phase == .optimumResult || phase == .traveller) {
                    phase = (phase == .traveller ? .heading : .board)
                }
                switch phase {
                case .heading:
                    initHeading(key: key, value: value)
                case .board:
                    initBoard(key: key, value: value)
                case .optimumResult:
                    let columns = line.components(separatedBy: " ").filter({$0 != ""})
                    initOptimumResult(columns: columns)
                case .traveller:
                    let columns = line.components(separatedBy: " ").filter({$0 != ""})
                    initTraveller(columns: columns)
                case .finished:
                    break
                }
            }
        }
               
        if error == nil && !lines.isEmpty {
            combineRankings()
            scoreTravellers()
            recalculateTravellers()
            validate()
        }
    }
    
    private func initHeading(key: String, value: String) {
        switch key.lowercased() {
        case "board":
            phase = .board
            board = Int(value)
            if let board = board {
                boards[board] = ImportedBoard(boardNumber: board)
            }
        case "event":
            title = value
        case "date":
            date = Date(from: value.replacingOccurrences(of: ".", with: "/"), format: "yyyy/MM/dd")
        default:
            break
        }
    }
    
    private func initBoard(key: String, value: String) {
        if let board = board {
            switch key.lowercased() {
            case "deal":
                boards[board]?.hand = initDeal(cards: value)
            case "optimumresulttable":
                phase = .optimumResult
                optimumResultHeadings = value.lowercased().replacingOccurrences(of: "\\2r", with: "").components(separatedBy: ";")
                boards[board]?.doubleDummy = [:]
            case "scoretable":
                phase = .traveller
                travellerHeadings = value.lowercased().components(separatedBy: ";").map{$0.components(separatedBy: "\\").first!}
                travellers[board] = []
            default:
                break
            }
        }
    }
    
    private func initOptimumResult(columns: [String]) {
        if columns.count >= 3  {
            var declarer = Seat.unknown
            var suit = Suit.blank
            var made: Int?
            for (index, value) in columns.enumerated() {
                if index < optimumResultHeadings.count {
                    switch optimumResultHeadings[index] {
                    case "declarer":
                        declarer = Seat(string: value)
                    case "denomination":
                        suit = Suit(string: value.left(1))
                    case "result":
                        made = Int(value)
                    default:
                        break
                    }
                }
            }
            if declarer != .unknown && suit != .blank && made != nil {
                if boards[board!]!.doubleDummy[declarer] == nil {
                    boards[board!]!.doubleDummy[declarer] = [:]
                }
                boards[board!]!.doubleDummy[declarer]![suit] = made
            }
        }
    }
    
    private func initRanking(columns: [String]) {
        let importedRanking = ImportedRanking()
        
        for (index, heading) in rankingHeadings.enumerated() {
            switch heading.lowercased() {
            case "pair", "team":
                if let string = columns.element(index) {
                    let number = Int(string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
                    importedRanking.number = number
                    importedRanking.full = string
                }
            case "name1":
                importedRanking.players[.north] = columns.element(index)
            case "name2":
                importedRanking.players[.south] = columns.element(index)
            case "name3":
                importedRanking.players[.east] = columns.element(index)
                format = .teams
            case "name4":
                importedRanking.players[.west] = columns.element(index)
                format = .teams
            default:
                break
            }
        }
        rankings.append(importedRanking)
    }
    
    private func initDeal(cards: String) -> String {
        var result = ""
        if let board = board {
            let components = cards.components(separatedBy: ":")
            let dealer = Seat.dealer(board: board)
            if dealer != .unknown {
                if Seat(string: components.first ?? "") == dealer {
                    var nextSeat = dealer
                    var hands: [Seat:String] = [:]
                    if let detail = components.last {
                        let handStrings = detail.components(separatedBy: " ")
                        for suitStrings in handStrings {
                            let suits = suitStrings.components(separatedBy: ".")
                            if suits.count == 4 {
                                hands[nextSeat] = suits.joined(separator: ",")
                                nextSeat = nextSeat.leftOpponent
                            }
                        }
                        if hands.count == 4 {
                            let hands = hands.sorted(by: {$0.key.rawValue < $1.key.rawValue}).map{$0.value}
                            result = hands.joined(separator: ",")
                        }
                    }
                }
            }
        }
        return result
    }
    
    private func initTraveller(columns: [String]) {
        if let board = board {
            let importedTraveller = ImportedTraveller(board: board)
            for (index, heading) in travellerHeadings.enumerated() {
                switch heading.lowercased() {
                case "pairid_ns", "pairid_ew":
                    if let column = columns.element(index) {
                        let number = column.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                        let pair = Pair(string: heading.lowercased().right(2))
                        let rankingNumber = Int(number) ?? 0
                        var ranking = rankings.first(where: {$0.number == rankingNumber})
                        if ranking == nil {
                            let name = "\(scorecard.type.description) \(rankingNumber)"
                            ranking = ImportedRanking(number: rankingNumber, name: name)
                            rankings.append(ranking!)
                        }
                        for seat in pair.seats {
                            importedTraveller.ranking[seat] = ranking!.number
                            importedTraveller.section[seat] = ranking!.section
                        }
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
                case "result":
                    if let string = columns.element(index), let tricks = Int(string) {
                        if let level = importedTraveller.contract?.level {
                            if level.rawValue > 0 {
                                importedTraveller.made = tricks - (level.rawValue + 6)
                            }
                        }
                    }
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
    }
    
    private func combineRankings() {
        // Teams pairs as separate lines
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
