//
//  Insights Selection View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 10/05/2026.
//

import SwiftUI

struct InsightsSelectionView : View {
    @ObservedObject var report: Report
        
    var body: some View {
        let columns = [GridItem(.fixed(80), spacing: 0),
                       GridItem(.flexible(minimum: 100), spacing: 0),
                       GridItem(.fixed(70), spacing: 0),
                       GridItem(.fixed(10), spacing: 0)]
        
        Top(padding: 40) {
            CenteredText("View Selection")
                .font(defaultFont)
            Spacer().frame(height: 40)
            ZStack {
                VStack(spacing: 0) {
                    Rectangle()
                        .palette(.contrastTile, inverse: true)
                        .frame(height: 40)
                    HStack(spacing: 0) {
                        Rectangle()
                            .palette(.tile, inverse: true)
                            .frame(height: 40)
                    }
                }
                .cornerRadius(8)
                LazyVGrid(columns: columns, spacing: 0) {
                    GridRow {
                        CenteredText("Level")
                        LeadingText("Logic")
                        CenteredText("Action")
                        Text("")
                    }
                    .palette(.contrastTile)
                    .frame(height: 40)
                    GridRow {
                        CenteredText("Board")
                        LeadingText("")
                        CenteredText("Edit")
                            .palette(.alternate)
                        Text("")
                    }
                    .frame(height: 40)
                    .palette(.tile)
                }
            }
        }
    }
}
