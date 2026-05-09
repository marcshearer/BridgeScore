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
    var calculatedColumns: [InsightColumn]
    
    init(pinnedColumns: [InsightColumn], unpinnedColumns: [InsightColumn], calculatedColumns: [InsightColumn]) {
        self.pinnedColumns = pinnedColumns
        self.unpinnedColumns = unpinnedColumns
        self.calculatedColumns = calculatedColumns
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
    
    init(pinnedColumns: [InsightColumn], unpinnedColumns: [InsightColumn], calculatedColumns: [InsightColumn]) {
        self.values = ReportValues(pinnedColumns: pinnedColumns, unpinnedColumns: unpinnedColumns, calculatedColumns: calculatedColumns)
    }
    
    func update(from newValues: ReportValues) {
        values.pinnedColumns = []
        values.unpinnedColumns = []
        values.calculatedColumns = []
        for column in newValues.pinnedColumns {
            values.pinnedColumns.append(column)
        }
        for column in newValues.unpinnedColumns {
            values.unpinnedColumns.append(column)
        }
        for column in newValues.calculatedColumns {
            values.calculatedColumns.append(column)
        }
    }
}

class CalculatedColumn : Codable, Equatable, Hashable, Identifiable, ObservableObject {
    var id = UUID()
    var title: String = ""
    var name: String = ""
    var type: CalculatedType = .numeric
    var decimalPlaces: Int = 0
    var width: Int = 80
    var align: CalculatedAlignment = .right
    var blankIf: CalculatedBlankIf = .none
    var percent: Bool = false
    var logic: [CalculatedElement] = []
    
    var tree: CalculatedParseNode?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(decimalPlaces)
        hasher.combine(width)
        hasher.combine(align)
        hasher.combine(blankIf)
        hasher.combine(percent)
        hasher.combine(logic)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
        case type
        case decimalPlaces
        case align
        case width
        case blankIf
        case percent
        case logic
    }
    
    func copy(from: CalculatedColumn) {
        self.id = from.id
        self.title = from.title
        self.name = from.name
        self.type = from.type
        self.decimalPlaces = from.decimalPlaces
        self.align = from.align
        self.width = from.width
        self.blankIf = from.blankIf
        self.percent = from.percent
        self.logic = from.logic
    }
    
    func value<ViewModel>(viewModel: ViewModel, evaluate: @escaping (ViewModel, InsightColumn) throws -> CalculatedValue?) throws -> CalculatedValue {
        if tree == nil {
            let parser = CalculatedParser(tokens: logic)
            parser.parse() { (tree, message) in
                self.tree = tree
            }
        }
        if let tree = tree {
            return try tree.value(viewModel: viewModel, variableValue: { column, vm in try evaluate(vm, column) })
        } else {
            throw CalculatedError.errorEvaluatingCalculatedColumn(name)
        }
    }
    
    static func == (lhs: CalculatedColumn, rhs: CalculatedColumn) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.name == rhs.name && lhs.type == rhs.type && lhs.decimalPlaces == rhs.decimalPlaces || lhs.align == rhs.align || lhs.width == rhs.width || lhs.blankIf == rhs.blankIf || lhs.percent == rhs.percent || lhs.logic == rhs.logic
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
