//
//  Widget Bundle.swift
//  BridgeScore Widget
//
//  Created by Marc Shearer on 29/01/2025.
//

import WidgetKit
import SwiftUI

@main
struct BridgeScoreWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder var body: some Widget {
        LastScorecardWidget()
        StatsWidget()
        CreateScorecardWidget()
    }
}
