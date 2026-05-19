//
//  Insights Prompt Value View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 19/05/2026.
//

import SwiftUI

struct InsightsPromptValueView : View {
    @ObservedObject var prompt: CalculatedPrompt
    @Binding var value: String
    var fieldType: InsightsPromptEditField
    @Binding var focus: InsightsPromptEditField?
    var onChange: ((String) -> ())? = nil
    
    @State var pickerValue: Int = 0
    
    var body: some View {
        switch prompt.promptType {
        case .partner:
            let values = ["Any partner"] + MasterData.shared.players.filter{!$0.isSelf && !$0.retired}.map{$0.name}
            InsightsPromptValuePickerView(value: $value, pickerValue: $pickerValue, values: values, onChange: onChange)
        case .location:
            let values = ["Any location"] + MasterData.shared.locations.filter{!$0.retired}.map{$0.name}
            InsightsPromptValuePickerView(value: $value, pickerValue: $pickerValue, values: values, onChange: onChange)
        case .levelType:
            let values: [String] = ["Any level"] + LevelType.allCases.map{$0.string}
            InsightsPromptValuePickerView(value: $value, pickerValue: $pickerValue, values: values, onChange: onChange)
        case .suitType:
            let values: [String] = ["Any suit"] + SuitType.validCases.map{$0.string}
            InsightsPromptValuePickerView(value: $value, pickerValue: $pickerValue, values: values, onChange: onChange)
        case .pairType:
            let values: [String] = ["Any pair"] + PairType.validCases.map{$0.string}
            InsightsPromptValuePickerView(value: $value, pickerValue: $pickerValue, values: values, onChange: onChange)
        case .seatPlayer:
            let values: [String] = ["Any player"] + SeatPlayer.simpleCases.map{$0.simple}
            InsightsPromptValuePickerView(value: $value, pickerValue: $pickerValue, values: values, onChange: onChange)
        case .eventType:
            let values: [String] = ["Any event type"] + EventType.validCases.map{$0.string}
            InsightsPromptValuePickerView(value: $value, pickerValue: $pickerValue, values: values, onChange: onChange)
        case .boardScoreType:
            let values: [String] = ["Any scoring method"] + ScoreType.validCases.map{$0.brief}
            InsightsPromptValuePickerView(value: $value, pickerValue: $pickerValue, values: values, onChange: onChange)
        default:
            switch prompt.type {
            case .boolean:
                Picker("", selection: $value) {
                    Text("True")
                        .tag("true")
                    Text("False")
                        .tag("false")
                }
                .pickerStyle(.segmented)
                .frame(width: 200, height: 40)
            default:
                InsightsTextView(text: $value, fieldType: fieldType, focus: $focus) { newValue in
                    onChange?(value)
                }
                .frame(width: 240, height: 40)
                .palette(.alternate)
                .cornerRadius(8)
            }
        }
    }
}

struct InsightsPromptValuePickerView : View {
    @Binding var value: String
    @Binding var pickerValue: Int
    @State var values: [String] = []
    var onChange: ((String) -> ())? = nil
    
    var body: some View {
        PickerInputSimple(title: "", field: $pickerValue, values: values, width: 200, height: 40, titleWidth: 0) { newValue in
            pickerValue = newValue
            value = (pickerValue > 0 ? values[pickerValue] : "")
            onChange?(value)
        }
        .onAppear {
            pickerValue = values.firstIndex(where: {$0 == value}) ?? 0
        }
        .offset(x: 10)
        .frame(width: 200, height: 40)
        .palette(.alternate)
        .cornerRadius(8)
    }
}
