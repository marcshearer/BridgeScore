//
//  Undo Handler.swift
//  BridgeScore
//
//  Created by Marc Shearer on 02/03/2022.
//

import SwiftUI

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
    
    @Environment(\.undoManager) var undoManager
    @StateObject var handler: UndoHandler<Value, Additional> = UndoHandler()
    var wrappedView: (Binding<Value>) -> Content
    var binding: Binding<Value>
    var setAdditional: ((Binding<Additional>?, Additional)->())? = nil
    var additionalBinding: Binding<Additional>? = nil
    
    init(_ binding: Binding<Value>, additionalBinding: Binding<Additional>? = nil, setAdditional: ((Binding<Additional>?, Additional)->())? = nil, @ViewBuilder wrappedView: @escaping (Binding<Value>) -> Content) {
        self.binding = binding
        self.additionalBinding = additionalBinding
        self.setAdditional = setAdditional
        self.wrappedView = wrappedView
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
            .onAppear {
                self.handler.binding = self.binding
                self.handler.additionalBinding = self.additionalBinding
                self.handler.setAdditional = self.setAdditional
                self.handler.undoManger = self.undoManager
            }
    }
}

class UndoHandler<Value, Additional>: ObservableObject where Value: Equatable, Additional: Equatable {
    var binding: Binding<Value>?
    var additionalBinding: Binding<Additional>?
    var setAdditional:  ((Binding<Additional>?, Additional)->())?
    weak var undoManger: UndoManager?
    
    func registerUndo(from undoValue: Value, to redoValue: Value, additionalFrom additionalUndoValue: Additional?, additionalTo additionalRedoValue: Additional?) {
        if undoValue != redoValue || additionalUndoValue != additionalRedoValue {
            print("registering undo from \(undoValue)\n                   to \(redoValue)")
            undoManger?.registerUndo(withTarget: self) { handler in
                print("executing   undo from \(redoValue)\n                   to \(undoValue)")
                handler.registerUndo(from: redoValue, to: undoValue, additionalFrom: additionalRedoValue, additionalTo: additionalUndoValue)
                handler.binding?.wrappedValue = undoValue
                if let additionalUndoValue = additionalUndoValue {
                    // Call customised set closure if one provided - otherwise just set it
                    if let setAdditional = self.setAdditional {
                        setAdditional(self.additionalBinding, additionalUndoValue)
                    } else {
                        self.additionalBinding?.wrappedValue = additionalUndoValue
                    }
                }
            }
        }
    }
}
