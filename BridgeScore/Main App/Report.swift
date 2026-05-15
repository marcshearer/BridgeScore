//
//  Report.swift
//  BridgeScore
//
//  Created by Marc Shearer on 06/05/2026.
//

import SwiftUI

struct ReportValues: Codable {
    var viewName: String
    var pinnedColumns: [InsightColumn]
    var unpinnedColumns: [InsightColumn]
    var calculatedColumns: [InsightColumn]
    var levels: [CalculatedSortLevel]
    
    init(viewName: String = "", pinnedColumns: [InsightColumn], unpinnedColumns: [InsightColumn], calculatedColumns: [InsightColumn] = [], levels: [CalculatedSortLevel] = [CalculatedSortLevel(isBoard: true)]) {
        self.viewName = viewName
        self.pinnedColumns = pinnedColumns
        self.unpinnedColumns = unpinnedColumns
        self.calculatedColumns = calculatedColumns
        self.levels = levels
    }
}

class Report: ObservableObject {
    @Published var values: ReportValues
    
    var availableColumns: Binding<[InsightColumn]> { Binding(
        get: { InsightColumn.allColumns.filter { !self.values.pinnedColumns.contains($0) && !self.values.unpinnedColumns.contains($0) } },
        set: { _ in  }
    )}
    
    var allColumns: Binding<[InsightColumn]> { Binding(
        get: { InsightColumn.allColumns.filter({ value in
            switch value {
            case .calculated(_): false
            default: true
            } })},
        set: { _ in  }
    )}
    
    func columns(listType: ListType) -> [InsightColumn] {
        switch listType {
        case .allColumns:
            allColumns.wrappedValue
        case .availableColumns:
            availableColumns.wrappedValue
        case .pinnedColumns:
            values.pinnedColumns
        case .unpinnedColumns:
            values.unpinnedColumns
        case .calculatedColumns:
            values.calculatedColumns
        default:
            []
        }
    }
    
    static var parses = 0
    static var selectionParses = 0
    
    init(viewName: String = "", pinnedColumns: [InsightColumn] = [], unpinnedColumns: [InsightColumn] = [], calculatedColumns: [InsightColumn] = [], levels: [CalculatedSortLevel] = [CalculatedSortLevel(isBoard: true)]) {
        self.values = ReportValues(viewName: viewName, pinnedColumns: pinnedColumns, unpinnedColumns: unpinnedColumns, calculatedColumns: calculatedColumns, levels: levels)
    }
    
    func update(from newValues: ReportValues) throws {
        values.viewName = newValues.viewName
        values.pinnedColumns = []
        values.unpinnedColumns = []
        values.calculatedColumns = []
        values.levels = []
        for column in newValues.pinnedColumns {
            values.pinnedColumns.append(column)
        }
        for column in newValues.unpinnedColumns {
            values.unpinnedColumns.append(column)
        }
        for column in newValues.calculatedColumns {
            values.calculatedColumns.append(column)
        }
        for sort in newValues.levels {
            values.levels.append(sort)
        }
        try refresh()
    }
    
    var referencedColumns: Set<InsightColumn> {
        get throws {
            var result = Set<InsightColumn>()
            for column in values.pinnedColumns {
                add(column)
            }
            for column in values.unpinnedColumns {
                add(column)
            }
            for column in values.calculatedColumns {
                add(column)
                try action(column)
            }
            for level in values.levels {
                if let column = level.key {
                    add(column)
                }
                if !level.selectionLogic.isEmpty {
                    try level.traverse(self, action)
                }
            }
            return result
            
            func add(_ column: InsightColumn) {
                result.insert(column)
            }
            
            func action(_ column: InsightColumn) throws -> () {
                add(column)
                if case .calculated(let calculated) = column {
                    try calculated.traverse(self, action)
                }
            }
        }
    }
    
