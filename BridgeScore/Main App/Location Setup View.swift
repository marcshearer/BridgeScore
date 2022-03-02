//
//  Location Setup View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 06/02/2022.
//

import SwiftUI

struct LocationSetupView: View {
    @State private var title = "Locations"
    @StateObject var selected = LocationViewModel()
    
    var body: some View {
        StandardView("Location") {
            VStack(spacing: 0) {
                Banner(title: $title, bottomSpace: false, back: true, backEnabled: { return selected.canSave })
                DoubleColumnView {
                    LocationSelectionView(selected: selected, changeSelected: changeSelection, removeSelected: removeSelection, addLocation: addLocation)
                } rightView: {
                    LocationDetailView(selected: selected)
                }
            }
        }
        .onAppear {
            selected.copy(from: MasterData.shared.locations.first!)
        }
        .onDisappear {
            save(location: selected)
        }
    }
    
    func changeSelection(newLocation: LocationViewModel) {
        save(location: selected)
        selected.copy(from: newLocation)
    }
    
    func removeSelection(removeLocation: LocationViewModel) {
        if selected.isNew {
            // Just get rid of it if it has never been saved
            selected.copy(from: MasterData.shared.locations.first!)
        } else {
            // If it is not used in a layout or a scorecard go ahead and delete it
            let isUsed = MasterData.shared.layouts.contains(where: {$0.location == removeLocation}) || MasterData.shared.scorecards.contains(where: {$0.location == removeLocation})
            if !isUsed {
                MessageBox.shared.show("This will delete the location permanently. Are you sure you want to do this?", cancelText: "Cancel", okText: "Delete", okAction: {
                    if let master = MasterData.shared.location(id: removeLocation.locationId) {
                        MasterData.shared.remove(location: master)
                    }
                    selected.copy(from: MasterData.shared.locations.first!)
                })
            } else {
                // It is used - retire it by setting the flag and moving it to the bottom of the list
                MessageBox.shared.show("As this location is used in scorecards or layouts it cannot be deleted. Instead it will be marked as retired. Are you sure you want to do this?", cancelText: "Cancel", okText: "Retire", okAction: {
                    selected.retired = true
                    save(location: selected)
                    if let index = MasterData.shared.locations.firstIndex(where: {$0 == selected}) {
                        MasterData.shared.move(locations: IndexSet(integer: index), to: MasterData.shared.locations.endIndex)
                    }
                })
            }
        }
    }

    func addLocation() {
        save(location: selected)
        selected.copy(from: LocationViewModel())
        selected.sequence = MasterData.shared.locations.last!.sequence + 1
    }
    
    func save(location: LocationViewModel) {
        if let master = MasterData.shared.location(id: location.locationId) {
            master.copy(from: location)
            MasterData.shared.save(location: master)
        } else {
            let master = LocationViewModel()
            master.copy(from: location)
            MasterData.shared.insert(location: master)
        }
    }
}

struct LocationSelectionView : View {
    @ObservedObject var selected: LocationViewModel
    @State var changeSelected: (LocationViewModel)->()
    @State var removeSelected: (LocationViewModel)->()
    @State var addLocation: ()->()

    var body: some View {
        let disabled = !selected.canSave
        
        VStack {
            HStack {
                List {
                    ForEach(MasterData.shared.locations) { location in
                        
                        let thisSelected = (selected == location)
                        let color = (thisSelected ? Palette.tile : Palette.background)
                        VStack {
                            Spacer().frame(height: 16)
                            HStack {
                                Spacer().frame(width: 40)
                                Text((location.name == "" ? "<Blank>" : location.name))
                                    .font(.title)
                                Spacer()
                            }
                            Spacer().frame(height: 16)
                        }
                        .background(Rectangle().fill(color.background))
                        .foregroundColor((location.retired ? color.faintText : color.text).opacity(disabled ? 0.3 : 1.0))
                        .onDrag({location.itemProvider})
                        .onTapGesture {
                            changeSelected(location)
                        }
                    }
                    .onMove { (indexSet, toIndex) in
                        MasterData.shared.move(locations: indexSet, to: toIndex)
                        selected.sequence = MasterData.shared.location(id: selected.locationId)?.sequence ?? selected.sequence
                    }
                }
                .listStyle(.plain)
                Spacer()
            }
            .disabled(disabled)
            Spacer()
            ToolbarView(canAdd: {selected.canSave}, canRemove: {selected.isNew || MasterData.shared.locations.count > 1}, addAction: addLocation, removeAction: { removeSelected(selected)})
        }
        .background(Palette.background.background)
    }
}


struct LocationDetailView : View {
    @ObservedObject var selected: LocationViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(spacing: 0) {
                    
                    InsetView(title: "Location Details") {
                        VStack(spacing: 0) {
                            
                            Input(title: "Name", field: $selected.name, message: $selected.nameMessage)
                            
                            if selected.retired {
                                
                                Separator()
                                
                                InputTitle(title: "This location has been marked as retired", topSpace: 50)
                                Spacer().frame(height: 16)
                                
                                HStack {
                                    Spacer().frame(width: 32)
                                    Button {
                                            // Remove retired flag and resequence above all other retired locations
                                        selected.retired = false
                                        if let index = MasterData.shared.locations.firstIndex(where: {$0 == selected}) {
                                            let toIndex = MasterData.shared.locations.firstIndex(where: {$0.retired}) ?? MasterData.shared.locations.endIndex
                                            MasterData.shared.move(locations: IndexSet(integer: index), to: toIndex)
                                        }
                                    } label: {
                                        VStack {
                                            Spacer().frame(height: 6)
                                            HStack {
                                                Spacer().frame(width: 16)
                                                Text("Reinstate")
                                                    .foregroundColor(Palette.enabledButton.text)
                                                    .font(.title2)
                                                Spacer().frame(width: 16)
                                            }
                                            Spacer().frame(height: 6)
                                        }
                                        .background(Palette.enabledButton.background)
                                        .cornerRadius(10)
                                    }
                                    Spacer()
                                }
                                Spacer().frame(height: 40)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .background(Palette.alternate.background)
    }
}
