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
    @State var awaitingSelection = true
    @State private var title = "Templates"
    @State private var canUndo = false
    @State private var canRedo = false
    
    var body: some View {
        StandardView("Layout", slideInId: id) {
            VStack(spacing: 0) {
                
                Banner(title: $title, bottomSpace: false, back: true, backEnabled: { return selected.canSave }, optionMode: .buttons, options: UndoManager.undoBannerOptions(canUndo: $canUndo, canRedo: $canRedo))
                DoubleColumnView(leftWidth: 350, separator: true) {
                    LayoutSelectionView(selected: selected, awaitingSelection: $awaitingSelection, changeSelected: changeSelected, removeSelected: removeSelection, addLayout: addLayout)
                } rightView: {
                    LayoutDetailView(id: id, selected: selected, awaitingSelection: $awaitingSelection)
                }
            }
            .undoManager(canUndo: $canUndo, canRedo: $canRedo)
        }
        .keyboardAdaptive
        .onAppear {
            // selected.copy(from: MasterData.shared.layouts.first!)
        }
        .onDisappear {
            save(layout: selected)
        }
    }
    
    func changeSelected(newLayout: LayoutViewModel) {
        if !awaitingSelection {
            save(layout: selected)
        }
        selected.copy(from: newLayout)
        awaitingSelection = false
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
    
    @Binding var awaitingSelection: Bool
    @State var changeSelected: (LayoutViewModel)->()
    @State var removeSelected: (LayoutViewModel)->()
    @State var addLayout: ()->()

    var body: some View {
        let disabled = !awaitingSelection && !selected.canSave
        
        VStack(spacing: 0) {
            let layouts = MasterData.shared.layouts
            HStack {
                List {
                    ForEach(layouts) { layout in
                        
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
            Separator(direction: .horizontal, thickness: 2.0, color: Palette.banner.background)
            ToolbarView(canAdd: {selected.canSave}, canRemove: {selected.isNew || MasterData.shared.layouts.count > 1}, addAction: addLayout, removeAction: { removeSelected(selected)})
        }
        .background(Palette.background.background)
    }
}


struct LayoutDetailView : View {
    var id: UUID
    @ObservedObject var selected: LayoutViewModel
    @Binding var awaitingSelection: Bool
    
    @State private var locations: [LocationViewModel] = []
    @State private var locationIndex: Int?
    
    let types: [ScorecardType] = []
    @State private var typeIndex: Int?
    
    let days = RegularDay.allCases
    @State private var dayIndex: Int?
    
    @State private var manualTotalsIndex: Int? = 0

    @State private var players: [PlayerViewModel] = []
    @State private var playerIndex: Int?
    
    @State private var inputType: Bool = false
    @State private var dismissTypeView: Bool = false
    @State var typeViewXOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    VStack(spacing: 0) {
                        if awaitingSelection {
                            HStack {
                                Spacer()
                                VStack {
                                    Spacer()
                                    Text("Nothing selected")
                                        .font(bannerFont)
                                        .foregroundColor(Palette.background.faintText)
                                    Spacer()
                                }
                                Spacer()
                            }
                            
                        } else {
                            
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
                                    
                                    Input(title: "Default description", field: $selected.scorecardDesc, topSpace: 8, inlineTitleWidth: 200)
                                    
                                    Separator()
                                   
                                    InputToggle(title: "Show details on create", field: $selected.displayDetail, disabled: Binding.constant(false), inlineTitleWidth: 200)
                                 
                                }
                            }
                             
                            InsetView(title: "Event Options") {
                                VStack(spacing: 0) {
                                 
                                    ScorecardTypePrompt(type: $selected.type, inLineTitleWidth: 200) {
                                        inputType = true
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
                                    
                                    StepperInput(title: "Sessions", field: $selected.sessions, label: { value in "\(value) \(plural("session", value))" }, minValue: {1}, maxValue: {8}, inlineTitleWidth: 200, onChange: { (sessions) in
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
                        }
                        Spacer()
                    }
                    .onChange(of: selected.layoutId, initial: false) { (_, layoutId) in
                        setIndexes()
                    }
                }
                Spacer()
            }
            .ignoresSafeArea()
            .background(Palette.alternate.background)
            if inputType {
                popoverView()
            }
        }
    }
    
    private func popoverView() -> some View {
        ZStack {
            Palette.maskBackground
                .ignoresSafeArea()
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ScorecardTypeView(id: id, type: $selected.type, dismiss: $dismissTypeView) { (from, to) in
                        selected.objectWillChange.send()
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
        var boards = max(selected.boards, boardsTable)
        boards = max(boardsTable, ((boards / boardsTable) * boardsTable))
        if boards != selected.boards {
            selected.boards = boards
        }
    }
    
    
    func boardsLabel(boards: Int) -> String {
        let tablesPerSession = (boards / max(1, selected.boardsTable) / max(1, selected.sessions))
        return "\(tablesPerSession) \(plural("table", tablesPerSession))\(selected.sessions <= 1 ? "" : " per session") - \(boards) \(plural("board", boards)) in total"
    }
    
    func plural(_ text: String, _ value: Int) -> String {
        return (value <= 1 ? text : text + "s")
    }
}

