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

let analysisCornerSize: CGFloat = 6

class AnalysisData : ObservableObject, Identifiable {
    private(set) var id = UUID()
    @Published var analysis: Analysis
    @Published var override: AnalysisOverride
    @Published var otherAnalysis: Analysis?
    @Published var combinations: [AnalysisTrickCombination] = []
    
    init(analysis: Analysis, otherAnalysis: Analysis?) {
        self.analysis = analysis
        self.otherAnalysis = otherAnalysis
        self.override = analysis.override
        update()
    }
    
    func update() {
        override = analysis.override
        updateCombinations()
    }
    
    func getAnalysis(combination: AnalysisTrickCombination) -> (Analysis, Bool, Bool) {
        var otherTable = false
        var matched = false
        var result = analysis
        if combination.suit == analysis.traveller.contract.suit && combination.declarer == analysis.traveller.declarer.pair {
            matched = true
        } else if let otherTraveller = analysis.otherTraveller {
            if combination.suit == otherTraveller.contract.suit && combination.declarer == otherTraveller.declarer.pair {
                result = otherAnalysis ?? analysis
                matched = true
                otherTable = true
            }
        }
        return (result, otherTable, matched)
    }
    
    public func updateCombinations() {
        let optionCombinations = analysis.options.map({AnalysisTrickCombination(board: $0.board, suit: $0.contract.suit, declarer: $0.declarer)})
        let otherOptionCombinations = (otherAnalysis?.options.map({AnalysisTrickCombination(board: $0.board, suit: $0.contract.suit, declarer: $0.declarer)})) ?? []
        let allOptionCombinations = optionCombinations + otherOptionCombinations
        let set = Set(allOptionCombinations)
        combinations = set.sorted(by: {isDeclarer($0) > isDeclarer($1) || (isDeclarer($0) == isDeclarer($1) && suitPriority($0) > suitPriority($1))})
    }
    
    func isDeclarer(_ combination: AnalysisTrickCombination) -> Int {
        analysis.traveller.declarer.pair == combination.declarer ? 1 : 0
    }
    
    func suitPriority(_ combination: AnalysisTrickCombination) -> Int {
        return combination.suit == analysis.traveller.contract.suit ? 9999 : (analysis.useMethodMadeValue(combination: combination)?.value ?? -9999)
        
    }
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
    @StateObject var analysisData: AnalysisData
    @State var bidAnnounce = ""
    @State var summaryMode = true
    @State var focused = false
    @State var stopEdit = false
    @State var formatInt: Int
    @State var responsiblePicker = false
    
