//
//  Insights Sort Level View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 10/05/2026.
//

import SwiftUI

struct InsightsSortLevelsView : View {
    @ObservedObject var report: Report
    
    @State private var showSortLevel: ShowSortLevel? = nil
    @State private var sortLevel: CalculatedSortLevel = CalculatedSortLevel()
    @State var selected: CalculatedSortLevel? = nil
    @State private var refreshId = UUID()
    
    var body: some View {
        let levels = report.values.levels
        let bodyHeight: CGFloat = min(240, CGFloat(40 * report.values.levels.count))
        
        Top(padding: 40) {
            CenteredText("View Sort and Selection")
                .font(defaultFont)
            Spacer().frame(height: 40)
            ZStack {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Rectangle()
                            .palette(.contrastTile, inverse: true)
                            .frame(height: 40)
                        Rectangle()
                            .palette(.tile, inverse: true)
                            .frame(height: bodyHeight)
                        Rectangle()
                            .palette(.contrastTile, inverse: true)
                            .frame(height: 40)
                    }
                    .cornerRadius(8)
                    Spacer()
                }
                VStack(spacing: 0) {
                    gridRow(level: "Level", key: "Sort by", direction: "\(SortDirection.ascending.symbol)/\(SortDirection.descending.symbol)", subtotal: "Total", logic: "Selection Logic")
                        .palette(.contrastTile, clear: true)
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            ForEach(0..<levels.count, id: \.self) { index in
                                let level = levels[index]
                                gridRowValues(index: index, level: level)
                                    .id(refreshId)
                            }
                        }
                    }
                    .frame(height: bodyHeight)
                    HStack {
                        Spacer().frame(width: 20)
                        Button {
                            editSortLevel(selected!)
                        } label: {
                            Text("Edit")
                        }
                        .contentShape(Rectangle())
                        .opacity(selected == nil ? 0.3 : 1)
                        .disabled(selected == nil)
                        Button {
                            if let index = (selected == nil ? report.values.levels.count - 1 : report.values.levels.firstIndex(where: {$0 == selected!})) {
                                sortLevel = CalculatedSortLevel(isBoard: false)
                                showSortLevel = ShowSortLevel(index: index + 1, editMode: .create)
                            }
                        } label: {
                            Image(systemName: "plus")
                                .contentShape(Rectangle())
                        }
                        if selected != nil, !selected!.isBoard {
                            Button {
                                if let index = report.values.levels.firstIndex(where: {$0 == selected!}) {
                                    report.values.levels.remove(at: index)
                                    selected = nil
                                }
                            } label: {
                                Image(systemName: "minus")
                                    .contentShape(Rectangle())
                            }
                            .opacity(selected == nil ? 0.3 : 1)
                            .disabled(selected == nil)
                        }
                        Spacer()
                    }
                    .palette(.contrastTile, clear: true)
                    .frame(height: 40)
                    Spacer()
                }
            }
            .frame(height: bodyHeight + 80)
        }
        .fullScreenCover(item: $showSortLevel) { showSortLevel in
            FullScreenView(minWidth: 1600, minHeight: 1200) {
                InsightsSortLevelView(report: report, sortLevel: $sortLevel, index: showSortLevel.index, editMode: showSortLevel.editMode, selected: $selected)
                    .onDisappear {
                        refreshId = UUID()
                    }
            }
        }
    }
    
    func editSortLevel(_ column: CalculatedSortLevel) {
        if let index = report.values.levels.firstIndex(where: {$0 == column}) {
            sortLevel = report.values.levels[index]
            showSortLevel = ShowSortLevel(index: index, editMode: .amend(index: index))
        }
    }
    
    func gridRow(level: String, key: String = "", direction: String = "", subtotal: String = "", logic: String) -> some View {
        HStack(spacing: 0) {
            CenteredText(level).frame(width: 120)
            LeadingText(key).frame(width: 180)
            CenteredText(direction).frame(width: 60)
            CenteredText(subtotal).frame(width: 80)
            LeadingText(logic)
        }
        .contentShape(Rectangle())
        .frame(height: 40)
        .palette(.tile, clear: true)
    }
    
    func gridRowValues(index: Int, level: CalculatedSortLevel) -> some View {
        HStack(spacing: 0) {
            if level.isBoard {
                gridRow(level: "Board", key: "", direction: "", subtotal: "", logic: level.selectionLogicString)
            } else {
                gridRow(level: "Level \(index)", key: level.key?.title ?? "", direction: (level.key == nil ? "" : level.direction.symbol), subtotal: (level.key == nil ? "" : level.subtotal.asTick), logic: level.selectionLogicString)
            }
        }
        .palette(.tile, clear: true)
        .if(selected == level) { view in
            view.palette(.alternate)
        }
        .onTapGesture {
            selected = level
        }
        .onTapGesture(count: 2) {
            selected = level
            editSortLevel(level)
        }
    }
}

