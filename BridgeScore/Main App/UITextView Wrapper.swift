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
    @State var frame: CGRect
    @Binding var field: String
    @Binding var focused: Bool
    @State var color: ThemeBackgroundColorName = .input
    
    func makeUIView(context: Context) -> TextViewContainer {
        let textViewContainer = TextViewContainer(frame: frame, field: $field, color: color, coordinator: context.coordinator)
        context.coordinator.textViewContainer = textViewContainer
        return textViewContainer
    }
    
    func updateUIView(_ textViewContainer: TextViewContainer, context: Context) {
        textViewContainer.textView.set(text: field)
        if focused {
            textViewContainer.textView.becomeFirstResponder()
        } else {
            textViewContainer.textView.setContentOffset(.zero, animated: false)
            textViewContainer.textView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, TextViewWrapperDelegate {
        var parent: TextViewWrapper
        var textViewContainer: TextViewContainer!
        
        init(_ parent: TextViewWrapper) {
            self.parent = parent
        }
        
        func autoCompleteDidMoveToSuperview(autoComplete: AutoComplete) { }
        
        func autoCompleteWillMoveToSuperview(autoComplete: AutoComplete) { }
        
        internal func replace(with text: String, textInput: ScorecardInputTextInput, positionAt: NSRange) {
            if let autoComplete = AnalysisViewer.autoComplete {
                textInput.textValue = text
                inputTextChanged(textInput)
                if let location = textInput.position(from: textInput.beginningOfDocument, offset: positionAt.location) {
                    textInput.selectedTextRange = textInput.textRange(from: location, to: location)
                }
                autoComplete.isActive = false
            }
        }

        func keyPressed(keyAction: KeyAction?, characters: String) -> Bool {
            var handled = false
            if let autoComplete = AnalysisViewer.autoComplete {
                if let keyAction = keyAction, autoComplete.isActive {
                    if keyAction.upDownKey || keyAction == .enter {
                        handled = autoComplete.keyPressed(keyAction: keyAction)
                    }
                }
            }
            return handled
        }
        
        func inputTextChanged(_ textInput: any ScorecardInputTextInput) {
            parent.field = textInput.textValue
        }
        
        func inputTextShouldChangeCharacters(_ textInput: any ScorecardInputTextInput, in range: NSRange, replacementString string: String) -> Bool {
            textAutoComplete(textInput, replacing: textInput.textValue!, range: range, with: string)
            return true
            
        }
        
        private func textAutoComplete(_ textInput: any ScorecardInputTextInput,replacing original: String, range: NSRange, with: String) {
            if let autoComplete = AnalysisViewer.autoComplete {
                if autoComplete.superview == nil {
                    // Bodge - view seems to be dropped out of hierarchy so re-insert it here
                    textInput.superview?.superview?.superview?.superview?.addSubview(autoComplete)
                }
                if autoComplete.superview != nil {
                    let text = (original as NSString).replacingCharacters(in: range, with: with)
                    let range = NSRange(location: range.location + NSString(string: with).length, length: 0)
                    autoComplete.delegate = self
                    let listSize = autoComplete.set(text: text, textInput: textInput, at: range)
                    if listSize == 0 {
                        autoComplete.isActive = false
                        autoComplete.delegate = nil
                    } else {
                        autoComplete.isActive = true
                        let height = CGFloat(min(5, listSize) * 40)
                        var point = textViewContainer.convert(CGPoint(x: textViewContainer.textView.frame.minX, y: textViewContainer.textView.frame.maxY), to: autoComplete.superview!)
                        if point.y + 200 >= UIScreen.main.bounds.height {
                            point = point.offsetBy(dy: -textViewContainer.frame.height - textViewContainer.frame.height)
                        }
                        autoComplete.frame = CGRect(x: point.x, y: point.y, width: textViewContainer.frame.width, height: height)
                        autoComplete.superview!.bringSubviewToFront(autoComplete)
                        textViewContainer.isHidden = false
                    }
                }
            }
        }
        
        func inputTextDidBeginEditing(_ textInput: any ScorecardInputTextInput) {
        }
        
        func inputTextDidEndEditing(_ textInput: any ScorecardInputTextInput) {
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
        }
        
        func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        }
        
        func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        }
        
    }
    
    public func paletteColor(_ color: ThemeBackgroundColorName) -> some View {
        var view = self
        view._color = State(initialValue: color)
        return view.id(UUID())
    }
}

class TextViewContainer: UIView {
    var textView: ScorecardInputTextView!
    var field: Binding<String>
    
    init(frame: CGRect, field: Binding<String>, color: ThemeBackgroundColorName, coordinator: TextViewWrapperDelegate) {
        self.field = field
        super.init(frame: frame)
        self.textView = ScorecardInputTextView(delegate: coordinator)
        self.textView.frame = frame
        self.textView.font = analysisCommentFont
        self.textView.backgroundColor = UIColor(PaletteColor(color).background)
        self.textView.textColor = UIColor(PaletteColor(color).textColor(.normal))
        self.textView.tintColor = UIColor(PaletteColor(color).textColor(.strong))
        self.textView.autocorrectionType = .no
        self.textView.autocapitalizationType = .sentences
        self.textView.inlinePredictionType = .no    
        self.textView.tintColorDidChange()
        self.textView.showsVerticalScrollIndicator = false
        textView.isScrollEnabled = false
        self.addSubview(textView, anchored: .top, .leading, .trailing)
        Constraint.setHeight(control: textView, height: frame.height)
        self.clipsToBounds = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

struct AutoCompleteWrapper: UIViewRepresentable {
    typealias UIViewType = AutoComplete
    @State var frame: CGRect
    
    func makeUIView(context: Context) -> AutoComplete {
        let autoComplete = AutoComplete()
        return autoComplete
    }
    
    func updateUIView(_ autoComplete: AutoComplete, context: Context) {
        context.coordinator.autoComplete = autoComplete
        setupAutoComplete(autoComplete: autoComplete, delegate: context.coordinator)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AutoCompleteDelegate {
        var parent: AutoCompleteWrapper
        var autoComplete: AutoComplete!
        
        init(_ parent: AutoCompleteWrapper) {
            self.parent = parent
        }
        
        func autoCompleteDidMoveToSuperview(autoComplete: AutoComplete) {
            AnalysisViewer.autoComplete = autoComplete
        }
        
        func autoCompleteWillMoveToSuperview(autoComplete: AutoComplete) {
            
        }
        
        func replace(with: String, textInput: any ScorecardInputTextInput, positionAt: NSRange) {
            
        }
    }
    
    func setupAutoComplete(autoComplete: AutoComplete, delegate: AutoCompleteDelegate) {
        var list:[(String, String, String)] = []
        for rank in CardRank.allCases {
            list.append(contentsOf: Suit.realSuits.map({(rank.short + $0.short.uppercased(), rank.short + $0.string, "\(rank.string) \(rank.rawValue > 7 ? "of" : "") \($0.words)")}))
        }
        list.append(contentsOf: Suit.realSuits.map({($0.short.uppercased(), $0.string, $0.words)}))
        list.append(contentsOf: Suit.realSuits.map({("1" + $0.short.uppercased(), "1" + $0.string, "1 " + $0.singular)}))
        autoComplete.set(list: list, consider: .trailingAlphaNumeric)
        autoComplete.delegate = delegate
    }
}
