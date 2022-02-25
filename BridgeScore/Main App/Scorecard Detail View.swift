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
    @State private var title = "New Scorecard"
    @State private var linkToCanvas = false
    @State private var linkToInput = false
    @State private var authenticatedScorecard: ScorecardViewModel?
    
    var body: some View {
        StandardView {
            VStack(spacing: 0) {
                
                let bannerOptions = [
                    BannerOption(image: AnyView(Image(systemName: "rectangle.split.3x3")), likeBack: true, action: {linkAction(toCanvas: false) }),
                    BannerOption(image: AnyView(Image(systemName: "square.and.pencil").rotationEffect(Angle.init(degrees: 90))), likeBack: true, action: {linkAction(toCanvas: true)})]
                Banner(title: $scorecard.editTitle, back: true, backAction: backAction, optionMode: .buttons, options: bannerOptions)
                
                ScrollView(showsIndicators: false) {
                    
                    ScorecardDetailsView(scorecard: scorecard)
                }
            }
            .keyboardAdaptive
            .onChange(of: linkToCanvas) { (linkToCanvas) in
                if linkToCanvas {
                    scorecard.backupCurrent()
                }
            }
            .onChange(of: linkToInput) { (linkToInput) in
                if linkToInput {
                    scorecard.backupCurrent()
                }
            }
            .onAppear {
                if !scorecard.isNew {
                    title = scorecard.desc
                }
            }
            NavigationLink(destination: ScorecardInputView(scorecard: scorecard), isActive: $linkToInput) {EmptyView()}
            NavigationLink(destination: ScorecardCanvasView(scorecard: scorecard), isActive: $linkToCanvas) {EmptyView()}
        }
    }
    
    func linkAction(toCanvas: Bool) {
        func link() {
            if toCanvas {
                linkToCanvas = true
            } else {
                linkToInput = true
            }
        }
        
        if scorecard == authenticatedScorecard || (toCanvas ? scorecard.noDrawing : !Scorecard.current.isSensitive) {
            link()
        } else {
            LocalAuthentication.authenticate(reason: "You must authenticate to access the scorecard detail") {
                authenticatedScorecard = scorecard
                link()
            } failure: {
                authenticatedScorecard = nil
            }
        }
    }
    
    func backAction() -> Bool {
        if scorecard.saveMessage != "" {
            MessageBox.shared.show(scorecard.saveMessage, cancelText: "Re-edit", okText: "Delete", okAction: {
                if !scorecard.isNew {
                    scorecard.remove()
                }
                UserDefault.currentUnsaved.set(false)
                presentationMode.wrappedValue.dismiss()
            })
            return false
        } else {
            if let master = MasterData.shared.scorecard(id: scorecard.scorecardId) {
                master.copy(from: scorecard)
                master.save()
            } else {
                let master = ScorecardViewModel()
                master.copy(from: scorecard)
                master.insert()
            }
            Scorecard.current.clear()
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
    
    let players = MasterData.shared.players
    @State private var playerIndex: Int = 0
    
    var body: some View {
        
        VStack {
            
            InsetView {
                VStack {
                    
                    PickerInput(title: "Location", field: $locationIndex, values: {locations.filter{!$0.retired || $0 == scorecard.location}.map{$0.name}})
                    { index in
                        scorecard.location = locations[index]
                    }
                    
                    PickerInput(title: "Partner", field: $playerIndex, values: {players.filter{!$0.retired || $0 == scorecard.partner}.map{$0.name}})
                    { index in
                        scorecard.partner = players[index]
                    }
                    
                    DatePickerInput(title: "Date", field: $scorecard.date, to: Date())
                    
                    Input(title: "Description", field: $scorecard.desc, message: $scorecard.descMessage)
                    
                    Input(title: "Comments", field: $scorecard.comment, height: 100)
                    
                    HStack {
                        InputFloat(title: "Score", field: $scorecard.score, width: 100, places: scorecard.type.matchPlaces)
                            .disabled(scorecard.type.matchAggregate != .manual)
                        Spacer()
                    }
                    
                    InputTitle(title: " Position")
                    HStack {
                        
                        InputInt(field: $scorecard.position, topSpace: 0, width: 60)
                        
                        Text(" of ")
                        
                        InputInt(field: $scorecard.entry, topSpace: 0, leadingSpace: 0, width: 60)
                        
                        Spacer()
                    }
                    
                    Spacer().frame(height: 16)
                }
            }
            
            InsetView {
                VStack {
                    
                    PickerInput(title: "Scoring Method", field: $typeIndex, values: {types.map{$0.string}})
                    { index in
                        if scorecard.type != types[index] {
                            scorecard.type = types[index]
                            updateScores()
                        }
                    }
                    
                    StepperInput(title: "Boards / Tables", field: $scorecard.boardsTable, label: { value in "\(value) boards per round" }, minValue: $minValue, labelWidth: 300) { (newValue) in
                        scorecard.boards = max(scorecard.boards, newValue)
                        scorecard.boards = max(newValue, ((scorecard.boards / newValue) * newValue))
                    }
                    
                    StepperInput(field: $scorecard.boards, label: boardsLabel, minValue: $scorecard.boardsTable, increment: $scorecard.boardsTable, topSpace: 0, labelWidth: 300)
                    
                    InputToggle(title: "Options", text: "Board numbers per table", field: $scorecard.resetNumbers)
                    
                    Spacer().frame(height: 16)
                    
                }
            }
            
            Spacer()
        }
        .onAppear {
            locationIndex = locations.firstIndex(where: {$0 == scorecard.location}) ?? 0
            playerIndex = players.firstIndex(where: {$0 == scorecard.partner}) ?? 0
            typeIndex = types.firstIndex(where: {$0 == scorecard.type}) ?? 0
            updateScores()
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
    
    func updateScores() {
        
        for tableNumber in 1...scorecard.tables {
            if Scorecard.updateTableScore(scorecard: scorecard, tableNumber: tableNumber) {
                Scorecard.current.tables[tableNumber]?.save()
            }
        }
        Scorecard.updateTotalScore(scorecard: scorecard)
    }
}