    init(board: BoardViewModel, traveller: TravellerViewModel, sitting: Seat, from: UIView) {
        self._analysisData = StateObject(wrappedValue: AnalysisData(analysis: Scorecard.current.analysis(board: board, traveller: traveller, sitting: sitting), otherAnalysis: nil))
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
                AnalysisBanner(nextTraveller: nextTraveller, updateOptions: updateAnalysisData, board: $board, traveller: $traveller, handTraveller: $handTraveller, sitting: $sitting, rotated: $rotated, initialSitting: $initialSitting, bidAnnounce: $bidAnnounce, summaryMode: $summaryMode, stopEdit: $stopEdit, responsiblePicker: $responsiblePicker)
                VStack {
                    Spacer().frame(height: 8)
                    HStack {
                        HandViewer(board: $board, traveller: $handTraveller, sitting: $sitting, rotated: $rotated, from: from, bidAnnounce: $bidAnnounce, stopEdit: $stopEdit)
                            .cornerRadius(analysisCornerSize)
                            .ignoresSafeArea(.keyboard)
                        Spacer().frame(width: 10)
                        VStack {
                            AnalysisWrapper(label: "Summary", height: 88, teamsHeight: 149, stopEdit: $stopEdit) {
                                AnalysisSummary(board: $board, traveller: $traveller, sitting: $sitting, analysisData: analysisData)
                            }
                            AnalysisWrapper(label: "Tricks Made", height: 130, stopEdit: $stopEdit) {
                                AnalysisCombinationTricks(board: $board, traveller: $traveller, sitting: $sitting, analysisData: analysisData)
                            }
                            AnalysisWrapper(label: "Suggest", height: 70, teamsHeight: 90, stopEdit: $stopEdit) {
                                AnalysisSuggestionView(board: $board, traveller: $traveller, sitting: $sitting, formatInt: $formatInt, analysisData: analysisData)
                            }
                            AnalysisWrapper(label: "Bidding Options", height: 150, stopEdit: $stopEdit) {
                                AnalysisBiddingOptions(board: $board, traveller: $traveller, sitting: $sitting, analysisData: analysisData, formatInt: $formatInt)
                            }
                            AnalysisWrapper(label: "Travellers", stopEdit: $stopEdit) {
                                AnalysisTravellerView(board: $board, traveller: $handTraveller, sitting: $sitting, summaryMode: $summaryMode, stopEdit: $stopEdit)
                            }
                        }
                    }
                }
                Spacer().frame(height: 10)
            }
        }
        .background(.clear)
        .onChange(of: board.board, initial: true) {
            updateAnalysisData()
        }
        .onSwipe() { direction in
            nextTraveller(direction == .left ? 1 : -1)
        }
        .onReceive(analysisViewerValueChange) { (source) in
            updateAnalysisData()
        }
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
        @Binding var stopEdit: Bool
        @Binding var responsiblePicker: Bool
        @State var keyboardAdjust: CGFloat = 0
        
        var body : some View {
            VStack {
                Spacer().frame(height: keyboardAdjust != 0 ? 89 : 0)
                VStack {
                    Spacer()
                    HStack {
                        Spacer().frame(width: 20)
                        Text("Board \(board.boardNumber)\(scorecard.resetNumbers ? "(\(board.tableNumber))" : "")")
                        if traveller.rankingNumber == handTraveller.rankingNumber {
                            HStack {
                                Spacer().frame(width: 20)
                                AnalysisCommentView(board: $board, stopEdit: $stopEdit)
                                    .palette(.bannerShadow)
                                    .cornerRadius(analysisCornerSize)
                                Spacer().frame(width: 20)
                            }
                        } else {
                            Text(" Other table ")
                            Button {
                                handTraveller = traveller
                                summaryMode = true
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
                        AnalysisResponsible(board: $board, stopEdit: $stopEdit, responsiblePicker: $responsiblePicker)
                        Spacer().frame(width: 40)
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
                            .cornerRadius(analysisCornerSize)
                            .opacity(0.7)
                        }
                        Spacer().frame(width: 50)
                        ButtonBar(nextTraveller: nextTraveller, otherTable: otherTable, save: save, board: $board, traveller: $handTraveller, sitting: $sitting, initialSitting: initialSitting, bidAnnounce: $bidAnnounce, summaryMode: $summaryMode)
                        Spacer().frame(width: 20)
                    }.font(bannerFont).foregroundColor(Palette.banner.text)
                    Spacer()
                }
                .background(Palette.banner.background)
                .cornerRadius(analysisCornerSize)
                .onTapGesture {
                    stopEdit = true
                }
            }
            .onReceive(Publishers.keyboardHeight) { (keyboardHeight) in
                keyboardAdjust = keyboardHeight
            }
            .frame(height: keyboardAdjust != 0 ? 169 : 80)
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
                    stopEdit = true
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
                            name = realName.components(separatedBy: " ").last!
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
                sitting = newSitting
                rotated = sitting.offset(to: initialSitting)
                board = newBoard
                traveller = newTraveller
                handTraveller = newTraveller
                stopEdit = true
                bidAnnounce = ""
                summaryMode = true
                break
            }
        } while boardNumber > 1 && boardNumber < boards
    }
    
    struct AnalysisResponsible : View {
        @Binding var board: BoardViewModel
        @Binding var stopEdit: Bool
        @Binding var responsiblePicker: Bool
        @State var scrollId: Int?
        @State var changed = false
        let show = (((Responsible.validCases.count - 1) / 2) * 2) + 1 // Must be odd

        var body : some View {
            AnalysisResponsibleElement(responsible: $board.responsible, changed: $changed, unknown: "Resp")
            .palette(.bannerShadow)
            .cornerRadius(analysisCornerSize)
            .frame(width: 70, height: 60)
            .onTapGesture {
                stopEdit = true
                responsiblePicker = true
            }
            .popover(isPresented: $responsiblePicker) {
                ZStack {
                    Palette.bannerShadow.background.scaleEffect(1.5)
                    AnalysisResponsiblePicker(board: $board, show: show, scrollId: $scrollId, changed: $changed)
                        .palette(.bannerShadow)
                }
            }
            .onChange(of: changed, initial: false) {
                if changed {
                    changed = false
                }
            }
        }
    }
    
    class AnalysisResponsibleEnumeration: Identifiable {
        var id: Int { index }
        var index: Int
        var responsible: Responsible
        
        init(index: Int, responsible: Responsible) {
            self.index = index
            self.responsible = responsible
        }
    }
    
    struct AnalysisResponsiblePicker : View {
        @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
        @Binding var board: BoardViewModel
        var show: Int
        @Binding var scrollId: Int?
        @Binding var changed: Bool
        @State var refresh = false
        
        var body : some View {
            let cases = Responsible.validCases.count
            let blanks = (cases / 2)
            let list = (Array(repeating: .blank, count: blanks) + Responsible.validCases + Array(repeating: .blank, count: blanks)).enumerated().map{AnalysisResponsibleEnumeration(index: $0.0, responsible: $0.1)}
            
            return ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(list) { (item) in
                        HStack(spacing: 0) {
                            if item.responsible != .blank {
                                if refresh { EmptyView() }
                                AnalysisResponsibleElement(responsible: Binding.constant(item.responsible), changed: $changed)
                                    .foregroundColor(item.responsible == board.responsible ? Palette.banner.contrastText : Palette.banner.text)
                                    .onTapGesture {
                                        scrollId = item.id
                                        board.responsible = item.responsible
                                        changed = true
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                Rectangle().foregroundColor(.black).frame(width: 1, height: 60)
                            } else {
                                Spacer()
                                if item.index == blanks - 1 {
                                    Rectangle().foregroundColor(.black).frame(width: 1, height: 60)
                                }
                            }
                        }
                        .frame(width: 70, height: 60)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrollId, anchor: .center)
            .scrollTargetBehavior(.viewAligned)
            .onChange(of: scrollId, initial: false) {
                if let scrollId = scrollId {
                    board.responsible = list[scrollId].responsible
                    changed = true
                    refresh.toggle()
                }
            }
            .onAppear {
                scrollId = (list.first(where: {$0.responsible == board.responsible}))?.id
            }
            .palette(.bannerShadow)
            .frame(width: (70 * CGFloat(show)), height: 60)
        }
    }
    
    struct AnalysisResponsibleElement : View {
        @Binding var responsible: Responsible
        @Binding var changed: Bool
        var unknown: String? = nil
        
        var body : some View {
            VStack {
                if changed { EmptyView() }
                Spacer()
                HStack {
                    Spacer()
                    Text(responsible.short).font(responsibleTitleFont)
                    Spacer()
                }
                Spacer().frame(height: 2)
                HStack {
                    Spacer()
                    Text((responsible == .unknown && unknown != nil ? unknown! : responsible.full)).font(responsibleCaptionFont)
                    Spacer()
                }
                Spacer().frame(height: 6)
            }.onChange(of: changed, initial: false) {
                if changed {
                    changed = false
                }
            }
        }
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
                Spacer().frame(width: 20)
                Button {
                    save()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
    }
    
    func updateAnalysisData() {
        analysisData.analysis = Scorecard.current.analysis(board: board, traveller: traveller, sitting: sitting)
        if let otherTraveller = analysisData.analysis.otherTraveller {
            analysisData.otherAnalysis = Scorecard.current.analysis(board: board, traveller: otherTraveller, sitting: sitting.equivalent)
        } else {
            analysisData.otherAnalysis = nil
        }
        analysisData.analysis.refreshOptions()
        analysisData.otherAnalysis?.refreshOptions()
        analysisData.update()
    }
}

enum AnalysisSource {
    case override
    case rejected
}

let analysisViewerValueChange = PassthroughSubject<AnalysisSource, Never>()

struct AnalysisWrapper <Content> : View where Content : View {
    @State var stopEdit: Binding<Bool>
    var label: String
    var height: CGFloat?
    var teamsHeight: CGFloat?
    var content: ()->Content
    
    init(label: String, height: CGFloat? = nil, teamsHeight: CGFloat? = nil, stopEdit: Binding<Bool>, @ViewBuilder content: @escaping ()->Content) {
        self.label = label
        self.height = height
        self.teamsHeight = teamsHeight
        self.stopEdit = stopEdit
        self.content = content
    }
    
    var body: some View {
        let type = Scorecard.current.scorecard?.type
        let teams = type?.players == 4
        let height = (teams && teamsHeight != nil ? teamsHeight! : height)
        
        HStack(spacing: 0) {
            ZStack {
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: analysisCornerSize,
                                                          bottomLeading: analysisCornerSize,
                                                          bottomTrailing: 0,
                                                          topTrailing: 0),
                                       style: .continuous)
                .foregroundColor(Palette.background.background)
                .frame(width: 500)
                .if(height != nil) { view in
                    view.frame(height: height)
                }
                
                content()
                    .frame(width: 500)
                    .if(height != nil) { view in
                        view.frame(height: height!)
                    }
                    .font(inputFont).minimumScaleFactor(0.6)
            }
            
            ZStack {
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: 0,
                                                          bottomLeading: 0,
                                                          bottomTrailing: analysisCornerSize,
                                                          topTrailing: analysisCornerSize),
                                       style: .continuous)
                .foregroundColor(Palette.handPlayer.background)
                .frame(width: 20)
                .if(height != nil) { view in
                    view.frame(height: height!)
                }
                
                HStack(spacing: 0) {
                    Spacer()
                    Text(label)
                        .foregroundColor(Palette.handPlayer.contrastText)
                        .font(smallFont)
                        .minimumScaleFactor(0.5)
                    Spacer()
                }
                .frame(width: height, height: 20)
                .fixedSize()
                .frame(width: 20)
                .if(height != nil) { view in
                    view.frame(height: height!)
                }
                .rotationEffect(.degrees(90))
            }
        }
        .onTapGesture {
            stopEdit.wrappedValue = true
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct AnalysisSummary : View {
    let scorecard = Scorecard.current.scorecard!
    @Binding var board: BoardViewModel
    @Binding var traveller: TravellerViewModel
    @Binding var sitting: Seat
    @ObservedObject var analysisData: AnalysisData
    
    var body: some View {
        let type = scorecard.type
        let teams = (type.players == 4)
        ZStack {
            VStack {
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: analysisCornerSize), style: .continuous)
                    .frame(height: 30).foregroundColor(Palette.tile.background)
                Spacer()
            }
            let tableColumns = (teams ? [GridItem(.fixed(60), spacing: 0), GridItem(.fixed(2), spacing: 0)] : [])
            let columns = tableColumns + [GridItem(.flexible(minimum: 100), spacing: 0), GridItem(.fixed(2), spacing: 0), GridItem(.flexible(minimum: 100), spacing: 0)]
            VStack {
                LazyVGrid(columns: columns, spacing: 0) {
                    GridRow {
                        if teams {
                            CenteredText("Table")
                            Text("")
                        }
                        CenteredText("Bidding")
                        Text("")
                        CenteredText("Play")
                    }
                    .bold()
                    .frame(height: 30)
                    .foregroundColor(Palette.tile.text)
                    ForEach(0..<2) { otherTable in
                        let otherTable = (otherTable == 1)
                        if !otherTable || scorecard.type.players == 4 {
                            GridRow {
                                if teams {
                                    CenteredText(otherTable ? "Other" : "This")
                                    Separator(direction: .vertical, thickness: 2).background(Palette.tile.background)
                                }
                                ForEach(0..<2) { phase in
                                    let phase: AnalysisPhase = (phase == 0 ? .bidding : .play)
                                    AnalysisSummaryDetail(board: $board, traveller: $traveller, sitting: $sitting, phase: phase, otherTable: otherTable, analysisData: analysisData)
                                    if phase == .bidding {
                                        Separator(direction: .vertical, thickness: 2).background(Palette.tile.background)
                                    }
                                }
                                .frame(height: 58)
                                if !otherTable && teams {
                                    GridRow {
                                        ForEach(0..<columns.count) { _ in
                                            Separator(direction: .horizontal, thickness: 3).background(Palette.tile.background)
                                        }
                                    }
                                    .frame(height: 3)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    struct AnalysisSummaryDetail : View {
        @Binding var board: BoardViewModel
        @Binding var traveller: TravellerViewModel
        @Binding var sitting: Seat
        @State var phase: AnalysisPhase
        @State var otherTable: Bool
        @ObservedObject var analysisData: AnalysisData
        @State var status: AnalysisSummaryStatus = .ok
        @State var text: AttributedString = ""
        @State var impact: String = ""
        
        var body: some View {
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    Spacer().frame(width: 8)
                    status.image.font(inputTitleFont)
                    Spacer().frame(width: 4)
                    HStack {
                        Text(text)
                        Spacer()
                    }
                    if status < .ok {
                        HStack {
                            Spacer()
                            Text(impact)
                            Spacer()
                        }
                        .frame(width: 80)
                        .bold()
                    }
                    Spacer().frame(width: 2)
                }
                .opacity(status == .rejected ? 0.4 : 1)
                Spacer()
            }
            .font(smallFont)
            .minimumScaleFactor(0.6)
            .onChange(of: board, initial: true) {
                updateSummary()
            }
            .onChange(of: sitting, initial: true) {
                updateSummary()
            }
            .onReceive(analysisViewerValueChange) { (_) in
                updateSummary()
            }
        }
        func updateSummary() {
            if let analysis = (otherTable ? analysisData.otherAnalysis : analysisData.analysis) {
                let summaryValues = analysis.summary(phase: phase, otherTable: otherTable, verbose: true)
                status = summaryValues.status
                text = summaryValues.text
                impact = summaryValues.impactDescription
            }
        }
    }
}
    
struct AnalysisCombinationTricks : View {
    @Binding var board: BoardViewModel
    @Binding var traveller: TravellerViewModel
    @Binding var sitting: Seat
    @ObservedObject var analysisData: AnalysisData
    @State var made: Int = 0
    @State var method: AnalysisAssessmentMethod = .override
    @State var refresh: Bool = true
    
    var body: some View {
        let columns = [GridItem(.fixed(50), spacing: 0), GridItem(.fixed(50), spacing: 0), GridItem(.fixed(80), spacing: 0), GridItem(.flexible(minimum: 100), spacing: 0), GridItem(.fixed(90), spacing: 0), GridItem(.fixed(130), spacing: 0)]
        
        ZStack {
            VStack {
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: analysisCornerSize), style: .continuous)
                    .frame(height: 30).foregroundColor(Palette.tile.background)
                Spacer()
            }
            HStack {
                VStack {
                    LazyVGrid(columns: columns, spacing: 0) {
                        GridRow {
                            CenteredText("Suit")
                            CenteredText("By")
                            CenteredText("Using")
                            CenteredText("Made")
                            CenteredText("Compare")
                            CenteredText("Impact")
                        }
                    }
                    .bold()
                    .frame(height: 30)
                    .foregroundColor(Palette.tile.text)
                    ScrollView {
                        ForEach(analysisData.combinations, id: \.self) { combination in
                            AnalysisCombination(board: $board, traveller: $traveller, sitting: $sitting, analysisData: analysisData, columns: columns, combination: combination)
                        }
                        Spacer().frame(height: 4)
                    }
                }
            }
        }
        .onReceive(analysisViewerValueChange) { (_) in
            refresh.toggle()
        }
        .onChange(of: sitting) {
            refresh.toggle()
        }
    }
    
    struct AnalysisCombination : View {
        @Binding var board: BoardViewModel
        @Binding var traveller: TravellerViewModel
        @Binding var sitting: Seat
        @ObservedObject var analysisData: AnalysisData
        let columns: [GridItem]
        @State var combination: AnalysisTrickCombination
        @State var made: Int?
        @State var method: AnalysisAssessmentMethod?
        @State var compare: AttributedString?
        
        var body : some View {
            LazyVGrid(columns: columns, spacing: 0) {
                GridRow {
                    CenteredAttributedText(combination.suit.colorString)
                    CenteredText(combination.declarer.short)
                    if let method = method {
                        HStack {
                            Spacer()
                            Text(method.string)
                            Spacer()
                        }
                        madeView(board: $board, sitting: $sitting, analysisData: analysisData, combination: $combination, method: $method, made: $made)
                        if let compare = compare {
                            HStack(spacing: 0) {
                                Spacer()
                                Text(compare)
                                Spacer()
                            }
                            AnalysisCombinationReject(board: $board, traveller: $traveller, analysisData: analysisData, combination: combination, method: $method)
                        } else {
                            Text("")
                        }
                    } else {
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                    }
                }
                .foregroundColor(Palette.background.text)
            }
            .onChange(of: board, initial: true) {
                updateState()
            }
            .onChange(of: sitting, initial: false) {
                updateState()
            }
            .onReceive(analysisViewerValueChange) { (_) in
                updateState()
            }
        }
        
        func updateState() {
            let (analysis, otherPage, matched) = analysisData.getAnalysis(combination: combination)
            if let (method, made) = analysis.useMethodMadeValue(combination: combination, overrideRegardless: true) {
                self.method = (method == .play && otherPage ? .other : method)
                self.made = made
                self.compare = nil
                if matched {
                    if let (compare, _, _) = analysis.compare(combination: combination) {
                        self.compare = AttributedString(compare)
                    }
                }
            } else {
                self.method = nil
                self.made = nil
                self.compare = nil
            }
        }
    }
    
    struct AnalysisCombinationReject : View {
        let scorecard = Scorecard.current.scorecard!
        @Binding var board: BoardViewModel
        @Binding var traveller: TravellerViewModel
        @ObservedObject var analysisData: AnalysisData
        @State var combination: AnalysisTrickCombination
        @Binding var method: AnalysisAssessmentMethod?
        @State var rejected = false
        @State var impact: Float = 0
        @State var analysis: Analysis?
        
        var body : some View {
            HStack {
                HStack(spacing: 0) {
                    Spacer()
                    Text(impact < 0.5 ? "No change" : impact.toString(places: 0) + scorecard.type.boardScoreType.suffix)
                        .foregroundColor(Palette.background.textColor(rejected ? .faint : .normal))
                    Spacer()
                    if impact >= 0.5 {
                        Analysis.checkBoxImage(rejected: rejected).font(inputTitleFont)
                            .onTapGesture {
                                rejected.toggle()
                                analysis?.set(rejected: rejected, phase: .play)
                                analysisViewerValueChange.send(.rejected)
                                updateImpact()
                            }
                        Spacer().frame(width: 2)
                    }
                }
            }
            .onChange(of: board, initial: true) {
                updateImpact()
            }
            .onChange(of: traveller, initial: false) {
                updateImpact()
            }
            .onReceive(analysisViewerValueChange) { (_) in
                updateImpact()
            }
        }
        
        func updateImpact() {
            (analysis, _, _) = analysisData.getAnalysis(combination: combination)
            
            if let (_, optionalImpact, _) = analysis?.compare(combination: combination) {
                impact = optionalImpact ?? 0
            } else {
                impact = 0
            }

            rejected = analysis?.rejected(phase: .play) ?? false
        }
    }
}

struct madeView : View {
    @Binding var board: BoardViewModel
    @Binding var sitting: Seat
    @ObservedObject var analysisData: AnalysisData
    @Binding var combination: AnalysisTrickCombination
    @Binding var method: AnalysisAssessmentMethod?
    @Binding var made: Int?
    @State var showOverride = false
    
    var body: some View {
        HStack(spacing: 0) {
            if let made = made {
                HStack {
                    Spacer()
                    Text("\(made)")
                    Spacer()
                }
                .frame(width: 40)
                .popover(isPresented: $showOverride) {
                    overridePopover(board: $board, analysisData: analysisData, combination: combination, method: $method, made: $made, showOverride: $showOverride)
                }
                Spacer().frame(width: 10)
                AnalysisSmallButton(label: "Change") {
                    showOverride = true
                }
            }
        }
    }
}

struct AnalysisSmallButton : View {
    @State var prefix: String?
    @State var label: String
    @State var action: ()->()
    
    var body : some View {
        Button {
            action()
        } label: {
            VStack {
                HStack(spacing: 0) {
                    Spacer().frame(width: 4)
                    if let prefix = prefix {
                        Image(systemName: prefix)
                    }
                    Text(label).minimumScaleFactor(0.5).font(tinyFont)
                    Spacer().frame(width: 4)
                }
                .frame(height: 20)
                .palette(.disabledButton)
                .cornerRadius(4)
            }
        }
    }
}
    
struct overridePopover : View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var board: BoardViewModel
    @ObservedObject var analysisData: AnalysisData
    @State var combination: AnalysisTrickCombination
    @Binding var method: AnalysisAssessmentMethod?
    @Binding var made: Int?
    @Binding var showOverride: Bool
    @State var newMethod: AnalysisAssessmentMethod = .override
    @State var newMade: Int = 0

    var body: some View {
        HStack {
            VStack {
                Spacer().frame(height: 10)
                HStack {
                    Spacer().frame(width: 30)
                    VStack {
                        Spacer().frame(height: 10)
                        HStack {
                            Text("Based on:")
                            Spacer()
                        }
                        .frame(width: 100)
                        Spacer()
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .foregroundColor(Palette.alternate.background)
                        HStack {
                            Spacer().frame(width: 10)
                            VStack {
                                Spacer().frame(height: 8)
                                ForEach(analysisData.analysis.allMethods(includeOverride: false), id: \.self) { inputMethod in
                                    Button {
                                        newMethod = inputMethod
                                    } label: {
                                        HStack {
                                            Text(inputMethod.string)
                                                .padding(8)
                                            Spacer()
                                        }
                                        .palette(inputMethod == newMethod ? .tile : .clear)
                                        .cornerRadius(6)
                                    }
                                    Spacer().frame(height: 5)
                                }
                                Spacer().frame(height: 8)
                            }
                            .frame(width: 200)
                            Spacer().frame(width: 10)
                        }
                    }
                    Spacer().frame(width: 50)
                }
                Spacer().frame(height: 20)
                HStack(spacing: 0) {
                    Spacer().frame(width: 30)
                    HStack {
                        Text("Tricks:")
                        Spacer()
                    }
                    .frame(width: 100)
                    HStack {
                        Spacer()
                        Text("\(newMade)")
                            .padding(8)
                    }
                    .frame(width: 80)
                    .palette(.alternate)
                    .cornerRadius(6)
                    Spacer().frame(width: 10)
                    button(label: "+", combination: combination, method: $newMethod, value: $newMade, change: +1, disabled: newMade >= 13, color: .enabledButton, font: inputTitleFont).frame(width: 60).font(inputTitleFont)
                    button(label: "-", combination: combination, method: $newMethod, value: $newMade, change: -1, disabled: newMade <= 0, color: .enabledButton, font: inputTitleFont).frame(width: 60).font(inputTitleFont)
                    Spacer()
                }
                Spacer().frame(height: 20)
                Separator(thickness: 2)
                Spacer().frame(height: 20)
                HStack {
                    Spacer()
                    button(label: "Cancel", combination: combination, color: .enabledButton) {
                        showOverride = false
                    }
                    Spacer().frame(width: 40)
                    button(label: "Reset", combination: combination, disabled: newMethod != .override, color: .enabledButton) {
                        setValue(combination: combination, value: nil)
                        showOverride = false
                    }
                    Spacer().frame(width: 40)
                    button(label: "Confirm", combination: combination, disabled: newMade == made && newMethod == method, color: .highlightButton) {
                        made = newMade
                        setValue(combination: combination, value: newMade)
                        showOverride = false
                    }
                    Spacer()
                }
                Spacer().frame(height: 20)
            }
        }
        .onAppear {
            newMade = made!
            newMethod = method!
        }
        .onChange(of: newMethod, initial: true) {
            let newValue = getValue(combination: combination, method: newMethod) ?? made!
            if newMethod != .override {
                newMade = newValue
            }
        }
    }
    
    func button(label: String, combination: AnalysisTrickCombination, method: Binding<AnalysisAssessmentMethod>? = nil, value: Binding<Int>? = nil, change: Int? = nil, disabled: Bool = false, color: ThemeBackgroundColorName = .background, font: Font = defaultFont, completion: (()->())? = nil) -> some View {
        
        return Button {
            if value != nil {
                let newValue = (value?.wrappedValue ?? 0) + (change ?? 0)
                method?.wrappedValue = .override
                value?.wrappedValue = newValue
            }
            completion?()
            
        } label: {
            VStack {
                Spacer()
                HStack {
                    Spacer().frame(width: 20)
                    Text(label).font(font).minimumScaleFactor(0.5)
                    Spacer().frame(width: 20)
                }
                Spacer()
            }
            .frame(height: 30)
            .palette(color).cornerRadius(6).opacity(disabled ? 0.4 : 1)
        }
        .disabled(disabled)
    }
    
    func setValue(combination: AnalysisTrickCombination, value: Int?) {
        analysisData.override.setValue(board: board.board, suit: combination.suit, declarer: combination.declarer, value: value)
        Scorecard.current.save(board: board)
        if value != nil {
            method = .override
            made = value!
        } else {
            if let (newMethod, newValue) = analysisData.analysis.useMethodMadeValue(combination: combination) {
                method = newMethod
                made = newValue
            }
        }
        analysisViewerValueChange.send(.override)
    }
    
    func getValue(combination: AnalysisTrickCombination, method: AnalysisAssessmentMethod = .override) -> Int? {
        analysisData.analysis.madeValue(combination: combination, method: method)
    }
}

struct AnalysisBiddingOptions : View {
    let scorecard = Scorecard.current.scorecard!
    @Binding var board: BoardViewModel
    @Binding var traveller: TravellerViewModel
    @Binding var sitting: Seat
    @ObservedObject var analysisData: AnalysisData
    @Binding var formatInt: Int
    
    var format: AnalysisOptionFormat { AnalysisOptionFormat(rawValue: formatInt) ?? .score }
    
    var body: some View {
        let allMethods = analysisData.analysis.allMethods()
        let columns = Array(repeating: GridItem(.fixed(CGFloat(305/allMethods.count)), spacing: 0), count: allMethods.count)
        let headerColumns = [GridItem(.fixed(180), spacing: 0)] + columns
        let bodyColumns = [GridItem(.fixed(105), spacing: 0), GridItem(.fixed(40), spacing: 0),GridItem(.fixed(35), spacing: 0)] + columns
        ZStack {
            VStack {
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: analysisCornerSize), style: .continuous)
                    .frame(height: 30).foregroundColor(Palette.tile.background)
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
                                }.frame(width: 108)
                                Spacer()
                            }
                            ForEach(allMethods, id: \.self) { method in
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
                        ForEach(analysisData.analysis.options) { option in
                            if !option.removed {
                                LazyVGrid(columns: bodyColumns, spacing: 0) {
                                    GridRow {
                                        let type = option.displayType
                                        let doubleString = (option.double ? AnalysisOptionType.doubleString(option.linked?.displayType) : nil)
                                        LeadingText(doubleString ?? type.string)
                                        LeadingAttributedText(option.contract.colorCompact)
                                        LeadingText(option.declarer.short)
                                        ForEach(analysisData.analysis.allMethods(), id: \.self) { method in
                                            HStack {
                                                Spacer()
                                                let compare = analysisData.analysis.options.first?.assessments[.play]
                                                Text(option.valueString(method: method, format: format, compare: compare))
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
        .font(smallFont)
    }
}

struct AnalysisCommentView: View {
    @Binding var board: BoardViewModel
    @Binding var stopEdit: Bool
    @State var comment: String = ""
    @FocusState var focused: Bool
    @State var editing: Bool = false
    @State var showClear = false
    @State var color: ThemeBackgroundColorName = .clear
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: analysisCornerSize).foregroundColor(PaletteColor(color).background)
            HStack {
                Spacer().frame(width: 16)
                ZStack {
                    if editing {
                        HStack {
                            VStack {
                                Spacer().frame(height: 4)
                                TextEditor(text: $comment)
                                    .onChange(of: comment, initial: false) {
                                        board.comment = comment
                                        showClear = (comment != "")
                                    }
                                    .scrollContentBackground(.hidden)
                                    .focused($focused)
                                    .padding(.all, 2)
                                    .font(inputFont)
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(2, reservesSpace: true)
                                Spacer().frame(height: 4)
                            }
                            if showClear {
                                Spacer().frame(width: 6)
                                VStack {
                                    Spacer()
                                    Button {
                                        focused = false
                                        comment = ""
                                        Utility.mainThread {
                                            focused = true
                                        }
                                    } label: {
                                        Image(systemName: "x.circle.fill").font(inputTitleFont).foregroundColor(Palette.banner.background)
                                    }
                                    Spacer()
                                }
                                .frame(width: 40)
                                Spacer().frame(width: 6)
                            }
                        }
                    } else {
                        VStack {
                            Spacer().if(editing) { view in view.frame(height: 4)}
                            HStack {
                                Spacer().frame(width: 1)
                                Text(comment)
                                    .font(inputTitleFont)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(2, reservesSpace: true)
                                Spacer()
                            }
                            Spacer().if(editing) { view in view.frame(height: 4)}
                        }
                        VStack {
                            Spacer()
                            HStack {
                                Spacer().frame(width:3)
                                Text(comment == "" ? "Enter comment" : "")
                                    .foregroundColor(PaletteColor(color).textColor(.normal))
                                    .opacity(focused ? 0.3 : 0.5)
                                    .font(inputTitleFont)
                                    .lineLimit(2)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
            }
            .onTapGesture {
                focused = true
                editing = true
                showClear = (comment != "")
                color = .bannerInput
            }
            .onChange(of: stopEdit, initial: false) {
                if stopEdit {
                    focused = false
                    editing = false
                    color = .clear
                    stopEdit = false
                }
            }
            .onChange(of: board, initial: true) {
                comment = board.comment
                showClear = (comment != "" && focused)
            }
        }
    }
}

struct AnalysisSuggestionView: View {
    let scorecard = Scorecard.current.scorecard!
    @Binding var board: BoardViewModel
    @Binding var traveller: TravellerViewModel
    @Binding var sitting: Seat
    @Binding var formatInt: Int
    @ObservedObject var analysisData: AnalysisData
    let tableWidth: CGFloat = 55
    let contractWidth: CGFloat = 110
    let impactWidth: CGFloat = 135
    
    var body: some View {
        ZStack {
            VStack {
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: analysisCornerSize), style: .continuous)
                    .frame(height: 30).foregroundColor(Palette.tile.background)
                Spacer()
            }
            HStack {
                Spacer().frame(width: 10)
                VStack {
                    VStack(spacing: 0) {
                        Spacer()
                        HStack(spacing: 0) {
                            if scorecard.type.players == 4 {
                                LeadingText("Table").frame(width: tableWidth)
                            }
                            CenteredText("Contract").frame(width: contractWidth)
                            CenteredText("Description")
                            CenteredText("Impact").frame(width: impactWidth)
                        }
                        .foregroundColor(Palette.tile.text).bold()
                        .frame(height: 25)
                        Spacer()
                    }.frame(height: 30)
                    Suggestion(board: $board, traveller: $traveller, table: "This", analysisData: analysisData, formatInt: $formatInt, otherTable: false, tableWidth: tableWidth, contractWidth: contractWidth, impactWidth: impactWidth)
                    if Scorecard.current.scorecard?.type.players == 4 {
                        Spacer().frame(height: 10)
                        Suggestion(board: $board, traveller: $traveller, table: "Other", analysisData: analysisData, formatInt: $formatInt, otherTable: true, tableWidth: tableWidth, contractWidth: contractWidth, impactWidth: impactWidth)
                    }
                    Spacer()
                }
                Spacer().frame(width: 4)
            }
        }.font(inputFont)
    }
    
    struct Suggestion: View {
        let scorecard = Scorecard.current.scorecard!
        @Binding var board: BoardViewModel
        @Binding var traveller: TravellerViewModel
        @State var table: String
        @ObservedObject var analysisData: AnalysisData
        @Binding var formatInt: Int
        @State var otherTable: Bool
        @State var rejected: Bool = false
        @State var tableWidth: CGFloat
        @State var contractWidth: CGFloat
        @State var impactWidth: CGFloat
        @State var option: AnalysisOption?
        @State var method: AnalysisAssessmentMethod?
        @State var actionDescription: AttributedString?
        @State var impactDescription: String?
        
        var body: some View {
            VStack {
                if let option = option, let method = method, let impactDescription = impactDescription, let actionDescription = actionDescription {
                    HStack(spacing: 0) {
                        if scorecard.type.players == 4 {
                            LeadingText(table).frame(width: tableWidth)
                        }
                        HStack {
                            Spacer()
                            Text(option.contract.colorCompact + option.valueString(method: method, format: .made, colorCode: false) + AttributedString("  " + option.declarer.short))
                            Spacer()
                        }.frame(width: contractWidth)
                        HStack {
                            Spacer()
                            Text(actionDescription)
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            Text("\(impactDescription ==  "" ? "No change" : impactDescription)")
                                .foregroundColor(Palette.background.textColor(rejected && impactDescription != "" ? .faint : .normal))
                            Spacer()
                            if impactDescription != "" {
                                Analysis.checkBoxImage(rejected: rejected)
                                    .onTapGesture {
                                        rejected.toggle()
                                    }
                            }
                            Spacer().frame(width: 2)
                        }.frame(width: impactWidth)
                    }
                }
            }
            .onChange(of: rejected, initial: false) {
                if rejected != analysisData.analysis.rejected(phase: .bidding, otherTable: otherTable) {
                    print("Rejected changed \(option!.contract.compact) \(rejected) \(analysisData.analysis.rejected(phase: .bidding))")
                    analysisData.analysis.set(rejected: rejected, phase: .bidding, otherTable: otherTable)
                    analysisViewerValueChange.send(.rejected)
                }
            }
            .onChange(of: board, initial: true) {
                updateState()
            }
            .onChange(of: traveller, initial: false) {
                updateState()
            }
            .onReceive(analysisViewerValueChange) { (_) in
                updateState()
            }
        }
        
        func updateState() {
            let analysis = (otherTable ? analysisData.otherAnalysis : analysisData.analysis)!
            option = analysis.bestOption
            if let option = option {
                method = option.useMethod
                let summaryValues = analysis.summary(phase: .bidding, otherTable: otherTable)
                actionDescription = summaryValues.text
                impactDescription = summaryValues.impactDescription
                rejected = analysisData.analysis.rejected(phase: .bidding, otherTable: otherTable)
            }
        }
    }
}

struct AnalysisTravellerView: View {
    let scorecard = Scorecard.current.scorecard!
    @Binding var board: BoardViewModel
    @Binding var traveller: TravellerViewModel
    @State var myTraveller: TravellerExtension!
    @State var handTraveller: TravellerExtension!
    @State var handSummary: TravellerSummary!
    @State var selectedSummary: TravellerSummary?
    @Binding var sitting: Seat
    @Binding var summaryMode: Bool
    @Binding var stopEdit: Bool
    @State var travellers: [TravellerExtension] = []
    @State var summary: [TravellerSummary] = []
    
    var body: some View {
        let headToHead = (scorecard.type.players == 4 && travellers.count <= 2)
        let columns = [GridItem(.flexible(minimum: headToHead ? 116 : 90), spacing: 0), GridItem(.fixed(40), spacing: 0), GridItem(.fixed(60), spacing: 0), GridItem(.fixed(54), spacing: 0), GridItem(.fixed(headToHead ? 70 : 60), spacing: 0), GridItem(.flexible(minimum: headToHead ? 80 : 70), spacing: 0)]
        let summaryColumns = [GridItem(.fixed(56), spacing: 0), GridItem(.fixed(50), spacing: 0)] + columns
        let detailColumns = [GridItem(.fixed(headToHead ? 60 : 106), spacing: 0)] + columns
        
        VStack {
            ZStack {
                VStack {
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: analysisCornerSize), style: .continuous)
                        .frame(height: 30).foregroundColor(Palette.tile.background)
                    Spacer()
                }
                HStack {
                    Spacer()
                    if summaryMode && !headToHead {
                        VStack {
                            LazyVGrid(columns: summaryColumns, spacing: 0) {
                                GridRow {
                                    LeadingText("")
                                    CenteredText("Rep")
                                    CenteredText("Contract")
                                    CenteredText("By")
                                    CenteredText("Lead")
                                    CenteredText("Made")
                                    HStack {
                                        Spacer()
                                        Text(sitting.pair.short)
                                    }
                                    HStack {
                                        Spacer()
                                        Text("\(sitting.pair.short)\(scorecard.type.boardScoreType.suffix)")
                                    }
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
                                                    Spacer()
                                                    AnalysisSmallButton(label: "Show") {
                                                        if let newTraveller = travellers.first(where: { $0 == summary }) {
                                                            traveller = newTraveller
                                                            reflectSelectionChange(traveller: newTraveller)
                                                        }
                                                    }
                                                    .palette(.clear)
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
                                        .if(myTraveller == summary) { view in
                                            view.palette(.handPlayer, .contrast)
                                        }
                                        .if(handTraveller == summary && !(myTraveller == summary)) { view in
                                            view.palette(.alternate)
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
                                    if headToHead {
                                        LeadingText("Table")
                                    } else {
                                        AnalysisSmallButton(prefix: "chevron.backward.2", label: "Back") {
                                            summaryMode = true
                                        }
                                    }
                                    CenteredText("Contract")
                                    CenteredText("By")
                                    CenteredText("Lead")
                                    CenteredText("Made").gridColumnAlignment(.trailing)
                                    HStack {
                                        Spacer()
                                        Text(sitting.pair.short).gridColumnAlignment(.trailing)
                                    }
                                    HStack {
                                        Spacer()
                                        Text("\(sitting.pair.short)\(scorecard.type.boardScoreType.suffix)").gridColumnAlignment(.trailing).frame(width: 80)
                                    }
                                }
                                .foregroundColor(Palette.tile.text).bold()
                                .frame(height: 25)
                            }
                            ScrollView {
                                LazyVGrid(columns: detailColumns, spacing: 3) {
                                    ForEach(travellers.filter({headToHead || $0 == selectedSummary!}), id: \.self) { traveller in
                                        GridRow {
                                            if headToHead {
                                                LeadingText(traveller.rankingNumber == handTraveller.rankingNumber ? "This" : "Other")
                                            } else if traveller.rankingNumber != handTraveller.rankingNumber {
                                                HStack {
                                                    Spacer()
                                                    AnalysisSmallButton(label: "Show") {
                                                        self.traveller = traveller
                                                        reflectSelectionChange(traveller: traveller)
                                                    }
                                                    .palette(.clear)
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
                                        .foregroundColor(headToHead || traveller.made >= 0 ? Palette.background.text : Palette.background.faintText)
                                        .if(!headToHead && handTraveller.rankingNumber == traveller.rankingNumber && !(myTraveller.rankingNumber == traveller.rankingNumber)) { view in
                                            view.palette(.alternate)
                                        }
                                        .if(!headToHead && traveller.rankingNumber == myTraveller.rankingNumber) { view in
                                            view.palette(.handPlayer, .contrast)
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
        .onChange(of: traveller.rankingNumber, initial: false) {
            reflectSelectionChange(traveller: TravellerExtension(scorecard: scorecard, traveller: traveller))
        }
        .onChange(of: sitting, initial: false) {
            reflectChange()
        }
    }
    
    func reflectChange() {
        summaryMode = true
        travellers = buildTravellers(board: self.board, sitting: self.sitting)
        summary = buildSummary()
        myTraveller = TravellerExtension(scorecard: scorecard, traveller: traveller)
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
        let headToHead = (scorecard.type.players == 4 && travellers.count <= 2)
        return result.sorted(by: {headToHead ? ($0 == traveller) : TravellerExtension.sort($0, $1, sitting: sitting)})
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
        self.tricksMade = traveller.tricksMade
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
        hasher.combine(contract)
        hasher.combine(declarer)
        hasher.combine(made)
        hasher.combine(tricksMade)
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

struct BindCenteredText: View {
    @Binding var text: String
    
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

