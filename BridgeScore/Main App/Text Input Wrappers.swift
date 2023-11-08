//
//  Text Input Wrappers.swift
//  BridgeScore
//
//  Created by Marc Shearer on 07/11/2023.
//

import UIKit

protocol ScorecardInputResponder {
    var isFirstResponder: Bool {get}
    var canBecomeFirstResponder: Bool {get}
    func becomeFirstResponder() -> Bool
    func resignFirstResponder() -> Bool
}

protocol ScorecardResponderDelegate {
    @discardableResult func getFocus() -> Bool
    func resignedFirstResponder(from: ScorecardResponder)
    @discardableResult func keyPressed(keyAction: KeyAction?, characters: String) -> Bool
    func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?)
    func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?)
}
 
extension ScorecardResponderDelegate {
    @discardableResult func keyPressed(keyAction: KeyAction?) -> Bool {
        keyPressed(keyAction: keyAction, characters: "")
    }
}

protocol ScorecardInputDelegate: ScorecardResponderDelegate {
    func textFieldChanged(_ textField: UITextField)
}

protocol ScorecardInputTextInput : ScorecardResponder, UITextInput, ScorecardInputResponder {
    var textValue: String! {get set}
    var textAlignment: NSTextAlignment {get set}
    var autocapitalizationType: UITextAutocapitalizationType {get set}
    var isHidden: Bool {get set}
    var adjustsFontForContentSizeCategory: Bool {get set}
    var font: UIFont? {get set}
    var autocorrectionType: UITextAutocorrectionType {get set}
    var backgroundColor: UIColor? {get set}
    var textColor: UIColor? {get set}
    var adjustsFontSizeToFitWidth: Bool {get set}
    var returnKeyType: UIReturnKeyType {get set}
    var keyboardType: UIKeyboardType {get set}
    var isUserInteractionEnabled: Bool {get set}
    var isFirstResponder: Bool {get}
    var canBecomeFirstResponder: Bool {get}
    func textChanged(_ control: ScorecardInputTextInput)
    func becomeFirstResponder() -> Bool
    func resignFirstResponder() -> Bool
}

class ScorecardInputTextView : UITextView, ScorecardInputTextInput, ScorecardInputResponder {
    
    public var textValue: String! {
        get { text }
        set { text = newValue}
    }
    
    public var updateFocus: Bool = true
    
    let textInputDelegate: ScorecardInputDelegate?
    
    public var adjustsFontSizeToFitWidth: Bool {
        get { adjustsFontForContentSizeCategory }
        set { adjustsFontForContentSizeCategory = newValue}
    }

    init(delegate: ScorecardInputDelegate? = nil) {
        self.textInputDelegate = delegate
        super.init(frame: CGRect(), textContainer: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textChanged(_ control: ScorecardInputTextInput) {
        control.textChanged(control)
    }
    
    @discardableResult override func becomeFirstResponder() -> Bool {
        if updateFocus {
            textInputDelegate?.getFocus()
        }
        return super.becomeFirstResponder()
    }
    
    @discardableResult override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if updateFocus {
            textInputDelegate?.resignedFirstResponder(from: self)
        }
        return result
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !processPressedKeys(presses, with: event, action: { (keyAction, _) in
            keyAction.navigationKey
        }) {
            super.pressesBegan(presses, with: event)
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if let keyPressed = textInputDelegate?.keyPressed {
            if !processPressedKeys(presses, with: event, action: keyPressed) {
                super.pressesEnded(presses, with: event)
            }
        }
    }
}

class ScorecardInputTextField : UITextField, ScorecardInputTextInput {
    var textValue: String! {
        get { text }
        set { text = newValue}
    }
    
    public var updateFocus = true
    
    let textInputDelegate: ScorecardInputDelegate?
    
    init(delegate: ScorecardInputDelegate? = nil) {
        self.textInputDelegate = delegate
        super.init(frame: CGRect())
    }
    
    override var canBecomeFocused : Bool { false }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textChanged(_ control: ScorecardInputTextInput) {
        textInputDelegate?.textFieldChanged(self)
    }
    
    @discardableResult override func becomeFirstResponder() -> Bool {
        if updateFocus {
            textInputDelegate?.getFocus()
        }
        return super.becomeFirstResponder()
    }
    
    @discardableResult override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if updateFocus {
            textInputDelegate?.resignedFirstResponder(from: self)
        }
        return result
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !processPressedKeys(presses, with: event, action: { (keyAction, _) in
            keyAction.navigationKey || keyAction.upDownKey || keyAction == .enter
        }) {
            super.pressesBegan(presses, with: event)
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if let keyPressed = textInputDelegate?.keyPressed {
            if !processPressedKeys(presses, with: event, action: keyPressed) {
                super.pressesEnded(presses, with: event)
            }
        }
    }
}
