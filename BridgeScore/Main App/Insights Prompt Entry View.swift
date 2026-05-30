//
//  Insights Prompt Entry View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 19/05/2026.
//

import SwiftUI

struct InsightsPromptEntryView : View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var report: Report
    @State var focus: Int? = nil
    var onCompletion: (Bool)->()
    
    var body: some View {
        let prompts = report.values.prompts
        
        VStack {
            Banner(title: Binding.constant("View Settings"), height: 80, back: false, leftTitle: false)
            VStack(spacing: 0) {
                Spacer().frame(height: 30)
                HStack {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack {
                            ForEach(0..<prompts.count, id: \.self) { index in
                                if case .prompt(let prompt) = report.values.prompts[index] {
                                    VStack(spacing: 0) {
                                        Spacer().frame(height: 20)
                                        Spacer()
                                        HStack {
                                            HStack {
                                                Spacer().frame(width: 50)
                                                Text("\(prompt.promptText): ")
                                                Spacer()
                                            }
                                            .frame(width: 300)
                                            HStack {
                                                InsightsPromptValueView(prompt: prompt, value: prompt.value!.textBinding, fieldType: index, focus: $focus, onChange: { newValue in
                                                    prompt.value!.lastBindingString = newValue
                                                })
                                                .frame(width: 300, height: 40)
                                                Spacer()
                                            }
                                        }
                                        Spacer()
                                        Spacer().frame(height: 20)
                                    }
                                    .frame(height: 60)
                                    .id(index)
                                }
                            }
                        }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    Spacer().frame(width: 5)
                }
                Spacer().frame(height: 40)
                HStack {
                    Spacer()
                    InsightsSetupButton(text: "Exit") {
                        onCompletion(false)
                        forceDismiss()
                    }
                    Spacer().frame(width: 100)
                    InsightsSetupButton(text: "Display View") {
                        onCompletion(true)
                        forceDismiss()
                    }
                    Spacer()
                }
                Spacer().frame(height: 20)
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(true)
    }
    
    func backAction() -> Bool {
        forceDismiss()
        return true
    }
}

extension Int: @retroactive CaseIterable {}
extension Int : InsightsFocusIndexBridge {
    public typealias AllCases = [Int]
    public static var allCases: [Int] { [] }
    public var intIndex: Int { self }
    public static func from(intIndex: Int) -> Int? { intIndex }
}
