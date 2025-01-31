//
//  New Scorecard View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 25/01/2022.
//

import SwiftUI

struct ScorecardDetailView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    private let id = scorecardDetailViewId
    @ObservedObject var scorecard: ScorecardViewModel
    @Binding var deleted: Bool
    @Binding var tableRefresh: Bool
    @State var title = "New Scorecard"
    @State private var canUndo = false
    @State private var canRedo = false
    @State var frame: CGRect
    @State var initialYOffset: CGFloat
    @State var yOffset: CGFloat = 0
    @Binding var dismissView: Bool
    @State private var inputType: Bool = false
    @State private var dismissTypeView: Bool = false
    @State var typeViewXOffset: CGFloat = 0
    @State var showResults: Bool = true
    @State var cancelButton: Bool = false
    let completion: (()->())?
    private let undoManagerObserver = NotificationCenter.default.publisher(for: .NSUndoManagerDidOpenUndoGroup)
    private let undoObserver = NotificationCenter.default.publisher(for: .NSUndoManagerDidRedoChange)
    private let redoObserver = NotificationCenter.default.publisher(for: .NSUndoManagerDidUndoChange)

    init(scorecard: ScorecardViewModel, deleted: Binding<Bool>, tableRefresh: Binding<Bool> = Binding.constant(false), title: String, frame: CGRect, initialYOffset: CGFloat? = nil, dismissView: Binding<Bool>, showResults: Bool = true, cancelButton: Bool = false, completion: (()->())? = nil) {
        self.scorecard = scorecard
        self.completion = completion
        _deleted = deleted
        _tableRefresh = tableRefresh
        _title = State(initialValue: title)
        _frame = State(initialValue: frame)
        let initialYOffset = initialYOffset ?? frame.minY
        _initialYOffset = State(initialValue: initialYOffset)
        _yOffset = State(initialValue: initialYOffset)
        _dismissView = dismissView
        _showResults = State(initialValue: showResults)
        _cancelButton = State(initialValue: cancelButton)
    }
    
    var body: some View {
        PopupStandardView("Detail", slideInId: id) {
            ZStack {
                VStack(spacing: 0) {
                    
                    let bannerOptions = UndoManager.undoBannerOptions(canUndo: $canUndo, canRedo: $canRedo) + cancelOption()
                    Banner(title: $title, alternateStyle: true, back: true, backText: cancelButton ? "Continue" : "Done", backAction: backAction, optionMode: .buttons, options: bannerOptions)
                    
                    ScrollView(showsIndicators: false) {
                        
                        ScorecardDetailsView(id: id, scorecard: scorecard, tableRefresh: $tableRefresh, inputType: $inputType, showResults: showResults)
                    }
                }
                .background(Palette.alternate.background)
                .cornerRadius(10)
                .undoManager(canUndo: $canUndo, canRedo: $canRedo)
                .keyboardAdaptive
                .onSwipe { (direction) in
                    if direction != .left {
                        if backAction() {
                            completion?()
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .onAppear {
                    withAnimation(.linear(duration: 0.25).delay(0.1)) {
                        yOffset = frame.minY
                    }
                }
                .onChange(of: dismissView) {
                    if dismissView == true {
                        dismissView = false
                        completion?()
                        withAnimation(.linear(duration: 0.25)) {
                            yOffset = initialYOffset
                        }
                        Utility.executeAfter(delay: 0.25) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                if inputType {
                    popoverView()
                }
            }
            .offset(x: frame.minX, y: yOffset)
            .frame(width: frame.width, height: frame.height)
            .interactiveDismissDisabled()
        }
    }
    
    func cancelOption() -> [BannerOption] {
        if cancelButton {
            return [BannerOption(text: "Cancel", likeBack: true, action: {
                Utility.mainThread {
                    if !scorecard.isNew {
                        scorecard.remove()
                    }
                    deleted = true
                    dismissView = true
                }
            })]
        } else {
            return []
        }
    }
    
    func backAction() -> Bool {
        deleted = false
        if scorecard.saveMessage != "" {
            MessageBox.shared.show(scorecard.saveMessage, cancelText: "Re-edit", okText: "Delete", okAction: {
                MessageBox.shared.show("This will delete the scorecard permanently.\nAre you sure you want to do this?", if: Scorecard.current.hasData, cancelText: "Re-edit", okText: "Delete", okDestructive: true, okAction: {
                    scorecard.remove()
                    UserDefault.currentUnsaved.set(false)
                    deleted = true
                    dismissView = true
                })
            })
            return false
        } else {
            scorecard.saveScorecard()
            dismissView = true
            return false
        }
    }
    
    private func popoverView() -> some View {
        ZStack {
            Palette.maskBackground
                .cornerRadius(8)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ScorecardTypeView(id: id, type: $scorecard.type, dismiss: $dismissTypeView) { (from, to) in
                        scorecard.objectWillChange.send()
                    }
                    Spacer()
                }
                Spacer()
            }
            .onChange(of: dismissTypeView, initial: false) {
                if dismissTypeView == true {
                    withAnimation(.linear(duration: 0.5)) {
                        inputType = false
                        dismissTypeView = false
                    }
                }
            }
        }
    }
}

struct ScorecardDetailsView: View {
    var id: UUID
    @ObservedObject var scorecard: ScorecardViewModel
    @Binding var tableRefresh: Bool
    @Binding var inputType: Bool
    
    @State private var locations: [LocationViewModel] = []
    @State private var locationIndex: Int?
    
    @State private var typeIndex: Int?
    
    @State private var manualTotalsIndex: Int? = 0

    @State private var players: [PlayerViewModel] = []
    @State private var playerIndex: Int?
    @State private var datePicker: Bool = false
    @State var showResults: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            
            InsetView {
                VStack(spacing: 0) {
                    
                    Input(title: "Description", field: $scorecard.desc, message: $scorecard.descMessage, topSpace: 0)
                    
                    Separator(thickness: 1)
                    
                    PickerInput(id: id, title: "Location", field: $locationIndex, values: {locations.map{$0.name}}, disabled: Scorecard.current.isImported)
                    { index in
                        if let index = index {
                            scorecard.location = locations[index]
                        }
                    }
                    
                    Separator(thickness: 1)
                    
                    if scorecard.type.players > 1 {
                        PickerInput(id: id, title: "Partner", field: $playerIndex, values: {players.map{$0.name}}, disabled: Scorecard.current.isImported)
                        { index in
                            if let index = index {
                                scorecard.partner = players[index]
                            }
                        }
                        
                        Separator(thickness: 1)
                    }
                    
                    DatePickerInput(title: "Date", field: $scorecard.date, to: Date(), textType: Scorecard.current.isImported ? .normal : .theme)
                        .disabled(Scorecard.current.isImported)
                }
            }
            
            if showResults {
                InsetView(title: "Results") {
                    VStack(spacing: 0) {
                        HStack {
                            InputFloat(title: scorecard.type.matchScoreType.title, field: $scorecard.score, width: 100, places: scorecard.type.matchPlaces, maxCharacters: 7)
                                .disabled(!scorecard.manualTotals || Scorecard.current.isImported)
                            
                            if scorecard.manualTotals && !Scorecard.current.isImported {
                                Text(" / ")
                                InputFloat(field: $scorecard.maxScore, width: 100, places: scorecard.type.matchPlaces, maxCharacters: 7)
                            } else {
                                Text(scorecard.type.matchSuffix(scorecard: scorecard))
                            }
                            
                            Spacer()
                        }
                        
                        Separator(thickness: 1)
                        
                        HStack {
                            
                            InputInt(title: "Position", field: $scorecard.position, width: 65, maxCharacters: 5)
                                .disabled(Scorecard.current.isImported)
                            
                            Text(" of ")
                            
                            InputInt(field: $scorecard.entry, leadingSpace: 0, width: 65, maxCharacters: 5, inlineTitle: false)
                                .disabled(Scorecard.current.isImported)
                            
                            Spacer()
                        }
                        
                        Separator(thickness: 1)
                        
                        Input(title: "Comments", field: $scorecard.comment)
                    }
                }
            }
            
            InsetView(title: "Options") {
                VStack(spacing: 0) {
                    
                    ScorecardTypePrompt(type: $scorecard.type) {
                        inputType = true
                    }
                    
                    Separator(thickness: 1)
                    
                    PickerInput(id: id, title: "Total calculation", field: $manualTotalsIndex, values: { TotalCalculation.allCases.map{$0.string}}, disabled: Scorecard.current.isImported)
                    { (index) in
                        if let index = index {
                            scorecard.manualTotals = (index == TotalCalculation.manual.rawValue)
                        }
                    }
                    
                    Separator(thickness: 1)
                    
                    StepperInputAdditional(title: "Boards per table", field: $scorecard.boardsTable, label: { value in "\(value) boards per table" }, isEnabled: !Scorecard.current.isImported, minValue: {1}, additionalBinding: $scorecard.boards, onChange: { (newValue) in
                        setBoards(boardsTable: newValue, sessions: scorecard.sessions)
                        tableRefresh = true
                    })
                    
                    Separator(thickness: 1)
                    
                        // Note this is inputting the number of boards even though prompting for tables
                    StepperInput(title: "Tables\(scorecard.sessions <= 1 ? "" : " per session")", field: $scorecard.boards, label: boardsLabel, isEnabled: !Scorecard.current.isImported, minValue: {scorecard.boardsTable * scorecard.sessions}, increment: {scorecard.boardsTable * scorecard.sessions}, onChange:  { (boards) in
                        tableRefresh = true
                    })
                    .disabled(Scorecard.current.isImported)
                    
                    Separator(thickness: 1)
                    
                    StepperInput(title: "Sessions\(scorecard.sessions <= 1 ? "" : " per session")", field: $scorecard.sessions, label: { value in "\(value) \(plural("session", value))" }, isEnabled: !Scorecard.current.isImported, minValue: {1}, maxValue: {8}, onChange: { (sessions) in
                            // Make sure total boards still makes sense
                        let tablesPerSession = (scorecard.boards / scorecard.boardsTable) / sessions
                        scorecard.boards = scorecard.boardsTable * max(1, tablesPerSession) * sessions
                        if sessions <= 1 {
                            scorecard.resetNumbers = false
                        } else if scorecard.sessions <= 1 {
                            scorecard.resetNumbers = true
                        }
                        tableRefresh = true
                    })
                    .disabled(Scorecard.current.isImported)
                    
                    Separator(thickness: 1)
                    
                    InputToggle(title: "Reset board number", field: $scorecard.resetNumbers, disabled: Binding.constant(scorecard.sessions <= 1), onChange:
                                    { (newValue) in
                        tableRefresh = true
                    })
                    .disabled(Scorecard.current.isImported)
                }
            }
            
            Spacer()
        }
        .background(Palette.alternate.background)
        .onAppear {
            players = MasterData.shared.players.filter({(!$0.retired || $0 == scorecard.partner!) && !$0.isSelf})
            locations = MasterData.shared.locations.filter({!$0.retired || $0 == scorecard.location!})
            locationIndex = locations.firstIndex(where: {$0 == scorecard.location}) ?? 0
            playerIndex = players.firstIndex(where: {$0 == scorecard.partner}) ?? 0
            manualTotalsIndex = (scorecard.manualTotals ? TotalCalculation.manual : TotalCalculation.automatic).rawValue
        }
    }
    
    func setBoards(boardsTable: Int, sessions: Int) {
        scorecard.boards = max(scorecard.boards, boardsTable * sessions)
        scorecard.boards = max(boardsTable * sessions, ((scorecard.boards / boardsTable) * boardsTable))
    }
    
    func boardsLabel(boards: Int) -> String {
        let tablesPerSession = (boards / max(1, scorecard.boardsTable) / max(1, scorecard.sessions))
        return "\(tablesPerSession) \(plural("table", tablesPerSession))\(scorecard.sessions <= 1 ? "" : " per session") - \(boards) \(plural("board", boards)) in total"
    }
    
    func plural(_ text: String, _ value: Int) -> String {
        return (value <= 1 ? text : text + "s")
    }
}

