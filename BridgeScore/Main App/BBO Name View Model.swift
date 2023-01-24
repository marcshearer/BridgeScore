//
//  BBO Name View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 17/03/2022.
//

import Combine
import SwiftUI
import CoreData

public class BBONameViewModel : ObservableObject, Identifiable, Equatable, CustomDebugStringConvertible {

    // Properties in core data model
    @Published public var bboName: String
    @Published public var name: String
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var bboNameMO: BBONameMO?
    
    @Published public var nameMessage: String = ""
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = false
    
    public let itemProvider = NSItemProvider(contentsOf: URL(string: "com.sheareronline.bridgescore.bboName")!)!

    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Equals
    public static func == (lhs: BBONameViewModel, rhs: BBONameViewModel) -> Bool {
        lhs.bboName.lowercased() == rhs.bboName.lowercased()
    }
    
    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.bboNameMO {
            if self.bboName != mo.bboName ||
               self.name != mo.name {
                    result = true
            }
        } else {
            result = true
        }
        return result
    }
    
    public init() {
        self.bboName = ""
        self.name = ""
        self.setupMappings()
    }
    
    public convenience init(bboNameMO: BBONameMO) {
        self.init()
        self.bboNameMO = bboNameMO
        self.revert()
    }
        
    private func setupMappings() {
        $name
            .receive(on: RunLoop.main)
            .map { (name) in
                return (name == "" ? "BbboName name must not be left blank. Either enter a valid name or delete this bboName" : (self.nameExists(name) ? "This name already exists on another bboName. The name must be unique" : ""))
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
        if let mo = self.bboNameMO {
            self.bboName = mo.bboName
            self.name = mo.name
        }
    }
    
    public func copy(from: BBONameViewModel) {
        self.bboName = from.bboName
        self.name = from.name
        self.bboNameMO = from.bboNameMO
    }
    
    public func updateMO() {
        self.bboNameMO!.bboName = self.bboName
        self.bboNameMO!.name = self.name
    }

    public func save() {
        if self.bboNameMO == nil {
            MasterData.shared.insert(bboName: self)
        } else {
            MasterData.shared.save(bboName: self)
        }
    }
    
    public func insert() {
        MasterData.shared.insert(bboName: self)
    }
    
    public func remove() {
        MasterData.shared.remove(bboName: self)
    }
    
    public var isNew: Bool {
        return self.bboNameMO == nil
    }
    
    private func nameExists(_ name: String) -> Bool {
        return !MasterData.shared.bboNames.filter({$0.name == name && $0.bboName != self.bboName}).isEmpty
    }
    
    private func bboNameExists(_ name: String) -> Bool {
        return !MasterData.shared.bboNames.filter({$0.bboName == bboName && $0.name != self.name}).isEmpty
    }
    
    public var description: String {
        "BbboName: \(self.name)"
    }
    
    public var debugDescription: String { self.description }
}
