//
//  Analysis Viewer.swift
//  BridgeScore
//
//  Created by Marc Shearer on 08/09/2023.
//

import SwiftUI
import UIKit
import Combine

fileprivate enum OutcomeLevel {
    case passout
    case grandSlam
    case smallSlam
    case game
    case partScore
    case penalty
}

class AnalysisData : ObservableObject {
    @Published var madeValues: [AnalysisTrickCombination:(method: AnalysisAssessmentMethod, default: Int, override: Int?)] = [:]
    @Published var options: [AnalysisOption] = []
    @Published var otherOptions: [AnalysisOption] = []
    @Published var combinations: [AnalysisTrickCombination] = []
}

struct AnalysisViewer: View {
    let scorecard = Scorecard.current.scorecard!
    @State var board: BoardViewModel
    @State var traveller: TravellerViewModel
    @State var handTraveller: TravellerViewModel
    @State var initialSitting: Seat
    @State var sitting: Seat
    @State var rotated: Int = 0
    @State var from: UIView
    @StateObject var analysisData = AnalysisData()
    @State var bidAnnounce = ""
    @State var summaryMode = true
    @State var focused = false
    @State var stopEdit = false
    @State var formatInt: Int
    
    init(board: BoardViewModel, traveller: TravellerViewModel, sitting: Seat, from: UIView) {
        self.board = board
        self.traveller = traveller
        self.handTraveller = traveller
        self.initialSitting = sitting
        self.sitting = sitting
        self.from = from
        _formatInt = State(initialValue: UserDefault.analysisOptionFormat.int)
    }
    
    var body: some View {
        HStack {
            VStack {
                Spacer().frame(height: 15)
                AnalysisBanner(nextTraveller: nextTraveller, updateOptions: updateAnalysis, board: $board, traveller: $traveller, handTraveller: $handTraveller, sitting: $sitting, rotated: $rotated, initialSitting: $initialSitting, bidAnnounce: $bidAnnounce, summaryMode: $summaryMode)
                VStack {
                    Spacer().frame(height: 10)
                    HStack {
                        HandViewer(board: $board, traveller: $handTraveller, sitting: $sitting, rotated: $rotated, from: from, bidAnnounce: $bidAnnounce, stopEdit: $stopEdit)
                            .cornerRadius(16)
                        Spacer().frame(width: 10)
                        VStack {
                            AnalysisCommentView(board: $board, stopEdit: $stopEdit)
                            AnalysisTricksMade(board: $board, traveller: $traveller, sitting: $sitting, analysisData: analysisData, stopEdit: $stopEdit)
                            AnalysisBiddingOptions(board: $board, traveller: $traveller, sitting: $sitting, stopEdit: $stopEdit, analysisData: analysisData, formatInt: $formatInt)
                            AnalysisActionView(board: $board, sitting: $sitting, formatInt: $formatInt, stopEdit: $stopEdit, analysisData: analysisData)
                            Spacer()
                            AnalysisTravellerView(board: $board, traveller: $handTraveller, sitting: $sitting, summaryMode: $summaryMode, stopEdit: $stopEdit)
                        }
                    }
                }
                Spacer().frame(height: 15)
            }
        }
        .background(.clear)
        .onChange(of: board.board, initial: true) {
            updateAnalysis()
        }
        .onSwipe() { direction in
            nextTraveller(direction == .left ? 1 : -1)
        }
        .onReceive(publisher) { (_, _, _) in // TODO remove publisher
            let analysis = Scorecard.current.analysis(board: board, traveller: traveller, sitting: sitting)
            analysis.refreshOptions()
            if let (_, made) = analysis.tricksMade[AnalysisTrickCombination(board: board.board, suit: Suit(string: "C"), declarer: .ew)] {
                print(made[AnalysisAssessmentMethod.override] ?? -1)
            }
            updateAnalysis()
        }
        .ignoresSafeArea(.keyboard)
    }
    
