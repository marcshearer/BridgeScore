//
//  Insights Setup View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 02/05/2026.
//

import SwiftUI

struct InsightsSetupView : View {
    @ObservedObject var report: Report
    @State var data: BoardSummaryExtension?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer().frame(width: 100)
                InsightsChooseColumnsView(report: report, data: data)
                Spacer().frame(width: 100)
                InsightsSaveReportView(report: report)
                Spacer()
            }
        }
    }
}

struct InsightsChooseColumnsView : View {
    @ObservedObject var report: Report
    @State var data: BoardSummaryExtension?
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    Spacer()
                    Text("Drag columns to different sections")
                        .font(defaultFont)
                    Spacer()
                }
                .frame(width: 500)
                Spacer()
            }
            Spacer().frame(height: 40)
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    InsightsColumnListView(report: report, data: data, title: "Not Used", columns: report.availableColumns, listType: .availableColumns, allowDrag: true, specificDrop: false, onDropReceived: onDropReceived)
                    Spacer().frame(height: 40)
                    InsightsColumnListView(report: report, data: data, title: "Calculated", columns: $report.values.calculatedColumns, listType: .calculatedColumns, allowDrag: true, showEdit: true, showInsert: true, showRemove: true)
                    Spacer()
                }
                Spacer().frame(width: 100)
                VStack(spacing: 0) {
                    InsightsColumnListView(report: report, data: data, title: "Pinned", columns: $report.values.pinnedColumns, listType: .pinnedColumns, allowDrag: true, showRemove: true, specificDrop: true, height: 240, onDropReceived: onDropReceived)
                    Spacer().frame(height: 40)
                    InsightsColumnListView(report: report, data: data, title: "Not Pinned", columns: $report.values.unpinnedColumns, listType: .unpinnedColumns, allowDrag: true, showRemove: true, specificDrop: true, onDropReceived: onDropReceived)
                    Spacer()
                }
                Spacer()
            }
            Spacer().frame(height: 50)
            Spacer()
        }
    }
    
    func onDropReceived(target: ListType, dropped: [InsightsSetupTransfer], after: (InsightColumn)?) -> Bool {
        var result = false
        var beforeIndex: Int?
        if after == nil {
            beforeIndex = 0
        } else {
            if let index = report.columns(listType: target).firstIndex(where: {$0.name == after!.name}) {
                beforeIndex = index + 1
            }
        }
        
        if let beforeIndex = beforeIndex {
            for droppedTransfer in dropped.reversed() {
                if droppedTransfer.source.isColumns {
                    if target == droppedTransfer.source {
                        // Dropping in same list - move it
                        if beforeIndex != 0 && droppedTransfer.column!.name != after!.name {
                            // No need to do anything if moving in a non-specific list
                            if let currentIndex = report.columns(listType: target).firstIndex(where: {$0.name  == droppedTransfer.column!.name}) {
                                switch target {
                                case .availableColumns:
                                    break // No need to do anything - will recalculated when added to the other group
                                case .pinnedColumns:
                                    report.values.pinnedColumns.move(fromOffsets: IndexSet([currentIndex]), toOffset: beforeIndex)
                                case .unpinnedColumns:
                                    report.values.unpinnedColumns.move(fromOffsets: IndexSet([currentIndex]), toOffset: beforeIndex)
                                default:
                                    break
                                }
                            }
                        }
                    } else {
                        switch droppedTransfer.source {
                        case .availableColumns:
                            break
                            // No need to remove anything - will recalculated when added to the other group
                        case .pinnedColumns:
                            report.values.pinnedColumns.removeAll(where: {$0 == droppedTransfer.column})
                        case .unpinnedColumns:
                            report.values.unpinnedColumns.removeAll(where: {$0 == droppedTransfer.column})
                        default:
                            break
                        }
                        switch target {
                        case .availableColumns:
                            break // No need to do anything - will recalculated when added to the other group
                        case .pinnedColumns:
                            report.values.pinnedColumns.insert(droppedTransfer.column!, at: beforeIndex)
                        case .unpinnedColumns:
                            report.values.unpinnedColumns.insert(droppedTransfer.column!, at: beforeIndex)
                        default:
                            break
                        }
                        report.objectWillChange.send()
                        result = true
                    }
                }
            }
        }
        return result
    }
}

