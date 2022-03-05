//
//  Layout Setup View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 04/02/2022.
//

import SwiftUI

struct LayoutSetupView: View {
    @StateObject var selected = LayoutViewModel()
    @State private var title = "Standard Layouts"
        
    var body: some View {
        StandardView("Layout") {
            VStack(spacing: 0) {
                Banner(title: $title, bottomSpace: false, back: true, backEnabled: { return selected.canSave })
                DoubleColumnView(leftWidth: 350) {
                    LayoutSelectionView(selected: selected, changeSelected: changeSelection, removeSelected: removeSelection, addLayout: addLayout)
                } rightView: {
                    LayoutDetailView(selected: selected)
                }
            }
        }
        .keyboardAdaptive
        .onAppear {
            selected.copy(from: MasterData.shared.layouts.first!)
        }
        .onDisappear {
            save(layout: selected)
        }
    }
    
    func changeSelection(newLayout: LayoutViewModel) {
        save(layout: selected)
        selected.copy(from: newLayout)
    }
    
    func removeSelection(removeLayout: LayoutViewModel) {
        func remove() {
            if let master = MasterData.shared.layout(id: removeLayout.layoutId) {
                MasterData.shared.remove(layout: master)
            }
            selected.copy(from: MasterData.shared.layouts.first!)
        }
        
        if selected.isNew {
            remove()
        } else {
            MessageBox.shared.show("This will delete the layout permanently. Are you sure you want to do this?", cancelText: "Cancel", okText: "Delete", okAction: {
                remove()
            })
        }
    }

    func addLayout() {
        save(layout: selected)
        selected.copy(from: LayoutViewModel())
        selected.location = MasterData.shared.locations.first!
        selected.partner = MasterData.shared.players.first!
        selected.sequence = MasterData.shared.layouts.last!.sequence + 1
    }
    
    func save(layout: LayoutViewModel) {
        if let master = MasterData.shared.layout(id: layout.layoutId) {
            master.copy(from: layout)
            MasterData.shared.save(layout: master)
        } else {
            let master = LayoutViewModel()
            master.copy(from: layout)
            MasterData.shared.insert(layout: master)
        }
    }
}

struct LayoutSelectionView : View {
    @ObservedObject var selected: LayoutViewModel
    @State var changeSelected: (LayoutViewModel)->()
    @State var removeSelected: (LayoutViewModel)->()
    @State var addLayout: ()->()

    var body: some View {
        let disabled = !selected.canSave
        
        VStack {
            HStack {
                List {
                    ForEach(MasterData.shared.layouts) { layout in
                        
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
                        }
                        .background(Rectangle().fill(color.background))
                        .foregroundColor(color.text.opacity(disabled ? 0.3 : 1.0))
                        .onDrag({layout.itemProvider})
                        .onTapGesture {
                            changeSelected(layout)
                        }
                    }
                    .onMove { (indexSet, toIndex) in
                        MasterData.shared.move(layouts: indexSet, to: toIndex)
                        selected.sequence = MasterData.shared.layout(id: selected.layoutId)?.sequence ?? selected.sequence
                    }
                }
                .listStyle(.plain)
                Spacer()
            }
            .disabled(disabled)
            Spacer()
            ToolbarView(canAdd: {selected.canSave}, canRemove: {selected.isNew || MasterData.shared.layouts.count > 1}, addAction: addLayout, removeAction: { removeSelected(selected)})
        }
        .background(Palette.background.background)
    }
}


struct LayoutDetailView : View {
    @ObservedObject var selected: LayoutViewModel
    
    @State var minValue = 1
    
    var locations = MasterData.shared.locations
    @State private var locationIndex: Int = 0
    
    let types = Type.allCases
    @State private var typeIndex: Int = 0
    
    @State private var resetBoardNumberIndex: Int = 0
    
    @State private var players = MasterData.shared.players
    @State private var playerIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(spacing: 0) {
                    InsetView(title: "Main Details") {
                        VStack(spacing: 0) {
                            
                            Input(title: "Description", field: $selected.desc, message: $selected.descMessage, inlineTitleWidth: 200)
                            
                            Separator()
                            
                            PickerInput(title: "Location", field: $locationIndex, values: {locations.filter{!$0.retired || $0 == selected.location}.map{$0.name}}, inlineTitleWidth: 200)
                            { index in
                                selected.location = locations[index]
                            }
                            
                            Separator()
                            
                            PickerInput(title: "Partner", field: $playerIndex, values: {players.filter{!$0.retired || $0 == selected.partner}.map{$0.name}}, inlineTitleWidth: 200)
                            { index in
                                selected.partner = players[index]
                            }
                            
                            Separator()
                            
                            Input(title: "Default description", field: $selected.scorecardDesc, inlineTitleWidth: 200)
                            
                        }
                    }
                    
                    InsetView(title: "Options") {
                        VStack(spacing: 0) {
                            
                            PickerInput(title: "Scoring Method", field: $typeIndex, values: {types.map{$0.string}}, inlineTitleWidth: 200)
                            { index in
                                selected.type = types[index]
                            }
                            
                            Separator()
                            
                            StepperInputAdditional(title: "Boards", field: $selected.boardsTable, label: { value in "\(value) boards per round" }, minValue: $minValue, inlineTitleWidth: 200, additionalBinding: $selected.boardsTable, onChange: { (newValue) in
                                    selected.boards = max(selected.boards, newValue)
                                    selected.boards = max(newValue, ((selected.boards / newValue) * newValue))
                                 })

                            Separator()
                            
                            StepperInput(title: "Tables", field: $selected.boards, label: boardsLabel, minValue: $selected.boardsTable, increment: $selected.boardsTable, inlineTitleWidth: 200)
                            
                            Separator()
                            
                            PickerInput(title: "Board Numbers", field: $resetBoardNumberIndex, values: { ResetBoardNumber.allCases.map{$0.string}}, inlineTitleWidth: 200)
                            { (index) in
                                selected.resetNumbers = (index == ResetBoardNumber.perTable.rawValue)
                            }
                            
                            
                        }
                    }
                    
                    Spacer()
                }
                .onChange(of: selected.layoutId) { (layoutId) in
                    locationIndex = locations.firstIndex(where: {$0 == selected.location}) ?? 0
                    playerIndex = players.firstIndex(where: {$0 == selected.partner}) ?? 0
                    typeIndex = types.firstIndex(where: {$0 == selected.type}) ?? 0
                    resetBoardNumberIndex = (selected.resetNumbers ? ResetBoardNumber.perTable : ResetBoardNumber.continuous).rawValue
                    
                }
            }
            Spacer()
        }
        .background(Palette.alternate.background)
    }
    
    func boardsLabel(boards: Int) -> String {
        let tables = boards / max(1, selected.boardsTable)
        return "\(tables) \(plural("table", tables)) - \(boards) \(plural("board", boards)) in total"
    }
    
    func plural(_ text: String, _ value: Int) -> String {
        return (value <= 1 ? text : text + "s")
    }
}

