//
//  Report.swift
//  BridgeScore
//
//  Created by Marc Shearer on 06/05/2026.
//

import SwiftUI

class ReportValues: Codable {
    var viewName: String
    var pinnedColumns: [InsightColumn]
    var unpinnedColumns: [InsightColumn]
    var calculatedColumns: [InsightColumn]
    var prompts: [InsightColumn]
    var levels: [CalculatedSortLevel]
    
    init(viewName: String = "", pinnedColumns: [InsightColumn], unpinnedColumns: [InsightColumn], calculatedColumns: [InsightColumn] = [], prompts: [InsightColumn] = [], levels: [CalculatedSortLevel] = [CalculatedSortLevel(isBoard: true)]) {
        self.viewName = viewName
        self.pinnedColumns = pinnedColumns
        self.unpinnedColumns = unpinnedColumns
        self.calculatedColumns = calculatedColumns
        self.levels = levels
        self.prompts = prompts
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.viewName = try container.decodeIfPresent(String.self, forKey: .viewName) ?? ""
        self.pinnedColumns = try container.decodeIfPresent([InsightColumn].self, forKey: .pinnedColumns) ?? []
        self.unpinnedColumns = try container.decodeIfPresent([InsightColumn].self, forKey: .unpinnedColumns) ?? []
        self.calculatedColumns = try container.decodeIfPresent([InsightColumn].self, forKey: .calculatedColumns) ?? []
        self.levels = try container.decodeIfPresent([CalculatedSortLevel].self, forKey: .levels) ?? []
        self.prompts = try container.decodeIfPresent([InsightColumn].self, forKey: .prompts) ?? []
    }
    
    var unpinnedSpacerColumns: [InsightColumn] {
        unpinnedColumns + [InsightColumn.spacer]
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
    
    init(viewName: String = "", pinnedColumns: [InsightColumn] = [], unpinnedColumns: [InsightColumn] = [], calculatedColumns: [InsightColumn] = [], prompts: [InsightColumn] = [], levels: [CalculatedSortLevel] = [CalculatedSortLevel(isBoard: true)]) {
        self.values = ReportValues(viewName: viewName, pinnedColumns: pinnedColumns, unpinnedColumns: unpinnedColumns, calculatedColumns: calculatedColumns, prompts: prompts, levels: levels)
    }
    
    func update(from newValues: ReportValues) throws {
        values.viewName = newValues.viewName
        values.pinnedColumns = []
        values.unpinnedColumns = []
        values.calculatedColumns = []
        values.levels = []
        values.prompts = []
        for column in newValues.pinnedColumns {
            values.pinnedColumns.append(column)
        }
        for column in newValues.unpinnedColumns {
            values.unpinnedColumns.append(column)
        }
        for column in newValues.calculatedColumns {
            values.calculatedColumns.append(column)
        }
        for level in newValues.levels {
            values.levels.append(level)
        }
        for prompt in newValues.prompts {
            values.prompts.append(prompt)
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
                recalculationIndexes[calculation.name] = index
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
                calculation.recalculationIndex = recalculationIndexes[calculation.name]!
            }
        }
        
        return recalculationIndexes
    }
    
    func refresh(includePrompts: Bool = true) throws {
        for column in values.calculatedColumns {
            if case .calculated(let calculation) = column {
                try calculation.refresh(report: self)
            }
        }
        for sort in values.levels {
            try sort.refresh(report: self)
        }
        if includePrompts {
            for prompt in values.prompts {
                if case .prompt(let prompt) = prompt {
                    prompt.refresh(report: self)
                }
            }
        }
    }
}

class CalculatedColumn : InsightColumnConfig {
    var id = UUID()
    var type: CalculatedType = .numeric
    var decimalPlaces: Int = 0
    var percent: Bool = false
    var recalculate: Bool = false
    var logic: [CalculatedElement] = []
    var recalculationIndex: Int = 0
    
    override init() {
        super.init()
    }
    
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
    