    struct AnalysisBanner : View {
        @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
        let scorecard = Scorecard.current.scorecard!
        @State var nextTraveller: (Int)->()
        @State var updateOptions: ()->()
        @Binding var board: BoardViewModel
        @Binding var traveller: TravellerViewModel
        @Binding var handTraveller: TravellerViewModel
        @Binding var sitting: Seat
        @Binding var rotated: Int
        @Binding var initialSitting: Seat
        @Binding var bidAnnounce: String
        @Binding var summaryMode: Bool
        
        var body : some View {
            VStack {
                Spacer()
                HStack {
                    Spacer().frame(width: 50)
                    Button {
                        save()
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    Spacer().frame(width: 20)
                    Text("Board \(board.boardNumber)")
                    if traveller.rankingNumber == handTraveller.rankingNumber {
                        Text(" v \(versus)").minimumScaleFactor(0.5)
                    } else {
                        Text(" - Other table ")
                        Button {
                            handTraveller = traveller
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "chevron.backward.2")
                                Text(" Back")
                                Spacer()
                            }
                            .frame(width: 160, height: 40)
                            .palette(.bannerButton)
                            .cornerRadius(8)
                        }
                    }
                    Spacer()
                    VStack {
                        HStack {
                            Spacer().frame(width: 20)
                            let score = sitting.pair == .ns ? traveller.nsScore : scorecard.type.invertScore(score: traveller.nsScore)
                            let places = scorecard.type.boardPlaces
                            Text("\(scorecard.type.boardScoreType.prefix(score: score))\(score.toString(places: places))\(scorecard.type.boardScoreType.suffix)")
                            Spacer().frame(width: 20)
                        }
                        .minimumScaleFactor(0.5)
                        .frame(width: (scorecard.type.players == 4 ? 150 : 230), height: 50)
                        .palette(.bannerShadow)
                        .cornerRadius(16)
                        .opacity(0.7)
                    }
                    Spacer().frame(width: 50)
                    ButtonBar(nextTraveller: nextTraveller, otherTable: otherTable, save: save, board: $board, traveller: $handTraveller, sitting: $sitting, initialSitting: initialSitting, bidAnnounce: $bidAnnounce, summaryMode: $summaryMode)
                    Spacer().frame(width: 20)
                }.font(bannerFont).foregroundColor(Palette.banner.text)
                Spacer()
            }
            .background(Palette.banner.background)
            .frame(height: 80)
            .cornerRadius(16)
        }
        
        func save() {
            if let board = Scorecard.current.boards[board.board] {
                if board.changed {
                    Scorecard.current.save(board: board)
                }
            }
        }
        
        func otherTable() {
            if let rankingNumber = traveller.rankingNumber[sitting] {
                let newSitting = (sitting == initialSitting ? sitting.equivalent : initialSitting)
                if let newTraveller = Scorecard.current.travellers(board: board.board, seat: newSitting, rankingNumber: rankingNumber).first {
                    sitting = newSitting
                    traveller = newTraveller
                    handTraveller = traveller
                    rotated = sitting.offset(to: initialSitting)
                }
                updateOptions()
            }
        }
        
