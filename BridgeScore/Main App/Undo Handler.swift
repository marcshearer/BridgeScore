//
//  Undo Handler.swift
//  BridgeScore
//
//  Created by Marc Shearer on 02/03/2022.
//

import SwiftUI
import Combine

struct UndoWrapper<Content, Value>: View where Content: View, Value: Equatable {
    private var undoWrapperAdditional: UndoWrapperAdditional<Content, Value, Int>
    private var any: Binding<Int>? = nil
    
    init(_ binding: Binding<Value>, @ViewBuilder wrappedView: @escaping (Binding<Value>) -> Content) {
        self.undoWrapperAdditional = UndoWrapperAdditional(binding, additionalBinding: any, wrappedView: wrappedView)
    }
    
    var body: some View {
        self.undoWrapperAdditional
    }
}

struct UndoWrapperAdditional<Content, Value, Additional>: View where Content: View, Value: Equatable, Additional: Equatable {
    private var handler: UndoHandler<Value, Additional>!
    var wrappedView: (Binding<Value>) -> Content
    var binding: Binding<Value>
    var setAdditional: ((Binding<Additional>?, Additional)->())? = nil
    var additionalBinding: Binding<Additional>? = nil
    private var undoObserver: NSObjectProtocol
    private let redoObserver: NSObjectProtocol
    
    init(_ binding: Binding<Value>, additionalBinding: Binding<Additional>? = nil, setAdditional: ((Binding<Additional>?, Additional)->())? = nil, @ViewBuilder wrappedView: @escaping (Binding<Value>) -> Content) {
        self.binding = binding
        self.additionalBinding = additionalBinding
        self.setAdditional = setAdditional
        self.wrappedView = wrappedView
        self.handler = UndoHandler(binding: binding, additionalBinding: additionalBinding, setAdditional: setAdditional)
        undoObserver = NotificationCenter.default.addObserver(forName: .NSUndoManagerDidUndoChange, object: nil, queue: nil) { (_) in
            UndoNotification.shared.publish()
        }
        redoObserver = NotificationCenter.default.addObserver(forName: .NSUndoManagerDidRedoChange, object: nil, queue: nil) { (_) in
            UndoNotification.shared.publish()
        }
    }
    
    var valueWrapper: Binding<Value> {
        Binding {
            self.binding.wrappedValue
        } set: { (newValue) in
            let from = self.binding.wrappedValue
            let fromAdditional = additionalBinding?.wrappedValue
            self.binding.wrappedValue = newValue
            self.handler.registerUndo(from: from, to: newValue, additionalFrom: fromAdditional, additionalTo: additionalBinding?.wrappedValue)
        }
    }
    
    var body: some View {
        wrappedView(self.valueWrapper)
    }
}

class UndoHandler<Value, Additional>: ObservableObject where Value: Equatable, Additional: Equatable {
    var binding: Binding<Value>?
    var additionalBinding: Binding<Additional>?
    var setAdditional:  ((Binding<Additional>?, Additional)->())?
    
    init(binding: Binding<Value>? = nil, additionalBinding: Binding<Additional>? = nil, setAdditional: ((Binding<Additional>?, Additional)->())? = nil) {
        self.binding = binding
        self.additionalBinding = additionalBinding
        self.setAdditional = setAdditional
    }
    
    func registerUndo(from undoValue: Value, to redoValue: Value, additionalFrom additionalUndoValue: Additional?, additionalTo additionalRedoValue: Additional?) {
        if (undoValue != redoValue || additionalUndoValue != additionalRedoValue) {
            MyApp.undoManager.registerUndo(withTarget: self) { handler in
                // Execute the undo
                self.binding?.wrappedValue = undoValue
                // Execute any additional undo if defined
                if let additionalUndoValue = additionalUndoValue {
                    // Call customised set closure if one provided - otherwise just set it
                    if let setAdditional = self.setAdditional {
                        setAdditional(self.additionalBinding, additionalUndoValue)
                    } else {
                        self.additionalBinding?.wrappedValue = additionalUndoValue
                    }
                }
                // Register for redo
                self.registerUndo(from: redoValue, to: undoValue, additionalFrom: additionalRedoValue, additionalTo: additionalUndoValue)
            }
            // Publish that undo state has changed
            UndoNotification.shared.publish()
        }
    }
}

class UndoNotification {
    public static var shared = UndoNotification()
    
    public var undoRegistered = PassthroughSubject<(), Never>()
    
    func publish() {
        Utility.executeAfter(delay: 0.1) {
            UndoNotification.shared.undoRegistered.send()
        }
    }
}
