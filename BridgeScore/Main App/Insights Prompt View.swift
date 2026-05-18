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
            .frame(height: 120)
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
            let bodyHeight: CGFloat = min(320, max(40, CGFloat(40 * (report.values.levels.count - 1))))
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
                                gridRowValues(index: index, prompt: prompt)
                                    .id(refreshId)
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
                            if let index = (selected == nil ? report.values.prompts.count - 1 : report.values.prompts.firstIndex(where: {$0 == selected!})) {
                                prompt = CalculatedPrompt()
                                showPrompt = ShowPrompt(index: index + 1, editMode: .create)
                            }
                        } label: {
                            Image(systemName: "plus")
                                .contentShape(Rectangle())
                        }
                        if selected != nil {
                            Button {
                                if let index = report.values.prompts.firstIndex(where: {$0 == selected!}) {
                                    report.values.prompts.remove(at: index)
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
                }
            }
            .frame(height: bodyHeight + 80)
            Spacer()
        }
    }
    
    func editPrompt(_ prompt: CalculatedPrompt) {
        if let index = report.values.prompts.firstIndex(where: {$0 == prompt}) {
            self.prompt = report.values.prompts[index]
            showPrompt = ShowPrompt(index: index, editMode: .amend(index: index))
        }
    }
    
    func gridRow(name: String, promptText: String = "") -> some View {
        HStack(spacing: 0) {
            LeadingText(name).frame(width: 120)
            LeadingText(promptText).frame(width: 240)
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
    @FocusState fileprivate var focused: EditField?
    @StateObject var editPrompt = CalculatedPrompt()
    
    var body: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("\(editMode.string.capitalized) Prompt"), alternateColor: true, height: 80)
            Spacer().frame(height: 30)
            HStack {
                Spacer().frame(width: 40)
                HStack(spacing: 0) {
                    Text("Name:")
                    Spacer()
                }
                .frame(width: 120)
                HStack {
                    Spacer().frame(width: 8)
                    MyTextField(field: $editPrompt.name, focused: $focused, focusValue: .name, nextFocusValue: .promptType, previousFocusValue: .promptType, color: .alternate)
                        .onChange(of: focused) {
                            if focused != .name {
                                focused = .promptText
                            }
                        }
                            
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
                    Text("Prompt text:")
                    Spacer()
                }
                .frame(width: 120)
                HStack {
                    Spacer().frame(width: 8)
                    MyTextField(field: $editPrompt.promptText, focused: $focused, focusValue: .promptText, nextFocusValue: .name, previousFocusValue: .name, color: .alternate)
                        .onChange(of: focused) {
                        if focused != .promptText {
                            focused = .name
                        }
                    }
                }
                .frame(width: 240, height: 40)
                .palette(.alternate)
                .cornerRadius(8)
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
        .task {
            Utility.mainThread {
                editPrompt.copy(from: prompt)
                focused = .name
            }
        }
    }
    
    func save() {
        report.objectWillChange.send()
        switch editMode {
        case .create:
            prompt.copy(from: editPrompt)
            report.values.prompts.insert(prompt, at: index)
            selected = prompt
        case .amend(let index):
            prompt.copy(from: editPrompt)
            report.values.prompts[index].copy(from: prompt)
            selected = prompt
        default:
            break
        }
        dismiss()
    }
    
    var canSave: Bool {
        !editPrompt.name.isEmpty && !editPrompt.promptText.isEmpty
    }
}

fileprivate enum EditField {
    case name
    case promptText
    case promptType
    case type
    case defaultValue
}
