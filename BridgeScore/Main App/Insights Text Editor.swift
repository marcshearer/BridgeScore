//
//  Native Input.swift
//  BridgeScore
//
//  Created by Marc Shearer on 18/05/2026.
//

import SwiftUI
import UIKit

struct InsightsTextView<EditField:InsightsFocusIndexBridge> : View  {
    @Binding var text: String
    var fieldType: EditField
    @Binding var focus: EditField?
    var placeholder: String = ""
    var spellCheckingType: UITextSpellCheckingType = .no
    var readOnly: Bool = false
    var setFocus: ((FocusDirection) -> Void)? = nil
    var onConfirm: (() -> Void)? = nil
    var onChange: ((String)->())? = nil
    
    var body: some View {
        HStack {
            Spacer().frame(width: 8)
            ZStack {
                InsightsTextViewRepresentable(text: $text, fieldType: fieldType, focus: $focus, spellCheckingType: spellCheckingType, readOnly: readOnly, setFocus: setFocus ?? defaultSetFocus, onConfirm: onConfirm, onChange: onChange)
                    .fixedSize(horizontal: false, vertical: true)
                if text == "" && placeholder != "" {
                    LeadingText(placeholder).opacity(0.5)
                }
            }
        }
    }
    
    func defaultSetFocus(direction: FocusDirection) {
        let allFields = Array(EditField.allCases)
        
        if let currentFocus = focus {
            var nextIndex: Int
            nextIndex = currentFocus.intIndex + direction.rawValue
            if nextIndex < 0 {
                focus = EditField.from(intIndex: allFields.count - 1)
            } else if nextIndex >= allFields.count {
                focus = EditField.from(intIndex: 0)
            } else {
                focus = EditField.from(intIndex: nextIndex)
            }
        }
    }
    
}

struct InsightsTextViewRepresentable<EditField:InsightsFocusIndexBridge>: UIViewRepresentable {
    @Binding var text: String
    var fieldType: EditField
    @Binding var focus: EditField?
    var spellCheckingType: UITextSpellCheckingType = .no
    var readOnly: Bool = false
    var setFocus: ((FocusDirection)->())? = nil
    var onConfirm: (()->())? = nil
    var onChange: ((String)->())? = nil

    func makeUIView(context: Context) -> UITextView {
        let textView = InsightsUITextView<EditField>(fieldType: fieldType, setFocus: setFocus, onConfirm: onConfirm)
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 16)
        textView.spellCheckingType = spellCheckingType
        textView.isScrollEnabled = false
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.isSelectable = true
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.isEditable = !readOnly
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
                    if focus == fieldType && !uiView.isFirstResponder {
                        uiView.becomeFirstResponder()
                    }
                }
            }
        } else {
            
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

class InsightsUITextView<EditField:InsightsFocusIndexBridge>: UITextView {
    var fieldType: EditField?
    var setFocus: ((FocusDirection)->())? = nil
    var onConfirm: (()->())? = nil
    
    
    convenience init(fieldType: EditField? = nil, setFocus: ((FocusDirection)->())? = nil, onConfirm: (()->())? = nil) {
        self.init()
        self.fieldType = fieldType
        self.setFocus = setFocus
        self.onConfirm = onConfirm
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let event = event {
            // Target the physical mouse wheel scroll engine (.scroll)
            if event.type == .scroll {
                return nil // 👈 Forwards discrete mouse wheel clicks directly to SwiftUI's ScrollView
            }
        }
        return super.hitTest(point, with: event)
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

enum FocusDirection: Int {
    case forwards = 1
    case backwards = -1
}

protocol InsightsFocusIndexBridge: CaseIterable, Equatable {
    var intIndex: Int { get }
    static func from(intIndex: Int) -> Self?
}

extension InsightsFocusIndexBridge {
    var intIndex: Int {
        let allCasesArray = Array(Self.allCases)
        return allCasesArray.firstIndex(of: self) ?? 0
    }
    
    static func from(intIndex: Int) -> Self? {
        let allCasesArray = Array(Self.allCases)
        guard intIndex >= 0 && intIndex < allCasesArray.count else { return nil }
        return allCasesArray[intIndex]
    }
}