    override func hash(into hasher: inout Hasher) {
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
        case type
        case decimalPlaces
        case percent
        case recalculate
        case logic
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        do {
            type = try container.decodeIfPresent(CalculatedType.self, forKey: .type) ?? .numeric
        } catch {
            self.type = .numeric
        }
        decimalPlaces = try container.decodeIfPresent(Int.self, forKey: .decimalPlaces) ?? 0
        percent = try container.decodeIfPresent(Bool.self, forKey: .percent) ?? false
        recalculate = try container.decodeIfPresent(Bool.self, forKey: .recalculate) ?? false
        do {
            logic = try container.decodeIfPresent([CalculatedElement].self, forKey: .logic) ?? []
        } catch {
            self.logic = []
        }
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(decimalPlaces, forKey: .decimalPlaces)
        try container.encode(percent, forKey: .percent)
        try container.encode(recalculate, forKey: .recalculate)
        try container.encode(logic, forKey: .logic)
        try super.encode(to: encoder)
    }
    
    func refresh(report: Report) throws {
        // Clear parse trees
        tree = nil
        // Update potentially stale references in logic
        for (index, logic) in self.logic.enumerated() {
            if case .variable(let column) = logic {
                switch column {
                case .calculated:
                    if let freshColumn = report.values.calculatedColumns.first(where: {$0.name == column.name}) {
                        self.logic[index] = .variable(freshColumn)
                    } else {
                        throw CalculatedError.invalidVariableName(column.name)
                    }
                case .prompt:
                    if let freshColumn = report.values.prompts.first(where: {$0.name == column.name}) {
                        self.logic[index] = .variable(freshColumn)
                    } else {
                        throw CalculatedError.invalidVariableName(column.name)
                    }
                default:
                    break
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
    
    var textAlignment: TextAlignment {
        switch self {
        case .left:
                .leading
        case .center:
                .center
        case .right:
                .trailing
        }
    }
    
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
    var defaultState: SortDataState = .expanded
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
                switch column {
                case .calculated:
                    if let freshColumn = report.values.calculatedColumns.first(where: {$0.name == column.name}) {
                        self.selectionLogic[index] = .variable(freshColumn)
                    } else {
                        throw CalculatedError.invalidVariableName(column.name)
                    }
                case .prompt:
                    if let freshColumn = report.values.prompts.first(where: {$0.name == column.name}) {
                        self.selectionLogic[index] = .variable(freshColumn)
                    } else {
                        throw CalculatedError.invalidVariableName(column.name)
                    }
                default:
                    break
                }
            }
        }
        // Update potentially stale reference in sort key
        if let key = key {
            switch key {
            case .calculated:
                if let freshColumn = report.values.calculatedColumns.first(where: {$0.name == key.name}) {
                    self.key = freshColumn
                } else {
                    throw CalculatedError.invalidVariableName(key.name)
                }
            case .prompt:
                if let freshColumn = report.values.prompts.first(where: {$0.name == key.name}) {
                    self.key = freshColumn
                } else {
                    throw CalculatedError.invalidVariableName(key.name)
                }
            default:
                break
            }
        }
    }
    
    func prepareTree(report: Report) {
        if selectionTree == nil {
            let parser = CalculatedParser(report: report, tokens: selectionLogic)
            parser.parse() { (tree, message) in
                self.selectionTree = tree
                Report.selectionParses += 1
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
        self.defaultState = .expanded
        self.selectionLogic = []
    }
    
    func copy(from: CalculatedSortLevel) {
        self.isBoard = from.isBoard
        self.key = from.key
        self.direction = from.direction
        self.subtotal = from.subtotal
        self.defaultState = from.defaultState
        self.selectionLogic = from.selectionLogic
    }
    
    enum CodingKeys: String, CodingKey {
        case isBoard
        case key
        case direction
        case subtotal
        case defaultState
        case selectionLogic
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isBoard = try container.decodeIfPresent(Bool.self, forKey: .isBoard) ?? false
        key = try container.decodeIfPresent(InsightColumn.self, forKey: .key) ?? nil
        direction = try container.decodeIfPresent(SortDirection.self, forKey: .direction) ?? .ascending
        subtotal = try container.decodeIfPresent(Bool.self, forKey: .subtotal) ?? false
        defaultState = try container.decodeIfPresent(SortDataState.self, forKey: .defaultState) ?? .expanded
        do {
            selectionLogic = try container.decodeIfPresent([CalculatedElement].self, forKey: .selectionLogic) ?? []
        } catch {
            selectionLogic = []
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(isBoard)
        hasher.combine(key)
        hasher.combine(direction)
        hasher.combine(subtotal)
        hasher.combine(defaultState)
        hasher.combine(selectionLogic)
    }
    
    static func == (lhs: CalculatedSortLevel, rhs: CalculatedSortLevel) -> Bool {
        return lhs.isBoard == rhs.isBoard && lhs.key == rhs.key && lhs.direction == rhs.direction && lhs.subtotal == rhs.subtotal && lhs.defaultState == rhs.defaultState && lhs.selectionLogic == rhs.selectionLogic
    }
    
    var selectionLogicString: String {
        selectionLogic.map{$0.string}.joined(separator: " ")
    }
}

enum CalculatedPromptType : Int, Equatable, Hashable, Codable, CaseIterable {
    case partner = 1
    case location = 2
    case levelType = 3
    case suitType = 4
    case pairType = 5
    case seatPlayer = 6
    case eventType = 7
    case boardScoreType = 8
    case other = 0
    
    var string: String {
        switch self {
        case .levelType:
            "Level Type"
        case .suitType:
            "Suit Type"
        case .pairType:
            "Pair Type"
        case .seatPlayer:
            "Declarer"
        case .eventType:
            "Event Type"
        case .boardScoreType:
            "Scoring Method"
        default:
            "\(self)".capitalized
        }
    }
    
    var type: CalculatedType? {
        switch self {
        case .partner, .location, .levelType, .suitType, .pairType, .seatPlayer, .eventType, .boardScoreType:
            .string
        default:
            nil
        }
    }
}

class CalculatedPrompt : Codable, Equatable, Hashable, Identifiable, ObservableObject {
    var id: UUID = UUID()
    var name: String
    var promptText: String
    var type: CalculatedType
    var defaultValue: String
    var promptType: CalculatedPromptType
    var value: CalculatedValue?
    
    var calculatedDefaultValue: CalculatedValue {
        switch type {
        case .numeric:
            CalculatedValue(Float(defaultValue) ?? 0)
        case .string:
            CalculatedValue(defaultValue)
        case .boolean:
            CalculatedValue(defaultValue.lowercased() == "true")
        }
    }
    
    init() {
        self.name = ""
        self.promptText = ""
        self.type = .numeric
        self.defaultValue = ""
        self.promptType = .other
        self.value = nil
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case promptText
        case type
        case defaultValue
        case promptType
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        promptText = try container.decodeIfPresent(String.self, forKey: .promptText) ?? ""
        type = try container.decodeIfPresent(CalculatedType.self, forKey: .type) ?? .numeric
        defaultValue = try container.decodeIfPresent(String.self, forKey: .defaultValue) ?? ""
        promptType = try container.decodeIfPresent(CalculatedPromptType.self, forKey: .promptType) ?? .other
        value = nil
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(promptText)
        hasher.combine(type)
        hasher.combine(defaultValue)
        hasher.combine(value)
    }
    
    func copy(from: CalculatedPrompt) {
        self.name = from.name
        self.promptText = from.promptText
        self.type = from.type
        self.defaultValue = from.defaultValue
        self.promptType = from.promptType
        self.value = from.value
    }
    
    func refresh(report: Report) {
        // Copy default value to value
        switch self.type {
        case .numeric:
            self.value = CalculatedValue(Float(self.defaultValue) ?? 0)
        case .boolean:
            self.value = CalculatedValue(self.defaultValue.lowercased() == "true")
        case .string:
            self.value = CalculatedValue(self.defaultValue)
        }
    }
    
    static func == (lhs: CalculatedPrompt, rhs: CalculatedPrompt) -> Bool {
        lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.promptText == rhs.promptText
        && lhs.type == rhs.type
        && lhs.defaultValue == rhs.defaultValue
        && lhs.value == rhs.value
    }
}

