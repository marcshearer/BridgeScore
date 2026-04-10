//
//  UITextView Wrapper.swift
//  BridgeScore
//
//  Created by Marc Shearer on 18/01/2025.
//

import UIKit
import SwiftUI

// Note this is specifically configured for the Analysis view

typealias TextViewWrapperDelegate = ScorecardInputDelegate & AutoCompleteDelegate

struct TextViewWrapper: UIViewRepresentable {
    typealias UIViewType = TextViewContainer
    @ObservedObject var autoComplete: AutoComplete
    @State var frame: CGRect
    @Binding var field: String
    @Binding var focused: Bool
    @State var disabledColor: ThemeBackgroundColorName = .input
    @State var enabledColor: ThemeBackgroundColorName = .input
    
    func makeUIView(context: Context) -> TextViewContainer {
        let textViewContainer = TextViewContainer(frame: frame, field: $field, disabledColor: disabledColor, enabledColor: enabledColor, coordinator: context.coordinator, autoComplete: autoComplete)
        context.coordinator.textViewContainer = textViewContainer
        autoComplete.delegate = context.coordinator
        return textViewContainer
    }
    
    func updateUIView(_ textViewContainer: TextViewContainer, context: Context) {
        textViewContainer.textView.set(text: field, useLabel: true)
        if focused {
            textViewContainer.textView.becomeFirstResponder()
        } else {
            textViewContainer.textView.setContentOffset(.zero, animated: false)
            textViewContainer.textView.resignFirstResponder()
        }
        textViewContainer.set(focused: focused)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, TextViewWrapperDelegate {
        var parent: TextViewWrapper
        var textViewContainer: TextViewContainer!
        
        init(_ parent: TextViewWrapper) {
            self.parent = parent
            super.init()
        }
        
        func replace(with text: String, positionAt: NSRange) {
            if let textInput = textViewContainer.textView {
                textInput.textValue = text
                inputTextChanged(textInput)
                if let location = textInput.position(from: textInput.beginningOfDocument, offset: positionAt.location) {
                    textInput.selectedTextRange = textInput.textRange(from: location, to: location)
                }
                parent.autoComplete.set(text: text, at: positionAt)
            }
        }

        func keyPressed(keyAction: KeyAction?, characters: String) -> Bool {
            var handled = false
            if let keyAction = keyAction, !parent.autoComplete.filteredList.isEmpty {
                if keyAction.upDownKey || keyAction == .enter {
                    parent.autoComplete.keyPressed(keyAction: keyAction)
                    handled = true
                }
            }
            if !handled {
                if keyAction == .escape || keyAction == .enter || (keyAction?.navigationKey ?? false) {
                    handled = true
                    textViewContainer.set(focused: false)
                }
            }
            return handled
        }
        
        func inputTextChanged(_ textInput: any ScorecardInputTextInput) {
            parent.field = textInput.textValue
        }
        
        func inputTextRangeChanged(_ textInput: any ScorecardInputTextInput) {
        }
        
        func inputTextShouldChangeCharacters(_ textInput: any ScorecardInputTextInput, in range: NSRange, replacementString string: String) -> Bool {
            textAutoComplete(textInput, replacing: textInput.textValue!, range: range, with: string)
            return true
            
        }
        
        private func textAutoComplete(_ textInput: any ScorecardInputTextInput, replacing original: String, range: NSRange, with: String) {
            let text = (original as NSString).replacingCharacters(in: range, with: with)
            let range = NSRange(location: range.location + NSString(string: with).length, length: 0)
            parent.autoComplete.set(text: text, at: range)
        }
        
        func inputTextDidBeginEditing(_ textInput: any ScorecardInputTextInput) {
        }
        
        func inputTextDidEndEditing(_ textInput: any ScorecardInputTextInput) {
            Utility.mainThread {
                self.parent.focused = false
            }
        }
        
        func inputTextShouldReturn(_ textInput: any ScorecardInputTextInput) -> Bool {
            return true
        }
        
        func inputTextSpecialCharacters(_ inputText: ScorecardInputTextView, text: String) -> Bool {
            var result = false
            if text == "\n" {
                if !keyPressed(keyAction: .enter) {
                     getFocus()
                }
                result = true
            } else if text == "\t" {
                keyPressed(keyAction: .next)
                result = true
            }
            return result
        }
        
        func getFocus(becomeFirstResponder: Bool) -> Bool {
            return true
        }
        
        func resignedFirstResponder(from: any ScorecardResponder) {
            Utility.mainThread {
                self.parent.focused = false
            }
        }
        
        func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        }
        
        func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            
        }
    }
    
    public func paletteColor(_ color: ThemeBackgroundColorName) -> some View {
        var view = self
        view._disabledColor = State(initialValue: color)
        return view.id(UUID())
    }
}

