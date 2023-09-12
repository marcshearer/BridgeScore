//
//  Analysis Viewer.swift
//  BridgeScore
//
//  Created by Marc Shearer on 08/09/2023.
//

import SwiftUI
import UIKit

struct AnalysisViewer: View {
    let scorecard = Scorecard.current.scorecard!
    @State var board: BoardViewModel
    @State var traveller: TravellerViewModel
    @State var initialTraveller: TravellerViewModel?
    @State var sitting: Seat
    @State var from: UIView
    
    var body: some View {
        HStack {
            VStack {
                Spacer().frame(height: 15)
                VStack {
                    Spacer()
                    HStack {
                        Spacer().frame(width: 50)
                        Text("Board \(board.boardNumber) \(traveller.rankingNumber == initialTraveller?.rankingNumber ? "v \(board.table?.versus ?? "Unknown")" : "  -  Viewing Other Traveller")")
                        Spacer()
                        VStack {
                            HStack {
                                Spacer().frame(width: 20)
                                let score = sitting.pair == .ns ? traveller.nsScore : scorecard.type.invertScore(score: traveller.nsScore)
                                let places = scorecard.type.boardPlaces
                                Text("\(scorecard.type.boardScoreType.prefix(score: score))\(score.toString(places: places))\(scorecard.type.boardScoreType.suffix)")
                                Spacer().frame(width: 20)
                            }.frame(width: 200, height: 50).background(Palette.bannerShadow.background).foregroundColor(Palette.banner.text).cornerRadius(6).opacity(0.7)
                        }
                        Spacer().frame(width: 50)
                        ButtonBar(board: $board, traveller: $traveller, sitting: $sitting)
                        Spacer().frame(width: 20)
                    }.font(bannerFont).foregroundColor(Palette.banner.text)
                    Spacer()
                }
                .background(Palette.banner.background)
                .frame(height: 80)
                .cornerRadius(16)
                VStack {
                    Spacer().frame(height: 10)
                    HStack {
                        HandViewer(board: $board, traveller: $traveller, sitting: $sitting, from: from)
                            .cornerRadius(16)
                        Spacer().frame(width: 10)
                        VStack {
                            AnalysisBiddingOptions(board: $board, traveller: $traveller, sitting: $sitting)
                            Spacer()
                            AnalysisTravellerView(board: $board, traveller: $traveller, sitting: $sitting)
                        }
                    }
                }
                Spacer().frame(height: 15)
            }
        }
        .background(.clear)
        .onAppear() {
            initialTraveller = traveller
        }
    }
    
    struct ButtonBar: View{
        @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
        let scorecard = Scorecard.current.scorecard!
        @Binding var board: BoardViewModel
        @Binding var traveller: TravellerViewModel
        @Binding var sitting: Seat
        
