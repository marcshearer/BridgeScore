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
    private let undoManagerObserver = NotificationCenter.default.publisher(for: .NSUndoManagerDidOpenUndoGroup)
    private let undoObserver = NotificationCenter.default.publisher(for: .NSUndoManagerDidRedoChange)
    private let redoObserver = NotificationCenter.default.publisher(for: .NSUndoManagerDidUndoChange)

    var body: some View {
        StandardView("Detail", slideInId: id) {
            VStack(spacing: 0) {
                
                Banner(title: $title, alternateStyle: true, back: true, backText: "Done", backAction: backAction, optionMode: .buttons, options: UndoManager.undoBannerOptions(canUndo: $canUndo, canRedo: $canRedo))
                
                ScrollView(showsIndicators: false) {
                    
                    ScorecardDetailsView(id: id, scorecard: scorecard, tableRefresh: $tableRefresh)
                }
                .background(Palette.alternate.background)
            }
            .undoManager(canUndo: $canUndo, canRedo: $canRedo)
            .keyboardAdaptive
            .onSwipe { (direction) in
                if direction != .left {
                    if backAction() {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
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
                    presentationMode.wrappedValue.dismiss()
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
            return true
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
                                        
                    Separator()
                    
                    PickerInput(id: id, title: "Location", field: $locationIndex, values: {locations.map{$0.name}})
                    { index in
                        if let index = index {
                            scorecard.location = locations[index]
                        }
                    }
                    
                    Separator()
                    
                    if scorecard.type.players > 1 {
                        PickerInput(id: id, title: "Partner", field: $playerIndex, values: {players.map{$0.name}})
                        { index in
                            if let index = index {
                                scorecard.partner = players[index]
                            }
                        }
                        .disabled(Scorecard.current.isImported)
                        
                        Separator()
                    }
                    
                    DatePickerInput(title: "Date", field: $scorecard.date, to: Date())
                        .disabled(Scorecard.current.isImported)
                }
            }
                 
            InsetView(title: "Results") {
                VStack(spacing: 0) {
                    HStack {
                        InputFloat(title: scorecard.type.matchScoreType.string, field: $scorecard.score, width: 60, places: scorecard.type.matchPlaces)
                            .disabled(!scorecard.manualTotals || Scorecard.current.isImported)
                        
                        if scorecard.manualTotals && !Scorecard.current.isImported {
                            Text(" / ")
                            InputFloat(field: $scorecard.maxScore, width: 60, places: scorecard.type.matchPlaces)
                        } else {
                            Text(scorecard.type.matchSuffix(scorecard: scorecard))
                        }
                        
                        Spacer()
                    }
                    
                    Separator()
                    
                    HStack {
                        
                        InputInt(title: "Position", field: $scorecard.position, width: 40)
                            .disabled(Scorecard.current.isImported)
                        
                        Text(" of ")
                        
                        InputInt(field: $scorecard.entry, topSpace: 0, leadingSpace: 0, width: 40, inlineTitle: false)
                            .disabled(Scorecard.current.isImported)
                        
                        Spacer()
                    }
                    
                    Separator()
                
                    Input(title: "Comments", field: $scorecard.comment)
                }
            }
            
            InsetView(title: "Options") {
                VStack(spacing: 0) {
                    
                    PickerInputAdditional(id: id, title: "Scoring", field: $typeIndex, values: {types.map{$0.string}}, additionalBinding: $scorecard.score, onChange:
                    { (index) in
                        if let index = index {
                            if scorecard.type != types[index] {
                                scorecard.type = types[index]
                                Scorecard.updateScores(scorecard: scorecard)
                            }
                        }
                    })
                    .disabled(Scorecard.current.isImported)
                    
                    Separator()
                    
                    PickerInput(id: id, title: "Total calculation", field: $manualTotalsIndex, values: { TotalCalculation.allCases.map{$0.string}})
                    { (index) in
                        if let index = index {
                            scorecard.manualTotals = (index == TotalCalculation.manual.rawValue)
                        }
                    }
                    .disabled(Scorecard.current.isImported)
                    
                    Separator()
                    
                    StepperInputAdditional(title: "Boards", field: $scorecard.boardsTable, label: { value in "\(value) boards per round" }, minValue: $minValue, additionalBinding: $scorecard.boards, onChange: { (newValue) in
                            setBoards(boardsTable: newValue)
                            tableRefresh = true
                        })
                        .disabled(Scorecard.current.isImported)
                    
                    Separator()
                    
                    StepperInput(title: "Tables", field: $scorecard.boards, label: boardsLabel, minValue: $scorecard.boardsTable, increment: $scorecard.boardsTable) { (_) in
                        tableRefresh = true
                    }
                    .disabled(Scorecard.current.isImported)
                    
                    Separator()
                    
                    PickerInput(id: id, title: "Board Numbers", field: $resetBoardNumberIndex, values: { ResetBoardNumber.allCases.map{$0.string}})
                    { (index) in
                        scorecard.resetNumbers = (index == ResetBoardNumber.perTable.rawValue)
                        tableRefresh = true
                    }
                    .disabled(Scorecard.current.isImported)
                    
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