fileprivate struct ShowSortLevel: Identifiable {
    var id = UUID()
    var index: Int
    var editMode: InsightEditMode
}

struct InsightsSortLevelView : View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var report: Report
    @Binding var sortLevel: CalculatedSortLevel
    @State var index: Int
    @State var editMode: InsightEditMode
    @Binding var selected: CalculatedSortLevel?
    
    @State var errorMessage: String = ""
    @State var cursor: Int = 0
    @FocusState fileprivate var focused: EditField?
    @State var editSortLevel = CalculatedSortLevel()
    @State var resultType: CalculatedType?
    @State var showErrorMessage: Bool = false
    @State var selectedListType: ListType? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("\(editMode.string.capitalized) \(sortLevel.isBoard ? "Board Selection" : "Sort Level \(index)")"), alternateColor: true)
            Spacer().frame(height: 40)
            if !editSortLevel.isBoard {
                HStack {
                    Spacer().frame(width: 40)
                    HStack(spacing: 0) {
                        Text("Sort column:")
                        Spacer()
                    }
                    .frame(width: 200)
                    HStack {
                        Spacer().frame(width: 8)
                        Text(editSortLevel.key?.title ?? "")
                            .focusable()
                            .focused($focused, equals: .sortKey)
                        Spacer()
                    }
                    .frame(width: 200, height: 40)
                    .palette(.alternate)
                    .cornerRadius(8)
                    .dropDestination(for: InsightsSetupTransfer.self) { droppedColumns, _ in
                        return onDropReceived(dropped: droppedColumns)
                    }
                    Spacer()
                }
                Spacer().frame(height: 30)
                HStack {
                    Spacer().frame(width: 40)
                    HStack {
                        Text("Sort Direction:")
                        Spacer()
                    }
                    .frame(width: 200)
                    Picker("Sort Direction", selection: $editSortLevel.direction) {
                        ForEach(SortDirection.allCases, id: \.self) { align in
                            Text(align.string)
                                .tag(align)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                    Spacer()
                }
                Spacer().frame(height: 30)
                HStack {
                    Spacer().frame(width: 40)
                    HStack {
                        Text("Sub-total:")
                        Spacer()
                    }
                    .frame(width: 200)
                    InputToggle(field: $editSortLevel.subtotal, disabled: Binding.constant(false), width: 80, inlineTitle: false) { _ in
                        if !editSortLevel.subtotal {
                            editSortLevel.selectionLogic = []
                            updateLogic()
                        }
                    }
                        .frame(width: 40)
                    Spacer()
                }
                Spacer().frame(height: 15)
            }
            HStack {
                Spacer().frame(width: 40)
                HStack(spacing: 0) {
                    Text("\(sortLevel.isBoard ? "Board" : "Subtotal") selection logic:")
                    Spacer()
                }
                .frame(width: 200)
                CalculatedValuesView(logic: $editSortLevel.selectionLogic, cursor: $cursor, focused: $focused, focusValue: .selectionLogic,  nextFocusValue: .sortKey, previousFocusValue: .sortKey, color: .alternate) {
                    updateLogic()
                }
                .disabled(!editSortLevel.subtotal)
                .opacity(editSortLevel.subtotal ? 1 : 0.3)
                HStack {
                    Spacer().frame(width: 20)
                    if editSortLevel.isBoard {
                        Text(resultType == nil ? (editSortLevel.selectionLogic.isEmpty ? "No logic" : "Invalid logic") : (resultType == .boolean ? "Correct" : "Invalid - Must be a boolean result"))
                    } else {
                        Text(resultType == nil ? (editSortLevel.selectionLogic.isEmpty ? "Correct" : "Invalid logic") : (resultType == .boolean ? "Correct" : "Invalid - Must be a boolean result"))
                    }
                    if errorMessage != "" && !editSortLevel.selectionLogic.isEmpty {
                        Spacer().frame(width: 20)
                        Button("􀁝")
                        {
                            showErrorMessage = true
                        }
                        .font(inputFont)
                        .foregroundColor(Palette.background.themeText)
                        .popover(isPresented: $showErrorMessage) {
                            HStack {
                                Spacer().frame(width: 50)
                                Text(errorMessage)
                                Spacer().frame(width: 50)
                            }
                        }
                    }
                    Spacer()
                }
                .frame(width: 300)
                .cornerRadius(8)
                Spacer().frame(width: 40)
            }
            HStack {
                Spacer().frame(maxWidth: 100)
                VStack(spacing: 0) {
                    MiddleCentered(height: 60) { Image(systemName: "arrowshape.up").font(bannerFont) }
                    InsightsColumnListView(report: report, title: "Data columns", columns: report.allColumns, listType: .allColumns, allowDrag: true, selectedListType: $selectedListType, onSelect: variableSelected)
                }
                .frame(width: 200)
                Spacer().frame(maxWidth: 60)
                VStack(spacing: 0) {
                    MiddleCentered(height: 60) { Image(systemName: "arrowshape.up").font(bannerFont) }
                    InsightsColumnListView(report: report, title: "Calculated columns", columns: $report.values.calculatedColumns, listType: .calculatedColumns, allowDrag: true, selectedListType: $selectedListType, onSelect: variableSelected)
                }
                .frame(width: 200)
                Spacer().frame(maxWidth: 60)
                VStack(spacing: 0) {
                    MiddleCentered(height: 60) { Image(systemName: "arrowshape.up").font(bannerFont) }
                    InsightsListView(title:"Functions", list: CalculatedFunction.allCases.map{$0.string}, listType: .functions, allowDrag: true, selectedListType: $selectedListType, onSelect: functionSelected)
                }
                .frame(width: 200)
                Spacer()
            }
            Spacer().frame(height: 40)
            HStack {
                Spacer()
                InsightsSetupButton(text: "Cancel") {
                    Utility.mainThread {
                        dismiss()
                    }
                }
                Spacer().frame(width: 100)
                InsightsSetupButton(text: "Save") {
                    Utility.mainThread {
                        save()
                    }
                }
                .disabled(!canSave)
                Spacer()
            }
            Spacer().frame(height: 40)
        }
        .focusable(false)
        .task {
            Utility.mainThread {
                editSortLevel.copy(from: sortLevel)
                updateLogic()
                focused = .selectionLogic
            }
        }
    }
    
    func onDropReceived(dropped: [InsightsSetupTransfer]) -> Bool {
        var result = false
        if let dropped = dropped.first {
            if dropped.source.isColumns {
                editSortLevel.key = dropped.column
                updateLogic()
                result = true
            }
        }
        return result
    }
    
    func updateLogic() {
        let parser = CalculatedParser(report: report, tokens: editSortLevel.selectionLogic)
        resultType = nil
        errorMessage = ""
        parser.parse() { (tree, message) in
            if let message = message {
                errorMessage = message
            } else if let tree = tree {
                do {
                    resultType = try tree.type(variableType: variableType)
                } catch let error as CalculatedError {
                    errorMessage = error.errorDescription
                } catch {
                    errorMessage = "Unknown error: \(error)"
                }
            }
        }
    }
    
    func save() {
        report.objectWillChange.send()
        switch editMode {
        case .create:
            sortLevel.copy(from: editSortLevel)
            report.values.levels.insert(sortLevel, at: index)
            selected = sortLevel
        case .amend(let index):
            sortLevel.copy(from: editSortLevel)
            report.values.levels[index].copy(from: sortLevel)
            selected = sortLevel
        default:
            break
        }
        dismiss()
    }
    
    var canSave: Bool {
        if editSortLevel.isBoard {
            !editSortLevel.selectionLogic.isEmpty && resultType == .boolean
        } else {
            (editSortLevel.selectionLogic.isEmpty || resultType == .boolean) && editSortLevel.key != nil
        }
    }
    
    func variableSelected(selected: InsightColumn) {
        if editSortLevel.subtotal {
            editSortLevel.selectionLogic.insert(.variable(selected), at: cursor)
            cursor += 1
            updateLogic()
            focused = .selectionLogic
        }
    }
    
    func calculatedVariableSelected(selected: CalculatedColumn) {
        if editSortLevel.subtotal {
            editSortLevel.selectionLogic.insert(.calculatedVariable(selected), at: cursor)
            cursor += 1
            updateLogic()
            focused = .selectionLogic
        }
    }
    
    func functionSelected(selected: CalculatedFunction) {
        if editSortLevel.subtotal {
            editSortLevel.selectionLogic.insert(contentsOf: [.function(selected), .bracket(.open), .bracket(.close)], at: cursor)
            cursor += 2
            updateLogic()
            focused = .selectionLogic
        }
    }
    
    func variableType(variable: InsightColumn) throws -> CalculatedType? {
        return variable.type
    }
}

fileprivate enum EditField {
    case sortKey
    case selectionLogic
}