        var versus: String {
            var versus = ""
            for seat in sitting.versus {
                if let ranking = traveller.ranking(seat: seat) {
                    var name = (ranking.players[seat] ?? "Unknown")
                    if Scorecard.current.scorecard?.importSource == .bbo {
                        if let realName = MasterData.shared.realName(bboName: name) {
                            name = realName
                        }
                    }
                    if versus != "" {
                        versus += " & "
                    }
                    versus += name
                }
            }
            return versus
        }
    }
    
    func nextTraveller(_ direction: Int) {
        let boards = Scorecard.current.boards.count
        var boardNumber = board.board
        repeat {
            boardNumber += direction
            if let (newBoard, newTraveller, newSitting) = Scorecard.getBoardTraveller(boardNumber: boardNumber, equivalentSeat: (sitting != initialSitting)) {
                initialSitting = newBoard.table!.sitting
                sitting =  newSitting
                rotated = sitting.offset(to: initialSitting)
                board = newBoard
                traveller = newTraveller
                handTraveller = newTraveller
                bidAnnounce = ""
                summaryMode = true
                break
            }
        } while boardNumber > 1 && boardNumber < boards
    }
    
    struct ButtonBar: View{
        @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
        let scorecard = Scorecard.current.scorecard!
        @State var nextTraveller: (Int)->()
        @State var otherTable: ()->()
        @State var save: ()->()
        @Binding var board: BoardViewModel
        @Binding var traveller: TravellerViewModel
        @Binding var sitting: Seat
        @State var initialSitting: Seat
        @Binding var bidAnnounce: String
        @Binding var summaryMode: Bool
        
        var body: some View {
            let boards = Scorecard.current.boards.count
            HStack {
                if scorecard.type.players == 4 {
                    Button {
                        otherTable()
                    } label: {
                        Image(systemName: "arrow.2.squarepath")
                            .if(sitting == initialSitting) { view in
                                view.scaleEffect(CGSize(width: 1.0, height: -1.0))
                            }
                    }
                }
                Spacer().frame(width: 20)
                Button {
                    save()
                    nextTraveller(-1)
                } label: {
                    Image(systemName: "backward.frame")
                }.disabled(board.board <= 1).foregroundColor(Palette.banner.text.opacity(board.board <= 1 ? 0.5 : 1))
                Spacer().frame(width: 20)
                Button {
                    save()
                    nextTraveller(1)
                } label: {
                    Image(systemName: "forward.frame")
                }.disabled(board.board >= boards).foregroundColor(Palette.banner.text.opacity(board.board >= boards ? 0.5 : 1))
            }
        }
    }
    
    func updateAnalysis() {
        let analysis = Scorecard.current.analysis(board: board, traveller: traveller, sitting: sitting)
        analysisData.options = analysis.options
        let set = Set(analysisData.options.map({AnalysisTrickCombination(board: $0.board, suit: $0.contract.suit, declarer: $0.declarer)}))
        analysisData.combinations = set.sorted(by: {$0.declarer < $1.declarer || ($0.declarer == $1.declarer && $0.suit < $1.suit)})
        analysisData.madeValues = analysis.madeValues(combinations: analysisData.combinations)
        if let rankingNumber = traveller.rankingNumber[sitting], let otherTraveller = Scorecard.current.travellers(board: board.board, seat: sitting.equivalent, rankingNumber: rankingNumber).first {
            analysisData.otherOptions = Scorecard.current.analysis(board: board, traveller: otherTraveller, sitting: sitting.equivalent).options
        } else {
            analysisData.otherOptions = []
        }
    }
        
}

let publisher = PassthroughSubject<(Int, Suit, Pair), Never>()

struct AnalysisTricksMade : View {
    let scorecard = Scorecard.current.scorecard!
    @Binding var board: BoardViewModel
    @Binding var traveller: TravellerViewModel
    @Binding var sitting: Seat
    @ObservedObject var analysisData: AnalysisData
    @Binding var stopEdit: Bool
    
