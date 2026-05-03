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
    var availableColumns: Binding<[InsightColumn]> { Binding(
        get: { InsightColumn.allColumns.filter { !pinnedColumns.contains($0) && !columns.contains($0) } },
        set: { _ in  } // No need to do this as it will be handled by a change to coluns or pinnedColumns
    )}
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)
            HStack(spacing: 0) {
                Spacer().frame(width: 100)
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
                Spacer().frame(width: 100)
                VStack(spacing: 0) {
                    columnList(title: "Unused", columns: availableColumns, height: 680, source: .available, specific: false)
                    Spacer()
                }
                Spacer().frame(width: 100)
                VStack(spacing: 0) {
                    columnList(title: "Pinned", columns: $pinnedColumns, height: 200, source: .pinned, specific: true)
                    Spacer().frame(height: 40)
                    columnList(title: "Un-pinned", columns: $columns, height: 400, source: .unpinned, specific: true)
                    Spacer()
                }
                Spacer()
            }
            Spacer()
        }
    }
    
    func columnList(title: String, columns: Binding<[InsightColumn]>, height: CGFloat, source: ColumnSource, specific: Bool) -> some View {
        
        return VStack(spacing: 0) {
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
                            .if(specific) { view in
                                view.dropDestination(for: ColumnTransfer.self) { droppedColumns, _ in
                                    return handleDrop(destination: columns, dropped: droppedColumns, after: nil)
                                }
                            }
                        ForEach(columns, id: \.self) { column in
                            GridRow {
                                VStack(spacing: 0) {
                                    HStack {
                                        Spacer()
                                        Text(column.wrappedValue.title)
                                        Spacer()
                                    }
                                    .frame(width: 200, height: 24)
                                    .palette(.tile)
                                    .draggable(ColumnTransfer(source: source, column: column.wrappedValue))
                                    .overlay(alignment: .top) {
                                        VStack(spacing: 0) {
                                            Spacer().frame(width: 200, height: 16)
                                                .background(.clear)
                                            Spacer().frame(width: 200, height: 8)
                                                .palette(.mutedTile)
                                        }
                                        .offset(y: 8)
                                        .if(specific) { view in
                                            view.dropDestination(for: ColumnTransfer.self) { droppedColumns, _ in
                                                return handleDrop(destination: columns, dropped: droppedColumns, after: column.wrappedValue)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: height)
            }
        }
        .if(!specific) { view in
            view.dropDestination(for: ColumnTransfer.self) { droppedColumns, _ in
                return handleDrop(destination: columns, dropped: droppedColumns, after: nil)
            }
        }
        .palette(.mutedTile)
        .cornerRadius(8)
        .frame(width: 200)
    }
    
    func handleDrop(destination: Binding<[InsightColumn]>, dropped: [ColumnTransfer], after: InsightColumn?) -> Bool {
        var result = false
        var beforeIndex: Int?
        if after == nil {
            beforeIndex = 0
        } else {
            if let index = destination.wrappedValue.firstIndex(where: {$0 == after!}) {
                beforeIndex = index + 1
            }
        }
        if let beforeIndex = beforeIndex {
            for droppedTransfer in dropped.reversed() {
                switch droppedTransfer.source {
                case .available:
                    break // No need to do anything - will recalculated when added to the other group
                case .pinned:
                    pinnedColumns.removeAll(where: {$0 == droppedTransfer.column})
                case .unpinned:
                    columns.removeAll(where: {$0 == droppedTransfer.column})
                }
                destination.wrappedValue.insert(droppedTransfer.column, at: beforeIndex)
                result = true
                
            }
        }
        return result
    }
}

enum ColumnSource : Codable {
    case available
    case pinned
    case unpinned
}

struct ColumnTransfer : Codable, Transferable {
    var source: ColumnSource
    var column: InsightColumn
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: ColumnTransfer.self, contentType: .data)
    }
}

