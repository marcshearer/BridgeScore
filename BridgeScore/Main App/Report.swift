//
//  Report.swift
//  BridgeScore
//
//  Created by Marc Shearer on 06/05/2026.
//

class Report<ColumnType : DerivedVariable, DerivedColumnType : DerivedVariable> : Codable, Identifiable {
    var pinnedColumns: [ColumnType]
    var unpinnedColumns: [ColumnType]
    var derivedColumns: [DerivedColumnType]
    
    init(pinnedColumns: [ColumnType], unpinnedColumns: [ColumnType], derivedColumns: [DerivedColumnType]) {
        self.pinnedColumns = pinnedColumns
        self.unpinnedColumns = unpinnedColumns
        self.derivedColumns = derivedColumns
    }
}
