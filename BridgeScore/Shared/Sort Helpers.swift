//
//  Sort Helpers.swift
//  BridgeScore
//
//  Created by Marc Shearer on 12/05/2026.
//

import Foundation

class SortData : Identifiable, Hashable {
    var id = UUID()
    var cellType: SortDataCellType?
    var totalType: SortTotalType?
    var xTotalLevel: Int?
    var yTotalLevel: Int?
    var levelKey: AttributedString?
    var xKeys: [CalculatedValue]
    var yKeys: [CalculatedValue]
    var xTotalCell: SortData? = nil
    var yTotalCell: SortData? = nil
    var source: BoardSummaryExtension? // This is any element in the total for a total cell
    private(set) var totals = SortTotals()
    var firstIndex: Int? = nil
    var lastIndex: Int? = nil
    var linked: [SortData] = []
    var state: SortDataState = .expanded
    
    init(cellType: SortDataCellType, totalType: SortTotalType? = nil, xTotalLevel: Int? = nil, yTotalLevel: Int? = nil, levelKey: AttributedString? = nil, xKeys: [CalculatedValue] = [], yKeys: [CalculatedValue], source: BoardSummaryExtension? = nil, totals: SortTotals = SortTotals(), firstIndex: Int? = nil, lastIndex: Int? = nil, state: SortDataState = .expanded) {
        self.cellType = cellType
        self.totalType = totalType
        self.xTotalLevel = xTotalLevel
        self.yTotalLevel = yTotalLevel
        self.levelKey = levelKey
        self.xKeys = xKeys
        self.yKeys = yKeys
        self.source = source
        self.totals.set(to: totals)
        self.firstIndex = firstIndex
        self.lastIndex = lastIndex
        self.state = state
    }
    
    var totalLevel: Int? {
        switch totalType {
        case .xAxis:
            xTotalLevel
        case .yAxis:
            yTotalLevel
        default:
            nil
        }
    }
    
    func set(totalCell: SortData?, axis: SortTotalType? = nil) {
        switch axis ?? totalCell?.totalType {
        case .xAxis:
            xTotalCell = totalCell
        case .yAxis:
            yTotalCell = totalCell
        default:
            xTotalCell = totalCell
            yTotalCell = totalCell
        }
    }
    
    func keys(axis: SortTotalType) -> [CalculatedValue] {
        switch axis {
        case .xAxis:
            xKeys
        case .yAxis:
            yKeys
        case .cell, .compound:
            yKeys + xKeys
        }
    }
        
    func keyString(axis: SortTotalType) -> String {
        var result: String = ""
        let keys = keys(axis: axis)
        for key in keys {
            let keyString = key.text
            if result != "" {
                result += ", "
            }
            result += keyString
        }
        return result
    }
    
    func copy(totalType: SortTotalType? = nil, totalLevel: Int? = nil, totals: SortTotals? = nil, firstIndex: Int? = nil, state: SortDataState? = nil) -> SortData {
        let copy = SortData(cellType: cellType!, totalType: totalType ?? self.totalType, xTotalLevel: xTotalLevel, yTotalLevel: yTotalLevel, levelKey: levelKey, xKeys: xKeys, yKeys: yKeys, source: source, firstIndex: firstIndex ?? self.firstIndex, lastIndex: lastIndex, state: state ?? self.state)
        copy.totals.set(to: totals ?? self.totals)
        
        if totalType != nil {
            cellType = .total
            switch totalType {
            case .xAxis:
                copy.yKeys = []
                copy.yTotalLevel = nil
                if let totalLevel = totalLevel {
                    copy.xKeys = Array(xKeys.prefix(totalLevel))
                    copy.xTotalLevel = totalLevel
                }
            case .yAxis:
                copy.xKeys = []
                copy.xTotalLevel = nil
                if let totalLevel = totalLevel {
                    copy.yKeys = Array(yKeys.prefix(totalLevel))
                    copy.yTotalLevel = totalLevel
                }
            default:
                break
            }
        }
        return copy
    }
    