    func generateRecalculationIndexes() throws -> [String: Int] {
        // Note that although these are put back into the reports values, the old values will
        // be cached in parse trees etc and those valuese will be stale. Much better to use the return dictionary
        
        // Set all to 1 and generate referenced columns for each
        var referencedColumns: [InsightColumn:Set<InsightColumn>] = [:]
        var recalculationIndexes: [String: Int] = [:]
        var index = 1
        for calculatedColumn in values.calculatedColumns {
            if case .calculated(let calculation) = calculatedColumn {
                recalculationIndexes[calculatedColumn.name] = index
            }
            referencedColumns[calculatedColumn] = try CalculatedColumn.referencedColumns(report: self, column: calculatedColumn)
        }
        // Now iterate round increasing the index if they reference columns at the same level
        var finished = false
        repeat {
            finished = true
            index += 1
            for calculatedColumn in values.calculatedColumns {
                if case .calculated(let calculation) = calculatedColumn {
                    for reference in referencedColumns[calculatedColumn]! {
                        if case .calculated(let referenceCalculation) = reference {
                            if recalculationIndexes[referenceCalculation.name] == index - 1 {
                                recalculationIndexes[calculation.name] = index
                                finished = false
                            }
                        }
                    }
                }
            }
        } while !finished
        // Insert the results back into the report
        for calculatedColumn in values.calculatedColumns {
            if case .calculated(let calculation) = calculatedColumn {
                calculation.recalculationIndex = recalculationIndexes[calculatedColumn.name]!
            }
        }
        
        return recalculationIndexes
    }
    
    func refresh() throws {
        for column in values.calculatedColumns {
            if case .calculated(let calculation) = column {
                try calculation.refresh(report: self)
            }
        }
        for sort in values.levels {
            try sort.refresh(report: self)
        }
    }
}

class CalculatedColumn : Codable, Equatable, Hashable, Identifiable, ObservableObject {
    var id = UUID()
    var title: String = ""
    var type: CalculatedType = .numeric
    var decimalPlaces: Int = 0
    var width: Int = 80
    var align: CalculatedAlignment = .right
    var blankIf: CalculatedBlankIf = .none
    var percent: Bool = false
    var visibility: CalculatedVisibility = .both
    var totalType: CalculatedTotalType = .average
    var recalculate: Bool = false
    var logic: [CalculatedElement] = []
    var recalculationIndex: Int = 0
    
    var name: String {
        var result: String = ""
        var words = title.split(separator: " ").map{ String($0.capitalized) }.filter({$0.trim() != ""})
        result = (words.first ?? "").lowercased()
        if !words.isEmpty {
            words.removeFirst()
        }
        result += words.joined(separator: "")
        return result
    }
    
