//
//  Sort Helpers.swift
//  BridgeScore
//
//  Created by Marc Shearer on 12/05/2026.
//

import Foundation

class SortData<ViewModel,Value:Comparable> : Identifiable, Hashable {
    var id = UUID()
    var rowType: InsightRowType?
    var totalLevel: Int?
    var levelKey: AttributedString?
    var keys: [CalculatedValue]
    var source: ViewModel?
    var totals: [InsightColumn:Value] = [:] // (Count, Total)
    var totalIndex: [Int?] = []
    var state: SortDataState = .expanded
    
    init(rowType: InsightRowType, totalLevel: Int? = nil, levelKey: AttributedString? = nil, keys: [CalculatedValue], source: ViewModel? = nil, totals: [InsightColumn:Value] = [:], state: SortDataState = .expanded) {
        self.rowType = rowType
        self.totalLevel = totalLevel
        self.levelKey = levelKey
        self.keys = keys
        self.source = source
        self.totals = totals
        self.state = state
    }
    
    static func == (lhs: SortData<ViewModel, Value>, rhs: SortData<ViewModel, Value>) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

enum SortDataState {
    case expanded
    case collapsed
    
    var inverse: SortDataState { (self == .expanded ? .collapsed : .expanded) }
}

class SortIndex {
    
    public static func sort<ViewModel,Value:Comparable>(_ first: SortData<ViewModel,Value>, _ second: SortData<ViewModel,Value>, directions: [SortDirection]) throws -> Bool {
        assert(first.keys.count == directions.count && second.keys.count == directions.count, "Inconsistent sort data")
        var result = false
        for key in 0..<directions.count {
            let firstValue = first.keys[key]
            let secondValue = second.keys[key]
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
        
        // Usage let sorted: [SortData] = sortDataList.sorted(by: { sort(first: $0, second: $1, directions: directions}) }
    }
}