    var body: some View {
        let columns = [GridItem(.fixed(80), spacing: 0), GridItem(.fixed(80), spacing: 0), GridItem(.flexible(minimum: 140), spacing: 0), GridItem(.flexible(minimum: 100), spacing: 0), GridItem(.flexible(minimum: 100), spacing: 0)]
        
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
                            CenteredText("Suit")
                            CenteredText("Declarer")
                            CenteredText("Source")
                            CenteredText("Tricks")
                            CenteredText("Override")
                        }
                    }
                    .frame(height: 30)
                    .foregroundColor(Palette.tile.text)
                    ScrollView {
                        ForEach(analysisData.combinations, id: \.self) { combination in
                            LazyVGrid(columns: columns, spacing: 0) {
                                GridRow {
                                    CenteredAttributedText(combination.suit.colorString)
                                    CenteredText(combination.declarer.short)
                                    if let (method, made, _) = analysisData.madeValues[combination] {
                                        CenteredText(method.string)
                                        CenteredText("\(made)")
                                        HStack {
                                            Button {
                                                let value = max(0, (analysisData.madeValues[combination]?.override ?? made) - 1)
                                                analysisData.madeValues[combination]?.override = value
                                                Scorecard.current.analysis(board: board, traveller: traveller, sitting: sitting).setOverride(board: board.board, suit: combination.suit, declarer: combination.declarer, override: value)
                                                publisher.send((value, combination.suit, combination.declarer))
                                            } label: {
                                                Text("-").font(.title)
                                            }
                                            Spacer().frame(width: 10)
                                            let override = analysisData.madeValues[combination]?.override ?? made
                                            UpdatingText(override, blankIf: made, suit: combination.suit, declarer: combination.declarer)
                                            Spacer().frame(width: 10)
                                            Button {
                                                let value = min(13, (analysisData.madeValues[combination]?.override ?? made) + 1)
                                                analysisData.madeValues[combination]?.override = value
                                                Scorecard.current.analysis(board: board, traveller: traveller, sitting: sitting).setOverride(board: board.board, suit: combination.suit, declarer: combination.declarer, override: value)
                                                publisher.send((value, combination.suit, combination.declarer))
                                            } label: {
                                                Text("+").font(.title)
                                            }
                                        }
                                    } else {
                                        Text("")
                                        Text("")
                                        Text("")
                                    }
                                }
                                .foregroundColor(Palette.background.text)
                                .frame(height: 20)
                            }
                        }
                        Spacer()
                    }
                }
                Spacer().frame(width: 10)
            }
        }
        .frame(width: 520, height: 150)
        .background(Palette.background.background).cornerRadius(16)
        .font(smallFont)
        .onTapGesture {
            stopEdit = true
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct UpdatingText: View {
    @State var value: Int
    @State var blankIf: Int
    @State var suit: Suit
    @State var declarer: Pair
    
    init(_ value: Int, blankIf: Int, suit: Suit, declarer: Pair) {
        _value = State(initialValue: value)
        _blankIf = State(initialValue: blankIf)
        _suit = State(initialValue: suit)
        _declarer = State(initialValue: declarer)
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text(value == blankIf ? "" : "\(value)")
                .onReceive(publisher) { (value, suit, declarer) in
                    if suit == self.suit && declarer == self.declarer {
                        self.value = value
                    }
                }
            Spacer()
        }
    }
}

struct AnalysisBiddingOptions : View {
    let scorecard = Scorecard.current.scorecard!
    @Binding var board: BoardViewModel
    @Binding var traveller: TravellerViewModel
    @Binding var sitting: Seat
    @Binding var stopEdit: Bool
    @ObservedObject var analysisData: AnalysisData
    @Binding var formatInt: Int
    
    var format: AnalysisOptionFormat { AnalysisOptionFormat(rawValue: formatInt) ?? .score }
    
