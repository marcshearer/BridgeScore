//
//  Widget Graph.swift
//  BridgeScore
//
//  Created by Marc Shearer on 03/02/2025.
//

import SwiftUI
import Charts

struct WidgetGraphValue: Identifiable {
    var id: UUID
    var sequence: Int
    var value: Float
    var date: Date?
    
    init(sequence: Int, value: Float, date: Date? = nil) {
        self.id = UUID()
        self.sequence = sequence
        self.value = value
        self.date = date
    }
}

struct WidgetGraph: View {
    var values: [WidgetGraphValue]
    var running: [WidgetGraphValue]
    var palette: PaletteEntity
    
    var body: some View {
        let minValue = values.map{$0.value}.min() ?? 0
        let maxValue = values.map{$0.value}.max() ?? 0
        let maxSequence = values.map{$0.sequence}.max() ?? 0
        let average = ((values.map{$0.value}.reduce(0,+)) / Float(values.count))
        let theme = PaletteColor(palette.detailPalette)
        
        if values.count <= 2 {
            MiddleCentered {
                Text("Insufficient Data!").font(.largeTitle).foregroundColor(theme.textColor(.faint))
            }
        } else {
            let startMonth = Utility.dateString(values.first?.date, format: "MMM YY")
            let endMonth = Utility.dateString(values.last?.date, format: "MMM YY")

            Chart {
                RuleMark(y: .value("", 50))
                    .foregroundStyle(theme.textColor(.faint))
                RuleMark(y: .value("Average", average))
                    .foregroundStyle(theme.textColor(.theme).opacity(0.5))
                    .annotation(position: .bottom, alignment: .bottomTrailing) {
                        Text("Average \(average.toString(places: 1))")
                            .foregroundColor(theme.textColor(.theme)).opacity(0.5)
                    }
                ForEach(values) { data in
                    LineMark(x: .value("", data.sequence), y: .value("", data.value), series: .value("", "Data"))
                        .foregroundStyle(Color(theme.textColor(.contrast)))
                        .symbol(.circle)
                }
                if running.count >= 3 {
                    ForEach(running) { data in
                        LineMark(x: .value("", data.sequence), y: .value("", data.value), series: .value("", "Average"))
                            .foregroundStyle(Color(theme.textColor(.strong)))
                            .lineStyle(StrokeStyle(lineWidth: 4))
                            .interpolationMethod(.catmullRom)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: [0, maxSequence]) { sequence in
                    if let sequence = sequence.as(Int.self) {
                        if sequence == 0 {
                            AxisValueLabel(anchor: .bottomLeading) {
                                Text(startMonth)                        .foregroundColor(theme.textColor(.faint))
                            }
                        } else {
                            AxisValueLabel(anchor: .bottomTrailing) {
                                Text(endMonth)
                                    .foregroundColor(theme.textColor(.faint))
                            }
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: yAxisValues(minValue: minValue, maxValue: maxValue)) { value in
                    if let value = value.as(Float.self) {
                        AxisValueLabel {
                            let intValue = Int(value.rounded())
                            Text("\(intValue)").foregroundColor(theme.textColor(.faint))
                        }
                    }
                }
                AxisMarks(values: yAxisValues(minValue: minValue, maxValue: maxValue, average: average)) { value in
                    AxisGridLine()
                        .foregroundStyle(theme.textColor(.faint))
                }
            }
            .chartYScale(domain: max(0, minValue - 5)...min(100, maxValue + 5))
            .chartXScale(domain: -1...values.last!.sequence+1)
            .padding()
        }
    }
    
    func yAxisValues(minValue: Float, maxValue: Float, average: Float? = nil) -> [Int] {
        var result: [Int] = []
        for i in stride(from: 5, to: 95, by: 5) {
            if (Float(i) >= minValue - 1) && (Float(i) <= maxValue + 2) && (average == nil || abs(average! - 1 - Float(i)) > 2) {
                result.append(i)
            }
        }
        return result
    }
}