    var tree: CalculatedParseNode?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(type)
        hasher.combine(decimalPlaces)
        hasher.combine(width)
        hasher.combine(align)
        hasher.combine(blankIf)
        hasher.combine(percent)
        hasher.combine(visibility)
        hasher.combine(totalType)
        hasher.combine(recalculate)
        hasher.combine(logic)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case type
        case decimalPlaces
        case align
        case width
        case blankIf
        case percent
        case visibility
        case totalType
        case recalculate
        case logic
    }
    
    func refresh(report: Report) throws {
        // Clear parse trees
        tree = nil
        // Update potentially stale references in logic
        for (index, logic) in self.logic.enumerated() {
            if case .variable(let column) = logic {
                if case .calculated = column {
                    if let freshColumn = report.values.calculatedColumns.first(where: {$0.name == column.name}) {
                        self.logic[index] = .variable(freshColumn)
                    } else {
                        throw CalculatedError.invalidVariableName(column.name)
                    }
                }
            }
        }
    }
    
    func copy(from: CalculatedColumn) {
        self.id = from.id
        self.title = from.title
        self.type = from.type
        self.decimalPlaces = from.decimalPlaces
        self.align = from.align
        self.width = from.width
        self.blankIf = from.blankIf
        self.percent = from.percent
        self.visibility = from.visibility
        self.totalType = from.totalType
        self.recalculate = from.recalculate
        self.logic = from.logic
    }
    
    func value<ViewModel>(report: Report, viewModel: ViewModel, evaluate: @escaping (Report, ViewModel, InsightColumn) throws -> CalculatedValue?) throws -> CalculatedValue {
        prepareTree(report: report)
        if let tree = tree {
            return try tree.value(viewModel: viewModel, variableValue: { column, viewModel in try evaluate(report, viewModel, column) })
        } else {
            throw CalculatedError.errorEvaluatingCalculatedColumn(name)
        }
    }
    
    func traverse(_ report: Report, _ calculatedAction: (InsightColumn) throws -> ()) throws {
        prepareTree(report: report)
        if let tree = tree {
            try tree.traverse(calculatedAction)
        } else {
            throw CalculatedError.errorEvaluatingCalculatedColumn(name)
        }
    }
    
    static func referencedColumns(report: Report, column: InsightColumn) throws -> Set<InsightColumn> {
        var result = Set<InsightColumn>()
        if case .calculated(let calculated) = column {
            try calculated.traverse(report, action)
        }
        return result
            
        func add(_ column: InsightColumn) {
            // Important - This column is a stale copy from the logic of the parent - need to get the latest
            var column = column
            if column.isCalculated {
                column = report.values.calculatedColumns.first(where: {$0.name == column.name})!
            }
            result.insert(column)
        }
        
        func action(_ column: InsightColumn) throws -> () {
            add(column)
            if case .calculated(let calculated) = column {
                try calculated.traverse(report, action)
            }
        }
    }
    
    func prepareTree(report: Report) {
        if tree == nil {
            let parser = CalculatedParser(report: report, tokens: logic)
            parser.parse() { (tree, message) in
                self.tree = tree
                Report.parses += 1
                print("Calculation parses: \(Report.parses)")
            }
        }
    }
    
    static func == (lhs: CalculatedColumn, rhs: CalculatedColumn) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.type == rhs.type && lhs.decimalPlaces == rhs.decimalPlaces && lhs.align == rhs.align && lhs.width == rhs.width && lhs.blankIf == rhs.blankIf && lhs.percent == rhs.percent && lhs.visibility == rhs.visibility && lhs.totalType == rhs.totalType && lhs.recalculate == rhs.recalculate && lhs.logic == rhs.logic
    }
}

enum CalculatedAlignment : Int, CaseIterable, Codable {
    case left = 1
    case center = 2
    case right = 3
    
    var string: String {
        "\(self)".capitalized
    }
}

enum CalculatedBlankIf : Int, CaseIterable, Codable {
    case negative = -2
    case nonPositive = -1
    case zero = 0
    case nonNegative = 1
    case positive = 2
    case none = 3
    
    var string: String {
        switch self {
        case .negative:
            "< 0"
        case .nonPositive:
            "≤ 0"
        case .zero:
            "= 0"
        case .nonNegative:
            "≥ 0"
        case .positive:
            "> 0"
        case .none:
            "None"
        }
    }
    
    func evaluate(value: Float) -> Bool {
        switch self {
        case .negative:
            value < 0
        case .nonPositive:
            value <= 0
        case .zero:
            value == 0
        case .nonNegative:
            value >= 0
        case .positive:
            value > 0
        default:
            false
        }
    }
}

enum CalculatedTotalType: Int, Equatable, Hashable, Codable, CaseIterable {
    case total = 1
    case average = 2
    
    var string: String {
        "\(self)".capitalized
    }
}

enum CalculatedVisibility : Int, Equatable, Hashable, Codable, CaseIterable {
    case boardOnly = 1
    case totalOnly = 2
    case both = 3
    case none = 0
    
    var string: String {
        "\(self)".capitalized
    }
    var isInTotal: Bool {
        self == .totalOnly || self == .both
    }
    
