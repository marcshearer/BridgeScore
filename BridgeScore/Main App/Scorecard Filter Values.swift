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
        FilterUserDefault.load(filterValues: self, type: self.filterType)
    }
    
    public func save() {
        FilterUserDefault.save(filterValues: self, type: self.filterType)
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
            let scorecardText = "\(scorecard.desc) \(scorecard.comment) \(scorecard.location?.name ?? "") \(scorecard.partner?.name ?? "")"
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
            if !types.value(scorecard.type.rawValue) {
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
}
