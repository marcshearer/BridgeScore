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
    @State var initialTraveller: TravellerViewModel
    @State var sitting: Seat
    @State var from: UIView
    @State var bidAnnounce = ""
    @State var summaryMode = true
    
    init(board: BoardViewModel, traveller: TravellerViewModel, sitting: Seat, from: UIView) {
        self.board = board
        self.traveller = traveller
        self.initialTraveller = traveller
        self.sitting = sitting
        self.from = from
    }
    
    var body: some View {
        HStack {
            VStack {
                Spacer().frame(height: 15)
                VStack {
                    Spacer()
                    HStack {
                        Spacer().frame(width: 50)
                        Text("Board \(board.boardNumber) \(traveller.rankingNumber == initialTraveller.rankingNumber ? "v \(board.table?.versus ?? "Unknown")" : "  -  Viewing Other Traveller")")
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
                        ButtonBar(board: $board, traveller: $traveller, initialTraveller: $initialTraveller, sitting: $sitting, bidAnnounce: $bidAnnounce, summaryMode: $summaryMode)
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
                        HandViewer(board: $board, traveller: $traveller, sitting: $sitting, from: from, bidAnnounce: $bidAnnounce)
                            .cornerRadius(16)
                        Spacer().frame(width: 10)
                        VStack {
                            AnalysisBiddingOptions(board: $board, traveller: $traveller, sitting: $sitting)
                            Spacer()
                            AnalysisCommentView(board: $board)
                            AnalysisTravellerView(board: $board, traveller: $traveller, sitting: $sitting, summaryMode: $summaryMode)
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
        .onSwipe() { direction in
            if let (newBoard, newTraveller) = Scorecard.getBoardTraveller(boardNumber: board.boardNumber + (direction == .left ? 1 : -1)) {
                board = newBoard
                traveller = newTraveller
                initialTraveller = newTraveller
                sitting = newBoard.table!.sitting
                bidAnnounce = ""
                summaryMode = true
            }
        }
    }
    
    struct ButtonBar: View{
        @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
        let scorecard = Scorecard.current.scorecard!
        @Binding var board: BoardViewModel
        @Binding var traveller: TravellerViewModel
        @Binding var initialTraveller: TravellerViewModel
        @Binding var sitting: Seat
        @Binding var bidAnnounce: String
        @Binding var summaryMode: Bool
        
        var body: some View {
            HStack {
                Button {
                    if let (newBoard, newTraveller) = Scorecard.getBoardTraveller(boardNumber: board.boardNumber - 1) {
                        board = newBoard
                        traveller = newTraveller
                        initialTraveller = newTraveller
                        sitting = newBoard.table!.sitting
                        bidAnnounce = ""
                        summaryMode = true
                    }
                } label: {
                    Image(systemName: "backward.frame")
                }.disabled(board.boardNumber <= 1).foregroundColor(Palette.banner.text.opacity(board.boardNumber <= 1 ? 0.5 : 1))
                Spacer().frame(width: 20)
                Button {
                    if let (newBoard, newTraveller) = Scorecard.getBoardTraveller(boardNumber: board.boardNumber + 1) {
                        board = newBoard
                        traveller = newTraveller
                        initialTraveller = newTraveller
                        sitting = newBoard.table!.sitting
                        bidAnnounce = ""
                        summaryMode = true
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
                                TrailingText(method.short)
                            }
                        }
                    }
                    .frame(height: 30)
                    .foregroundColor(Palette.tile.text)
                    .font(smallFont)
                    .bold()
                    ScrollView {
                            // TODO These are wrong way round - should be grid above for
                        ForEach(options) { option in
                            if !option.removed {
                                LazyVGrid(columns: columns, spacing: 0) {
                                    GridRow {
                                        let type = option.displayType
                                        let doubleString = (type.double ? AnalysisOptionType.doubleString(option.linked?.displayType) : nil)
                                        LeadingText(doubleString ?? type.string)
                                        LeadingAttributedText(option.contract.colorCompact)
                                        LeadingText(option.declarer.short)
                                        ForEach(AnalysisAssessmentMethod.allCases, id: \.self) { method in
                                            let methodPoints = option.assessment[method]?.points
                                            TrailingText(methodPoints == nil ? "" : "\(methodPoints!)")
                                        }
                                    }
                                    .foregroundColor(option.removed ? Palette.background.strongText : Palette.background.text)
                                    .frame(height: 20)
                                    .if(option.separator) { view in
                                        view.overlay(Separator(thickness: 2, color: Palette.tile.background), alignment: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
            Spacer()
        }
        .frame(width: 520, height: 250)
        .background(Palette.background.background).cornerRadius(16)
        .font(smallFont)
        .onAppear {
            buildOptions()
        }
        .onChange(of: traveller) { traveller in
            buildOptions()
        }
    }
    
    func buildOptions() {
        options = [] // TODO Need options just to be an array
        
        let contracts = traveller.contracts
        let declarer = traveller.declarer.pair
        let weDeclared = (declarer == sitting.pair)
        
        // Find last bid by defenders
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
        let theirBid = (weDeclared ? previousBid : traveller.contract)
        
        let multiplier: Float = (sitting.pair == .ns ? 1 : -1)
        let travellers = Scorecard.current.travellers(board: board.boardNumber).sorted(by: { (($0.nsScore - $1.nsScore) * multiplier) < 0 })
        
        let types = (weDeclared ? AnalysisOptionType.declaringCases : AnalysisOptionType.defendingCases)
        for type in types {
            var contract: [Contract] = []
            var declarer = sitting.pair
            var decisionBy: Pair?
            
            // Generic options
            switch type {
            case .actual:
                contract = [Contract(copying: traveller.contract)]
                declarer = traveller.declarer.pair
            case .optimum:
                if (board.optimumScore?.contract.level ?? .blank) != .blank {
                    contract = [Contract(copying: board.optimumScore!.contract)]
                    declarer = board.optimumScore!.declarer
                }
            case .best:
                if let bestTraveller = travellers.last {
                    contract = [Contract(copying: bestTraveller.contract)]
                    declarer = bestTraveller.declarer.pair
                }
            default:
                break
            }
            
            if weDeclared {
                    // Options if we declared
                switch type {
                case .stopLower:
                        // Stop in a lower contract below game
                    if let ourBid = ourBid {
                        if ourBid.level.rawValue > 1 {
                            for level in 1..<ourBid.level.rawValue {
                                let tryBid = Contract(copying: ourBid)
                                tryBid.level = ContractLevel(rawValue: level)!
                                if theirBid == nil || tryBid > theirBid! {
                                    contract.append(tryBid)
                                    declarer = sitting.pair
                                }
                            }
                        }
                    }
                case .otherSuit, .median, .mode:
                        // TODO
                    break
                default:
                    break
                }
            } else {
                // Options if they declared
                switch type {
                case .bidOver:
                        // Bid on below game level
                    if let ourSuit = ourSuit, let ourGameLevel = ourGameLevel, let theirBid = theirBid {
                        if let bidOver = Contract.init(higher: theirBid, suit: ourSuit) {
                            if bidOver.level.rawValue < ourGameLevel {
                                contract.append(bidOver)
                                declarer = sitting.pair
                            }
                        }
                    }
                default:
                    break
                }
            }
            
            // Options if bidding or declaring
            switch type {
            case .pass:
                // Pass their last bid
                if let theirBid = theirBid {
                    if weDeclared || theirBid.double == .doubled {
                        contract = [Contract(copying: theirBid)]
                        contract.last!.double = .undoubled
                        declarer = sitting.pair.other
                        decisionBy = sitting.pair
                    }
                }
            case .double:
                // Double their last bid
                if let theirBid = theirBid {
                    if theirBid.double == .undoubled {
                        contract = [Contract(copying: theirBid)]
                        contract.first!.double = .doubled
                        declarer = sitting.pair.other
                        decisionBy = sitting.pair
                    }
                }
            case .upToGame:
                    // Bid on to game level
                if let ourBid = ourBid, let ourGameLevel = ourGameLevel {
                    if ourBid.level.rawValue < ourGameLevel {
                        for level in ourBid.level.rawValue+1...ourGameLevel {
                            contract.append(Contract(copying: ourBid))
                            contract.last!.level = ContractLevel(rawValue: level)!
                            declarer = sitting.pair
                        }
                    }
                }
            case .upToSlam:
                    // Bid on to small slam level
                if let ourBid = ourBid {
                    if ourBid.level < Values.smallSlamLevel {
                        contract.append(Contract(copying: ourBid))
                        contract.last!.level = Values.smallSlamLevel
                        declarer = sitting.pair
                    }
                }
            case .upToGrand:
                    // Bid on to grand slam level
                if let ourBid = ourBid {
                    if ourBid.level < Values.grandSlamLevel {
                        contract.append(Contract(copying: ourBid))
                        contract.last!.level = Values.grandSlamLevel
                        declarer = sitting.pair
                    }
                }
            default:
                break
            }

            if !contract.isEmpty {
                let decisionBy = decisionBy ?? declarer
                for contract in contract {
                    let option = AnalysisOption(type: type, contract: contract, declarer: declarer, decisionBy: decisionBy)
                    options.append(option)
                    
                    if !weDeclared && declarer == sitting.pair {
                        // Add linked options for opps doubling or overbidding and us them doubling them
                        let doubleUs = Contract(copying: contract)
                        doubleUs.double = .doubled
                        options.append(AnalysisOption(type: .double, contract: doubleUs, declarer: declarer, decisionBy: declarer.other, linked: option))
                        
                        if let bidOver = Contract(higher: contract, suit: theirBid!.suit) {
                            let bidOverOption = AnalysisOption(type: .bidOver, contract: bidOver, declarer: declarer.other, decisionBy: declarer.other, linked: option)
                            options.append(bidOverOption)
                            
                            let doubleThem = Contract(copying: bidOver)
                            doubleThem.double = .doubled
                            options.append(AnalysisOption(type: .bidOverDouble, contract: doubleThem, declarer: declarer.other, decisionBy: declarer, linked: bidOverOption))
                        }
                    }
                }
            }
        }
                
        buildScores()
        removeBadOptions()
        // Set separators
        var lastOption: AnalysisOption?
        for option in options {
            if !option.removed {
                if lastOption != nil && (lastOption?.declarer != option.declarer) {
                    lastOption?.separator = true
                }
                lastOption = option
            }
        }
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
    
    func removeBadOptions () {
        if options.count >= 2 {
            for optionIndex in 1..<options.count {
                let option = options[optionIndex]
                for compareIndex in 0..<optionIndex {
                    let compare = options[compareIndex]
                    if AnalysisOption.equalOrWorsePoints(option, compare, invert: invert(option)) {
                        option.removed = true
                    }
                }
            }
            
            // Remove linking options if no longer in play
            for option in options {
                if let linked = option.linked {
                    if linked.removed {
                        option.removed = true
                    }
                }
            }
            
            // Now consider removing original linked double if worse than double
            for option in options {
                if option.type.double && !option.removed {
                    if let linked = option.linked {
                        if !linked.removed {
                            if AnalysisOption.equalOrWorsePoints(linked, option, invert: invert(option)) {
                                linked.removed = true
                            }
                        }
                    }
                }
            }
        }
        
        func invert(_ option: AnalysisOption) -> Bool {
            var invert = option.declarer != sitting.pair
            if option.decisionBy != option.declarer {
                invert.toggle()
            }
            return invert
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

struct AnalysisCommentView: View {
    @Binding var board: BoardViewModel
    
    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .foregroundColor(Palette.background.background)
                    .cornerRadius(16)
                VStack {
                    Spacer().frame(height: 6)
                    HStack {
                        Spacer().frame(width: 6)
                        TextField("", text: $board.comment)
                            .padding(.all, 2)
                            .foregroundColor(Palette.background.text)
                        Spacer().frame(width: 6)
                    }
                    Spacer().frame(height: 6)
                }
                .cornerRadius(16)
                .keyboardAdaptive
            }
            .frame(width: 520, height: 80)
            .font(defaultFont)
        }
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
    @Binding var summaryMode: Bool
    @State var travellers: [TravellerExtension] = []
    @State var summary: [TravellerSummary] = []
    let columns = [GridItem(.fixed(50), spacing: 0), GridItem(.fixed(50), spacing: 0), GridItem(.flexible(minimum: 90), spacing: 0), GridItem(.fixed(50), spacing: 0), GridItem(.fixed(60), spacing: 0), GridItem(.fixed(70), spacing: 0), GridItem(.fixed(55), spacing: 0), GridItem(.flexible(minimum: 70), spacing: 0)]
    
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
                                    LeadingText("")
                                    CenteredText("Frq")
                                    CenteredText("Contract")
                                    CenteredText("By")
                                    CenteredText("Lead")
                                    CenteredText("Made")
                                    TrailingText(sitting.pair.short)
                                    TrailingText("\(sitting.pair.short)\(scorecard.type.boardScoreType.suffix)")
                                }
                                .foregroundColor(Palette.tile.text).bold()
                                .frame(height: 25)
                            }
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 3) {
                                    ForEach(summary, id: \.self) { summary in
                                        GridRow {
                                            if !(handTraveller == summary) {
                                                Image(systemName: "arrow.up.left")
                                                    .background(Palette.background.background)
                                                    .foregroundColor(Palette.background.text)
                                                    .onTapGesture {
                                                        if let newTraveller = travellers.first(where: { $0 == summary }) {
                                                            reflectSelectionChange(traveller: newTraveller)
                                                        }
                                                    }
                                            } else {
                                                CenteredText("")
                                            }
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
                                        .foregroundColor(summary.made >= 0 ? Palette.background.text : Palette.background.faintText)
                                        .onTapGesture {
                                            selectedSummary = summary
                                            summaryMode.toggle()
                                        }
                                        .onSwipe() { direction in
                                            
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        VStack {
                            LazyVGrid(columns: columns, spacing: 0) {
                                GridRow {
                                    LeadingText("")
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
                                            if traveller.rankingNumber != handTraveller.rankingNumber {
                                                Image(systemName: "arrow.up.left")
                                                    .background(Palette.background.background)
                                                    .foregroundColor(Palette.background.text)
                                                    .onTapGesture {
                                                        reflectSelectionChange(traveller: traveller)
                                                    }
                                            } else {
                                                CenteredText("")
                                            }
                                            CenteredText("")
                                            CenteredAttributedText(traveller.contract.colorCompact)
                                            CenteredText(traveller.declarer.short)
                                            CenteredAttributedText(traveller.leadString)
                                            CenteredText(traveller.tricksMadeString)
                                            TrailingText(traveller.pointsString(board: board, sitting: sitting))
                                            TrailingText(traveller.scoreString(sitting: sitting))
                                        }
                                        .frame(height: 25)
                                        .foregroundColor(traveller.made >= 0 ? Palette.background.text : Palette.background.faintText)
                                        .if(traveller.rankingNumber == handTraveller.rankingNumber) { view in
                                            view.background(Palette.handPlayer.background).foregroundColor(Palette.handPlayer.contrastText)
                                        }
                                        .onTapGesture {
                                            summaryMode.toggle()
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
        .background(Palette.background.background)
        .foregroundColor(Palette.background.text)
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
    case pass = 1
    case double = 2
    case stopLower = 3
    case otherSuit = 4
    case bidOver = 5
    case bidOverDouble = 6
    case upToGame = 7
    case upToSlam = 8
    case upToGrand = 9
    case median = 10
    case mode = 11
    case best = 12
    case optimum = 13
    
    var string: String {
        return "\(self)".replacingOccurrences(of: "Double", with: "*").splitCapitals
    }
    
    var upToTypes: [AnalysisOptionType] {
        return [.upToGame, .upToSlam, .upToGrand]
    }
    
    var notMakingType: AnalysisOptionType {
        return (upToTypes.contains(self) ? .bidOver : self)
    }
    
    static func doubleString(_ type: AnalysisOptionType?) -> String? {
        return type == nil ? nil : "\(type!.string)*"
    }
    
    static var declaringCases: [AnalysisOptionType] = [.actual, .pass, .double, .stopLower, .otherSuit, .upToGame, .upToSlam, .upToGrand, .median, .mode, .best, .optimum]
    
    static var defendingCases: [AnalysisOptionType] = [.actual, .pass, .double, .bidOver, .upToGame, .upToSlam,. upToGrand, .median, .mode, .best, .optimum]
    
    var double: Bool {
        return self == .double || self == .bidOverDouble
    }
    
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

class AnalysisOption : Identifiable {
    public var id: UUID = UUID()
    public var type: AnalysisOptionType
    public var contract: Contract
    public var declarer: Pair
    public var decisionBy: Pair
    public var removed = false
    public var assessment: [AnalysisAssessmentMethod:AnalysisAssessment] = [:]
    public var separator = false
    public var linked: AnalysisOption?
    
    init(type: AnalysisOptionType, contract: Contract, declarer: Pair, decisionBy: Pair, linked: AnalysisOption? = nil) {
        self.type = type
        self.contract = contract
        self.declarer = declarer
        self.decisionBy = decisionBy
        self.linked = linked
    }
    
    public static func == (lhs: AnalysisOption, rhs: AnalysisOption) -> Bool {
        return lhs.id == rhs.id
    }
    
    public var displayType : AnalysisOptionType {
        var allNotMaking = true
        for (_, assess) in assessment {
            if assess.tricks >= Values.trickOffset + contract.level.rawValue {
                allNotMaking = false
            }
        }
        return allNotMaking ? type.notMakingType : type
    }
    
    public static func equalOrWorsePoints(_ lhs: AnalysisOption, _ rhs: AnalysisOption, invert: Bool = false) -> Bool{
        var result = true
        for (index, lhsValue) in lhs.assessment {
            if let rhsValue = rhs.assessment[index] {
                if (lhsValue.points - rhsValue.points) * (invert ? -1 : 1) > 0 {
                    result = false
                    break
                }
            }
        }
        return result
    }
}
