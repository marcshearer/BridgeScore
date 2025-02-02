//
//  Scorecard Filter Values.swift
//  BridgeScore
//
//  Created by Marc Shearer on 30/03/2022.
//

import Foundation

class ScorecardFilterValues: ObservableObject {
    @Published public var partners: Flags
    @Published public var locations: Flags
    @Published public var dateFrom: Date?
    @Published public var dateTo: Date?
    @Published public var types: Flags
    @Published public var searchText: String
    @Published public var filterType: FilterType
    
    init(_ filterType: FilterType) {
        self.filterType = filterType
        self.partners = Flags()
        self.locations = Flags()
        self.types = Flags()
        self.searchText = ""
    }
    
    public var partner: PlayerViewModel? {
        var result: PlayerViewModel?
        if let partnerIdString = partners.firstValue(equal: true) as? String {
            if let partnerId = UUID(uuidString: partnerIdString) {
                result = MasterData.shared.player(id: partnerId)
            }
        }
        return result
    }
    
    public var location: LocationViewModel? {
        var result: LocationViewModel?
        if let locationIdString = locations.firstValue(equal: true) as? String {
            if let locationId = UUID(uuidString: locationIdString) {
                result = MasterData.shared.location(id: locationId)
            }
        }
        return result
    }

    public func clear() {
        self.partners.clear()
        self.locations.clear()
        self.types.clear()
        self.dateFrom = nil
        self.dateTo = nil
        self.searchText = ""
        save()
    }
    
    public func load() {
        ScorecardFilterValues.load(filterValues: self, type: self.filterType)
    }
    
    public func save() {
        ScorecardFilterValues.save(filterValues: self, type: self.filterType)
    }
    
    public var isClear: Bool {
        return (
            self.partners.isClear &&
            self.locations.isClear &&
            self.types.isClear &&
            self.dateFrom == nil &&
            self.dateTo == nil &&
            self.searchText == "")
    }
    
    public func filter(_ scorecard: ScorecardViewModel) -> Bool {
        var include = true
        if searchText != "" {
            let scorecardText = "\(scorecard.desc) \(scorecard.comment) \(scorecard.location?.name ?? "") \(scorecard.partner?.name ?? "") \(scorecard.type.string)"
            include = self.wordSearch(for: searchText, in: scorecardText)
        }
        
        if !partners.isEmpty {
            if !partners.value(scorecard.partner?.playerId.uuidString) {
                include = false
            }
        }
    
        if !locations.isEmpty {
            if !locations.value(scorecard.location?.locationId.uuidString) {
                include = false
            }
        }

        if !types.isEmpty {
            if !types.value(scorecard.type.eventType.rawValue) {
                include = false
            }
        }
        
        if let dateFrom = dateFrom {
            if scorecard.date < Date.startOfDay(from: dateFrom)! {
                include = false
            }
        }

        if let dateTo = dateTo {
            if scorecard.date > Date.endOfDay(from: dateTo)! {
                include = false
            }
        }
        
        return include
    }
    
    private func wordSearch(for searchWords: String, in target: String) -> Bool {
        var result = true
        let searchList = searchWords.uppercased().components(separatedBy: " ")
        let targetList = target.uppercased().components(separatedBy: " ")
        
        for searchWord in searchList {
            var found = false
            for targetWord in targetList {
                if targetWord.starts(with: searchWord) {
                    found = true
                }
            }
            if !found {
                result = false
            }
        }
        
        return result
        
    }
    
    public static func load(filterValues: ScorecardFilterValues, type: FilterType) {

        // Partners
        if let partners = FilterUserDefault.filterPartners.array(type) as? [String] {
            filterValues.partners.setArray(partners)
        }
        
        // Locations
        if let locations = FilterUserDefault.filterLocations.array(type) as? [String] {
            filterValues.locations.setArray(locations)
        }

        // Types
        if let types = FilterUserDefault.filterTypes.array(type) as? [Int] {
            filterValues.types.setArray(types)
        }
            
        // Date from
        if let dateFrom = FilterUserDefault.filterDateFrom.date(type) {
            filterValues.dateFrom = dateFrom
        }

        // Date to
        if let dateTo = FilterUserDefault.filterDateTo.date(type) {
            filterValues.dateTo = dateTo
        }
                    
        // Search text
        filterValues.searchText = FilterUserDefault.filterSearchText.string(type)
         
    }
    
    public static func save(filterValues: ScorecardFilterValues, type: FilterType) {
        FilterUserDefault.filterPartners.set(filterValues.partners.trueValues, type: type)
        FilterUserDefault.filterLocations.set(filterValues.locations.trueValues, type: type)
        FilterUserDefault.filterTypes.set(filterValues.types.trueValues, type: type)
        FilterUserDefault.filterDateFrom.set(filterValues.dateFrom, type: type)
        FilterUserDefault.filterDateTo.set(filterValues.dateTo, type: type)
        FilterUserDefault.filterSearchText.set(filterValues.searchText, type: type)
    }
}
