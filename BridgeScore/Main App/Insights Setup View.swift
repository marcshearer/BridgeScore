//
//  Insights Setup View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 02/05/2026.
//

import SwiftUI

struct InsightsSetupView : View {
    @Binding var pinnedColumns: [InsightColumn]
    @Binding var columns: [InsightColumn]
    @Binding var data: [BoardSummaryExtension]
    @State var logic: [DerivedElement] = []
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer().frame(width: 100)
                InsightsChooseColumnsView(pinnedColumns: $pinnedColumns, columns: $columns)
                Spacer().frame(width: 100)
                InsightsDerivedValueView(logic: $logic, data: $data)
                Spacer().frame(width: 100)
                Spacer()
            }
        }
    }
}

struct InsightsChooseColumnsView : View {
    @Binding var pinnedColumns: [InsightColumn]
    @Binding var columns: [InsightColumn]
    
    var availableColumns: Binding<[InsightColumn]> { Binding(
        get: { InsightColumn.allColumns.filter { !pinnedColumns.contains($0) && !columns.contains($0) } },
        set: { _ in  } // No need to do this as it will be handled by a change to coluns or pinnedColumns
    )}
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    Spacer()
                    Text("Drag columns to different sections")
                        .font(defaultFont)
                    Spacer()
                }
                .frame(width: 500)
                Spacer()
            }
            Spacer().frame(height: 40)
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    InsightsColumnListView(title: "Unused", columns: availableColumns, listType: .available, specificDrop: false, allowDrag: true, handleDrop: handleDrop)
                    Spacer()
                }
                Spacer().frame(width: 100)
                VStack(spacing: 0) {
                    InsightsColumnListView(title: "Pinned", columns: $pinnedColumns, height: 240, listType: .pinned, specificDrop: true, allowDrag: true, handleDrop: handleDrop)
                    Spacer().frame(height: 40)
                    InsightsColumnListView(title: "Not Pinned", columns: $columns, listType: .unpinned, specificDrop: true, allowDrag: true, handleDrop: handleDrop)
                    Spacer()
                }
                Spacer()
            }
            Spacer().frame(height: 50)
            Spacer()
        }
    }
    
    func handleDrop(target: ListType, targetColumns: Binding<[InsightColumn]>, dropped: [ColumnTransfer], after: InsightColumn?) -> Bool {
        var result = false
        var beforeIndex: Int?
        if after == nil {
            beforeIndex = 0
        } else {
            if let index = targetColumns.wrappedValue.firstIndex(where: {$0 == after!}) {
                beforeIndex = index + 1
            }
        }
        
        if let beforeIndex = beforeIndex {
            for droppedTransfer in dropped.reversed() {
                if target == droppedTransfer.source {
                    // Dropping in same list - move it
                    if beforeIndex != 0 && droppedTransfer.column != after {
                        // No need to do anything if moving in a non-specific list
                        if let currentIndex = targetColumns.wrappedValue.firstIndex(of: droppedTransfer.column) {
                            targetColumns.wrappedValue.move(fromOffsets: IndexSet([currentIndex]), toOffset: beforeIndex)
                        }
                    }
                } else {
                    switch droppedTransfer.source {
                    case .available:
                        break // No need to do anything - will recalculated when added to the other group
                    case .pinned:
                        pinnedColumns.removeAll(where: {$0 == droppedTransfer.column})
                    case .unpinned:
                        columns.removeAll(where: {$0 == droppedTransfer.column})
                    }
                    targetColumns.wrappedValue.insert(droppedTransfer.column, at: beforeIndex)
                    result = true
                }
            }
        }
        return result
    }
}

struct InsightsColumnListView : View {
    var title: String
    @Binding var columns: [InsightColumn]
    var height: CGFloat? = nil
    var listType: ListType
    var specificDrop: Bool = true
    var allowDrag: Bool
    var handleDrop: ((_ target: ListType, _ destination: Binding<[InsightColumn]>, _ columns: [ColumnTransfer], _ dropped: InsightColumn?) -> Bool)?
    