struct InsightsListView : View {
    var title: String
    var list: [String]
    var height: CGFloat? = nil
    var listType: ListType
    var allowDrag: Bool
    var allowSelect: Bool = true
    @State var selected: String? = nil
    var onClickArrow: ((CalculatedFunction) -> Void)? = nil
    
    var body : some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow {
                        HStack {
                            Spacer()
                            Text(title)
                                .frame(width: 200, height: 40)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .palette(.contrastTile)
                        
                    }
                    .frame(width: 200, height: 40)
                    
                    ScrollView {
                        VStack {
                            Spacer().frame(width: 200, height: 4)
                                .palette(.mutedTile)
                            ForEach(list, id: \.self) { element in
                                GridRow {
                                    VStack(spacing: 0) {
                                        HStack {
                                            Spacer()
                                            Text(element)
                                            Spacer()
                                        }
                                        .frame(width: 200, height: 24)
                                        .palette(selected == element ? .filterTile : .tile)
                                        .draggable(InsightsSetupTransfer(source: listType, function: CalculatedFunction(rawValue: element)!))
                                    }
                                }
                                .onTapGesture {
                                    if let onclickArrow = onClickArrow {
                                        onclickArrow(CalculatedFunction(rawValue: element)!)
                                    } else if allowSelect {
                                        selected = element
                                    }
                                }
                            }
                        }
                    }
                    .if(height != nil) { view in
                        view.frame(height: height! - 40)
                    }
                }
            }
            .palette(.mutedTile)
            .cornerRadius(8)
            .frame(width: 200)
        }
    }
}

enum InsightEditMode {
    case create
    case amend(index: Int)
    case delete(index: Int)
    case display(index: Int)
    
    var string: String {
        switch self {
        case .create: return "Create"
        case .amend: return "Amend"
        case .delete: return "Delete"
        case .display: return "Display"
        }
    }
}

struct InsightsColumnListView : View {
    @ObservedObject var report: Report
    @State var data: BoardSummaryExtension?
    var title: String
    @Binding var columns: [InsightColumn]
    var listType: ListType
    var allowSelect: Bool = true
    var allowDrag: Bool
    var showEdit: Bool = false
    var showInsert: Bool = false
    var showRemove: Bool = false
    var specificDrop: Bool = true
    var height: CGFloat? = nil
    var onSelect: ((InsightColumn) -> Void)? = nil
    var onDropReceived: ((_ target: ListType, _ droppedColumns: [InsightsSetupTransfer], _ before: (InsightColumn)?) -> Bool)?
    
