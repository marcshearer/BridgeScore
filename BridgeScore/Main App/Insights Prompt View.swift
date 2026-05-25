//
//  Insights Prompt View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 18/05/2026.
//

import SwiftUI

struct InsightsPromptsView : View {
    @ObservedObject var report: Report
    
    @State private var showPrompt: ShowPrompt? = nil
    @State private var prompt: CalculatedPrompt = CalculatedPrompt()
    @State var selected: CalculatedPrompt? = nil
    @State private var refreshId = UUID()
    
    var body: some View {
        
        VStack {
            Top(padding: 40) {
                CenteredText("View Prompts")
                    .font(defaultFont)
                    .frame(height: 40)
            }
            .frame(height: 40)
            promptView()
            Spacer()
        }
        .sheet(item: $showPrompt) { showPrompt in
            InsightsPromptView(report: report, prompt: $prompt, index: showPrompt.index, editMode: showPrompt.editMode, selected: $selected)
                .onDisappear {
                    refreshId = UUID()
                }
        }
    }
    
    func promptView() -> some View {
        VStack(spacing: 0) {
            let prompts = report.values.prompts
            let bodyHeight: CGFloat = min(280, max(40, CGFloat(40 * (report.values.prompts.count))))
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
                }
                VStack(spacing: 0) {
                    gridRow(name: "Prompt Name", promptText: "Prompt Text")
                        .palette(.contrastTile, clear: true)
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            ForEach(0..<prompts.count, id: \.self) { index in
                                let prompt = prompts[index]
                                if let promptColumn = prompt.promptColumn {
                                    gridRowValues(index: index, prompt: promptColumn)
                                        .id(refreshId)
                                }
                            }
                        }
                    }
                    .frame(height: bodyHeight)
                    HStack {
                        Spacer().frame(width: 20)
                        Button {
                            editPrompt(selected!)
                        } label: {
                            Text("Edit")
                        }
                        .contentShape(Rectangle())
                        .opacity(selected == nil ? 0.3 : 1)
                        .disabled(selected == nil)
                        Button {
                            if let index = (selected == nil ? report.values.prompts.count - 1 : report.values.prompts.firstIndex(where: {$0.promptColumn! == selected!})) {
                                prompt = CalculatedPrompt()
                                showPrompt = ShowPrompt(index: index + 1, editMode: .create)
                            }
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 30, height: 40)
                                .background(Color.clear)
                                .contentShape(Rectangle())
                        }
                        Button {
                            InsightsSetupView.checkAndRemoveColumn(report: report, column: .prompt(prompt: selected!), completion:  {
                                self.selected = nil
                            })
                        } label: {
                            Image(systemName: "minus")
                                .contentShape(Rectangle())
                        }
                        .opacity(selected == nil ? 0.3 : 1)
                        .disabled(selected == nil)
                        Spacer()
                    }
                    .palette(.contrastTile, clear: true)
                    .frame(height: 40)
                }
            }
            .frame(height: bodyHeight + 80)
            Spacer()
        }
    }
    
    func editPrompt(_ prompt: CalculatedPrompt) {
        if let index = report.values.prompts.firstIndex(where: {$0.promptColumn! == prompt}) {
            self.prompt = report.values.prompts[index].promptColumn!
            showPrompt = ShowPrompt(index: index, editMode: .amend(index: index))
        }
    }
    
    func gridRow(name: String, promptText: String = "") -> some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 10)
            LeadingText(name).frame(width: 150)
            LeadingText(promptText)
            Spacer().frame(width: 10)
        }
        .contentShape(Rectangle())
        .frame(height: 40)
    }
    
    func gridRowValues(index: Int, prompt: CalculatedPrompt) -> some View {
        HStack(spacing: 0) {
            gridRow(name: prompt.name, promptText: prompt.promptText)
        }
        .palette(.tile, clear: true)
        .if(selected == prompt) { view in
            view.palette(.alternate)
        }
        .onTapGesture {
            selected = prompt
        }
        .onTapGesture(count: 2) {
            selected = prompt
            editPrompt(prompt)
        }
    }
}

fileprivate struct ShowPrompt: Identifiable {
    var id = UUID()
    var index: Int
    var editMode: InsightEditMode
}

