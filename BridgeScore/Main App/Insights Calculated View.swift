//
//  Insights Calculated View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 10/05/2026.
//

import SwiftUI

struct InsightsCalculatedColumnView : View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var report: Report
    @Binding var column: CalculatedColumn
    @State var data: BoardSummaryExtension?
    @State var editMode: InsightEditMode
    @State var duplicateMessage: String = ""
    @State var errorMessage: String = ""
    @State var cursor: Int = 0
    @FocusState fileprivate var focused: EditField?
    @StateObject var editColumn = CalculatedColumn()
    @State var canSave: Bool = true
    @State var align: CalculatedAlignment = .right
    @State var resultType: CalculatedType?
    @State var notNumeric: Bool = true
    @State var showErrorMessage: Bool = false
    @State var showDuplicateMessage: Bool = false
    @State var referencedVariables: [CalculatedColumn] = []
    @State var selectedListType: ListType? = nil
    var calculatedColumns: Binding<[InsightColumn]> { Binding( // Need to exclude this column
        get: {
            report.values.calculatedColumns.filter({ matchColumn in
            if case .calculated(let calculated) = matchColumn {
                return calculated != column
            } else {
                return false
            }
        })},
        set: { _ in  }
    )}
    
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
                    checkTitle()
                }
                Spacer().frame(width: 20)
                Text(duplicateMessage)
                    .foregroundColor(Palette.background.strongText)
                if duplicateMessage != "" {
                    Spacer().frame(width: 20)
                    Button("􀁝")
                    {
                        showDuplicateMessage = true
                    }
                    .font(inputFont)
                    .foregroundColor(Palette.background.themeText)
                    .popover(isPresented: $showDuplicateMessage) {
                        HStack {
                            Spacer().frame(width: 50)
                            Text("Name is created by stripping spaces from the description")
                            Spacer().frame(width: 50)
                        }
                    }
                }
                Spacer()
            }
            Spacer().frame(height: 40)
            HStack {
                Spacer().frame(width: 40)
                HStack(spacing: 0) {
                    Text("Calculation:")
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
                    InsightsColumnListView(report: report, data: data, title: "Data columns", columns: report.allColumns, listType: .allColumns, allowDrag: true, selectedListType: $selectedListType, onSelect: variableSelected)
                }
                .frame(width: 200)
                Spacer().frame(maxWidth: 60)
                VStack(spacing: 0) {
                    MiddleCentered(height: 60) { Image(systemName: "arrowshape.up").font(bannerFont) }
                    InsightsColumnListView(report: report, data: data, title: "Calculated columns", columns: calculatedColumns, listType: .calculatedColumns, allowDrag: true, selectedListType: $selectedListType, onSelect: variableSelected)
                }
                .frame(width: 200)
                Spacer().frame(maxWidth: 60)
                VStack(spacing: 0) {
                    MiddleCentered(height: 60) { Image(systemName: "arrowshape.up").font(bannerFont) }
                    InsightsListView(title:"Functions", list: CalculatedFunction.allCases.map{$0.string}, listType: .functions, allowDrag: true, selectedListType: $selectedListType, onSelect: functionSelected)
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
                        Picker("Blank If:", selection: $editColumn.blankIf) {
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
                        .frame(width: 40)
                        Spacer()
                    }
                    HStack {
                        HStack {
                            Text("Show in:")
                            Spacer()
                        }
                        .frame(width: 120)
                        Picker("Show in:", selection: $editColumn.visibility) {
                            ForEach(CalculatedVisibility.allCases, id: \.self) { visibility in
                                Text(visibility.string)
                                    .tag(visibility)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 300)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        HStack {
                            Text("Calculate as:")
                            Spacer()
                        }
                        .frame(width: 120)
                        Picker("Calculate as:", selection: $editColumn.totalType) {
                            ForEach(CalculatedTotalType.allCases, id: \.self) { totalType in
                                Text(totalType.string)
                                    .tag(totalType)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(!editColumn.visibility.isInTotal)
                        .frame(width: 300)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        HStack {
                            Text("Recalculate:")
                            Spacer()
                        }
                        .frame(width: 120)
                        InputToggle(field: $editColumn.recalculate, disabled: .constant(false), width: 80, inlineTitle: false) { _ in
                            Utility.mainThread {
                                updateLogic()
                            }
                        }
                        .frame(width: 40)
                        .disabled(!editColumn.visibility.isInTotal)
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
            editColumn.copy(from: column)
            checkTitle()
            updateLogic()
            focused = .logic
        }
    }
    
    func checkTitle() {
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
        let duplicates = names.enumerated().filter({ $1 == editColumn.name && $0 != index })
        if duplicates.count > 0 {
            duplicateMessage = "Duplicate description with '\(report.values.calculatedColumns[duplicates.first!.offset].title)'"
        } else {
            duplicateMessage = ""
        }
        canSave = !editColumn.name.isEmpty && !editColumn.logic.isEmpty && duplicates.count == 0 && resultType != nil
    }
    
    func updateLogic() {
        canSave = !editColumn.name.isEmpty && !editColumn.logic.isEmpty
        let parser = CalculatedParser(report: report, tokens: editColumn.logic)
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
                    editColumn.type = resultType ?? .numeric
                }
            }
        }
        Utility.mainThread {
            canSave = canSave && errorMessage.isEmpty
        }
        
        return
        
        func traverseCalculatedColumn(variable: InsightColumn) throws {
            let otherReferencedVariables = referencedVariables.filter({$0 != editColumn})
            if case let .calculated(calculated) = variable {
                if otherReferencedVariables.contains(where: { $0.name == calculated.name }) {
                    throw CalculatedError.circularReference(calculated.title)
                } else {
                    // Need to carry on going down in this variable's logic
                    referencedVariables.append(calculated)
                    try calculated.traverse(report, traverseCalculatedColumn)
                }
            }
        }
    }
    
    func save() {
        checkTitle()
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
                return try column.value(report: report, viewModel: data)
            } else {
                return nil
            }
        } catch {
            return CalculatedValue("ERROR")
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

fileprivate enum EditField {
    case description
    case logic
}