    @State private var selected: InsightColumn? = nil
    @State private var showCalculatedColumn: Bool = false
    @State private var column = CalculatedColumn()
    @State private var editMode: InsightEditMode? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow {
                        HStack {
                            Spacer()
                            Text(title)
                                .frame(width: 200, height: 40)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .palette(.contrastTile)
                        
                    }
                    .frame(width: 200, height: 40)
                    
                    ScrollView {
                        VStack {
                            Spacer().frame(width: 200, height: 4)
                                .palette(.mutedTile)
                                .if(specificDrop && onDropReceived != nil) { view in
                                    view.dropDestination(for: InsightsSetupTransfer.self) { droppedColumns, _ in
                                        return onDropReceived!(listType, droppedColumns, nil)
                                    }
                                }
                            ForEach(0..<columns.count, id: \.self) { index in
                                let column = $columns[index]
                                GridRow {
                                    VStack(spacing: 0) {
                                        HStack {
                                            Spacer()
                                            Text(column.wrappedValue.title)
                                            Spacer()
                                        }
                                        .frame(width: 200, height: 24)
                                        .palette(selected == column.wrappedValue ? .filterTile : .tile)
                                        .draggable(InsightsSetupTransfer(source: listType, column: column.wrappedValue))
                                        .overlay(alignment: .top) {
                                            VStack(spacing: 0) {
                                                Spacer().frame(width: 200, height: 16)
                                                    .background(.clear)
                                                Spacer().frame(width: 200, height: 8)
                                                    .palette(.mutedTile)
                                            }
                                            .offset(y: 8)
                                            .if(specificDrop && onDropReceived != nil) { view in
                                                view.dropDestination(for: InsightsSetupTransfer.self) { droppedColumns, _ in
                                                    return onDropReceived!(listType, droppedColumns, column.wrappedValue)
                                                }
                                            }
                                        }
                                    }
                                }
                                .onTapGesture {
                                    if let onSelect = onSelect {
                                        onSelect(column.wrappedValue)
                                        selected = nil
                                    } else if allowSelect {
                                        selected = column.wrappedValue
                                    }
                                }
                            }
                        }
                    }
                    .if(height != nil) { view in
                        view.frame(height: height! - 40)
                    }
                }
                if showInsert || ((showRemove || showEdit) && selected != nil) {
                    Spacer()
                    HStack {
                        Spacer().frame(width: 20)
                        if showEdit {
                            Button {
                                switch selected {
                                case .calculated(column: let calculated):
                                    if let index = columns.firstIndex(where: { $0 == selected! }) {
                                        editMode = .amend(index: index)
                                        column = calculated
                                        showCalculatedColumn = true
                                    }
                                default:
                                    break
                                }
                            } label: {
                                Text("Edit")
                            }
                            .opacity(selected == nil ? 0.3 : 1)
                            .disabled(selected == nil)
                        }
                        if showInsert {
                            Button {
                                editMode = .create
                                column = CalculatedColumn()
                                showCalculatedColumn = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                        if showRemove {
                            Button {
                                columns.removeAll(where: {$0 == selected})
                            } label: {
                                Image(systemName: "minus")
                            }
                            .opacity(selected == nil ? 0.3 : 1)
                            .disabled(selected == nil)
                        }
                        Spacer()
                    }
                    .frame(height: 40)
                    .palette(.alternate)
                }

            }
            .if(!specificDrop && onDropReceived != nil) { view in
                view.dropDestination(for: InsightsSetupTransfer.self) { droppedColumns, _ in
                    return onDropReceived!(listType, droppedColumns, nil)
                }
            }
            .fullScreenCover(isPresented: $showCalculatedColumn) {
                FullScreenView(minWidth: 1600, minHeight: 1200) {
                    InsightsCalculatedColumnView(report: report, column: $column, data: data, editMode: editMode!)
                }
            }
            .palette(.mutedTile)
            .cornerRadius(8)
        }
        .frame(width: 200)
    }
}

enum ListType : Codable {
    case availableColumns
    case allColumns
    case pinnedColumns
    case unpinnedColumns
    case calculatedColumns
    case functions
    
    var isColumns: Bool { self != .functions }
}

struct InsightsSetupTransfer : Codable, Transferable {
    var source: ListType
    var column: InsightColumn?
    var function: CalculatedFunction?
    
    init(source: ListType, column: InsightColumn? = nil, calculatedColumn: CalculatedColumn? = nil, function: CalculatedFunction? = nil) {
        self.source = source
        if source == .calculatedColumns, let calculatedColumn {
            self.column = .calculated(column: calculatedColumn)
        } else {
            self.column = column
        }
        self.function = function
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: InsightsSetupTransfer.self, contentType: .data)
    }
}

fileprivate enum EditField {
    case description
    case logic
}

