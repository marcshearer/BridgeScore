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
    private let undoManagerObserver = NotificationCenter.default.publisher(for: .NSUndoManagerDidOpenUndoGroup)
    private let undoObserver = NotificationCenter.default.publisher(for: .NSUndoManagerDidRedoChange)
    private let redoObserver = NotificationCenter.default.publisher(for: .NSUndoManagerDidUndoChange)

    init(scorecard: ScorecardViewModel, deleted: Binding<Bool>, tableRefresh: Binding<Bool>, title: String, frame: CGRect, initialYOffset: CGFloat, dismissView: Binding<Bool>) {
        self.scorecard = scorecard
        _deleted = deleted
        _tableRefresh = tableRefresh
        _title = State(initialValue: title)
        _frame = State(initialValue: frame)
        _initialYOffset = State(initialValue: initialYOffset)
        _yOffset = State(initialValue: initialYOffset)
        _dismissView = dismissView
    }
    
    var body: some View {
        PopupStandardView("Detail", slideInId: id) {
            VStack(spacing: 0) {
                
                Banner(title: $title, alternateStyle: true, back: true, backText: "Done", backAction: backAction, optionMode: .buttons, options: UndoManager.undoBannerOptions(canUndo: $canUndo, canRedo: $canRedo))
                
                ScrollView(showsIndicators: false) {
                    
                    ScorecardDetailsView(id: id, scorecard: scorecard, tableRefresh: $tableRefresh)
                }
            }
            .background(Palette.alternate.background)
            .cornerRadius(10)
            .undoManager(canUndo: $canUndo, canRedo: $canRedo)
            .keyboardAdaptive
            .onSwipe { (direction) in
                if direction != .left {
                    if backAction() {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .offset(x: frame.minX, y: yOffset)
            .onAppear {
                withAnimation(.linear(duration: 0.25).delay(0.1)) {
                    yOffset = frame.minY
                }
            }
            .onChange(of: dismissView) {
                if dismissView == true {
                    dismissView = false
                    withAnimation(.linear(duration: 0.25)) {
                        yOffset = initialYOffset
                    }
                    Utility.executeAfter(delay: 0.25) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .frame(width: frame.width, height: frame.height)
        }
        .interactiveDismissDisabled()
    }
    
    func backAction() -> Bool {
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
            Scorecard.current.addNew()
            if let master = MasterData.shared.scorecard(id: scorecard.scorecardId) {
                master.copy(from: scorecard)
                master.save()
                scorecard.copy(from: master)
            } else {
                let master = ScorecardViewModel()
                master.copy(from: scorecard)
                master.insert()
                scorecard.copy(from: master)
            }
            dismissView = true
            return false
        }
    }
}

struct ScorecardDetailsView: View {
    var id: UUID
    @ObservedObject var scorecard: ScorecardViewModel
    @Binding var tableRefresh: Bool
    @State var minValue = 1

    @State private var locations: [LocationViewModel] = []
    @State private var locationIndex: Int?
    
    let types = Type.allCases
    @State private var typeIndex: Int?
    
    @State private var resetBoardNumberIndex: Int?
    @State private var manualTotalsIndex: Int? = 0

    @State private var players: [PlayerViewModel] = []
    @State private var playerIndex: Int?
    @State private var datePicker: Bool = false
    
    var body: some View {
        
        VStack(spacing: 0) {
                    
            InsetView {
                VStack(spacing: 0) {
                    
                    Input(title: "Description", field: $scorecard.desc, message: $scorecard.descMessage)
                                        
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
                 
            InsetView(title: "Results") {
                VStack(spacing: 0) {
                    HStack {
                        InputFloat(title: scorecard.type.matchScoreType.string, field: $scorecard.score, width: 100, places: scorecard.type.matchPlaces, maxCharacters: 7)
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
            
            InsetView(title: "Options") {
                VStack(spacing: 0) {
                    
                    PickerInputAdditional(id: id, title: "Scoring", field: $typeIndex, values: {types.map{$0.string}}, disabled: Scorecard.current.isImported, additionalBinding: $scorecard.score, onChange:
                    { (index) in
                        if let index = index {
                            if scorecard.type != types[index] {
                                scorecard.type = types[index]
                                Scorecard.updateScores(scorecard: scorecard)
                            }
                        }
                    })
                    
                    Separator(thickness: 1)

                    PickerInput(id: id, title: "Total calculation", field: $manualTotalsIndex, values: { TotalCalculation.allCases.map{$0.string}}, disabled: Scorecard.current.isImported)
                    { (index) in
                        if let index = index {
                            scorecard.manualTotals = (index == TotalCalculation.manual.rawValue)
                        }
                    }
                    
                    Separator(thickness: 1)

                    StepperInputAdditional(title: "Boards", field: $scorecard.boardsTable, label: { value in "\(value) boards per round" }, isEnabled: !Scorecard.current.isImported, minValue: $minValue, additionalBinding: $scorecard.boards, onChange: { (newValue) in
                            setBoards(boardsTable: newValue)
                            tableRefresh = true
                        })
                    
                    Separator(thickness: 1)

                    StepperInput(title: "Tables", field: $scorecard.boards, label: boardsLabel, isEnabled: !Scorecard.current.isImported, minValue: $scorecard.boardsTable, increment: $scorecard.boardsTable, onChange:  { (newValue) in
                        tableRefresh = true
                    })
                    .disabled(Scorecard.current.isImported)
                    
                    Separator(thickness: 1)

                    PickerInput(id: id, title: "Board Numbers", field: $resetBoardNumberIndex, values: { ResetBoardNumber.allCases.map{$0.string}}, disabled: Scorecard.current.isImported)
                    { (index) in
                        scorecard.resetNumbers = (index == ResetBoardNumber.perTable.rawValue)
                        tableRefresh = true
                    }
                    
                    Spacer().frame(height: 16)
                    
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
            typeIndex = types.firstIndex(where: {$0 == scorecard.type}) ?? 0
            resetBoardNumberIndex = (scorecard.resetNumbers ? ResetBoardNumber.perTable : ResetBoardNumber.continuous).rawValue
            manualTotalsIndex = (scorecard.manualTotals ? TotalCalculation.manual : TotalCalculation.automatic).rawValue
        }
    }
    
    func setBoards(boardsTable: Int) {
        scorecard.boards = max(scorecard.boards, boardsTable)
        scorecard.boards = max(boardsTable, ((scorecard.boards / boardsTable) * boardsTable))
    }
    
    func boardsTableLabel(boardsTable: Int) -> String {
        return "\(boardsTable) \(plural("board", boardsTable)) per table"
    }
    
    func boardsLabel(boards: Int) -> String {
         let tables = boards / max(1, scorecard.boardsTable)
        return "\(tables) \(plural("table", tables)) - \(boards) \(plural("board", boards)) in total"
    }
    
    func plural(_ text: String, _ value: Int) -> String {
        return (value <= 1 ? text : text + "s")
    }
}