class TextViewContainer: UIView {
    var textView: ScorecardInputTextView!
    var label: FirstResponderLabel!
    var field: Binding<String>
    var disabledColor: ThemeBackgroundColorName
    var enabledColor: ThemeBackgroundColorName
    var tapGesture: UITapGestureRecognizer!
    
    init(frame: CGRect, field: Binding<String>, disabledColor: ThemeBackgroundColorName, enabledColor: ThemeBackgroundColorName, coordinator: TextViewWrapperDelegate, autoComplete: AutoComplete? = nil) {
        self.field = field
        self.disabledColor = disabledColor
        self.enabledColor = enabledColor
        super.init(frame: frame)
        self.label = FirstResponderLabel()
        self.textView = ScorecardInputTextView(delegate: coordinator, label: label, autoComplete: autoComplete)
        self.textView.frame = frame
        self.textView.font = analysisCommentFont
        self.textView.autocorrectionType = .no
        self.textView.autocapitalizationType = .sentences
        self.textView.inlinePredictionType = .no    
        self.textView.tintColorDidChange()
        self.textView.isScrollEnabled = true
        self.textView.allowsKeyboardScrolling = true
        self.textView.showsVerticalScrollIndicator = false
        self.textView.set(attributed: Suit.colorSuits)
        self.set(focused: false)
        self.addSubview(textView, anchored: .top, .leading, .trailing)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.9
        label.font = analysisCommentFont
        label.backgroundColor = .clear
        label.textColor = UIColor(PaletteColor(disabledColor).textColor(.normal))
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(TextViewContainer.labelTapped(_:)))
        label.addGestureRecognizer(tapGesture)
        tapGesture.isEnabled = true
        label.isUserInteractionEnabled = true
        self.addSubview(label, anchored: .top, .leading, .trailing)
        Constraint.setHeight(control: textView, height: frame.height)
        Constraint.setHeight(control: label, height: frame.height)
        self.bringSubviewToFront(label)
        self.clipsToBounds = false
    }
    
    @objc func labelTapped(_ from: UIView) {
        self.set(focused: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
                                          
    func set(focused: Bool) {
        self.textView.backgroundColor = .clear
        let color = (focused ? enabledColor : disabledColor)
        self.textView.textColor = UIColor(PaletteColor(color).textColor(.normal))
        self.textView.tintColor = UIColor(PaletteColor(color).textColor(.strong))
        self.label.isHidden = focused
        self.textView.isHidden = !focused
        if focused {
            self.textView.becomeFirstResponder()
        }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !processPressedKeys(presses, with: event, allowCharacters: true, action: { (keyAction, _) in
            keyAction == .characters || keyAction == .escape || keyAction == .enter || keyAction.navigationKey
        }) {
            super.pressesBegan(presses, with: event)
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !processPressedKeys(presses, with: event, allowCharacters: true, action: { (keyAction, _) in
            keyAction == .characters || keyAction == .escape || keyAction == .enter || keyAction.navigationKey
        }) {
            super.pressesEnded(presses, with: event)
        }
    }
}