    func total(column: InsightColumn) -> InsightTotal? {
        totals.total(column: column)
    }
    
    func set(column: InsightColumn, total: InsightTotal) {
        totals.set(column: column, total: total)
    }
    
    func set(totals: SortTotals) {
        self.totals.set(to: totals)
    }
    
    func set(column: InsightColumn, value: Float) {
        totals.set(column: column, value: value)
    }
    
    func add(totals: SortTotals) {
        self.totals.add(totals: totals)
    }
    
    func getTotalValue(name: String) -> Float? {
        // Only used for debug
        totals.getValue(name: name)
    }
    
    static func == (lhs: SortData, rhs: SortData) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

enum SortDataCellType {
    case data
    case total
}

enum SortTotalType {
    case xAxis
    case yAxis
    case cell
    case compound
}

enum SortDataState : Codable, Hashable, CaseIterable {
    case expanded
    case collapsed
    case hidden
    
    var inverse: SortDataState { (self == .expanded ? .collapsed : self == .collapsed ? .expanded : self) }
    
    var string: String { "\(self)".capitalized }
}

class SortTotals {
    private var totals: [InsightColumn:InsightTotal]
    
    init() {
        totals = [:]
    }
    
    init(columns: [InsightColumn]) {
        totals = Dictionary(uniqueKeysWithValues: zip(columns, repeatElement(InsightTotal(), count: columns.count)))
    }
    
    func total(column: InsightColumn) -> InsightTotal? {
        totals[column]
    }
    
    func set(column: InsightColumn, total: InsightTotal) {
        if totals[column] == nil { totals[column] = InsightTotal()}
        totals[column]!.copy(from: total)
    }
    
    func set(column: InsightColumn, value: Float) {
        // Must already exist and count is preserved
        totals[column]!.value = value
    }
    
    func set(to totals: SortTotals) {
        totals.iterate() { column, total in
            self.set(column: column, total: total)
        }
    }
    
    func add(column: InsightColumn, total: InsightTotal) {
        if totals[column] == nil { totals[column] = InsightTotal()}
        totals[column]!.add(total: total)
    }

    func add(column: InsightColumn, value: Float) {
        if totals[column] == nil { totals[column] = InsightTotal()}
        totals[column]!.add(value: value)
    }

    func add(totals: SortTotals) {
        totals.iterate() { column, total in
            if self.totals[column] == nil { self.totals[column] = InsightTotal()}
            self.totals[column]!.add(total: total)
        }
    }
    
    func iterate(action: (InsightColumn, InsightTotal)->()) {
        for (column, total) in totals {
            action(column, total)
        }
    }
    
    func getValue(name: String) -> Float? {
        // Only used to debug
        if let value = totals.first(where: {$0.key.name.lowercased() == name.lowercased()})?.value {
            return value.value
        } else {
            return nil
        }
    }
}

class SortIndex {
    
    public static func sort(_ first: SortData, _ second: SortData, directions: [SortDirection] = []) throws -> Bool {
        assert(first.yKeys.count + first.xKeys.count == directions.count && second.yKeys.count + second.xKeys.count == directions.count , "Inconsistent sort data")
        var result = false
        let firstKeys = first.yKeys + first.xKeys
        let secondKeys = second.yKeys + second.xKeys
        for key in 0..<directions.count {
            let firstValue = firstKeys[key]
            let secondValue = secondKeys[key]
            let equal = try (firstValue == secondValue).boolean!
            let lessThan = try (firstValue < secondValue).boolean!
            if !equal {
                result = lessThan
                if directions[key] == .descending {
                    result.toggle()
                }
                break
            }
        }
        return result
        
        // Usage let sorted: [SortData] = sortDataList.sorted(by: { sort(first: $0, second: $1, xDirections: xDirections, yDirections: yDirections}) }
        
        // Note that sort is by Y keys first and then X keys
    }
}