struct InsightsPromptView : View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var report: Report
    @Binding var prompt: CalculatedPrompt
    @State var index: Int
    @State var editMode: InsightEditMode
    @Binding var selected: CalculatedPrompt?
    
    @State var errorMessage: String = ""
    @State var cursor: Int = 0
    @State var focused: InsightsPromptEditField? = .name
    @StateObject var editPrompt = CalculatedPrompt()
    @State var canSave: Bool = false
    @State var canEditType: Bool = true
    @State var promptTypePickerSelection: Int = 0
    @State var typePickerSelection: Int = 0
    @State var defaultValue: String = ""
    @State var duplicateMessage: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("\(editMode.string.capitalized) Prompt"), alternateColor: true, height: 80)
            Spacer().frame(height: 30)
            HStack {
                Spacer().frame(width: 40)
                HStack(spacing: 0) {
                    Text("Prompt text:")
                    Spacer()
                }
                .frame(width: 120)
                InsightsTextView(text: $editPrompt.promptText, fieldType: InsightsPromptEditField.promptText, focus: $focused, onChange: { newValue in
                    checkAvailable()
                })
                .frame(width: 240, height: 40)
                .palette(.alternate)
                .cornerRadius(8)
                Text(duplicateMessage)
                    .foregroundColor(Palette.background.strongText)
                Spacer()
            }
            Spacer().frame(height: 30)
            HStack {
                Spacer().frame(width: 40)
                HStack(spacing: 0) {
                    Text("Prompt type:")
                    Spacer()
                }
                .frame(width: 120)
                HStack {
                    PickerInputSimple(title: "", field: $promptTypePickerSelection, values: CalculatedPromptType.allCases.sorted(by: {$0.rawValue < $1.rawValue}).map{$0.string}, width: 200, titleWidth: 0) { rawValue in
                        Utility.mainThread {
                            editPrompt.promptType = CalculatedPromptType(rawValue: rawValue)!
                            if let type = editPrompt.promptType.type {
                                let typeChanged = (type != editPrompt.type)
                                editPrompt.type = type
                                if typeChanged {
                                    editPrompt.defaultValue = emptyDefaultValue
                                }
                                typePickerSelection = type.rawValue
                            }
                            checkAvailable()
                        }
                    }
                    .offset(x: -8)
                }
                .frame(width: 240, height: 40)
                .palette(.alternate)
                .cornerRadius(8)
                Spacer()
            }
            Spacer().frame(height: 30)
            HStack {
                Spacer().frame(width: 40)
                HStack(spacing: 0) {
                    Text("Data type:")
                    Spacer()
                }
                .frame(width: 120)
                HStack {
                    PickerInputSimple(title: "", field: $typePickerSelection, values: CalculatedType.allCases.map{$0.string}, width: 200, titleWidth: 0) { rawValue in
                        let type = CalculatedType(rawValue: rawValue)!
                        let typeChanged = (type != editPrompt.type)
                        editPrompt.type = type
                        if typeChanged {
                            editPrompt.defaultValue = emptyDefaultValue
                        }
                        checkAvailable()
                    }
                    .disabled(!canEditType)
                    .opacity(canEditType ? 1 : 0.3)
                    .offset(x: -8)
                }
                .frame(width: 240, height: 40)
                .palette(.alternate)
                .cornerRadius(8)
                Spacer()
            }
            Spacer().frame(height: 30)
            HStack {
                Spacer().frame(width: 40)
                HStack(spacing: 0) {
                    Text("Default value:")
                    Spacer()
                }
                .frame(width: 120)
                InsightsPromptValueView(prompt: editPrompt, value: $editPrompt.defaultValue, fieldType: InsightsPromptEditField.defaultValue, focus: $focused) { newValue in
                    checkAvailable()
                }
                Spacer()
            }
            Spacer().frame(height: 40)
            Spacer()
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
        .onAppear {
            editPrompt.copy(from: prompt)
            promptTypePickerSelection = editPrompt.promptType.rawValue
            typePickerSelection = editPrompt.type.rawValue
            focused = .name
            checkAvailable()
        }
    }
    
    func checkAvailable() {
        var checkType = true
        switch editPrompt.type {
        case .numeric:
            if Float(editPrompt.defaultValue) == nil {
                checkType = false
            }
        case .boolean:
            if !["true", "false"].contains(editPrompt.defaultValue.lowercased()) {
                checkType = false
            }
        case .string:
            break
        }
        
        // Check for duplicate name
        editPrompt.name = stripped(name: editPrompt.promptText)
        let names = report.values.prompts.map{$0.promptColumn!.name}
        let duplicates = names.enumerated().filter({ stripped(name: $1.lowercased()) ==  stripped(name: editPrompt.name) && $0 != index })
        if let (_, duplicateName) = duplicates.first {
            let duplicate = report.values.prompts.first(where: {$0.promptColumn!.name == duplicateName})!
            duplicateMessage = "Duplicate with '\(duplicate.promptColumn!.promptText)'"
        } else {
            duplicateMessage = ""
        }
        
        canSave = (editPrompt.name != "" && editPrompt.promptText != "" && checkType && duplicates.count == 0)
        canEditType = (editPrompt.promptType.type == nil)
    }
    
    var emptyDefaultValue: String {
        switch editPrompt.type {
        case .string:
            ""
        case .numeric:
            "0"
        case .boolean:
            "false"
        }
    }
    
    func stripped(name: String) -> String {
        var result = ""
        let components = name.split { !$0.isLetter && !$0.isNumber }
    if let first = components.first {
            result = first.lowercased()
        }
        for component in components.dropFirst() {
            result += component.capitalized
        }
        return result
    }
    
    func save() {
        report.objectWillChange.send()
        switch editMode {
        case .create:
            prompt.copy(from: editPrompt)
            report.values.prompts.insert(.prompt(prompt: prompt), at: index)
            selected = prompt
        case .amend(let index):
            prompt.copy(from: editPrompt)
            report.values.prompts[index].promptColumn!.copy(from: prompt)
            selected = prompt
        default:
            break
        }
        dismiss()
    }
}

enum InsightsPromptEditField : InsightsFocusIndexBridge {
    case name
    case promptText
    case defaultValue
}