    var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    HStack {
                        Spacer()
                        Text(title)
                            .frame(width: 200, height: 40)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .palette(.contrastTile)
                    
                }
                .frame(width: 200, height: 40)
                
                ScrollView {
                    VStack {
                        Spacer().frame(width: 200, height: 4)
                            .palette(.mutedTile)
                            .if(specificDrop && handleDrop != nil) { view in
                                view.dropDestination(for: ColumnTransfer.self) { droppedColumns, _ in
                                    return handleDrop!(listType, $columns, droppedColumns, nil)
                                }
                            }
                        ForEach($columns, id: \.self) { column in
                            GridRow {
                                VStack(spacing: 0) {
                                    HStack {
                                        Spacer()
                                        Text(column.wrappedValue.title)
                                        Spacer()
                                    }
                                    .frame(width: 200, height: 24)
                                    .palette(.tile)
                                    .draggable(ColumnTransfer(source: listType, column: column.wrappedValue))
                                    .overlay(alignment: .top) {
                                        VStack(spacing: 0) {
                                            Spacer().frame(width: 200, height: 16)
                                                .background(.clear)
                                            Spacer().frame(width: 200, height: 8)
                                                .palette(.mutedTile)
                                        }
                                        .offset(y: 8)
                                        .if(specificDrop && handleDrop != nil) { view in
                                            view.dropDestination(for: ColumnTransfer.self) { droppedColumns, _ in
                                                return handleDrop!(listType, $columns, droppedColumns, column.wrappedValue)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .if(height != nil) { view in
                    view.frame(height: height! - 40)
                }
            }
        }
        .if(!specificDrop && handleDrop != nil) { view in
            view.dropDestination(for: ColumnTransfer.self) { droppedColumns, _ in
                return handleDrop!(listType, $columns, droppedColumns, nil)
            }
        }
        .palette(.mutedTile)
        .cornerRadius(8)
        .frame(width: 200)
    }
}

enum ListType : Codable {
    case available
    case pinned
    case unpinned
}

struct ColumnTransfer : Codable, Transferable {
    var source: ListType
    var column: InsightColumn
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: ColumnTransfer.self, contentType: .data)
    }
}

struct InsightsDerivedValueView : View {
    @Binding var logic: [DerivedElement]
    @Binding var data: [BoardSummaryExtension]
    @State var errorMessage: String?
    @State var typeMessage: String?
    @State var treeValue: String?
    @State var value: String?
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    Spacer()
                    Text("Derived Value")
                        .font(defaultFont)
                    Spacer()
                }
                .frame(width: 500)
                Spacer()
            }
            Spacer().frame(height: 40)
            DerivedValuesView(logic: $logic, color: .alternate)
            Spacer().frame(height: 40)
            Button ("Parse") {
                let parser = DerivedParser(tokens: logic)
                parser.parse() { (tree, message) in
                    if let message = message {
                        errorMessage = message
                        treeValue = nil
                        value = nil
                        typeMessage = nil
                    } else if let tree = tree {
                        typeMessage = nil
                        errorMessage = nil
                        treeValue = tree.string
                        do {
                            let resultType = try tree.type(variableType: variableType)
                            typeMessage = "Type is \(resultType.string)"
                        } catch {
                            typeMessage = "Error type checking \(error)"
                        }
                            
                        do {
                            try value = tree.value(variableValue: evaluate).text
                        } catch {
                            value = "Error evaluating \(error)"
                        }
                    }
                }
            }
            ScrollView(.horizontal) {
                Text(errorMessage ?? "")
            }
            ScrollView(.horizontal) {
                Text(typeMessage ?? "")
            }
            .frame(height: 50)
            ScrollView(.horizontal) {
                Text(treeValue ?? "")
            }
            .frame(height: 50)
            .contentMargins(.bottom, 10, for: .scrollContent)
            Text(value ?? "")
        }
    }
    
    func variableType(variable: any DerivedVariable) -> DerivedType? {
        variable.type
    }
    
    func evaluate(variable: any DerivedVariable) -> DerivedValue? {
        if let data = data.first {
            return variable.value(viewModel: data)
        } else {
            return nil
        }
    }
}
