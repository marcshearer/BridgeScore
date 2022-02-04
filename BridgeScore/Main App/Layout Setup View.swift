//
//  Layout Setup View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 04/02/2022.
//

import SwiftUI

struct LayoutSetupView: View {
    @State private var title = "Layouts"
    @State var selected = LayoutViewModel()
    
    var body: some View {
        StandardView() {
            VStack(spacing: 0) {
                Banner(title: $title, bottomSpace: false, back: true)
                DoubleColumnView {
                    LayoutSelectionView(update: update)
                        .environmentObject(selected)
                } rightView: {
                    LayoutDetailView()
                        .environmentObject(selected)
                }
            }
        }
        .onAppear {
            selected = MasterData.shared.layouts.compactMap{$0.value}.sorted(by: {$0.sequence < $1.sequence}).first!
        }
    }
    
    func update(to: LayoutViewModel) {
        selected = to
    }
}

struct LayoutSelectionView : View {
    @State var update: (LayoutViewModel)->()
    
    @EnvironmentObject var selected: LayoutViewModel
    
    var body: some View {
        let disabled = !selected.canSave
        
        VStack {
            HStack {
                LazyVStack {
                    ForEach(MasterData.shared.layouts.compactMap{$0.value}.sorted(by: {$0.sequence < $1.sequence})) { layout in
                        
                        let thisSelected = (selected == layout)
                        let color = (thisSelected ? Palette.tile : Palette.background)
                        VStack {
                            Spacer().frame(height: 16)
                            HStack {
                                Spacer().frame(width: 40)
                                Text((layout.desc == "" ? "<Blank>" : layout.desc))
                                    .font(.title)
                                Spacer()
                            }
                            Spacer().frame(height: 16)
                            Separator()
                        }
                        .background(Rectangle().fill(color.background))
                        .foregroundColor(color.text.opacity(disabled ? 0.3 : 1.0))
                        .onTapGesture {
                            update(layout)
                        }
                    }
                }
                Spacer()
            }
            Spacer()
        }
        .disabled(disabled)
        .background(Palette.background.background)
    }
}

struct LayoutDetailView : View {
    @EnvironmentObject var selected: LayoutViewModel
    
    @State var minValue = 1
    
    var locations = MasterData.shared.locations.compactMap { $0.value }.sorted(by: {$0.sequence < $1.sequence})
    @State private var locationIndex: Int = 0
    
    let types = Type.allCases
    @State private var typeIndex: Int = 0
    
    let players = MasterData.shared.players.compactMap { $0.value }.sorted(by: {$0.sequence < $1.sequence})
    @State private var playerIndex: Int = 0
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    
                    InsetView(content: { AnyView( VStack {
                        
                        Input(title: "Description", field: $selected.desc, message: $selected.descMessage)
                        
                        PickerInput(title: "Location", field: $locationIndex, values: locations.map {$0.name})
                        { index in
                            selected.location = locations[index]
                        }
                        
                        PickerInput(title: "Partner", field: $playerIndex, values: players.map {$0.name})
                        { index in
                            selected.partner = players[index]
                        }
                        
                        Input(title: "Default scorecard description", field: $selected.scorecardDesc)
                        
                        Spacer().frame(height: 16)
                    })})
                    
                    InsetView(content: { AnyView( VStack {
                        
                        PickerInput(title: "Scoring Method", field: $typeIndex, values: types.map{$0.string})
                        { index in
                            selected.type = types[index]
                        }
                        
                        StepperInput(title: "Boards / Tables", field: $selected.boardsTable, label: { value in "\(value) boards per round" }, minValue: $minValue, width: 400) { (newValue) in
                            selected.boards = max(selected.boards, newValue)
                            selected.boards = max(newValue, ((selected.boards / newValue) * newValue))
                        }
                        
                        StepperInput(field: $selected.boards, label: boardsLabel, minValue: $selected.boardsTable, increment: $selected.boardsTable, topSpace: 0, width: 400)
                        
                        InputToggle(title: "Options", text: "Show table totals", field: $selected.tableTotal)
                        
                        Spacer().frame(height: 16)
                        
                    })})
                    
                    Spacer()
                }
                .onChange(of: selected) { (layout) in
                    locationIndex = locations.firstIndex(where: {$0 == layout.location}) ?? 0
                    playerIndex = players.firstIndex(where: {$0 == layout.partner}) ?? 0
                    typeIndex = types.firstIndex(where: {$0 == layout.type}) ?? 0
                }
            }
            Spacer()
        }
        .background(Palette.background.background)
    }
    
    func boardsLabel(boards: Int) -> String {
        let tables = boards / max(1, selected.boardsTable)
        return "\(tables) \(plural("table", tables)) - \(boards) \(plural("board", boards)) in total"
    }
    
    func plural(_ text: String, _ value: Int) -> String {
        return (value <= 1 ? text : text + "s")
    }
}

struct DoubleColumnView <LeftContent, RightContent> : View where LeftContent : View, RightContent : View {
    var leftView: LeftContent
    var rightView: RightContent
    var leftWidth: CGFloat = 300
    
    init(@ViewBuilder leftView: ()->LeftContent, @ViewBuilder rightView: ()->RightContent) {
        self.leftView = leftView()
        self.rightView = rightView()
    }
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                leftView
                Spacer()
            }
            .frame(width: leftWidth)
            Divider()
            VStack {
                rightView
                Spacer()
            }
            Spacer()
        }
    }
}

