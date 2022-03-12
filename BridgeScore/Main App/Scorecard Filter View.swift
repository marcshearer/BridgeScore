//
//  Scorecard Filter View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 28/02/2022.
//

import SwiftUI

class ScorecardFilterValues: ObservableObject {
    @Published public var partner: PlayerViewModel?
    @Published public var location: LocationViewModel?
    @Published public var dateFrom: Date?
    @Published public var dateTo: Date?
    @Published public var type: Type?
    @Published public var searchText: String
    
    init(partner: PlayerViewModel? = nil, location: LocationViewModel? = nil, dateFrom: Date? = nil, dateTo: Date? = nil, type: Type? = nil, searchText: String = "") {
        self.partner = partner
        self.location = location
        self.dateFrom = dateFrom
        self.dateTo = dateTo
        self.type = type
        self.searchText = searchText
    }
    
    public func clear() {
        self.partner = nil
        self.location = nil
        self.dateFrom = nil
        self.dateTo = nil
        self.searchText = ""
    }
    
    public func filter(_ scorecard: ScorecardViewModel) -> Bool {
        var include = true
        if searchText != "" {
            let scorecardText = "\(scorecard.desc) \(scorecard.comment) \(scorecard.location?.name ?? "") \(scorecard.partner?.name ?? "")"
            include = self.wordSearch(for: searchText, in: scorecardText)
        }
        
        if let partner = partner {
            if partner != scorecard.partner {
                include = false
            }
        }

        if let location = location {
            if location != scorecard.location {
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
        
        if let type = type {
            if type != scorecard.type {
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

struct ScorecardFilterView: View {
    @ObservedObject var filterValues: ScorecardFilterValues
    @Binding var closeFilter: Bool
    @State private var partnerIndex: Int?
    @State private var locationIndex: Int?
    @State private var fromDateClearText: String? = nil
    @State private var toDateClearText: String? = nil
    let players = MasterData.shared.players.filter{!$0.retired}
    let locations = MasterData.shared.locations.filter{!$0.retired}
    
    var body: some View {
        
        HStack {
            
                Spacer().frame(width: 16)
                GeometryReader { (geometry) in
                ZStack {
                    Palette.filterTile.background
                        .ignoresSafeArea(edges: .all)
                        .cornerRadius(16)
                    VStack(spacing: 0) {
                        Spacer().frame(height: 4)
                        HStack {
                            Spacer().frame(width: 20)
                            VStack {
                                Spacer().frame(height: 8)
                                Text("FILTER BY:").font(.caption2)
                            }
                            Spacer()
                            Button {
                                filterValues.clear()
                                reset()
                                closeFilter = true
                            } label: {
                                Image(systemName: "xmark").foregroundColor(Palette.filterTile.text)
                            }
                            Spacer().frame(width: 8)
                        }
                        Spacer().frame(height: 10)
                        HStack {
                            let buttonWidth: CGFloat = (geometry.size.width - 24 - (3 * 15)) / 4
                            Spacer().frame(width: 16)
                            PickerInput(field: $partnerIndex, values: {["No partner filter"] + players.map{$0.name}}, popupTitle: "Partners", placeholder: "Partner", width: buttonWidth, height: 40, centered: true, color: (partnerIndex != nil ? Palette.filterUsed : Palette.filterUnused), selectedColor: Palette.filterUsed, cornerRadius: 20, animation: .none) { (index) in
                                if index ?? 0 != 0 {
                                    filterValues.partner = players[index! - 1]
                                } else {
                                    partnerIndex = nil
                                    filterValues.partner = nil
                                }
                            }
                            
                            Spacer().frame(width: 15)
                            
                            PickerInput(field: $locationIndex, values: {["No location filter"] + locations.map{$0.name}}, popupTitle: "Locations", placeholder: "Location", width: buttonWidth, height: 40, centered: true, color: (locationIndex != nil ? Palette.filterUsed : Palette.filterUnused), selectedColor: Palette.filterUsed, cornerRadius: 20, animation: .none) { (index) in
                                if index ?? 0 != 0 {
                                    filterValues.location = locations[index! - 1]
                                } else {
                                    locationIndex = nil
                                    filterValues.location = nil
                                }
                            }
                            
                            Spacer().frame(width: 15)
                            
                            OptionalDatePickerInput(field: $filterValues.dateFrom, placeholder: "Date from", clearText: fromDateClearText, to: filterValues.dateTo, color: (filterValues.dateFrom != nil ? Palette.filterUsed : Palette.filterUnused), textType: .normal, cornerRadius: 20, width: buttonWidth, height: 40, centered: true) { (date) in
                                if date == nil {
                                    fromDateClearText = nil
                                } else {
                                    fromDateClearText = "Clear Date From"
                                }
                            }
                            
                            Spacer().frame(width: 20)
                            
                            OptionalDatePickerInput(field: $filterValues.dateTo, placeholder: "Date to", clearText: toDateClearText, from: filterValues.dateFrom, color: (filterValues.dateTo != nil ? Palette.filterUsed : Palette.filterUnused), textType: .normal, cornerRadius: 20, width: buttonWidth, height: 40, centered: true) { (date) in
                                if date == nil {
                                    toDateClearText = nil
                                } else {
                                    toDateClearText = "Clear Date To"
                                }
                            }
                            
                            Spacer()
                        }
                        Spacer().frame(height: 12)
                        HStack {
                            Spacer().frame(width: 16)
                            ZStack {
                                Rectangle()
                                    .foregroundColor(Palette.input.background)
                                    .cornerRadius(20)
                                if filterValues.searchText.isEmpty {
                                    HStack {
                                        Spacer().frame(width: 20)
                                        Text("Search words")
                                            .foregroundColor(Palette.input.faintText)
                                        Spacer()
                                    }
                                }
                                HStack {
                                    Input(field: $filterValues.searchText, height: 20, color: Palette.clear, clearText: true)
                                        .foregroundColor(Palette.input.text)
                                }
                            }
                            Spacer().frame(width: 8)
                        }
                        Spacer().frame(height: 12)
                    }
                }
            }
            .frame(height: 140)
            Spacer().rightSpacer
        }
        .onAppear {
            partnerIndex = filterValues.partner == nil ? nil : (players.firstIndex(where: {$0 == filterValues.partner})  ?? -1) + 1
            locationIndex = filterValues.location == nil ? nil : (locations.firstIndex(where: {$0 == filterValues.location})  ?? -1) + 1
        }
    }
    
    private func reset() {
        filterValues.partner = nil
        filterValues.location = nil
        filterValues.dateFrom = nil
        filterValues.dateTo = nil
        filterValues.type = nil
        filterValues.searchText = ""
    }
}

