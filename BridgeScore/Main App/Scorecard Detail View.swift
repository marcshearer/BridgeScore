//
//  New Scorecard View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 25/01/2022.
//

import SwiftUI

struct ScorecardDetailView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @ObservedObject var scorecard: ScorecardViewModel
    @Binding var deleted: Bool
    @State var title = "New Scorecard"
    
    var body: some View {
        StandardView {
            VStack(spacing: 0) {
                
                Banner(title: $title, alternateStyle: true, back: true, backText: "Done", backAction: backAction)
                
                ScrollView(showsIndicators: false) {
                    
                    ScorecardDetailsView(scorecard: scorecard)
                }
                .background(Palette.alternate.background)
            }
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
    @ObservedObject var scorecard: ScorecardViewModel
    @State var minValue = 1

    var locations = MasterData.shared.locations
    @State private var locationIndex: Int = 0
    
    let types = Type.allCases
    @State private var typeIndex: Int = 0
    
    @State private var resetBoardNumberIndex: Int = 0

    let players = MasterData.shared.players
    @State private var playerIndex: Int = 0
    @State private var datePicker: Bool = false
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            InsetView(title: "Main Details") {
                VStack(spacing: 0) {
                    
                    Input(title: "Description", field: $scorecard.desc, message: $scorecard.descMessage)
                                        
                    Separator()
                    
                    PickerInput(title: "Location", field: $locationIndex, values: {locations.filter{!$0.retired || $0 == scorecard.location}.map{$0.name}})
                    { index in
                        scorecard.location = locations[index]
                    }
                    
                    Separator()
                    
                    PickerInput(title: "Partner", field: $playerIndex, values: {players.filter{!$0.retired || $0 == scorecard.partner}.map{$0.name}})
                    { index in
                        scorecard.partner = players[index]
                    }
                    
                    Separator()
                    
                    DatePickerInput(title: "Date", field: $scorecard.date, to: Date())
                    
                }
            }
                 
            InsetView(title: "Results") {
                VStack(spacing: 0) {
                    HStack {
                        InputFloat(title: scorecard.type.matchScoreType.string, field: $scorecard.score, width: 100, places: scorecard.type.matchPlaces)
                            .disabled(scorecard.type.matchAggregate != .manual)
                        Spacer()
                    }
                    
                    Separator()
                    
                    HStack {
                        
                        InputInt(title: "Position", field: $scorecard.position, width: 40)
                        
                        Text(" of ")
                        
                        InputInt(field: $scorecard.entry, topSpace: 0, leadingSpace: 0, width: 40, inlineTitle: false)
                        
                        Spacer()
                    }
                    
                    Separator()
                
                    Input(title: "Comments", field: $scorecard.comment)
                }
            }
            
            InsetView(title: "Options") {
                VStack(spacing: 0) {
                    
                    PickerInput(title: "Scoring", field: $typeIndex, values: {types.map{$0.string}})
                    { (index) in
                        if scorecard.type != types[index] {
                            scorecard.type = types[index]
                            Scorecard.updateScores(scorecard: scorecard)
                        }
                    }
                    
                    StepperInput(title: "Boards", field: $scorecard.boardsTable, label: { value in "\(value) boards per round" }, minValue: $minValue) { (newValue) in
                        scorecard.boards = max(scorecard.boards, newValue)
                        scorecard.boards = max(newValue, ((scorecard.boards / newValue) * newValue))
                    }
                    
                    StepperInput(title: "Tables", field: $scorecard.boards, label: boardsLabel, minValue: $scorecard.boardsTable, increment: $scorecard.boardsTable)
                    
                    
                    PickerInput(title: "Board Numbers", field: $resetBoardNumberIndex, values: { ResetBoardNumber.allCases.map{$0.string}})
                    { (index) in
                        scorecard.resetNumbers = (index == ResetBoardNumber.perTable.rawValue)
                    }
                    
                    Spacer().frame(height: 16)
                    
                }
            }
            
            Spacer()
        }
        .background(Palette.alternate.background)
        .onAppear {
            locationIndex = locations.firstIndex(where: {$0 == scorecard.location}) ?? 0
            playerIndex = players.firstIndex(where: {$0 == scorecard.partner}) ?? 0
            typeIndex = types.firstIndex(where: {$0 == scorecard.type}) ?? 0
            resetBoardNumberIndex = (scorecard.resetNumbers ? ResetBoardNumber.perTable : ResetBoardNumber.continuous).rawValue
        }
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
