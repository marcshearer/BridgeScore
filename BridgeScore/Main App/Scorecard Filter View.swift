//
//  Scorecard Filter View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 28/02/2022.
//

import SwiftUI

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
    @State var portraitPhone = (MyApp.format == .phone && !isLandscape)
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()

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
                        if MyApp.format == .phone && !isLandscape {
                            VStack {
                                let buttonWidth: CGFloat = (geometry.size.width - 24 - (1 * 15)) / 2
                                HStack {
                                    Spacer().frame(width: 16)
                                    partnerButton(width: buttonWidth)
                                    Spacer().frame(width: 15)
                                    locationButton(width: buttonWidth)
                                    Spacer()
                                }
                                HStack {
                                    Spacer().frame(width: 16)
                                    dateFromButton(width: buttonWidth)
                                    Spacer().frame(width: 15)
                                    dateToButton(width: buttonWidth)
                                    Spacer()
                                }
                            }
                        } else {
                            HStack {
                                let buttonWidth: CGFloat = (geometry.size.width - 24 - (3 * 15)) / 4
                                Spacer().frame(width: 16)
                                partnerButton(width: buttonWidth)
                                Spacer().frame(width: 15)
                                locationButton(width: buttonWidth)
                                Spacer().frame(width: 15)
                                dateFromButton(width: buttonWidth)
                                Spacer().frame(width: 20)
                                dateToButton(width: buttonWidth)
                                Spacer()
                            }
                        }
                        Spacer().frame(height: 12)
                        searchText
                        Spacer().frame(height: 12)
                    }
                }
            }
                .frame(height: 140 + (MyApp.format == .phone && !isLandscape ? 50 : 0))
            Spacer().rightSpacer
        }
        .onAppear {
            filterValues.load()
            partnerIndex = filterValues.partner == nil ? nil : (players.firstIndex(where: {$0 == filterValues.partner})  ?? -1) + 1
            locationIndex = filterValues.location == nil ? nil : (locations.firstIndex(where: {$0 == filterValues.location})  ?? -1) + 1
        }
    }
    
    func partnerButton(width: CGFloat) -> some View {
        PickerInput(id: id, field: $partnerIndex, values: {["No partner filter"] + players.map{$0.name}}, popupTitle: "Partners", placeholder: "Partner", width: width, height: 40, centered: true, color: (partnerIndex != nil ? Palette.filterUsed : Palette.filterUnused), cornerRadius: 20, animation: .none) { (index) in
                if index ?? 0 > 0 {
                    partnerIndex = index
                    filterValues.partners.set(players[index! - 1].playerId.uuidString)
                } else {
                    partnerIndex = nil
                    filterValues.partners.clear()
                }
                filterValues.objectWillChange.send()
                filterValues.save()
        }
    }
    
    func locationButton(width: CGFloat) ->  some View {
        PickerInput(id: id, field: $locationIndex, values: {["No location filter"] + locations.map{$0.name}}, popupTitle: "Locations", placeholder: "Location", width: width, height: 40, centered: true, color: (locationIndex != nil ? Palette.filterUsed : Palette.filterUnused), cornerRadius: 20, animation: .none) { (index) in
                if index ?? 0 != 0 {
                    locationIndex = index
                    filterValues.locations.set(locations[index! - 1].locationId.uuidString)
                } else {
                    locationIndex = nil
                    filterValues.locations.clear()
                }
                filterValues.objectWillChange.send()
                filterValues.save()
        }
    }
    
    func dateFromButton(width: CGFloat) ->  some View {
        OptionalDatePickerInput(field: $filterValues.dateFrom, placeholder: "Date from", clearText: fromDateClearText, to: filterValues.dateTo, color: (filterValues.dateFrom != nil ? Palette.filterUsed : Palette.filterUnused), textType: .normal, cornerRadius: 20, width: width, height: 40, centered: true) { (date) in
                if date == nil {
                    fromDateClearText = nil
                } else {
                    fromDateClearText = "Clear Date From"
                }
                filterValues.save()
        }
    }
    
    func dateToButton(width: CGFloat) ->  some View {
        OptionalDatePickerInput(field: $filterValues.dateTo, placeholder: "Date to", clearText: toDateClearText, from: filterValues.dateFrom, color: (filterValues.dateTo != nil ? Palette.filterUsed : Palette.filterUnused), textType: .normal, cornerRadius: 20, width: width, height: 40, centered: true) { (date) in
                if date == nil {
                    toDateClearText = nil
                } else {
                    toDateClearText = "Clear Date To"
                }
                filterValues.save()
        }
    }
    
    private var searchText: some View {
        HStack {
            Spacer().frame(width: 16)
            ZStack {
                Rectangle()
                    .foregroundColor(Palette.input.background)
                    .cornerRadius(20)
                HStack {
                    Spacer().frame(width: 20)
                    Input(field: $filterValues.searchText, placeHolder: "Search words", height: 40, color: Palette.clear, clearText: true) { (text) in
                            filterValues.save()
                    }
                    .frame(height: 40)
                    .foregroundColor(Palette.input.text)
                }
            }
            Spacer().frame(width: 8)
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

