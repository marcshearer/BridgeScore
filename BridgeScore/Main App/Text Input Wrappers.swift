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
    var description: String {get}
}
 
extension ScorecardResponderDelegate {
    @discardableResult func keyPressed(keyAction: KeyAction?) -> Bool {
        keyPressed(keyAction: keyAction, characters: "")
    }
}

protocol ScorecardInputDelegate: ScorecardResponderDelegate {
    func inputTextChanged(_ textInput: ScorecardInputTextInput)
    func inputTextShouldChangeCharacters(_ textInput: ScorecardInputTextInput, in range: NSRange, replacementString string: String) -> Bool
    func inputTextDidBeginEditing(_ textInput: ScorecardInputTextInput)
    func inputTextDidEndEditing(_ textInput: ScorecardInputTextInput)
    func inputTextShouldReturn(_ textInput: ScorecardInputTextInput) -> Bool
    func inputTextSpecialCharacters(_ inputText: ScorecardInputTextView, text: String) -> Bool
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
    var textOnEntry: String? {get set}
    var numeric: Bool {get set}
    var unsigned: Bool {get set}
    var decimalPlaces: Int {get set}
    var showLabel: Bool {get}
    var isActive: Bool {get set}
    var useLabel: Bool {get set}
    var forceFirstResponder: Bool {get set}
    func becomeFirstResponder() -> Bool
    func resignFirstResponder() -> Bool
    func prepareForReuse()
}

class ScorecardInputTextView : UITextView, ScorecardInputTextInput, ScorecardInputResponder, UITextViewDelegate {
    public var textOnEntry: String?
    public var numeric: Bool = false
    public var unsigned: Bool = false
    public var decimalPlaces: Int = 0
    public var updateFocus: Bool = true
    private var label: FirstResponderLabel?
    public var forceFirstResponder: Bool = false
    
    var textValue: String! { get { text } set { text = newValue} }
    override var text: String? { didSet { label?.text = text } }
    override var isUserInteractionEnabled: Bool { didSet { enableControls() } }
    private var firstResponder: Bool = false { didSet { enableControls() } }
    public var isActive: Bool = false { didSet { enableControls() } }
    public var useLabel: Bool = false { didSet { enableControls() } }
    public var showLabel: Bool { (label != nil) && useLabel && (!isUserInteractionEnabled || (!firstResponder && !forceFirstResponder)) }

    let textInputDelegate: ScorecardInputDelegate?
    
    public var adjustsFontSizeToFitWidth: Bool {
        get { adjustsFontForContentSizeCategory }
        set { adjustsFontForContentSizeCategory = newValue}
    }

    init(delegate: ScorecardInputDelegate? = nil, label: FirstResponderLabel? = nil) {
        self.textInputDelegate = delegate
        super.init(frame: CGRect(), textContainer: nil)
        label?.backgroundColor = .lightGray
        self.delegate = self
    }
    
    func prepareForReuse() {
        firstResponder = false
        forceFirstResponder = false
        numeric = false
        unsigned = false
        decimalPlaces = 0
        updateFocus = true
        text = ""
        isActive = false
        useLabel = false
    }
    
    func enableControls() {
        label?.isHidden = !showLabel || !isActive
        isHidden = showLabel || !isActive
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textChanged(_ : Any) {
        textViewDidChange(self)
    }
    
    // MARK: - Text View Delegates
    
    func textViewDidChange(_ textView: UITextView) {
        textInputDelegate?.inputTextChanged(self)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if !(textInputDelegate?.inputTextSpecialCharacters(self, text: text) ?? false) {
            textInputDelegate?.inputTextShouldChangeCharacters(self, in: range, replacementString: text) ?? true
        } else {
            true
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textInputDelegate?.inputTextDidBeginEditing(self)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textInputDelegate?.inputTextDidEndEditing(self)
    }
    
    // MARK: - First responders and presses
    
    @discardableResult override func becomeFirstResponder() -> Bool {
        if updateFocus {
            textInputDelegate?.getFocus()
        }
        var result = true
        if !isFirstResponder {
            result = super.becomeFirstResponder()
        }
        firstResponder = isFirstResponder
        forceFirstResponder = false
        return result
    }
    
    @discardableResult override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if updateFocus {
            textInputDelegate?.resignedFirstResponder(from: self)
        }
        firstResponder = isFirstResponder
        forceFirstResponder = false
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

class ScorecardInputTextField : UITextField, ScorecardInputTextInput, UITextFieldDelegate {
    public var textOnEntry: String?
    public var numeric: Bool = false
    public var unsigned: Bool = false
    public var decimalPlaces: Int = 0
    public var updateFocus: Bool = true
    public var forceFirstResponder: Bool = false
    private var label: FirstResponderLabel?
    
    var textValue: String! { get { text } set { text = newValue} }
    override var text: String? { didSet { label?.text = text } }
    override var isUserInteractionEnabled: Bool { didSet { enableControls() } }
    private var firstResponder: Bool = false { didSet { enableControls() } }
    public var isActive: Bool = false { didSet { enableControls() } }
    public var useLabel: Bool = false { didSet { enableControls() } }
    public var showLabel: Bool { (label != nil) && useLabel && (!isUserInteractionEnabled || (!firstResponder && !forceFirstResponder)) }
    
    let textInputDelegate: ScorecardInputDelegate?
    
    init(delegate: ScorecardInputDelegate? = nil, label: FirstResponderLabel? = nil) {
        self.textInputDelegate = delegate
        self.label = label
        super.init(frame: CGRect())
        self.delegate = self
        addTarget(self, action: #selector(ScorecardInputTextField.textFieldChanged), for: .editingChanged)
    }
    
    func prepareForReuse() {
        firstResponder = false
        forceFirstResponder = false
        numeric = false
        unsigned = false
        decimalPlaces = 0
        updateFocus = true
        text = ""
        isActive = false
        useLabel = false
    }
    
    func enableControls() {
        label?.isHidden = !showLabel || !isActive
        isHidden = showLabel || !isActive
    }
    
    override var canBecomeFocused : Bool { false }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func textChanged(_ : Any) {
        textFieldChanged(self)
    }
    
    // MARK: - Text Field Delegates
    
    @objc internal func textFieldChanged(_ textField: UITextField) {
        textInputDelegate?.inputTextChanged(self)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        textInputDelegate?.inputTextShouldChangeCharacters(self, in: range, replacementString: string) ?? true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textInputDelegate?.inputTextDidBeginEditing(self)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textInputDelegate?.inputTextDidEndEditing(self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textInputDelegate?.inputTextShouldReturn(self) ?? true
    }
    
    // MARK: - First responders and presses
    
    @discardableResult override func becomeFirstResponder() -> Bool {
        if updateFocus {
            textInputDelegate?.getFocus()
        }
        var result = true
        if !isFirstResponder {
            result = super.becomeFirstResponder()
        }
        firstResponder = isFirstResponder
        forceFirstResponder = false
        return result
    }
    
    @discardableResult override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if updateFocus {
            textInputDelegate?.resignedFirstResponder(from: self)
        }
        firstResponder = isFirstResponder
        forceFirstResponder = false
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