    var body: some View {
        let columns = [GridItem(.flexible(minimum: 50), spacing: 0), GridItem(.flexible(minimum: 50), spacing: 0), GridItem(.flexible(minimum: 50), spacing: 0), GridItem(.flexible(minimum: 50), spacing: 0), GridItem(.flexible(minimum: 50), spacing: 0), GridItem(.flexible(minimum: 50), spacing: 0)]
        let headerColumns = [GridItem(.fixed(195), spacing: 0)] + columns
        let bodyColumns = [GridItem(.fixed(110), spacing: 0), GridItem(.fixed(45), spacing: 0),GridItem(.fixed(40), spacing: 0)] + columns
        ZStack {
            VStack {
                Rectangle().frame(height: 30).foregroundColor(Palette.tile.background)
                Spacer()
            }
            HStack {
                Spacer().frame(width: 10)
                VStack {
                    LazyVGrid(columns: headerColumns, spacing: 0) {
                        GridRow {
                            HStack {
                                PickerInputSimple(title: "Show", field: $formatInt, values: AnalysisOptionFormat.allCases.map{$0.string}) { newValue in
                                    UserDefault.analysisOptionFormat.set(newValue)
                                }.frame(width: 140)
                                Spacer()
                            }
                            ForEach(AnalysisAssessmentMethod.allCases, id: \.self) { method in
                                if format == .made {
                                    CenteredText(method.short)
                                } else {
                                    TrailingText(method.short)
                                }
                            }.bold().minimumScaleFactor(0.5)
                        }
                    }
                    .frame(height: 30)
                    .foregroundColor(Palette.tile.text)
                    .font(smallFont)
                    ScrollView {
                            // TODO These are wrong way round - should be Grid above ForEach
                        ForEach(analysisData.options) { option in
                            if !option.removed {
                                LazyVGrid(columns: bodyColumns, spacing: 0) {
                                    GridRow {
                                        let type = option.displayType
                                        let doubleString = (option.double ? AnalysisOptionType.doubleString(option.linked?.displayType) : nil)
                                        LeadingText(doubleString ?? type.string)
                                        LeadingAttributedText(option.contract.colorCompact)
                                        LeadingText(option.declarer.short)
                                        ForEach(AnalysisAssessmentMethod.allCases, id: \.self) { method in
                                            HStack {
                                                Spacer()
                                                let compare = analysisData.options.first?.assessments[.play]
                                                Text(option.value(method: method, format: format, compare: compare))
                                                if format == .made {
                                                    Spacer()
                                                } else {
                                                    Spacer().frame(width: 2)
                                                }
                                            }
                                        }
                                    }
                                    .minimumScaleFactor(0.5)
                                    .foregroundColor(option.removed ? Palette.background.strongText : Palette.background.text)
                                    .frame(height: 20)
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
            Spacer()
        }
        .frame(width: 520, height: 150)
        .background(Palette.background.background).cornerRadius(16)
        .font(smallFont)
        .onTapGesture {
            stopEdit = true
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct AnalysisCommentView: View {
    @Binding var board: BoardViewModel
    @Binding var stopEdit: Bool
    @State var comment: String = ""
    @FocusState var focused: Bool
    @State var showClear = false
    
    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .foregroundColor(Palette.background.background)
                    .cornerRadius(16)
                VStack {
                    Spacer().frame(height: 4)
                    HStack {
                        Spacer().frame(width: 16)
                        Text("COMMENT").font(smallFont).foregroundColor(Palette.background.faintText)
                        Spacer()
                    }
                    Spacer().frame(height: 2)
                    HStack {
                        Spacer().frame(width: 16)
                        TextField("", text: $comment)
                            .onChange(of: comment, initial: false) {
                                board.comment = comment
                                showClear = (comment != "")
                            }
                            .focused($focused)
                            .padding(.all, 2)
                            .foregroundColor(Palette.background.text)
                            .font(inputTitleFont)
                            .minimumScaleFactor(0.8)
                        Spacer().frame(width: 6)
                        if showClear {
                            VStack {
                                Spacer()
                                Button {
                                    focused = false
                                    comment = ""
                                    Utility.mainThread {
                                        focused = true
                                    }
                                } label: {
                                    Image(systemName: "x.circle.fill").font(inputTitleFont).foregroundColor(Palette.clearText)
                                }
                                Spacer()
                            }
                            .frame(width: 40)
                        }
                        Spacer().frame(width: 6)
                    }
                    Spacer()
                }
                .onTapGesture {
                    focused = true
                }
                .cornerRadius(16)
            }
            .frame(width: 520, height: 70)
            .font(defaultFont)
        }
        .onChange(of: stopEdit, initial: false) {
            if stopEdit {
                focused = false
                stopEdit = false
            }
        }
        .onChange(of: board, initial: true) {
            comment = board.comment
            showClear = (comment != "")
        }
    }
}

struct AnalysisActionView: View {
    @Binding var board: BoardViewModel
    @Binding var sitting: Seat
    @Binding var formatInt: Int
    @Binding var stopEdit: Bool
    @ObservedObject var analysisData: AnalysisData
    
    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .foregroundColor(Palette.background.background)
                    .cornerRadius(16)
                VStack {
                    Spacer().frame(height: 4)
                    HStack {
                        Spacer().frame(width: 8)
                        Text("SUGGESTED BIDDING").font(smallFont).foregroundColor(Palette.background.faintText)
                        Spacer()
                    }
                    Spacer().frame(height: 10)
                    Action(description: "Us", analysisData: analysisData, formatInt: $formatInt, useOther: false)
                    if Scorecard.current.scorecard?.type.players == 4 {
                        Spacer().frame(height: 10)
                        Action(description: "Team", analysisData: analysisData, formatInt: $formatInt, useOther: true)
                    }
                    Spacer()
                }
            }
            .frame(width: 520, height: 90)
            .font(defaultFont)
        }
    }
    
    struct Action: View {
        @State var description: String
        @ObservedObject var analysisData: AnalysisData
        @Binding var formatInt: Int
        @State var useOther: Bool
        @State var bestOption: AnalysisOption?
        
        var body: some View {
            HStack(spacing: 0) {
                if let bestOption = bestOption, let useMethod = bestOption.useMethod {
                    Spacer().frame(width: 16)
                    if Scorecard.current.scorecard?.type.players == 4 {
                        HStack(spacing: 0) {
                            Text("\(description):")
                            Spacer()
                        }.frame(width: 70)
                    }
                    HStack(spacing: 0) {
                        Text(bestOption.contract.colorCompact)
                        Text("\(bestOption.value(method: useMethod, format: .made, colorCode: false))")
                        Spacer().frame(width: 6)
                        Text(bestOption.declarer.short)
                        Spacer().frame(width: 12)
                        Spacer()
                    }.frame(width: 130)
                    Text(bestOption.action.description)
                    Spacer()
                    let options = useOther ? analysisData.otherOptions : analysisData.options
                    let compare = options.first?.assessments[.play]
                    Text("\(bestOption.value(method: useMethod, format: .score, compare: compare, verbose: true, showVariance: true, colorCode: false))").frame(width: 100)
                    Spacer().frame(width: 4)
                }
            }
            .font(inputTitleFont).minimumScaleFactor(0.8)
            .onChange(of: analysisData.options, initial: true) {
                let options = (useOther ? analysisData.otherOptions : analysisData.options).filter({!$0.removed})
                let sorted = options.sorted(by:{$0.reliability < $1.reliability || ($0.reliability == $1.reliability && ($0.useAssessment?.score ?? -9999.99) < ($1.useAssessment?.score ?? -9999.99))})
                if var bestOption = sorted.last {
                    // Ignore double if within 1 of making
                    if let tricks = bestOption.useAssessment?.tricks {
                        if bestOption.double && bestOption.linked != nil && tricks >= bestOption.contract.tricks - 1 {
                            bestOption = bestOption.linked!
                        }
                    }
                    self.bestOption = bestOption
                } else {
                    self.bestOption = nil
                }
            }
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
    @Binding var stopEdit: Bool
    @State var travellers: [TravellerExtension] = []
    @State var summary: [TravellerSummary] = []
    
    var body: some View {
        let columns = [GridItem(.flexible(minimum: 90), spacing: 0), GridItem(.fixed(50), spacing: 0), GridItem(.fixed(60), spacing: 0), GridItem(.fixed(70), spacing: 0), GridItem(.fixed(60), spacing: 0), GridItem(.flexible(minimum: 70), spacing: 0)]
        let summaryColumns = [GridItem(.fixed(30), spacing: 0), GridItem(.fixed(50), spacing: 0)] + columns
        let detailColumns = [GridItem(.fixed(80), spacing: 0)] + columns
        
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
                            LazyVGrid(columns: summaryColumns, spacing: 0) {
                                GridRow {
                                    LeadingText("")
                                    CenteredText("Rep")
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
                                LazyVGrid(columns: summaryColumns, spacing: 3) {
                                    ForEach(summary, id: \.self) { summary in
                                        GridRow {
                                            if !(handTraveller == summary) {
                                                HStack {
                                                    Spacer().frame(width: 10)
                                                    Image(systemName: "arrow.up.left")
                                                        .background(Palette.background.background)
                                                        .foregroundColor(Palette.background.text)
                                                        .onTapGesture {
                                                            if let newTraveller = travellers.first(where: { $0 == summary }) {
                                                                traveller = newTraveller
                                                                reflectSelectionChange(traveller: newTraveller)
                                                            }
                                                        }
                                                    Spacer()
                                                }
                                            } else {
                                                CenteredText("")
                                            }
                                            CenteredText(summary.frequency <= 1 ? "" : "x\(summary.frequency)")
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
                                            if summary.frequency > 1 {
                                                selectedSummary = summary
                                                summaryMode.toggle()
                                            }
                                            stopEdit = true
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        VStack {
                            LazyVGrid(columns: detailColumns, spacing: 0) {
                                GridRow {
                                    Button {
                                        summaryMode = true
                                    } label: {
                                        HStack {
                                            Spacer()
                                            Image(systemName: "chevron.backward.2")
                                            Text("Back")
                                            Spacer()
                                        }
                                        .bold(false)
                                        .frame(width: 80, height: 18)
                                        .minimumScaleFactor(0.5)
                                        .palette(.bannerButton)
                                        .cornerRadius(4)
                                    }
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
                                LazyVGrid(columns: detailColumns, spacing: 3) {
                                    ForEach(travellers.filter({$0 == selectedSummary!}), id: \.self) { traveller in
                                        GridRow {
                                            if traveller.rankingNumber != handTraveller.rankingNumber {
                                                HStack {
                                                    Spacer().frame(width: 10)
                                                    Image(systemName: "arrow.up.left")
                                                        .background(Palette.background.background)
                                                        .foregroundColor(Palette.background.text)
                                                        .onTapGesture {
                                                            self.traveller = traveller
                                                            reflectSelectionChange(traveller: traveller)
                                                        }
                                                    Spacer()
                                                }
                                            } else {
                                                CenteredText("")
                                            }
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
                            stopEdit = true
                        }
                    }
                    Spacer()
                }
            }
            Spacer().frame(height: 4)
        }
        .onChange(of: board.board, initial: true) {
            reflectChange()
        }
        .onChange(of: sitting, initial: true) {
            reflectChange()
        }
        .onTapGesture {
            stopEdit = true
        }
        .frame(width: 520, height: 200)
        .background(Palette.background.background)
        .foregroundColor(Palette.background.text)
        .font(.body)
        .cornerRadius(16)
    }
    
    func reflectChange() {
        summaryMode = true
        travellers = buildTravellers(board: self.board, sitting: self.sitting)
        summary = buildSummary()
        reflectSelectionChange(traveller: TravellerExtension(scorecard: scorecard, traveller: traveller))
    }
    
    func reflectSelectionChange(traveller: TravellerExtension) {
        handTraveller = traveller
        handSummary = summary.first(where: {traveller == $0})
    }
    
    func buildTravellers(board: BoardViewModel, sitting: Seat) -> [TravellerExtension] {
        var result: [TravellerExtension] = []
        for traveller in Scorecard.current.travellers(board: board.board) {
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
    var board: BoardViewModel
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
        self.board = board
        self.contract = Contract(copying: traveller.contract)
        self.declarer = traveller.declarer
        self.lead = traveller.lead
        self.made = traveller.contract.level == .passout ? 0 : traveller.made
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
        hasher.combine(board)
        hasher.combine(outcomeLevel)
        hasher.combine(contract.suit)
        hasher.combine(contract.double)
        hasher.combine(declarer)
        hasher.combine(tricksMade)
        hasher.combine(nsPoints)
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
        return lhs.outcomeLevel == rhs.outcomeLevel && (lhs.outcomeLevel == .passout || ( lhs.contract.suit == rhs.contract.suit && lhs.contract.double == rhs.contract.double && lhs.declarer == rhs.declarer && lhs.tricksMade == rhs.tricksMade && lhs.nsPoints == rhs.nsPoints))
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
        if  contract.level == .passout {
            level = .passout
        } else if made < 0 {
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
        return lhs.outcomeLevel == rhs.outcomeLevel && (lhs.outcomeLevel == .passout || (lhs.contract.suit == rhs.contract.suit && lhs.contract.double == rhs.contract.double && lhs.declarer == rhs.declarer && lhs.tricksMade == rhs.tricksMade && lhs.nsPoints == rhs.nsPoints))
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
