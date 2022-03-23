//
//  Player View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 12/02/2021.
//

import Combine
import SwiftUI
import CoreData

public class PlayerViewModel : ObservableObject, Identifiable, Equatable, CustomDebugStringConvertible {

    // Properties in core data model
    @Published private(set) var playerId: UUID
    @Published public var sequence: Int
    @Published public var name: String
    @Published public var bboName: String
    @Published public var isSelf: Bool
    @Published public var retired: Bool
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var playerMO: PlayerMO?
    
    @Published public var nameMessage: String = ""
    @Published public var bboNameMessage: String = ""
    @Published public var isSelfMessage: String = ""
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = false
    
    public let itemProvider = NSItemProvider(contentsOf: URL(string: "com.sheareronline.bridgescore.player")!)!

        // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Equals
    public static func == (lhs: PlayerViewModel, rhs: PlayerViewModel) -> Bool {
        lhs.playerId == rhs.playerId
    }

    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.playerMO {
            if self.playerId != mo.playerId ||
                self.sequence != mo.sequence ||
                self.name != mo.name ||
                self.bboName != mo.bboName ||
                self.isSelf != mo.isSelf ||
                self.retired != mo.retired {
                    result = true
            }
        } else {
            result = true
        }
        return result
    }
    
    public init() {
        self.playerId = UUID()
        self.sequence = Int.max
        self.name = ""
        self.bboName = ""
        self.isSelf = false
        self.retired = false
        self.setupMappings()
    }
    
    public convenience init(playerMO: PlayerMO) {
        self.init()
        self.playerMO = playerMO
        self.revert()
    }
    
    private func setupMappings() {
    
        $name
            .receive(on: RunLoop.main)
            .map { (name) in
                return (name == "" ? "Player name must not be left blank. Either enter a valid name or delete this player" :
                        (self.nameExists(name) ? "This name already exists on another player. The name must be unique" :
                          ""))
            }
        .assign(to: \.nameMessage, on: self)
        .store(in: &cancellableSet)
        
        $bboName
            .receive(on: RunLoop.main)
            .map { (bboName) in
                return (self.bboNameExists(bboName) ? "This BBO name already exists on another player. The BBO name must be unique" :
                          "")
            }
        .assign(to: \.bboNameMessage, on: self)
        .store(in: &cancellableSet)
        
        $isSelf
            .receive(on: RunLoop.main)
            .map { (isSelf) in
                return (isSelf && self.otherIsSelf ? "Another player has been defined as yourself. Only one player can be defined as yourself" :
                          "")
            }
        .assign(to: \.isSelfMessage, on: self)
        .store(in: &cancellableSet)
        
        Publishers.CombineLatest3($nameMessage, $bboNameMessage, $isSelfMessage)
            .receive(on: RunLoop.main)
            .map { (nameMessage, bboNameMessage, isSelfMessage) in
                return (nameMessage != "" ? nameMessage : (bboNameMessage != "" ? bboNameMessage : isSelfMessage))
            }
        .assign(to: \.saveMessage, on: self)
        .store(in: &cancellableSet)

        $saveMessage
            .receive(on: RunLoop.main)
            .map { (saveMessage) in
                return (saveMessage == "")
            }
        .assign(to: \.canSave, on: self)
        .store(in: &cancellableSet)
        
    }
    
    private func revert() {
        if let mo = self.playerMO {
            self.playerId = mo.playerId
            self.sequence = mo.sequence
            self.name = mo.name
            self.bboName = mo.bboName
            self.isSelf = mo.isSelf
            self.retired = mo.retired
        }
    }
    
    public func copy(from: PlayerViewModel) {
        self.playerId = from.playerId
        self.sequence = from.sequence
        self.name = from.name
        self.bboName = from.bboName
        self.isSelf = from.isSelf
        self.retired = from.retired
        self.playerMO = from.playerMO
    }
    
    public func updateMO() {
        playerMO!.playerId = self.playerId
        playerMO!.sequence = self.sequence
        playerMO!.bboName = self.bboName
        playerMO!.isSelf = self.isSelf
        playerMO!.retired = self.retired
        playerMO!.name = self.name
    }
    
    public func save() {
        if playerMO == nil {
            MasterData.shared.insert(player: self)
        } else {
            MasterData.shared.save(player: self)
        }
    }
    
    public func insert() {
        MasterData.shared.insert(player: self)
    }
    
    public func remove() {
        MasterData.shared.remove(player: self)
    }
    
    public var isNew: Bool {
        return self.playerMO == nil
    }
    
    private func nameExists(_ name: String) -> Bool {
        return !MasterData.shared.players.filter({$0.name == name && $0.playerId != self.playerId}).isEmpty
    }
    
    private func bboNameExists(_ bboName: String) -> Bool {
        return bboName != "" && !MasterData.shared.players.filter({$0.bboName.lowercased() == bboName.lowercased() && $0.playerId != self.playerId}).isEmpty
    }
    
    public var otherIsSelf: Bool {
        return !MasterData.shared.players.filter({$0.isSelf && $0.playerId != self.playerId}).isEmpty
    }
    
    public var description: String {
        "Player: \(name)"
    }
    
    public var debugDescription: String { description }
}
