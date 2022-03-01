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
    @State private var partnerColor = Palette.enabledButton
    @State private var locationColor = Palette.enabledButton
    @State private var fromDateColor = Palette.enabledButton
    @State private var fromDateClearText: String? = nil
    @State private var toDateColor = Palette.enabledButton
    @State private var toDateClearText: String? = nil

    var body: some View {
        let players = MasterData.shared.players.filter{!$0.retired}
        let locations = MasterData.shared.locations.filter{!$0.retired}
        
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
                            PickerInput(field: $partnerIndex, values: {["No partner filter"] + players.map{$0.name}}, placeholder: "Partner", width: buttonWidth, height: 40, color: partnerColor, cornerRadius: 20) { (index) in
                                if index == 0 {
                                    values.partner = nil
                                    partnerColor = Palette.enabledButton
                                    partnerIndex = -1
                                } else {
                                    values.partner = players[index - 1]
                                    partnerColor = Palette.highlightButton
                                }
                            }
                            
                            Spacer().frame(width: 15)
                            
                            PickerInput(field: $locationIndex, values: {["No location filter"] + locations.map{$0.name}}, placeholder: "Location", width: buttonWidth, height: 40, color: locationColor, cornerRadius: 20) { (index) in
                                if index == 0 {
                                    values.location = nil
                                    locationColor = Palette.enabledButton
                                    locationIndex = -1
                                } else {
                                    values.location = locations[index - 1]
                                    locationColor = Palette.highlightButton
                                }
                            }
                            
                            Spacer().frame(width: 15)
                            
                            OptionalDatePickerInput(field: $values.dateFrom, placeholder: "Date from", clearText: fromDateClearText, to: values.dateTo, color: fromDateColor, cornerRadius: 20, width: buttonWidth, height: 40, centered: true) { (date) in
                                if date == nil {
                                    fromDateColor = Palette.enabledButton
                                    fromDateClearText = nil
                                } else {
                                    fromDateColor = Palette.highlightButton
                                    fromDateClearText = "Clear Date From"
                                }
                            }
                            
                            Spacer().frame(width: 20)
                            
                            OptionalDatePickerInput(field: $values.dateTo, placeholder: "Date to", clearText: toDateClearText, from: values.dateFrom, color: toDateColor, cornerRadius: 20, width: buttonWidth, height: 40, centered: true) { (date) in
                                if date == nil {
                                    toDateColor = Palette.enabledButton
                                    toDateClearText = nil
                                } else {
                                    toDateColor = Palette.highlightButton
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
            reset()
        }
    }
    
    private func reset() {
        partnerIndex = -1
        partnerColor = Palette.enabledButton
        locationIndex = -1
        locationColor = Palette.enabledButton
        fromDateColor = Palette.enabledButton
        toDateColor = Palette.enabledButton
    }
}

