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
    @Published public var searchText: String
    
    init(partner: PlayerViewModel? = nil, location: LocationViewModel? = nil, dateFrom: Date? = nil, dateTo: Date? = nil, searchText: String = "") {
        self.partner = partner
        self.location = location
        self.dateFrom = dateFrom
        self.dateTo = dateTo
        self.searchText = searchText
    }
    
    public func clear() {
        self.partner = nil
        self.location = nil
        self.dateFrom = nil
        self.dateTo = nil
        self.searchText = ""
    }
}

struct ScorecardFilterView: View {
    @ObservedObject var values: ScorecardFilterValues
    @Binding var closeFilter: Bool
    @State private var partnerIndex = -1
    @State private var locationIndex = -1
    @State private var fromDateClearText: String? = nil
    @State private var toDateClearText: String? = nil
    let players = MasterData.shared.players.filter{!$0.retired}
    let locations = MasterData.shared.locations.filter{!$0.retired}
    
    var body: some View {
        
        HStack {
            
                Spacer().frame(width: 16)
                GeometryReader { (geometry) in
                ZStack {
                    Palette.filter.background
                        .ignoresSafeArea(edges: .all)
                        .cornerRadius(10)
                    VStack(spacing: 0) {
                        
                        Spacer().frame(height: 8)
                        HStack {
                            Spacer().frame(width: 8)
                            VStack {
                                Spacer().frame(height: 8)
                                Text("FILTER BY:").font(.caption2)
                            }
                            Spacer()
                            Button {
                                values.clear()
                                reset()
                                closeFilter = true
                            } label: {
                                Image(systemName: "xmark").foregroundColor(Palette.filter.text)
                            }
                            Spacer().frame(width: 8)
                        }
                        Spacer().frame(height: 8)
                        HStack {
                            let buttonWidth: CGFloat = (geometry.size.width - 24 - (3 * 15)) / 4
                            Spacer().frame(width: 16)
                            PickerInput(field: $partnerIndex, values: {["No partner filter"] + players.map{$0.name}}, popupTitle: "Partners", placeholder: "Partner", width: buttonWidth, height: 40, centered: true, color: (partnerIndex > 0 ? Palette.highlightButton : Palette.enabledButton), cornerRadius: 20, animation: .none) { (index) in
                                if index == 0 {
                                    values.partner = nil
                                } else {
                                    values.partner = players[index - 1]
                                }
                            }
                            
                            Spacer().frame(width: 15)
                            
                            PickerInput(field: $locationIndex, values: {["No location filter"] + locations.map{$0.name}}, popupTitle: "Locations", placeholder: "Location", width: buttonWidth, height: 40, centered: true, color: (locationIndex > 0 ? Palette.highlightButton : Palette.enabledButton), cornerRadius: 20, animation: .none) { (index) in
                                if index == 0 {
                                    values.location = nil
                                } else {
                                    values.location = locations[index - 1]
                                }
                            }
                            
                            Spacer().frame(width: 15)
                            
                            OptionalDatePickerInput(field: $values.dateFrom, placeholder: "Date from", clearText: fromDateClearText, to: values.dateTo, color: (values.dateFrom != nil ? Palette.highlightButton : Palette.enabledButton), textType: .normal, cornerRadius: 20, width: buttonWidth, height: 40, centered: true) { (date) in
                                if date == nil {
                                    fromDateClearText = nil
                                } else {
                                    fromDateClearText = "Clear Date From"
                                }
                            }
                            
                            Spacer().frame(width: 20)
                            
                            OptionalDatePickerInput(field: $values.dateTo, placeholder: "Date to", clearText: toDateClearText, from: values.dateFrom, color: (values.dateTo != nil ? Palette.highlightButton : Palette.enabledButton), textType: .normal, cornerRadius: 20, width: buttonWidth, height: 40, centered: true) { (date) in
                                if date == nil {
                                    toDateClearText = nil
                                } else {
                                    toDateClearText = "Clear Date To"
                                }
                            }
                            
                            Spacer()
                        }
                        Spacer().frame(height: 8)
                        HStack {
                            Spacer().frame(width: 16)
                            ZStack {
                                Rectangle()
                                    .foregroundColor(Palette.input.background)
                                    .cornerRadius(20)
                                if values.searchText.isEmpty {
                                    HStack {
                                        Spacer().frame(width: 20)
                                        Text("Search words")
                                            .foregroundColor(Palette.input.faintText)
                                        Spacer()
                                    }
                                }
                                HStack {
                                    Input(field: $values.searchText, height: 20, color: Palette.clear, clearText: true)
                                        .foregroundColor(Palette.input.text)
                                }
                            }
                            Spacer().frame(width: 8)
                        }
                        Spacer()
                    }
                }
            }
            .frame(height: 130)
            Spacer().rightSpacer
        }
        .onAppear {
            partnerIndex = (players.firstIndex(where: {$0 == values.partner})  ?? -1) + 1
            locationIndex = (locations.firstIndex(where: {$0 == values.location})  ?? -1) + 1
        }
    }
    
    private func reset() {
        values.partner = nil
        values.location = nil
        values.dateFrom = nil
        values.dateTo = nil
    }
}

