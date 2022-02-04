//
//  Layout View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 12/02/2021.
//

import Combine
import SwiftUI
import CoreData

public class LayoutViewModel : ObservableObject, Identifiable, CustomDebugStringConvertible {

    // Properties in core data model
    @Published private(set) var layoutId: UUID
    @Published public var sequence: Int
    @Published public var location: LocationViewModel?
    @Published public var partner: PlayerViewModel?
    @Published public var desc: String
    @Published public var boards: Int = 0
    @Published public var boardsTable: Int = 0
    @Published public var type: Type = .percent
    @Published public var tableTotal: Bool = false
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var layoutMO: LayoutMO?
    
    @Published public var descMessage: String = ""
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = false
    @Published internal var canExit: Bool = false
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.layoutMO {
            if self.layoutId != mo.layoutId ||
                self.location?.locationId != mo.locationId ||
                self.partner?.playerId != mo.partnerId ||
                self.desc != mo.desc ||
                self.sequence != mo.sequence ||
                self.boards != mo.boards ||
                self.boardsTable != mo.boardsTable ||
                self.type != mo.type ||
                self.tableTotal != mo.tableTotal {
                    result = true
            }
        }
        return result
    }
    
    public init() {
        self.layoutId = UUID()
        self.sequence = Int.max
        self.desc = ""
        self.setupMappings()
    }
    
    public convenience init(layoutMO: LayoutMO) {
        self.init()
        self.layoutMO = layoutMO
        self.revert()
    }
    
    private func setupMappings() {
        $desc
            .receive(on: RunLoop.main)
            .map { (desc) in
                return (desc == "" ? "Layout description must not be left blank. Either enter a valid description or delete this layout" : (self.descExists(desc) ? "This description already exists on another layout. The description must be unique" : ""))
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
        
        Publishers.CombineLatest3($desc, $layoutMO, $canSave)
            .receive(on: RunLoop.main)
            .map { (desc, layoutMO, canSave) in
                return (canSave || (layoutMO == nil && desc == ""))
            }
        .assign(to: \.canExit, on: self)
        .store(in: &cancellableSet)
 
    }
    
    private func revert() {
        if let mo = self.layoutMO {
            self.layoutId = mo.layoutId
            self.sequence = mo.sequence
            if let location = MasterData.shared.location(id: mo.locationId) {
                self.location = location
            }
            if let partner = MasterData.shared.player(id: mo.partnerId) {
                self.partner = partner
            }
            self.desc = mo.desc
            self.boards = mo.boards
            self.boardsTable = mo.boardsTable
            self.type = mo.type
            self.tableTotal = mo.tableTotal
        }
    }
    
    public func save() {
        if self.layoutMO == nil {
            MasterData.shared.insert(layout: self)
        } else {
            MasterData.shared.save(layout: self)
        }
    }
    
    public func insert() {
        MasterData.shared.insert(layout: self)
    }
    
    public func remove() {
        MasterData.shared.remove(layout: self)
    }
    
    private func descExists(_ name: String) -> Bool {
        return !MasterData.shared.layouts.compactMap{$1}.filter({$0.desc == desc && $0.layoutId != self.layoutId}).isEmpty
    }
    
    public var description: String {
        "Layout: \(self.desc)"
    }
    
    public var debugDescription: String { self.description }
}
