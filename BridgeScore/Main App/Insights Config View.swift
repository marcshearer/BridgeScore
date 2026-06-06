//
//  Insights Config View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 06/06/2026.
//

import SwiftUI

struct InsightsConfigView : View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var report: Report
    var column: InsightColumn
    @State var editMode: InsightEditMode
    var completion: (InsightColumnConfig) -> ()
    
    @State var config: InsightColumnConfig = InsightColumnConfig()
    @State var focus: InsightsCalculatedEditField? = .description
    
    var body: some View {
        VStack(spacing: 0) {
            Banner(title: Binding.constant("Configure Column"), alternateColor: true, height: 80)
            Spacer().frame(height: 30)
            HStack {
                Spacer().frame(width: 80)
                VStack(spacing: 0) {
                    HStack {
                        HStack(spacing: 0) {
                            Text("Title:")
                            Spacer()
                        }
                        .frame(width: 180)
                        InsightsTextView(text: $config.title, fieldType: InsightsCalculatedEditField.description, focus: $focus)
                            .frame(width: 300, height: 40)
                            .palette(.alternate)
                            .cornerRadius(8)
                        Spacer()
                    }
                    Spacer().frame(height: 30)
                    HStack {
                        HStack {
                            Text("Alignment:")
                            Spacer()
                        }
                        .frame(width: 180)
                        Picker("Alignment", selection: $config.align) {
                            ForEach(CalculatedAlignment.allCases, id: \.self) { align in
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
                        HStack {
                            Text("Width:")
                            Spacer()
                        }
                        .frame(width: 180)
                        StepperInput(field: $config.width, minValue: {50}, maxValue: {200}, increment: {10}, height: 30, width: 100, inlineTitle: false)
                            .frame(width: 140)
                        Spacer()
                    }
                    Spacer().frame(height: 30)
                    if column.type == .numeric {
                        HStack {
                            HStack {
                                Text("Blank If:")
                                Spacer()
                            }
                            .frame(width: 180)
                            Picker("Blank If:", selection: $config.blankIf) {
                                ForEach(CalculatedBlankIf.allCases, id: \.self) { align in
                                    Text(align.string)
                                        .tag(align)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 300)
                            Spacer()
                        }
                        Spacer().frame(height: 30)
                        HStack {
                            HStack {
                                Text("Show in:")
                                Spacer()
                            }
                            .frame(width: 180)
                            Picker("Show in:", selection: $config.visibility) {
                                ForEach(CalculatedVisibility.allCases, id: \.self) { visibility in
                                    Text(visibility.string)
                                        .tag(visibility)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 300)
                            Spacer()
                        }
                        Spacer().frame(height: 30)
                        HStack {
                            HStack {
                                Text("Calculate as:")
                                Spacer()
                            }
                            .frame(width: 180)
                            Picker("Calculate as:", selection: $config.totalType) {
                                ForEach(CalculatedTotalType.allCases, id: \.self) { totalType in
                                    Text(totalType.string)
                                        .tag(totalType)
                                }
                            }
                            .pickerStyle(.segmented)
                            .disabled(!config.visibility.isInTotal)
                            .frame(width: 300)
                            Spacer()
                        }
                    }
                    Spacer()
                }
            }
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
                        completion(config)
                        dismiss()
                    }
                }
                Spacer()
            }
            Spacer().frame(height: 40)
        }
        .frame(width: 700, height: column.type == .numeric ? 600 : 400)
        .cornerRadius(8)
        .palette(.background)
        .onAppear {
            config = column.config ?? InsightColumnConfig(from: column)
        }
    }
}
