//
//  Layout Setup View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 04/02/2022.
//

import Foundation
import SwiftUI

struct LayoutSetupView: View {
    
    private let id = layoutSetupViewId
    @StateObject var selected = LayoutViewModel()
    @State private var title = "Templates"
    @State private var canUndo = false
    @State private var canRedo = false
    
    var body: some View {
        StandardView("Layout", slideInId: id) {
            VStack(spacing: 0) {
                
                Banner(title: $title, bottomSpace: false, back: true, backEnabled: { return selected.canSave }, optionMode: .buttons, options: UndoManager.undoBannerOptions(canUndo: $canUndo, canRedo: $canRedo))
                DoubleColumnView(leftWidth: 350) {
                    LayoutSelectionView(selected: selected, changeSelected: changeSelection, removeSelected: removeSelection, addLayout: addLayout)
                } rightView: {
                    LayoutDetailView(id: id, selected: selected)
                }
            }
            .undoManager(canUndo: $canUndo, canRedo: $canRedo)
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
        UndoManager.clearActions()
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
        
        VStack(spacing: 0) {
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
                        .cornerRadius(10)
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
                .listStyle(.inset)
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
    var id: UUID
    @ObservedObject var selected: LayoutViewModel
    
    @State private var locations: [LocationViewModel] = []
    @State private var locationIndex: Int?
    
    let types = ScorecardType.allCases
    @State private var typeIndex: Int?
    
    let days = RegularDay.allCases
    @State private var dayIndex: Int?
    
    @State private var manualTotalsIndex: Int? = 0

    @State private var players: [PlayerViewModel] = []
    @State private var playerIndex: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(spacing: 0) {
                    InsetView(title: "Main Details") {
                        VStack(spacing: 0) {
                            
                            Input(title: "Description", field: $selected.desc, message: $selected.descMessage, inlineTitleWidth: 200)
                            
                            Separator()
                            
                            PickerInput(id: id, title: "Location", field: $locationIndex, values: {locations.map{$0.name}}, inlineTitleWidth: 200)
                            { index in
                                if let index = index {
                                    selected.location = locations[index]
                                }
                            }
                            
                            Separator()
                            
                            if selected.type.players > 1 {
                                PickerInput(id: id, title: "Partner", field: $playerIndex, values: {players.map{$0.name}}, inlineTitleWidth: 200)
                                { index in
                                    if let index = index {
                                        selected.partner = players[index]
                                    }
                                }
                                
                                Separator()
                            }
                            
                            PickerInput(id: id, title: "Regular day", field: $dayIndex, values: {days.map{$0.string}}, inlineTitleWidth: 200)
                            { index in
                                if let index = index {
                                    selected.regularDay = days[index]
                                }
                            }
                            
                            Separator()
                            
                            Input(title: "Default description", field: $selected.scorecardDesc, inlineTitleWidth: 200)
                            
                        }
                    }
                    
                    InsetView(title: "Options") {
                        VStack(spacing: 0) {
                            
                            PickerInput(id: id, title: "Scoring Method", field: $typeIndex, values: {types.map{$0.string}}, inlineTitleWidth: 200)
                            { index in
                                if let index = index {
                                    selected.type = types[index]
                                }
                            }

                            Separator()

                            PickerInput(id: id, title: "Total calculation", field: $manualTotalsIndex, values: { TotalCalculation.allCases.map{$0.string}}, inlineTitleWidth: 200)
                            { (index) in
                                if let index = index {
                                    selected.manualTotals = (index == TotalCalculation.manual.rawValue)
                                }
                            }
                            
                            Separator()
                            
                            StepperInputAdditional(title: "Boards per table", field: $selected.boardsTable, label: { value in "\(value) boards per table" }, inlineTitleWidth: 200, additionalBinding: $selected.boardsTable, onChange: { (newValue) in
                                setBoards(boardsTable: newValue)
                                 })

                            Separator()
                            
                            // Note this is inputting the number of boards even though prompting for tables
                            StepperInput(title: "Tables\(selected.sessions <= 1 ? "" : " per session")", field: $selected.boards, label: boardsLabel, minValue: {selected.boardsTable}, increment: {selected.boardsTable * selected.sessions}, inlineTitleWidth: 200)
                            
                            Separator()
                            
                            StepperInput(title: "Sessions", field: $selected.sessions, label: { value in "\(value) \(plural("session", value))" }, maxValue: {8}, inlineTitleWidth: 200, onChange: { (sessions) in
                                // Make sure total boards still makes sense
                                let tablesPerSession = (selected.boards / selected.boardsTable) / sessions
                                selected.boards = selected.boardsTable * max(1, tablesPerSession) * sessions
                                if sessions <= 1 {
                                    selected.resetNumbers = false
                                } else if selected.sessions <= 1 {
                                    selected.resetNumbers = true
                                }
                            })
                            
                            Separator()
                            
                            InputToggle(title: "Reset board numbers", field: $selected.resetNumbers, disabled: Binding.constant(selected.sessions <= 1), inlineTitleWidth: 200)
                            
                        }
                    }
                    
                    Spacer()
                }
                .onChange(of: selected.layoutId, initial: true) { (_, layoutId) in
                    setIndexes()
                }
            }
            Spacer()
        }
        .background(Palette.alternate.background)
    }
    
    func setIndexes() {
        players = MasterData.shared.players.filter({(!$0.retired || $0 == selected.partner!) && !$0.isSelf})
        locations = MasterData.shared.locations.filter({!$0.retired || $0 == selected.location!})
        locationIndex = locations.firstIndex(where: {$0 == selected.location}) ?? 0
        playerIndex = players.firstIndex(where: {$0 == selected.partner}) ?? 0
        typeIndex = types.firstIndex(where: {$0 == selected.type}) ?? 0
        dayIndex = days.firstIndex(where: {$0 == selected.regularDay}) ?? 0
        manualTotalsIndex = (selected.manualTotals ? TotalCalculation.manual : TotalCalculation.automatic).rawValue

    }
    
    func setBoards(boardsTable: Int) {
        selected.boards = max(selected.boards, boardsTable)
        selected.boards = max(boardsTable, ((selected.boards / boardsTable) * boardsTable))
    }
    
    func boardsLabel(boards: Int) -> String {
        let tablesPerSession = (boards / max(1, selected.boardsTable) / max(1, selected.sessions))
        return "\(tablesPerSession) \(plural("table", tablesPerSession))\(selected.sessions <= 1 ? "" : " per session") - \(boards) \(plural("board", boards)) in total"
    }
    
    func plural(_ text: String, _ value: Int) -> String {
        return (value <= 1 ? text : text + "s")
    }
}

