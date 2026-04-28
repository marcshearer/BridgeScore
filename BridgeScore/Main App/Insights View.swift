//
//  Insights View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 27/04/2026.
//

import SwiftUI

struct InsightsView: View {
    @State var boardSummary: [BoardSummaryViewModel] = []
    var body: some View {
        Text("Insights View")
            .onAppear {
                Insights.build()
                boardSummary = Insights.Load()
            }
    }
}
