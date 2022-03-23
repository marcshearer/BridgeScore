//
//  Location View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 12/02/2021.
//

import Combine
import SwiftUI
import CoreData

public class LocationViewModel : ObservableObject, Identifiable, Equatable, CustomDebugStringConvertible {

    // Properties in core data model
    @Published private(set) var locationId: UUID
    @Published public var sequence: Int
    @Published public var name: String
    @Published public var retired: Bool
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var locationMO: LocationMO?
    
    @Published public var nameMessage: String = ""
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = false
    
    public let itemProvider = NSItemProvider(contentsOf: URL(string: "com.sheareronline.bridgescore.location")!)!

        // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Equals
    public static func == (lhs: LocationViewModel, rhs: LocationViewModel) -> Bool {
        lhs.locationId == rhs.locationId
    }
    
    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.locationMO {
            if self.locationId != mo.locationId ||
                self.sequence != mo.sequence ||
                self.name != mo.name ||
                self.retired != mo.retired {
                    result = true
            }
        } else {
            result = true
        }
        return result
    }
    
    public init() {
        self.locationId = UUID()
        self.sequence = Int.max
        self.name = ""
        self.retired = false
        self.setupMappings()
    }
    
    public convenience init(locationMO: LocationMO) {
        self.init()
        self.locationMO = locationMO
        self.revert()
    }
        
    private func setupMappings() {
        $name
            .receive(on: RunLoop.main)
            .map { (name) in
                return (name == "" ? "Location name must not be left blank. Either enter a valid name or delete this location" : (self.nameExists(name) ? "This name already exists on another location. The name must be unique" : ""))
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
        if let mo = self.locationMO {
            self.locationId = mo.locationId
            self.sequence = mo.sequence
            self.name = mo.name
            self.retired = mo.retired
        }
    }
    
    public func copy(from: LocationViewModel) {
        self.locationId = from.locationId
        self.sequence = from.sequence
        self.name = from.name
        self.retired = from.retired
        self.locationMO = from.locationMO
    }
    
    public func updateMO() {
        self.locationMO!.locationId = self.locationId
        self.locationMO!.sequence = self.sequence
        self.locationMO!.name = self.name
        self.locationMO!.retired = self.retired
    }

    public func save() {
        if self.locationMO == nil {
            MasterData.shared.insert(location: self)
        } else {
            MasterData.shared.save(location: self)
        }
    }
    
    public func insert() {
        MasterData.shared.insert(location: self)
    }
    
    public func remove() {
        MasterData.shared.remove(location: self)
    }
    
    public var isNew: Bool {
        return self.locationMO == nil
    }
    
    private func nameExists(_ name: String) -> Bool {
        return !MasterData.shared.locations.filter({$0.name == name && $0.locationId != self.locationId}).isEmpty
    }
    
    public var description: String {
        "Location: \(self.name)"
    }
    
    public var debugDescription: String { self.description }
}
