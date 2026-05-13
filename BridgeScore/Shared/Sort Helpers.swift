//
//  Sort Helpers.swift
//  BridgeScore
//
//  Created by Marc Shearer on 12/05/2026.
//

class SortData<ViewModel> {
    var totalLevel: Int?
    var keys: [CalculatedValue]
    var source: ViewModel?
    var totals: [InsightColumn:(Int,Float)] = [:] // (Count, Total)
    
    init(totalLevel: Int? = nil, keys: [CalculatedValue], source: ViewModel? = nil, totals: [InsightColumn:(Int, Float)] = [:]) {
        self.totalLevel = totalLevel
        self.keys = keys
        self.source = source
        self.totals = totals
    }
}

class SortIndex {
    
    public static func sort<ViewModel>(_ first: SortData<ViewModel>, _ second: SortData<ViewModel>, directions: [SortDirection]) throws -> Bool {
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

