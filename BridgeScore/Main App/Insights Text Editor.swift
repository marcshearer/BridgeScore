//
//  Native Input.swift
//  BridgeScore
//
//  Created by Marc Shearer on 18/05/2026.
//

import SwiftUI
import UIKit

struct InsightsTextView<EditField> : View where EditField : Hashable & Equatable & CaseIterable {
    @Binding var text: String
    var fieldType: EditField
    @Binding var focus: EditField?
    var placeholder: String = ""
    var spellCheckingType: UITextSpellCheckingType = .no
    var setFocus: ((FocusDirection) -> Void)? = nil
    var onConfirm: (() -> Void)? = nil
    var onChange: ((String)->())? = nil
    
    var body: some View {
        HStack {
            Spacer().frame(width: 8)
            InsightsTextViewRepresentable(text: $text, fieldType: fieldType, focus: $focus, placeholder: placeholder, setFocus: setFocus ?? defaultSetFocus, onConfirm: onConfirm, onChange: onChange)
        }
    }
    
    func defaultSetFocus(direction: FocusDirection) {
        print("Setting focus")
        let allFields = Array(EditField.allCases)
        if let currentIndex = allFields.firstIndex(where: {$0 == fieldType}) {
            var nextIndex: Int
            if direction == .forwards {
                nextIndex = currentIndex + 1
            } else {
                nextIndex = currentIndex - 1
            }
            if nextIndex < allFields.startIndex {
                focus = allFields[allFields.endIndex - 1]
            } else if nextIndex >= allFields.endIndex {
                focus = allFields[allFields.startIndex]
            } else {
                focus = allFields[nextIndex]
            }
        }
    }
    
}

struct InsightsTextViewRepresentable<EditField>: UIViewRepresentable where EditField : Hashable & Equatable & CaseIterable {
    @Binding var text: String
    var fieldType: EditField
    @Binding var focus: EditField?
    var placeholder: String = ""
    var spellCheckingType: UITextSpellCheckingType = .no
    var setFocus: ((FocusDirection)->())? = nil
    var onConfirm: (()->())? = nil
    var onChange: ((String)->())? = nil

    func makeUIView(context: Context) -> UITextView {
        let textView = InsightsUITextView<EditField>(fieldType: fieldType, setFocus: setFocus, onConfirm: onConfirm)
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 16)
        textView.spellCheckingType = .no
        textView.isScrollEnabled = true
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Safe sync to prevent infinite update loops
        if uiView.text != text {
            uiView.text = text
        }
        
        if focus == fieldType {
            if !uiView.isFirstResponder && uiView.window != nil {
                Utility.mainThread {
                    if focus == fieldType {
                        print("\(fieldType) is first responder")
                        uiView.becomeFirstResponder()
                    }
                }
            }
        } else {
            print("\(fieldType) is not first responder")
            if uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: UIResponder, UITextViewDelegate {
        var parent: InsightsTextViewRepresentable
        init(_ parent: InsightsTextViewRepresentable) { self.parent = parent }
        
        func textViewDidChange(_ textView: UITextView) {
            // This forces your state variable to update instantly on every keypress
            // Your computed property validation will light up your Save button instantly!
            parent.text = textView.text
            parent.onChange?(textView.text)
        }
    }
}

class InsightsUITextView<EditField>: UITextView where EditField : Hashable & Equatable & CaseIterable {
    var fieldType: EditField?
    var setFocus: ((FocusDirection)->())? = nil
    var onConfirm: (()->())? = nil
    
    
    convenience init(fieldType: EditField? = nil, setFocus: ((FocusDirection)->())? = nil, onConfirm: (()->())? = nil) {
        self.init()
        self.fieldType = fieldType
        self.setFocus = setFocus
        self.onConfirm = onConfirm
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !processPressedKeys(presses, with: event, allowCharacters: false, action: { (keyAction, _) in
            switch keyAction {
            case .up:
                setFocus?(.backwards)
                return true
            case .down:
                setFocus?(.forwards)
                return true
            default:
                return false
            }
    }) {
            super.pressesBegan(presses, with: event)
        }
    }
    
    override var keyCommands: [UIKeyCommand]? {
        
        let returnCommand = UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(handleReturn))
        returnCommand.wantsPriorityOverSystemBehavior = true
        
        let enterCommand = UIKeyCommand(input: "\u{3}", modifierFlags: [], action: #selector(handleReturn))
        
        let shiftTabCommand = UIKeyCommand(input: "\t", modifierFlags: .shift, action: #selector(handleShiftTab))
        
        let tabCommand = UIKeyCommand(input: "\t", modifierFlags: [], action: #selector(handleTab))
        
        return[returnCommand, enterCommand, shiftTabCommand, tabCommand]

    }
    
    @objc func handleShiftTab(sender: UIKeyCommand) {
        setFocus?(.backwards)
    }
    
    @objc func handleTab(sender: UIKeyCommand) {
        setFocus?(.forwards)
    }
    
    @objc func handleReturn(sender: UIKeyCommand) {
        onConfirm?()
    }
}

enum FocusDirection {
    case forwards
    case backwards
}
