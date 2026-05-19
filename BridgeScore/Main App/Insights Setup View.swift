//
//  Insights Setup View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 02/05/2026.
//

import SwiftUI

struct InsightsSetupView : View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var report: Report
    @State var data: BoardSummaryExtension?
    @Binding var dismissView: Bool
    @State var completion: ()->()

    var title: Binding<String> {  Binding(
        get: { "Insights View Setup" + (report.values.viewName.isEmpty ? "" : " - " + report.values.viewName) },
        set: { _ in}
    )}
    
    var body: some View {
        VStack(spacing: 0) {
            Banner(title: title, height: 80, backAction: {
                completion() ; return true
            }, escapeToDismiss: true)
            HStack(spacing: 0) {
                Spacer().frame(width: 30)
                InsightsChooseColumnsView(report: report, data: data)
                Spacer().frame(width: 30)
                VStack(spacing: 0) {
                    InsightsSortLevelsView(report: report).layoutPriority(1)
                    InsightsPromptsView(report: report).layoutPriority(1)
                    Spacer().layoutPriority(1)
                }
                Spacer().frame(width: 30)
                InsightsReportViewStorage(report: report)
                Spacer().frame(width: 30)
            }
        }
        .onChange(of: dismissView) {
            completion()
            dismiss()
        }
        .palette(.background)
        .cornerRadius(20)
    }
}

struct InsightsChooseColumnsView : View {
    @ObservedObject var report: Report
    @State var data: BoardSummaryExtension?
    @State var selectedListType: ListType? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    Spacer()
                    Text("Drag columns to report sections")
                        .font(defaultFont)
                        .minimumScaleFactor(0.5)
                    Spacer()
                }
                .frame(minWidth: 300, maxWidth: 500)
                Spacer()
            }
            .frame(height: 40)
            Spacer().frame(height: 40)
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    InsightsColumnListView(report: report, data: data, title: "Not Used", columns: report.availableColumns, listType: .availableColumns, allowDrag: true, specificDrop: false, selectedListType: $selectedListType, onDropReceived: onDropReceived)
                    Spacer().frame(height: 40)
                    InsightsColumnListView(report: report, data: data, title: "Calculated", columns: $report.values.calculatedColumns, listType: .calculatedColumns, allowDrag: true, showEdit: true, showInsert: true, showRemove: true, selectedListType: $selectedListType)
                    Spacer()
                }
                Spacer().frame(width: 30)
                VStack(spacing: 0) {
                    InsightsColumnListView(report: report, data: data, title: "Pinned", columns: $report.values.pinnedColumns, listType: .pinnedColumns, allowDrag: true, showRemove: true, specificDrop: true, height: 240, selectedListType: $selectedListType, onDropReceived: onDropReceived)
                    Spacer().frame(height: 40)
                    InsightsColumnListView(report: report, data: data, title: "Not Pinned", columns: $report.values.unpinnedColumns, listType: .unpinnedColumns, allowDrag: true, showRemove: true, specificDrop: true, selectedListType: $selectedListType, onDropReceived: onDropReceived)
                    Spacer()
                }
                Spacer()
            }
            Spacer().frame(height: 50)
            Spacer()
        }
    }
    
    func onDropReceived(target: ListType, dropped: [InsightsSetupTransfer], after: (InsightColumn)?) -> Bool {
        var result = false
        var beforeIndex: Int?
        if after == nil {
            beforeIndex = 0
        } else {
            if let index = report.columns(listType: target).firstIndex(where: {$0.name == after!.name}) {
                beforeIndex = index + 1
            }
        }
        
        if let beforeIndex = beforeIndex {
            for droppedTransfer in dropped.reversed() {
                if droppedTransfer.source.isColumns {
                    if target == droppedTransfer.source {
                        // Dropping in same list - move it
                        if beforeIndex != 0 && droppedTransfer.column!.name != after!.name {
                            // No need to do anything if moving in a non-specific list
                            if let currentIndex = report.columns(listType: target).firstIndex(where: {$0.name  == droppedTransfer.column!.name}) {
                                switch target {
                                case .availableColumns:
                                    break // No need to do anything - will recalculated when added to the other group
                                case .pinnedColumns:
                                    report.values.pinnedColumns.move(fromOffsets: IndexSet([currentIndex]), toOffset: beforeIndex)
                                case .unpinnedColumns:
                                    report.values.unpinnedColumns.move(fromOffsets: IndexSet([currentIndex]), toOffset: beforeIndex)
                                default:
                                    break
                                }
                            }
                        }
                    } else {
                        switch droppedTransfer.source {
                        case .availableColumns:
                            break
                            // No need to remove anything - will recalculated when added to the other group
                        case .pinnedColumns:
                            report.values.pinnedColumns.removeAll(where: {$0 == droppedTransfer.column})
                        case .unpinnedColumns:
                            report.values.unpinnedColumns.removeAll(where: {$0 == droppedTransfer.column})
                        default:
                            break
                        }
                        switch target {
                        case .availableColumns:
                            break // No need to do anything - will recalculated when added to the other group
                        case .pinnedColumns:
                            report.values.pinnedColumns.insert(droppedTransfer.column!, at: beforeIndex)
                        case .unpinnedColumns:
                            report.values.unpinnedColumns.insert(droppedTransfer.column!, at: beforeIndex)
                        default:
                            break
                        }
                        report.objectWillChange.send()
                        result = true
                    }
                }
            }
        }
        return result
    }
}