        var body: some View {
            HStack {
                Button {
                    if let (newBoard, newTraveller) = Scorecard.getBoardTraveller(boardNumber: board.boardNumber - 1) {
                        board = newBoard
                        traveller = newTraveller
                        sitting = newBoard.table!.sitting
                    }
                } label: {
                    Image(systemName: "backward.frame")
                }.disabled(board.boardNumber <= 1).foregroundColor(Palette.banner.text.opacity(board.boardNumber <= 1 ? 0.5 : 1))
                Spacer().frame(width: 20)
                Button {
                    if let (newBoard, newTraveller) = Scorecard.getBoardTraveller(boardNumber: board.boardNumber + 1) {
                        board = newBoard
                        traveller = newTraveller
                        sitting = newBoard.table!.sitting
                    }
                } label: {
                    Image(systemName: "forward.frame")
                }.disabled(board.boardNumber >= scorecard.boards).foregroundColor(Palette.banner.text.opacity(board.boardNumber >= scorecard.boards ? 0.5 : 1))
                Spacer().frame(width: 30)
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}

struct AnalysisBiddingOptions : View {
    let scorecard = Scorecard.current.scorecard!
    @Binding var board: BoardViewModel
    @Binding var traveller: TravellerViewModel
    @Binding var sitting: Seat
    @State var options: [AnalysisOption] = []
    let columns = [GridItem(.flexible(minimum: 100), spacing: 0), GridItem(.fixed(45), spacing: 0),GridItem(.fixed(40), spacing: 0),  GridItem(.flexible(minimum: 60), spacing: 0), GridItem(.flexible(minimum: 60), spacing: 0), GridItem(.flexible(minimum: 60), spacing: 0), GridItem(.flexible(minimum: 60), spacing: 0),GridItem(.flexible(minimum: 60), spacing: 0)]
    
    var body: some View {
        ZStack {
            VStack {
                Rectangle().frame(height: 30).foregroundColor(Palette.tile.background)
                Spacer()
            }
            HStack {
                Spacer().frame(width: 10)
                VStack {
                    LazyVGrid(columns: columns, spacing: 0) {
                        GridRow {
                            LeadingText("")
                            LeadingText("")
                            LeadingText("")
                            ForEach(AnalysisAssessmentMethod.allCases, id: \.self) { method in
                                CenteredText(method.short)
                            }
                        }
                    }
                    .frame(height: 30)
                    .foregroundColor(Palette.tile.text)
                    .font(smallFont)
                    .bold()
                    ForEach(options) { option in // TODO These are wrong way round - should be grid above for
                        LazyVGrid(columns: columns, spacing: 0) {
                            GridRow {
                                LeadingText(option.type.string)
                                LeadingAttributedText(option.contract.colorCompact)
                                LeadingText(option.declarer.short)
                                ForEach(AnalysisAssessmentMethod.allCases, id: \.self) { method in
                                    let methodPoints = option.assessment[method]?.points
                                    CenteredText(methodPoints == nil ? "" : "\(methodPoints!)")
                                }
                            }
                            .frame(height: 25)
                            .if(option.separator) { view in
                                view.overlay(Separator(thickness: 2, color: Palette.tile.background), alignment: .bottom)
                            }
                        }
                    }
                    Spacer()
                }
                Spacer()
            }
        }
        .frame(width: 520)
        .background(Palette.alternate.background).cornerRadius(16)
        .font(smallFont)
        .onAppear {
            buildOptions()
        }
        .onChange(of: traveller) { traveller in
            buildOptions()
        }
    }
    
    func buildOptions() {
        options = []
        
        let contracts = traveller.contracts
        let declarer = traveller.declarer.pair
        let weDeclared = (declarer == sitting.pair)
        var bidder = declarer
        var previousBid: Contract?
        var started = false
        for bid in contracts.reversed() {
            if bid != nil || started {
                started = true
                if bidder != declarer && bid != nil {
                    previousBid = bid
                    break
                }
                bidder = bidder.other
            }
        }
        
        let ourBid = (weDeclared ? traveller.contract : previousBid)
        let ourSuit = ourBid?.suit
        let ourGameLevel = ourSuit?.gameTricks
        let ourLevel = ourBid?.level.rawValue
        let theirBid = (weDeclared ? previousBid : traveller.contract)
        let theirLevel = theirBid?.level.rawValue
        
        let multiplier: Float = (sitting.pair == .ns ? 1 : -1)
        let travellers = Scorecard.current.travellers(board: board.boardNumber).sorted(by: { (($0.nsScore - $1.nsScore) * multiplier) < 0 })
        
        let types = (weDeclared ? AnalysisOptionType.declaringCases : AnalysisOptionType.defendingCases)
        for type in types {
            var contract: Contract?
            var declarer = sitting.pair
            switch type {
            case .actual:
                contract = Contract(copying: traveller.contract)
                declarer = traveller.declarer.pair
            case .ourLast:
                if let bid = ourBid {
                    contract = Contract(copying: bid)
                }
            case .higher, .higherDouble:
                if let level = ourLevel, let bid = ourBid {
                    if level <= Values.trickOffset {
                        if type == .higher || bid.double == .undoubled {
                            contract = Contract(copying: bid)
                            contract?.level = ContractLevel(rawValue: level + 1)!
                            if type == .higherDouble {
                                contract?.double = .doubled
                            }
                        }
                    }
                }
            case .game:
                if let level = ourLevel, let bid = ourBid, let gameLevel = ourGameLevel {
                    if level + 1 < gameLevel {
                        contract = Contract(copying: bid)
                        contract?.level = ContractLevel(rawValue: gameLevel)!
                    }
                }
            case .smallSlam:
                if let level = ourLevel, let bid = ourBid {
                    if level + 1 < Values.smallSlamLevel.rawValue {
                        contract = Contract(copying: bid)
                        contract?.level = Values.smallSlamLevel
                    }
                }
            case .grandSlam:
                if let level = ourLevel, let bid = ourBid {
                    if level + 1 < Values.grandSlamLevel.rawValue {
                        contract = Contract(copying: bid)
                        contract?.level = Values.grandSlamLevel
                    }
                }
            case .lower:
                if let level = ourLevel, let bid = ourBid {
                    if weDeclared && level - 1 > 0 {
                        contract = Contract(copying: bid)
                        contract?.level = ContractLevel(rawValue: level - 1)!
                        contract?.double = .undoubled
                    }
                }
            case .oppLast:
                if let bid = theirBid {
                    contract = Contract(copying: bid)
                    declarer = sitting.pair.other
                }
            case .oppHigher, .oppHigherDouble:
                if let level = theirLevel, let bid = theirBid {
                    if level <= Values.trickOffset {
                        if type == .oppHigher || bid.double == .undoubled {
                            contract = Contract(copying: bid)
                            contract?.level = ContractLevel(rawValue: level + 1)!
                            if type == .oppHigherDouble {
                                contract?.double = .doubled
                            }
                            declarer = sitting.pair.other
                        }
                    }
                }
            case .optimum:
                if (board.optimumScore?.contract.level ?? .blank) != .blank {
                    contract = Contract(copying: board.optimumScore!.contract)
                    declarer = board.optimumScore!.declarer
                }
            case .best:
                if let bestTraveller = travellers.last {
                    contract = Contract(copying: bestTraveller.contract)
                    declarer = bestTraveller.declarer.pair
                }
            default:
                break
            }
            if let contract = contract {
                print("\(options.count) \(type.string)")
                options.append(AnalysisOption(type: type, contract: contract, declarer: declarer))
            }
        }
        for (index, option) in options.enumerated() {
            if index > 0 && (options[index - 1].declarer != option.declarer) {
                options[index - 1].separator = true
            }
        }
        buildScores()
    }
    
    func buildScores(){
        let tricksMade = buildTricksMade()
        for option in options {
            var assessment: [Int:AnalysisAssessment] = [:]
            if let allTricksMade = tricksMade[option.declarer]?[option.contract.suit]?.map({$0.value}) {
                let tricksMadeSet = Set(allTricksMade)
                for made in tricksMadeSet {
                    let points = Scorecard.points(contract: option.contract, vulnerability: Vulnerability(board: traveller.boardNumber), declarer: option.declarer.seats.first!, made: made - Values.trickOffset - option.contract.level.rawValue, seat: sitting)
                    assessment[made] = (AnalysisAssessment(tricks: made, points: points, score: 0))
                }
                for method in AnalysisAssessmentMethod.allCases {
                    if let methodTricks = tricksMade[option.declarer]?[option.contract.suit]?[method] {
                        option.assessment[method] = assessment[methodTricks]
                    }
                }
            }
        }
    }
    
    func buildTricksMade() -> [Pair:[Suit:[AnalysisAssessmentMethod:Int]]] {
        var result: [Pair:[Suit:[AnalysisAssessmentMethod:Int]]] = [:]
        for pair in Pair.validCases {
            result[pair] = [:]
            for suit in Suit.validCases {
                result[pair]![suit] = [:]
                let multiplier = (pair == .ns ? 1 : -1)
                let suitTravellers = Scorecard.current.travellers(board: board.boardNumber).filter({ $0.contract.suit == suit && $0.declarer.pair == pair && $0 != traveller }) .sorted(by: { ((($0.contractLevel + $0.made) - ($1.contractLevel + $1.made)) * multiplier) < 0 })
                    // Play
                if suit == traveller.contract.suit {
                    result[pair]![suit]![.play] = Values.trickOffset + traveller.contractLevel + traveller.made
                }
                
                    // Double dummy
                var made: [Int] = []
                for index in 0...1 {
                    made.append(board.doubleDummy[pair.seats[index]]?[suit]?.made ?? -1)
                }
                if made.max() ?? -1 >= 0 {
                    result[pair]![suit]![.doubleDummy] = made.max()
                }
                
                    // Median
                if suitTravellers.count > 0 {
                    let medianTraveller = suitTravellers[(suitTravellers.count) / 2]
                    result[pair]![suit]![.median] = Values.trickOffset + medianTraveller.contractLevel + medianTraveller.made
                }
                
                    //Mode
                let counts = NSCountedSet(array: suitTravellers.map{Values.trickOffset + $0.contractLevel + $0.made})
                if counts.count > 0 {
                    if let maxCount = counts.max(by: { counts.count(for: $0) < counts.count(for: $1)}), let mostFrequent = maxCount as? Int {
                        result[pair]![suit]![.mode] = mostFrequent
                    }
                }
                    // Best
                if let bestTraveller = suitTravellers.last {
                    result[pair]![suit]![.best] = Values.trickOffset + bestTraveller.contractLevel + bestTraveller.made
                }
            }
        }
        return result
    }
}

struct AnalysisTravellerView: View {
    let scorecard = Scorecard.current.scorecard!
    @Binding var board: BoardViewModel
    @Binding var traveller: TravellerViewModel
    @State var handTraveller: TravellerExtension!
    @State var handSummary: TravellerSummary!
    @State var selectedSummary: TravellerSummary?
    @Binding var sitting: Seat
    @State var summaryMode: Bool = true
    @State var travellers: [TravellerExtension] = []
    @State var summary: [TravellerSummary] = []
    let columns = [GridItem(.fixed(50), spacing: 0), GridItem(.flexible(minimum: 90), spacing: 0), GridItem(.fixed(50), spacing: 0), GridItem(.fixed(60), spacing: 0), GridItem(.fixed(70), spacing: 0), GridItem(.fixed(60), spacing: 0), GridItem(.flexible(minimum: 70), spacing: 0)]
    
    var body: some View {
        VStack {
            ZStack {
                VStack {
                    Rectangle().frame(height: 30).foregroundColor(Palette.tile.background)
                    Spacer()
                }
                HStack {
                    Spacer()
                    if summaryMode {
                        VStack {
                            LazyVGrid(columns: columns, spacing: 0) {
                                GridRow {
                                    Text("Freq")
                                    Text("Contract")
                                    Text("By")
                                    Text("Lead")
                                    Text("Made").gridColumnAlignment(.trailing)
                                    TrailingText(sitting.pair.short).gridColumnAlignment(.trailing)
                                    TrailingText("\(sitting.pair.short)\(scorecard.type.boardScoreType.suffix)").gridColumnAlignment(.trailing).frame(width: 80)
                                }
                                .foregroundColor(Palette.tile.text).bold()
                                .frame(height: 25)
                            }
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 3) {
                                    ForEach(summary, id: \.self) { summary in
                                        GridRow {
                                            CenteredText("\(summary.frequency)")
                                            CenteredAttributedText(summary.contractStringPlus)
                                            CenteredText(summary.declarer.short)
                                            CenteredAttributedText(summary.leadStringPlus)
                                            CenteredText(summary.madeString)
                                            TrailingText(summary.pointsString)
                                            TrailingText(summary.scoreString)
                                        }
                                        .frame(height: 25)
                                        .if(handTraveller == summary) { view in
                                            view.background(Palette.handPlayer.background).foregroundColor(Palette.handPlayer.contrastText)
                                        }
                                        .foregroundColor(summary.made >= 0 ? Palette.alternate.text : Palette.alternate.faintText)
                                        .onTapGesture {
                                            selectedSummary = summary
                                            summaryMode.toggle()
                                        }
                                        .onSwipe() { direction in
                                            if direction == .left {
                                                if let newTraveller = travellers.first(where: { $0 == summary }) {
                                                    reflectSelectionChange(traveller: newTraveller)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        VStack {
                            LazyVGrid(columns: columns, spacing: 0) {
                                GridRow {
                                    CenteredText("")
                                    CenteredText("Contract")
                                    CenteredText("By")
                                    CenteredText("Lead")
                                    CenteredText("Made").gridColumnAlignment(.trailing)
                                    TrailingText(sitting.pair.short).gridColumnAlignment(.trailing)
                                    TrailingText("\(sitting.pair.short)\(scorecard.type.boardScoreType.suffix)").gridColumnAlignment(.trailing).frame(width: 80)
                                }
                                .foregroundColor(Palette.tile.text).bold()
                                .frame(height: 25)
                            }
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 3) {
                                    ForEach(travellers.filter({$0 == selectedSummary!}), id: \.self) { traveller in
                                        GridRow {
                                            CenteredText("")
                                            CenteredAttributedText(traveller.contract.colorCompact)
                                            CenteredText(traveller.declarer.short)
                                            CenteredAttributedText(traveller.leadString)
                                            CenteredText(traveller.tricksMadeString)
                                            TrailingText(traveller.pointsString(board: board, sitting: sitting))
                                            TrailingText(traveller.scoreString(sitting: sitting))
                                        }
                                        .frame(height: 25)
                                        .foregroundColor(traveller.made >= 0 ? Palette.alternate.text : Palette.alternate.faintText)
                                        .if(traveller.rankingNumber == handTraveller.rankingNumber) { view in
                                            view.background(Palette.handPlayer.background).foregroundColor(Palette.handPlayer.contrastText)
                                        }
                                        .onTapGesture {
                                            summaryMode.toggle()
                                        }
                                        .onSwipe() { direction in
                                            if direction == .left {
                                                reflectSelectionChange(traveller: traveller)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .onTapGesture {
                            summaryMode = true
                        }
                    }
                    Spacer()
                }
            }
            Spacer().frame(height: 4)
        }
        .onAppear() {
            reflectChange()
        }
        .onChange(of: board.boardNumber) { boardNumber in
            reflectChange()
        }
        .frame(width: 520, height: 200)
        .background(Palette.alternate.background)
        .foregroundColor(Palette.alternate.text)
        .font(.body)
        .cornerRadius(16)
    }
    
    func reflectChange() {
        travellers = buildTravellers(board: self.board, sitting: self.sitting)
        summary = buildSummary()
        handTraveller = TravellerExtension(scorecard: scorecard, traveller: traveller)
        reflectSelectionChange(traveller: handTraveller)
    }
    
    func reflectSelectionChange(traveller: TravellerExtension) {
        handTraveller = traveller
        self.traveller = traveller
        handSummary = summary.first(where: {traveller == $0})
    }
    
    func buildTravellers(board: BoardViewModel, sitting: Seat) -> [TravellerExtension] {
        var result: [TravellerExtension] = []
        for traveller in Scorecard.current.travellers(board: board.boardNumber) {
            result.append(TravellerExtension(scorecard: scorecard, traveller: traveller))
        }
        return result.sorted(by: {TravellerExtension.sort($0, $1, sitting: sitting)})
    }
    
    func buildSummary() -> [TravellerSummary] {
        var result: [TravellerSummary] = []
        for traveller in self.travellers {
            let summary = TravellerSummary(board: board, traveller: traveller, sitting: sitting)
            if let existing = result.first(where: {$0 == summary}) {
                existing.frequency += 1
                if !existing.levelRange && existing.contract.level != summary.contract.level {
                    existing.levelRange = true
                    existing.contract.level = ContractLevel(rawValue: min(existing.contract.level.rawValue, summary.contract.level.rawValue))!
                }
                if !existing.leadRange && existing.lead != summary.lead {
                    existing.leadRange = true
                }
            } else {
                result.append(summary)
            }
        }
        return result
    }
}

class TravellerSummary: Equatable, Identifiable, Hashable {
    var contract: Contract
    var declarer: Seat
    var lead: String
    var made: Int
    var tricksMade: Int
    var nsPoints: Int
    var nsScore: Float
    var levelRange: Bool
    var leadRange: Bool
    var frequency: Int
    fileprivate var outcomeLevel: OutcomeLevel
    var leadString: AttributedString
    var madeString: String
    var pointsString: String
    var scoreString: String
    
    init(board: BoardViewModel, traveller: TravellerExtension, sitting: Seat) {
        self.contract = Contract(copying: traveller.contract)
        self.declarer = traveller.declarer
        self.lead = traveller.lead
        self.made = traveller.made
        self.tricksMade = Values.trickOffset + contract.level.rawValue + traveller.made
        self.nsPoints = Scorecard.points(contract: traveller.contract, vulnerability: Vulnerability(board: traveller.boardNumber), declarer: traveller.declarer, made: traveller.made, seat: .north)
        self.nsScore = traveller.nsScore
        self.frequency = 1
        self.levelRange = false
        self.leadRange = false
        self.outcomeLevel = traveller.outcomeLevel
        self.madeString = traveller.tricksMadeString
        self.leadString = traveller.leadString
        self.pointsString = traveller.pointsString(board: board, sitting: sitting)
        self.scoreString = traveller.scoreString(sitting: sitting)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(contract.suit)
        hasher.combine(contract.double)
        hasher.combine(declarer)
        hasher.combine(made)
        hasher.combine(nsPoints)
        hasher.combine(outcomeLevel)
    }
    
    public var contractStringPlus: AttributedString {
        if levelRange {
            return AttributedString(contract.level.string) + contract.suit.colorString + AttributedString(contract.double.short + (levelRange ? "+" : ""))
        } else {
            return contract.colorCompact
        }
    }
    
    public var leadStringPlus: AttributedString {
        leadString + AttributedString(leadRange ? "+" : "")
    }
    
    static func == (lhs: TravellerSummary, rhs: TravellerSummary) -> Bool {
        return lhs.contract.suit == rhs.contract.suit && lhs.contract.double == rhs.contract.double && lhs.declarer == rhs.declarer && lhs.tricksMade == rhs.tricksMade && lhs.outcomeLevel == rhs.outcomeLevel && lhs.nsPoints == rhs.nsPoints
    }
}

class TravellerExtension: TravellerViewModel {
    var nsPoints: Int = 0
    
    init() {
        super.init(scorecard: Scorecard.current.scorecard!, board: 0, section: [:], ranking: [:])
    }
    
    init(scorecard: ScorecardViewModel, traveller: TravellerViewModel) {
        super.init(scorecard: scorecard, board: traveller.board, section: traveller.section, ranking: traveller.rankingNumber)
        self.travellerMO = traveller.travellerMO
        self.revert()
        self.nsPoints = Scorecard.points(contract: traveller.contract, vulnerability: Vulnerability(board: traveller.boardNumber), declarer: traveller.declarer, made: traveller.made, seat: .north)
    }
    
    fileprivate var outcomeLevel: OutcomeLevel {
        var level: OutcomeLevel
        if made < 0 {
            level = .penalty
        } else if contract.level == .six {
            level = .smallSlam
        } else if contract.level == .seven {
            level = .grandSlam
        } else if Scorecard.madePoints(contract: contract) >= 100 {
            level = .game
        } else {
            level = .partScore
        }
        return level
    }
    
    static func == (lhs: TravellerExtension, rhs: TravellerSummary) -> Bool {
        return lhs.contract.suit == rhs.contract.suit && lhs.contract.double == rhs.contract.double && lhs.declarer == rhs.declarer && lhs.tricksMade == rhs.tricksMade && lhs.outcomeLevel == rhs.outcomeLevel && lhs.nsPoints == rhs.nsPoints
    }
    
    var leadString: AttributedString {
        let suitString = lead.right(1)
        let suit = Suit(string: suitString)
        let card = lead == "" ? "" : (lead.left(lead.count - 1) + suit.string)
        return AttributedString(card, color: suit.color)
    }
    
    public var tricksMadeString: String {
        return passout ? "" : "\(tricksMade)"
    }
    
    var tricksMade: Int {
        return (passout ? 0 : Values.trickOffset + contract.level.rawValue + made)
    }
    
    var passout: Bool {
        return (contract.level == .passout)
    }
    
    func pointsString(board: BoardViewModel, sitting: Seat) -> String {
        let passout = (contract.level == .passout)
        let sign = (sitting.pair == .ns ? 1 : -1)
        return (passout ? "0" : String(format: "%+d",sign * Scorecard.points(contract: contract, vulnerability: Vulnerability(board: boardNumber), declarer: declarer, made: made, seat: .north)))
    }
    
    func scoreString(sitting: Seat) -> String {
        let score = scorecard.type.invertScore(score: nsScore, pair: sitting.pair)
        return "\(scorecard.type.boardScoreType.prefix(score: score))\(score.toString(places: scorecard.type.boardPlaces))"
    }
    
    static func sort(_ first: TravellerExtension, _ second: TravellerExtension, sitting: Seat) -> Bool {
        let multiplier = sitting.pair == .ns ? 1 : -1
        if (second.nsScore - first.nsScore) * Float(multiplier) < 0 {
            return true
        } else if second.nsScore == first.nsScore {
            if (second.nsPoints - first.nsPoints) * multiplier < 0 {
                return true
            } else if second.nsPoints == first.nsPoints {
                if (second.contract.level.rawValue - first.contract.level.rawValue) < 0 {
                    return true
                } else if second.contract.level.rawValue == first.contract.level.rawValue {
                    if (second.contract.suit.rawValue - first.contract.suit.rawValue) <= 0 {
                        return true
                    } else {
                        return false
                    }
                } else {
                    return false
                }
            } else {
                return false
            }
        } else {
            return false
        }
    }
}

struct LeadingAttributedText: View {
    @State var text: AttributedString
    
    init(_ text: AttributedString) {
        _text = State(initialValue: text)
    }
    
    var body: some View {
        HStack {
            Spacer().frame(width: 2)
            Text(text)
            Spacer()
        }
    }
}

struct LeadingText: View {
    @State var text: String
    
    init(_ text: String) {
        _text = State(initialValue: text)
    }
    
    var body: some View {
        HStack {
            Spacer().frame(width: 2)
            Text(text)
            Spacer()
        }
    }
}

struct CenteredAttributedText: View {
    @State var text: AttributedString
    
    init(_ text: AttributedString) {
        _text = State(initialValue: text)
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text(text)
            Spacer()
        }
    }
}

struct CenteredText: View {
    @State var text: String
    
    init(_ text: String) {
        _text = State(initialValue: text)
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text(text)
            Spacer()
        }
    }
}

struct TrailingText: View {
    @State var text: String
    
    init(_ text: String) {
        _text = State(initialValue: text)
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text(text)
            Spacer().frame(width: 2)
        }
    }
}

struct TrailingAttributedText: View {
    @State var text: AttributedString
    
    init(_ text: AttributedString) {
        _text = State(initialValue: text)
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text(text)
            Spacer().frame(width: 2)
        }
    }
}

fileprivate enum OutcomeLevel {
    case grandSlam
    case smallSlam
    case game
    case partScore
    case penalty
}

enum AnalysisOptionType : Int, CaseIterable, Hashable {
    case actual = 0
    case ourLast = 1
    case higher = 2
    case higherDouble = 3
    case game = 4
    case smallSlam = 5
    case grandSlam = 6
    case lower = 7
    case oppLast = 8
    case oppHigher = 9
    case oppHigherDouble = 10
    case median = 11
    case mode = 12
    case best = 13
    case optimum = 14
    
    var string: String {
        return "\(self)".replacingOccurrences(of: "Double", with: "*").splitCapitals
    }
    
    static var declaringCases: [AnalysisOptionType] = [.lower, .actual, .higher, .higherDouble, .game, .smallSlam, .grandSlam, .oppHigher, .oppHigherDouble, .oppLast, .median, .mode, .best, .optimum]
    
    static var defendingCases: [AnalysisOptionType] = [.actual, .oppHigher, oppHigherDouble, .ourLast, .higher, .higherDouble, .game, .smallSlam, .grandSlam, .lower, .median, .mode, .best, .optimum]
    
}

enum AnalysisAssessmentMethod : Int, CaseIterable, Hashable {
    case play = 0
    case median = 1
    case mode = 2
    case best = 3
    case doubleDummy = 4
    
    var string: String {
        return "\(self).splitCapitals"
    }
    
    var short: String {
        switch self {
        case .doubleDummy:
            return "DD"
        case .median:
            return "Med"
        default:
            return "\(self)".capitalized
        }
    }
}

class AnalysisAssessment : Hashable {
    var tricks: Int
    var points: Int
    var score: Float
    
    init(tricks: Int, points: Int, score: Float) {
        self.tricks = tricks
        self.points = points
        self.score = score
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(tricks)
        hasher.combine(points)
        hasher.combine(score)
    }
    
    static func == (lhs: AnalysisAssessment, rhs: AnalysisAssessment) -> Bool {
        return (lhs.tricks == rhs.tricks && lhs.points == rhs.points && lhs.score == rhs.score)
    }
}

class AnalysisOption : Identifiable, Equatable {
    public var id: UUID = UUID()
    public var type: AnalysisOptionType
    public var contract: Contract
    public var declarer: Pair
    public var assessment: [AnalysisAssessmentMethod:AnalysisAssessment] = [:]
    public var separator = false
    
    init(type: AnalysisOptionType, contract: Contract, declarer: Pair) {
        self.type = type
        self.contract = contract
        self.declarer = declarer
    }
    
    public static func == (lhs: AnalysisOption, rhs: AnalysisOption) -> Bool {
        return lhs.type == rhs.type
    }
}
