//
//  New Scorecard View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 25/01/2022.
//

import SwiftUI

struct ScorecardDetailView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State private var title = "New Scorecard"
    @Binding var scorecard: ScorecardViewModel
    @State private var linkToScorecard = false
    
    var body: some View {
        StandardView {
            VStack(spacing: 0) {
                
                let bannerOptions = [ BannerOption(image: AnyView(Image(systemName: "square.and.pencil").rotationEffect(Angle.init(degrees: 90))), likeBack: true, action: {  linkToScorecard = true})]
                Banner(title: $scorecard.editTitle, back: true, backImage: AnyView(Image(systemName: "xmark")), backAction: backAction, optionMode: .buttons, options: bannerOptions)
                
                ScrollView(showsIndicators: false) {
                    
                    ScorecardDetailsView(scorecard: scorecard)
                }
            }
            .keyboardAdaptive
            .onChange(of: linkToScorecard) { (linkToScorecard) in
                if linkToScorecard {
                    scorecard.backupCurrent()
                }
            }
            .onAppear {
                if !scorecard.isNew {
                    title = scorecard.desc
                }
            }
            NavigationLink(destination: ScorecardView(scorecard: $scorecard), isActive: $linkToScorecard) {EmptyView()}
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
            scorecard.save()
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
            
            InsetView(content: { AnyView( VStack {
                
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
                    Input(title: "Score", field: $scorecard.totalScore, width: 100, clearText: false)
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
            })})
            
            InsetView(content: { AnyView( VStack {
                
                PickerInput(title: "Scoring Method", field: $typeIndex, values: {types.map{$0.string}})
                { index in
                    scorecard.type = types[index]
                }
                
                StepperInput(title: "Boards / Tables", field: $scorecard.boardsTable, label: { value in "\(value) boards per round" }, minValue: $minValue, labelWidth: 300) { (newValue) in
                    scorecard.boards = max(scorecard.boards, newValue)
                    scorecard.boards = max(newValue, ((scorecard.boards / newValue) * newValue))
                }
                
                StepperInput(field: $scorecard.boards, label: boardsLabel, minValue: $scorecard.boardsTable, increment: $scorecard.boardsTable, topSpace: 0, labelWidth: 300)
                
                InputToggle(title: "Options", text: "Show table totals", field: $scorecard.tableTotal)
                
                Spacer().frame(height: 16)
                
            })})
            
            Spacer()
        }
        .onAppear {
            locationIndex = locations.firstIndex(where: {$0 == scorecard.location}) ?? 0
            playerIndex = players.firstIndex(where: {$0 == scorecard.partner}) ?? 0
            typeIndex = types.firstIndex(where: {$0 == scorecard.type}) ?? 0
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
