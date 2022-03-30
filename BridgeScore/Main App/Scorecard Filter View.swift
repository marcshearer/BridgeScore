//
//  Scorecard Filter View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 28/02/2022.
//

import SwiftUI

class ScorecardFilterValues: ObservableObject {
    @Published public var partners: Flags
    @Published public var locations: Flags
    @Published public var dateFrom: Date?
    @Published public var dateTo: Date?
    @Published public var types: Flags
    @Published public var searchText: String
    
    init() {
        self.partners = Flags()
        self.locations = Flags()
        self.types = Flags()
        self.searchText = ""
    }
    
    public var partner: PlayerViewModel? {
        MasterData.shared.player(id: partners.firstValue(equal: true) as? UUID)
    }
    
    public var location: LocationViewModel? {
        MasterData.shared.location(id: locations.firstValue(equal: true) as? UUID)
    }

    public func clear() {
        self.partners.clear()
        self.locations.clear()
        self.types.clear()
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

struct ScorecardFilterView: View {
    var id: UUID
    @ObservedObject var filterValues: ScorecardFilterValues
    @Binding var closeFilter: Bool
    @State private var partnerIndex: Int?
    @State private var locationIndex: Int?
    @State private var fromDateClearText: String? = nil
    @State private var toDateClearText: String? = nil
    let players = MasterData.shared.players.filter{!$0.retired && !$0.isSelf}
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
                                .debugPrint("Partner: \(partnerIndex)")
                            PickerInput(id: id, field: $partnerIndex, values: {["No partner filter"] + players.map{$0.name}}, popupTitle: "Partners", placeholder: "Partner", width: buttonWidth, height: 40, centered: true, color: (partnerIndex != nil ? Palette.filterUsed : Palette.filterUnused), selectedColor: Palette.filterUsed, cornerRadius: 20, animation: .none) { (index) in
                                if index ?? 0 > 0 {
                                    partnerIndex = index
                                    filterValues.partners.set(players[index! - 1].playerId.uuidString)
                                } else {
                                    partnerIndex = nil
                                    filterValues.partners.clear()
                                }
                                filterValues.objectWillChange.send()
                            }
                            
                            Spacer().frame(width: 15)
                            
                            PickerInput(id: id, field: $locationIndex, values: {["No location filter"] + locations.map{$0.name}}, popupTitle: "Locations", placeholder: "Location", width: buttonWidth, height: 40, centered: true, color: (locationIndex != nil ? Palette.filterUsed : Palette.filterUnused), selectedColor: Palette.filterUsed, cornerRadius: 20, animation: .none) { (index) in
                                if index ?? 0 != 0 {
                                    locationIndex = index
                                    filterValues.locations.set(locations[index! - 1].locationId.uuidString)
                                } else {
                                    locationIndex = nil
                                    filterValues.locations.clear()
                                }
                                filterValues.objectWillChange.send()
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
            print("Set partner: \(partnerIndex)")
            locationIndex = filterValues.location == nil ? nil : (locations.firstIndex(where: {$0 == filterValues.location})  ?? -1) + 1
        }
    }
    
    private func reset() {
        filterValues.partners.clear()
        filterValues.locations.clear()
        filterValues.dateFrom = nil
        filterValues.dateTo = nil
        filterValues.types.clear()
        filterValues.searchText = ""
    }
}