struct InsightsListView : View {
    var title: String
    var list: [String]
    var height: CGFloat? = nil
    var listType: ListType
    var allowDrag: Bool
    var allowSelect: Bool = true
    var selectedListType: Binding<ListType?>
    var onSelect: ((CalculatedFunction) -> Void)? = nil
    
    @State var selected: String? = nil
    
    var body : some View {
        VStack(spacing: 0) {
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
                            ForEach(list, id: \.self) { element in
                                GridRow {
                                    VStack(spacing: 0) {
                                        HStack {
                                            Spacer()
                                            Text(element)
                                            Spacer()
                                        }
                                        .frame(width: 200, height: 24)
                                        .palette(selected == element ? .filterTile : .tile)
                                        .draggable(InsightsSetupTransfer(source: listType, function: CalculatedFunction(rawValue: element)!))
                                    }
                                }
                                .onTapGesture {
                                    if let onSelect = onSelect {
                                        onSelect(CalculatedFunction(rawValue: element)!)
                                    } else if allowSelect {
                                        selected = element
                                        selectedListType.wrappedValue = listType
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
            .palette(.mutedTile)
            .cornerRadius(8)
            .frame(width: 200)
        }
        .onChange(of: selectedListType.wrappedValue) {
            if selectedListType.wrappedValue != listType {
                selected = nil
            }
        }
    }
}

enum InsightEditMode {
    case create
    case amend(index: Int)
    case delete(index: Int)
    case display(index: Int)
    
    var string: String {
        switch self {
        case .create: return "Create"
        case .amend: return "Amend"
        case .delete: return "Delete"
        case .display: return "Display"
        }
    }
}

struct InsightsColumnListView : View {
    @ObservedObject var report: Report
    @State var data: BoardSummaryExtension?
    var title: String
    @Binding var columns: [InsightColumn]
    var listType: ListType
    var allowSelect: Bool = true
    var allowDrag: Bool
    var showEdit: Bool = false
    var showInsert: Bool = false
    var showRemove: Bool = false
    var specificDrop: Bool = true
    var height: CGFloat? = nil
    var selectedListType: Binding<ListType?>
    var onSelect: ((InsightColumn) -> Void)? = nil
    var onDropReceived: ((_ target: ListType, _ droppedColumns: [InsightsSetupTransfer], _ before: InsightColumn?) -> Bool)?
    
    @State private var selected: InsightColumn? = nil
    @State private var showCalculatedColumn: Bool = false
    @State private var column = CalculatedColumn()
    @State private var editMode: InsightEditMode? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                let showBottomBar = (showInsert || ((showRemove || showEdit) && selected != nil))
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow {
                        HStack {
                            Spacer()
                            Text(title)
                                .frame(width: 200, height: 40)
                            Spacer()
                        }
                        .dropDestination(for: InsightsSetupTransfer.self) { droppedColumns, _ in
                            return onDropReceived!(listType, droppedColumns, nil)
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
                                .if(specificDrop && onDropReceived != nil) { view in
                                    view.dropDestination(for: InsightsSetupTransfer.self) { droppedColumns, _ in
                                        return onDropReceived!(listType, droppedColumns, nil)
                                    }
                                }
                            ForEach(0..<columns.count, id: \.self) { index in
                                let wrappedColumn = $columns[index]
                                let showColumn = wrappedColumn.wrappedValue
                                GridRow {
                                    VStack(spacing: 0) {
                                        HStack {
                                            Spacer()
                                            Text(showColumn.title)
                                            Spacer()
                                        }
                                        .frame(width: 200, height: 24)
                                        .palette(selected == showColumn ? .filterTile : .tile)
                                        .if(specificDrop) { view in
                                            view.dropDestination(for: String.self) { _, _ in return false } // Exclude drop
                                        }
                                        .draggable(InsightsSetupTransfer(source: listType, column: showColumn))
                                        .overlay(alignment: .top) {
                                            VStack(spacing: 0) {
                                                Spacer().frame(width: 200, height: 16)
                                                    .background(.clear)
                                                Spacer().frame(width: 200, height: 8)
                                                    .palette(.mutedTile)
                                            }
                                            .offset(y: 8)
                                            .if(specificDrop && onDropReceived != nil) { view in
                                                view.dropDestination(for: InsightsSetupTransfer.self) { droppedColumns, _ in
                                                    return onDropReceived!(listType, droppedColumns, showColumn)
                                                }
                                            }
                                        }
                                    }
                                }
                                .onTapGesture {
                                    tapHandler(column: showColumn)
                                }
                                .onTapGesture(count: 2) {
                                    tapHandler(column: showColumn, count: 2)
                                }
                            }
                        }
                    }
                    .if(specificDrop && onDropReceived != nil) { view in
                        view.dropDestination(for: InsightsSetupTransfer.self) { droppedColumns, _ in
                            return onDropReceived!(listType, droppedColumns, columns.last)
                        }
                    }
                    .if(height != nil) { view in
                        view.frame(height: height! - 40 - (showBottomBar ? 40 : 0))
                    }
                }
                if showBottomBar {
                    if height == nil {
                        Spacer()
                    }
                    HStack {
                        Spacer().frame(width: 20)
                        if showEdit {
                            Button {
                                editCalculated(selected!)
                            } label: {
                                Text("Edit")
                            }
                            .contentShape(Rectangle())
                            .opacity(selected == nil ? 0.3 : 1)
                            .disabled(selected == nil)
                        }
                        if showInsert {
                            Button {
                                editMode = .create
                                column = CalculatedColumn()
                                showCalculatedColumn = true
                            } label: {
                                Image(systemName: "plus")
                                    .contentShape(Rectangle())
                            }
                        }
                        if showRemove {
                            Button {
                                columns.removeAll(where: {$0 == selected})
                                selected = nil
                            } label: {
                                Image(systemName: "minus")
                                    .contentShape(Rectangle())
                            }
                            .opacity(selected == nil ? 0.3 : 1)
                            .disabled(selected == nil)
                        }
                        Spacer()
                    }
                    .frame(height: 40)
                    .palette(.contrastTile)
                }
                
            }
            .onChange(of: $columns.count) {
                // Check selected hasn't been removed
                if selected != nil && !columns.contains(selected!) {
                    selected = nil
                }
            }
            .onChange(of: selectedListType.wrappedValue) {
                if selectedListType.wrappedValue != listType {
                    selected = nil
                }
            }
            .if(!specificDrop && onDropReceived != nil) { view in
                view.dropDestination(for: InsightsSetupTransfer.self) { droppedColumns, _ in
                    return onDropReceived!(listType, droppedColumns, nil)
                }
            }
            .fullScreenCover(isPresented: $showCalculatedColumn) {
                FullScreenView(minWidth: 1600, minHeight: 1200, escapeToDismiss: false) {
                    InsightsCalculatedColumnView(report: report, column: $column, data: data, editMode: editMode!)
                }
            }
            .palette(.mutedTile)
            .cornerRadius(8)
        }
        .frame(width: 200)
    }
    
    func tapHandler(column: InsightColumn, count: Int = 1) {
        if showEdit && count == 2 {
            editCalculated(column)
        } else if let onSelect = onSelect {
            onSelect(column)
            selected = nil
        } else if allowSelect {
            selected = column
            selectedListType.wrappedValue = listType
        }
    }
    
    func editCalculated(_ column: InsightColumn) {
        switch column {
        case .calculated(column: let calculated):
            if let index = columns.firstIndex(where: { $0 == column }) {
                editMode = .amend(index: index)
                self.column = calculated
                showCalculatedColumn = true
            }
        default: break
        }
    }
}

enum ListType : Codable {
    case availableColumns
    case allColumns
    case pinnedColumns
    case unpinnedColumns
    case calculatedColumns
    case promptColumns
    case functions
    
    var isColumns: Bool { self != .functions }
}

struct InsightsSetupTransfer : Codable, Transferable {
    var source: ListType
    var column: InsightColumn?
    var function: CalculatedFunction?
    
    init(source: ListType, column: InsightColumn? = nil, calculatedColumn: CalculatedColumn? = nil, function: CalculatedFunction? = nil) {
        self.source = source
        if source == .calculatedColumns, let calculatedColumn {
            self.column = .calculated(column: calculatedColumn)
        } else {
            self.column = column
        }
        self.function = function
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: InsightsSetupTransfer.self, contentType: .data)
    }
}