struct InsightsCalculatedColumnView : View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var report: Report
    @Binding var column: CalculatedColumn
    @State var data: BoardSummaryExtension?
    @State var editMode: InsightEditMode
    
    @State var errorMessage: String = ""
    @State var cursor: Int = 0
    @FocusState fileprivate var focused: EditField?
    @StateObject var editColumn = CalculatedColumn()
    @State var canSave: Bool = false
    @State var align: CalculatedAlignment = .right
    @State var resultType: CalculatedType?
    @State var notNumeric: Bool = true
    @State var showErrorMessage: Bool = false
    @State var referencedVariables: [CalculatedColumn] = []
    
    var body: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("\(editMode.string.capitalized) Calculated Value"), alternateColor: true)
            Spacer().frame(height: 60)
            HStack {
                Spacer().frame(width: 40)
                HStack(spacing: 0) {
                    Text("Description:")
                    Spacer()
                }
                .frame(width: 114)
                MyTextField(field: $editColumn.title, focused: $focused, focusValue: EditField.description, nextFocusValue: .logic, previousFocusValue: .logic, width: 800, height: 40, cornerRadius: 8, color: .alternate) { _ in
                    updateName()
                }
                Spacer()
            }
            Spacer().frame(height: 40)
            HStack {
                Spacer().frame(width: 40)
                HStack(spacing: 0) {
                    Text("Logic:")
                    Spacer()
                }
                .frame(width: 120)
                CalculatedValuesView(logic: $editColumn.logic, cursor: $cursor, focused: $focused, focusValue: .logic,  nextFocusValue: .description, previousFocusValue: .description, color: .alternate) {
                    updateLogic()
                }
                .cornerRadius(8)
                Spacer().frame(width: 100)
            }
            HStack {
                Spacer().frame(maxWidth: 100)
                VStack(spacing: 0) {
                    MiddleCentered(height: 60) { Image(systemName: "arrowshape.up").font(bannerFont) }
                    InsightsColumnListView(report: report, data: data, title: "Data columns", columns: report.allColumns, listType: .allColumns, allowDrag: true, onSelect: variableSelected)
                }
                .frame(width: 200)
                Spacer().frame(maxWidth: 60)
                VStack(spacing: 0) {
                    MiddleCentered(height: 60) { Image(systemName: "arrowshape.up").font(bannerFont) }
                    InsightsColumnListView(report: report, data: data, title: "Calculated columns", columns: $report.values.calculatedColumns, listType: .calculatedColumns, allowDrag: true, onSelect: variableSelected)
                }
                .frame(width: 200)
                Spacer().frame(maxWidth: 60)
                VStack(spacing: 0) {
                    MiddleCentered(height: 60) { Image(systemName: "arrowshape.up").font(bannerFont) }
                    InsightsListView(title:"Functions", list: CalculatedFunction.allCases.map{$0.string},listType: .functions, allowDrag: true, onClickArrow: functionSelected)
                }
                .frame(width: 200)
                Spacer().frame(width: 60)
                VStack {
                    Spacer().frame(height: 60)
                    HStack {
                        HStack {
                            Text("Result type:")
                            Spacer()
                        }
                        .frame(width: 120)
                        Text(resultType == nil ? editColumn.logic.isEmpty ?"No logic" : "Invalid" : resultType!.string)
                        if errorMessage != "" && !editColumn.logic.isEmpty {
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
                    Spacer().frame(height: 50)
                    HStack {
                        HStack {
                            Text("Alignment:")
                            Spacer()
                        }
                        .frame(width: 120)
                        Picker("Alignment", selection: $editColumn.align) {
                            ForEach(CalculatedAlignment.allCases, id: \.self) { align in
                                Text(align.string)
                                    .tag(align)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 240)
                        Spacer()
                    }
                    Spacer().frame(height: 50)
                    HStack {
                        HStack {
                            Text("Width:")
                            Spacer()
                        }
                        .frame(width: 120)
                        StepperInput(field: $editColumn.width, minValue: {50}, maxValue: {200}, increment: {10}, height: 30, width: 100, inlineTitle: false)
                            .frame(width: 140)
                        Spacer()
                    }
                    Spacer().frame(height: 50)
                    HStack {
                        HStack {
                            Text("Decimal places:")
                            Spacer()
                        }
                        .frame(width: 120)
                        StepperInput(field: $editColumn.decimalPlaces, isEnabled: !notNumeric, minValue: {0}, maxValue: {4}, increment: {1}, height: 30, width: 100, inlineTitle: false)
                            .frame(width: 140)
                        Spacer()
                    }
                    Spacer().frame(height: 50)
                    HStack {
                        HStack {
                            Text("Blank If:")
                            Spacer()
                        }
                        .frame(width: 120)
                        Picker("Blank If", selection: $editColumn.blankIf) {
                            ForEach(CalculatedBlankIf.allCases, id: \.self) { align in
                                Text(align.string)
                                    .tag(align)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(notNumeric)
                        .frame(width: 300)
                        Spacer()
                    }
                    HStack {
                        HStack {
                            Text("Percentage:")
                            Spacer()
                        }
                        .frame(width: 120)
                        InputToggle(field: $editColumn.percent, disabled: $notNumeric, width: 80, inlineTitle: false)
                        .frame(width: 80)
                        Spacer()
                    }
                    Spacer()
                }
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
                editColumn.copy(from: column)
                updateLogic()
                focused = .logic
            }
        }
    }
    
    func updateName() {
        let alpha = editColumn.title.filter({ $0.isLetter || $0.isNumber || $0 == " " })
        var words = alpha.split(separator: " ").map{ String($0.capitalized) }.filter({$0.trim() != ""})
        editColumn.name = (words.first ?? "").lowercased()
        if !words.isEmpty {
            words.removeFirst()
        }
        editColumn.name += words.joined(separator: "")
        
        let index = switch editMode {
        case .amend(let amendIndex):
            amendIndex
        default:
            -1
        }
        let names = report.values.calculatedColumns.compactMap { item -> String? in
            if case let .calculated(calculated) = item {
                return calculated.name
            }
            return nil
        }
        let duplicates = names.enumerated().count(where: { $1 == editColumn.name && $0 != index })
        Utility.mainThread {
            canSave = !editColumn.name.isEmpty && !editColumn.logic.isEmpty && duplicates == 0 && resultType != nil
        }
    }
    
    func updateLogic() {
        canSave = !editColumn.name.isEmpty && !editColumn.logic.isEmpty
        let parser = CalculatedParser(tokens: editColumn.logic)
        resultType = nil
        notNumeric = true
        errorMessage = ""
        parser.parse() { (tree, message) in
            if let message = message {
                errorMessage = message
            } else if let tree = tree {
                do {
                    resultType = try tree.type(variableType: variableType)
                    notNumeric = !resultType!.isNumeric
                } catch let error as CalculatedError {
                    errorMessage = error.errorDescription
                } catch {
                    errorMessage = "Unknown error: \(error)"
                }
                if resultType != nil {
                    // Traverse the tree looking for duplicates
                    referencedVariables = [editColumn]
                    do {
                        try tree.traverse(traverseCalculatedColumn)
                    } catch let error as CalculatedError {
                        errorMessage = error.errorDescription
                        resultType = nil
                    } catch {
                        errorMessage = "Unknown error: \(error)"
                        resultType = nil
                    }
                }
            }
        }
        Utility.mainThread {
            canSave = canSave && errorMessage.isEmpty
        }
    }
    
    func save() {
        updateName()
        switch editMode {
        case .create:
            report.values.calculatedColumns.append(.calculated(column: editColumn))
        case .amend:
            column.copy(from: editColumn)
            updateCalculatedColumns(in: report.values.pinnedColumns, listType: .pinnedColumns, from: editColumn)
            updateCalculatedColumns(in: report.values.unpinnedColumns, listType: .unpinnedColumns, from: editColumn)
        default:
            break
        }
        dismiss()
    }
    
    func updateCalculatedColumns(in targetColumns: [InsightColumn], listType: ListType, from sourceColumn: CalculatedColumn) {
        for (index, column) in targetColumns.enumerated() {
            switch column {
            case .calculated(column: let calculated):
                if calculated.id == sourceColumn.id {
                    switch listType {
                    case .pinnedColumns:
                        report.values.pinnedColumns[index] = .calculated(column: sourceColumn)
                    case .unpinnedColumns:
                        report.values.unpinnedColumns[index] = .calculated(column: sourceColumn)
                    default:
                        break
                    }
                }
            default:
                break
            }
        }
    }
    
    func variableSelected(selected: InsightColumn) {
        editColumn.logic.insert(.variable(selected), at: cursor)
        cursor += 1
        updateLogic()
        focused = .logic
        editColumn.objectWillChange.send()
        canSave = !editColumn.name.isEmpty && !editColumn.logic.isEmpty
    }
    
    func calculatedVariableSelected(selected: CalculatedColumn) {
        editColumn.logic.insert(.calculatedVariable(selected), at: cursor)
        cursor += 1
        updateLogic()
        focused = .logic
        canSave = !editColumn.name.isEmpty && !editColumn.logic.isEmpty
    }
    
    func functionSelected(selected: CalculatedFunction) {
        editColumn.logic.insert(contentsOf: [.function(selected), .bracket(.open), .bracket(.close)], at: cursor)
        cursor += 2
        updateLogic()
        focused = .logic
        canSave = !editColumn.name.isEmpty && !editColumn.logic.isEmpty
    }
    
    func variableType(variable: InsightColumn) throws -> CalculatedType? {
        return variable.type
    }
    
    func variableValue<ViewModel>(column: InsightColumn, viewModel: ViewModel) throws -> CalculatedValue? {
        do {
            if let data = data {
                return try column.value(viewModel: data)
            } else {
                return nil
            }
        } catch {
            return CalculatedValue("ERROR")
        }
    }
    
    func traverseCalculatedColumn(calculated: CalculatedColumn) throws {
        if referencedVariables.contains(where: { $0.name == calculated.name }) {
            throw CalculatedError.circularReference(calculated.title)
        } else {
            // Need to carry on going down in this variable's logic
            referencedVariables.append(calculated)
            try calculated.traverse(traverseCalculatedColumn)
        }
    }
}

struct MyTextField<Focus> : View where Focus: Hashable {
    @Binding var field: String
    @FocusState.Binding var focused: Focus?
    let focusValue: Focus
    var nextFocusValue: Focus? = nil
    var previousFocusValue: Focus? = nil
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = 8
    var color: ThemeBackgroundColorName = .input
    var keyboardType: UIKeyboardType = .default
    var autoCapitalize: TextInputAutocapitalization = .sentences
    var autoCorrect: Bool = true
    var onChange: ((String)->())?
    
    var body: some View {
        let binding = Binding<String>(
                get: { self.field },
                set: { newValue in
                    self.field = newValue
                    self.onChange?(newValue) // Triggers immediately on every key press
                }
            )
        
        MiddleCentered(horizontalPadding: 8, verticalPadding: 4) {
            TextField("", text: binding)
                .onChange(of: field) { oldValue, newValue in
                    onChange?(newValue)
                }
                .if(height != nil) { view in
                    view.frame(height: height! - 8)
                }
                .if(width != nil) { view in
                    view.frame(width: width! - 16)
                }
                .textFieldStyle(.plain)
                .background(.clear)
                .labelsHidden()
                .lineLimit(1)
                .focusEffectDisabled(true)
                .focusable(true)
                .focused($focused, equals: focusValue)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autoCapitalize)
                .disableAutocorrection(!autoCorrect)
                .onKeyPress{ keyPress in
                    let shift = keyPress.modifiers.contains(.shift)
                    if let nextFocusValue = nextFocusValue, (keyPress.key == .return || (keyPress.key == .tab && !shift)) {
                        // Move focus forward
                        focused = nextFocusValue
                        return .handled
                    } else if let previousFocusValue = previousFocusValue, (keyPress.key == .tab && shift) {
                        focused = previousFocusValue
                        return .handled
                    }
                    return .ignored
                }
        }
        .if(height != nil) { view in
            view.frame(height: height!)
        }
        .if(width != nil) { view in
            view.frame(width: width!)
        }
        .palette(color)
        .cornerRadius(cornerRadius)
    }
}

struct InsightsSaveReportView : View {
    @ObservedObject var report: Report
    
    var body: some View {
        HStack {
            Spacer().frame(width: 100)
            VStack {
                Spacer().frame(height: 100)
                Button("Save") {
                    InsightsSaveReportView.save(report: report)
                }
                Spacer().frame(height: 40)
                Button("Load") {
                    InsightsSaveReportView.load(report: report, from: "default")
                }
                Spacer()
            }
            Spacer()
        }
    }
    
    private static var storageURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let directory = paths[0].appendingPathComponent("InsightReport", isDirectory: true)
        
        // Create the folder if it doesn't exist
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
    
    static func save(report: Report) {
        let fileURL = storageURL.appendingPathComponent("default.json")
        do {
            let data = try JSONEncoder().encode(report.values)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Save failed: \(error)")
        }
    }
    
    static func load(report: Report, from: String) {
        let fileURL = storageURL.appendingPathComponent("\(from).json")
        do {
            let values = try JSONDecoder().decode(ReportValues.self, from: Data(contentsOf: fileURL))
            report.update(from: values)
        } catch {
            print("Load failed: \(error)")
        }
    }
}

struct InsightsSetupButton : View {
    @Environment(\.isEnabled) private var isEnabled
    var text: String
    var action: ()->()
    
    var body : some View {
        Button {
            action()
        } label: {
            MiddleCentered {
                Text(text)
            }
            .bold()
            .frame(width: 130, height: 40)
            .font(inputTitleFont)
            .palette(isEnabled ? .enabledButton : .disabledButton)
            .opacity(isEnabled ? 1 : 0.7)
            .cornerRadius(6)
        }
        .focusable(false)
    }
}
