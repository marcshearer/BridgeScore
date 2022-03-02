//
//  Player Setup View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 06/02/2022.
//

import SwiftUI

struct PlayerSetupView: View {
    @State private var title = "Players"
    @StateObject var selected = PlayerViewModel()
    
    var body: some View {
        StandardView("Player") {
            VStack(spacing: 0) {
                Banner(title: $title, bottomSpace: false, back: true, backEnabled: { return selected.canSave })
                DoubleColumnView {
                    PlayerSelectionView(selected: selected, changeSelected: changeSelection, removeSelected: removeSelection, addPlayer: addPlayer)
                } rightView: {
                    PlayerDetailView(selected: selected)
                }
            }
        }
        .onAppear {
            selected.copy(from: MasterData.shared.players.first!)
        }
        .onDisappear {
            save(player: selected)
        }
    }
    
    func changeSelection(newPlayer: PlayerViewModel) {
        save(player: selected)
        selected.copy(from: newPlayer)
    }
    
    func removeSelection(removePlayer: PlayerViewModel) {
        if selected.isNew {
            // Just get rid of it if it has never been saved
            selected.copy(from: MasterData.shared.players.first!)
        } else {
            // If it is not used in a layout or a scorecard go ahead and delete it
            let isUsed = MasterData.shared.layouts.contains(where: {$0.partner == removePlayer}) || MasterData.shared.scorecards.contains(where: {$0.partner == removePlayer})
            if !isUsed {
                MessageBox.shared.show("This will delete the player permanently. Are you sure you want to do this?", cancelText: "Cancel", okText: "Delete", okAction: {
                    if let master = MasterData.shared.player(id: removePlayer.playerId) {
                        MasterData.shared.remove(player: master)
                    }
                    selected.copy(from: MasterData.shared.players.first!)
                })
            } else {
                // It is used - retire it by setting the flag and moving it to the bottom of the list
                MessageBox.shared.show("As this player is used in scorecards or layouts it cannot be deleted. Instead it will be marked as retired. Are you sure you want to do this?", cancelText: "Cancel", okText: "Retire", okAction: {
                    selected.retired = true
                    save(player: selected)
                    if let index = MasterData.shared.players.firstIndex(where: {$0 == selected}) {
                        MasterData.shared.move(players: IndexSet(integer: index), to: MasterData.shared.players.endIndex)
                    }
                })
            }
        }
    }

    func addPlayer() {
        save(player: selected)
        selected.copy(from: PlayerViewModel())
        selected.sequence = MasterData.shared.players.last!.sequence + 1
    }
    
    func save(player: PlayerViewModel) {
        if let master = MasterData.shared.player(id: player.playerId) {
            master.copy(from: player)
            MasterData.shared.save(player: master)
        } else {
            let master = PlayerViewModel()
            master.copy(from: player)
            MasterData.shared.insert(player: master)
        }
    }
}

struct PlayerSelectionView : View {
    @ObservedObject var selected: PlayerViewModel
    @State var changeSelected: (PlayerViewModel)->()
    @State var removeSelected: (PlayerViewModel)->()
    @State var addPlayer: ()->()

    var body: some View {
        let disabled = !selected.canSave
        
        VStack(spacing: 0) {
            HStack {
                List {
                    ForEach(MasterData.shared.players) { player in
                        
                        let thisSelected = (selected == player)
                        let color = (thisSelected ? Palette.tile : Palette.background)
                        VStack {
                            Spacer().frame(height: 16)
                            HStack {
                                Spacer().frame(width: 40)
                                Text((player.name == "" ? "<Blank>" : player.name))
                                    .font(.title)
                                Spacer()
                            }
                            Spacer().frame(height: 16)
                        }
                        .background(Rectangle().fill(color.background))
                        .foregroundColor((player.retired ? color.faintText : color.text).opacity(disabled ? 0.3 : 1.0))
                        .onDrag({player.itemProvider})
                        .onTapGesture {
                            changeSelected(player)
                        }
                    }
                    .onMove { (indexSet, toIndex) in
                        MasterData.shared.move(players: indexSet, to: toIndex)
                        selected.sequence = MasterData.shared.player(id: selected.playerId)?.sequence ?? selected.sequence
                    }
                }
                .listStyle(.plain)
                Spacer()
            }
            .disabled(disabled)
            Spacer()
            ToolbarView(canAdd: {selected.canSave}, canRemove: {selected.isNew || MasterData.shared.players.count > 1}, addAction: addPlayer, removeAction: { removeSelected(selected)})
        }
        .background(Palette.background.background)
    }
}


struct PlayerDetailView : View {
    @ObservedObject var selected: PlayerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(spacing: 0) {
                    InsetView(title: "Main Details") {
                        VStack(spacing: 0) {
                            
                            Input(title: "Name", field: $selected.name, message: $selected.nameMessage)
                            
                            if selected.retired {
                                
                                Separator()
                                
                                InputTitle(title: "This player has been marked as retired", topSpace: 50)
                                
                                
                                Spacer().frame(height: 16)
                                
                                HStack {
                                    Spacer().frame(width: 32)
                                    Button {
                                            // Remove retired flag and resequence above all other retired players
                                        selected.retired = false
                                        if let index = MasterData.shared.players.firstIndex(where: {$0 == selected}) {
                                            let toIndex = MasterData.shared.players.firstIndex(where: {$0.retired}) ?? MasterData.shared.players.endIndex
                                            MasterData.shared.move(players: IndexSet(integer: index), to: toIndex)
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
