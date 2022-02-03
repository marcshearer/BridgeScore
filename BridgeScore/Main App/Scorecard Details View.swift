//
//  New Scorecard View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 25/01/2022.
//

import SwiftUI

struct ScorecardDetailsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State var title = "New Scorecard"
    @Binding var scorecard: ScorecardViewModel
    @State var refresh = false
    @State var minValue = 1
    @State var linkToScorecard = false
    
    var locations = MasterData.shared.locations.compactMap { $0.value }.sorted(by: {$0.sequence < $1.sequence})
    @State private var locationIndex: Int = 0
    
    let types = Type.allCases
    @State private var typeIndex: Int = 0
    
    let players = MasterData.shared.players.compactMap { $0.value }.sorted(by: {$0.sequence < $1.sequence})
    @State private var playerIndex: Int = 0
    
    var body: some View {
        StandardView {
            VStack(spacing: 0) {
                
                // Just to trigger view refresh
                if refresh { EmptyView() }
                
                let bannerOptions = [ BannerOption(image: AnyView(Image(systemName: "chevron.right")), likeBack: true, action: {  linkToScorecard = true}) ]
                Banner(title: $scorecard.editTitle, back: true, backImage: AnyView(Image(systemName: "xmark")), backAction: backAction, optionMode: .buttons, options: bannerOptions)
                
                ScrollView(showsIndicators: false) {
                    
                    InsetView(content: { AnyView( VStack {
                        
                        PickerInput(title: "Location", field: $locationIndex, values: locations.map {$0.name})
                            { index in
                                scorecard.location = locations[index]
                            }
                        
                        PickerInput(title: "Partner", field: $playerIndex, values: players.map {$0.name})
                            { index in
                                scorecard.partner = players[index]
                            }
                        
                        DatePickerInput(title: "Date", field: $scorecard.date, to: Date())
                        
                        Input(title: "Description", field: $scorecard.desc, message: $scorecard.descMessage)
                        
                        Input(title: "Comments", field: $scorecard.comment, height: 100)
                        
                        Spacer().frame(height: 16)
                    })})
                    
                    InsetView(content: { AnyView( VStack {
                        
                        PickerInput(title: "Scoring Method", field: $typeIndex, values: types.map{$0.string})
                            { index in
                                scorecard.type = types[index]
                            }
                        
                        StepperInput(title: "Boards / Tables", field: $scorecard.boardsTable, label: { value in "\(value) boards per round" }, minValue: $minValue, width: 400) { (newValue) in
                            scorecard.boards = max(scorecard.boards, newValue)
                            scorecard.boards = max(newValue, ((scorecard.boards / newValue) * newValue))
                            scorecard.objectWillChange.send()
                            refresh.toggle()
                        }
                        
                        StepperInput(field: $scorecard.boards, label: boardsLabel, minValue: $scorecard.boardsTable, increment: $scorecard.boardsTable, topSpace: 0, width: 400)
                        
                        InputToggle(title: "Options", text: "Show table totals", field: $scorecard.tableTotal)
                        
                        Spacer().frame(height: 16)
                        
                    })})
                    
                    Spacer()
                }
            }
            .onChange(of: linkToScorecard) { (linkToScorecard) in
                if linkToScorecard {
                    scorecard.backupCurrent()
                }
            }
            .onAppear {
                locationIndex = locations.firstIndex(where: {$0 == scorecard.location}) ?? 0
                playerIndex = players.firstIndex(where: {$0 == scorecard.partner}) ?? 0
                typeIndex = types.firstIndex(where: {$0 == scorecard.type}) ?? 0
                if !scorecard.isNew {
                    title = scorecard.desc
                }
            }
            NavigationLink(destination: ScorecardView(scorecard: $scorecard), isActive: $linkToScorecard) {EmptyView()}
        }
    }
    
    func backAction() -> Bool {
        scorecard.save()
        return true
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