    var isInBoard: Bool {
        self == .boardOnly || self == .both
    }
}

class CalculatedSortLevel : Codable, Equatable, Hashable, Identifiable { // Had to be a struct to refresh parent view!
    var id: UUID = UUID()
    var isBoard: Bool
    var key: InsightColumn?
    var direction: SortDirection
    var subtotal: Bool
    var selectionLogic: [CalculatedElement]
    
    var selectionTree: CalculatedParseNode?
    
    var isTotalling: Bool {
        !isBoard && (subtotal || !selectionLogic.isEmpty)
    }
    
    func value<ViewModel>(report: Report, viewModel: ViewModel, level: Int, evaluate: @escaping (ViewModel, InsightColumn) throws -> CalculatedValue?) throws -> Bool {
        if selectionLogic.isEmpty {
            return true
        } else {
            prepareTree(report: report)
            if let tree = selectionTree {
                let value = try tree.value(viewModel: viewModel, variableValue: { column, viewModel in
                    try evaluate(viewModel, column) })
                if value.isBoolean, let boolean = value.boolean {
                    return boolean
                } else {
                    throw CalculatedError.errorEvaluatingSelection(isBoard ? "board level" : "level \(level)")
                }
            } else {
                throw CalculatedError.errorEvaluatingSelection(isBoard ? "board level" : "level \(level)")
            }
        }
    }
    
    func refresh(report: Report) throws {
        // Clear parse trees
        selectionTree = nil
        for (index, logic) in self.selectionLogic.enumerated() {
            // Update potentially stale references in logic
            if case .variable(let column) = logic {
                if case .calculated = column {
                    if let freshColumn = report.values.calculatedColumns.first(where: {$0.name == column.name}) {
                        self.selectionLogic[index] = .variable(freshColumn)
                    } else {
                        throw CalculatedError.invalidVariableName(column.name)
                    }
                }
            }
        }
        // Update potentially stale reference in sort key
        if let key = key {
            if case .calculated = key {
                if let freshColumn = report.values.calculatedColumns.first(where: {$0.name == key.name}) {
                    self.key = freshColumn
                } else {
                    throw CalculatedError.invalidVariableName(key.name)
                }
            }
        }
    }
    
    func prepareTree(report: Report) {
        if selectionTree == nil {
            let parser = CalculatedParser(report: report, tokens: selectionLogic)
            parser.parse() { (tree, message) in
                self.selectionTree = tree
                Report.selectionParses += 1
                print("Selection parses: \(Report.selectionParses)")
            }
        }
    }
    
    func traverse(_ report: Report, _ action: (InsightColumn) throws -> ()) throws {
        prepareTree(report: report)
        if let tree = selectionTree {
            try tree.traverse(action)
        }
    }
    
    init(isBoard: Bool = false) {
        self.isBoard = isBoard
        self.key = nil
        self.direction = .ascending
        self.subtotal = false
        self.selectionLogic = []
    }
    
    func copy(from: CalculatedSortLevel) {
        self.isBoard = from.isBoard
        self.key = from.key
        self.direction = from.direction
        self.subtotal = from.subtotal
        self.selectionLogic = from.selectionLogic
    }
    
    enum CodingKeys: String, CodingKey {
        case isBoard
        case key
        case direction
        case subtotal
        case selectionLogic
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(isBoard)
        hasher.combine(key)
        hasher.combine(direction)
        hasher.combine(subtotal)
        hasher.combine(selectionLogic)
    }
    
    static func == (lhs: CalculatedSortLevel, rhs: CalculatedSortLevel) -> Bool {
        return lhs.isBoard == rhs.isBoard && lhs.key == rhs.key && lhs.direction == rhs.direction && lhs.subtotal == rhs.subtotal && lhs.selectionLogic == rhs.selectionLogic
    }
    
    var selectionLogicString: String {
        selectionLogic.map{$0.string}.joined(separator: " ")
    }
}

