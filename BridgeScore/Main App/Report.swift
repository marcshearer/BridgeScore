//
//  Report.swift
//  BridgeScore
//
//  Created by Marc Shearer on 06/05/2026.
//

import SwiftUI

struct ReportValues: Codable {
    var pinnedColumns: [InsightColumn]
    var unpinnedColumns: [InsightColumn]
    var derivedColumns: [InsightColumn]
    
    init(pinnedColumns: [InsightColumn], unpinnedColumns: [InsightColumn], derivedColumns: [InsightColumn]) {
        self.pinnedColumns = pinnedColumns
        self.unpinnedColumns = unpinnedColumns
        self.derivedColumns = derivedColumns
    }
}

class Report: ObservableObject {
    @Published var values: ReportValues
    
    init(pinnedColumns: [InsightColumn], unpinnedColumns: [InsightColumn], derivedColumns: [InsightColumn]) {
        self.values = ReportValues(pinnedColumns: pinnedColumns, unpinnedColumns: unpinnedColumns, derivedColumns: derivedColumns)
    }
}
