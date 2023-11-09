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
    var isUserInteractionEnabled: Bool {get set}
    var isFirstResponder: Bool {get}
    var canBecomeFirstResponder: Bool {get}
    var showLabel: Bool {get}
    var forceFirstResponder: Bool {get set}
    func becomeFirstResponder() -> Bool
    func resignFirstResponder() -> Bool
    func prepareForReuse()
    func set(text: String?, numeric: Bool?, unsigned: Bool?, decimalPlaces: Int?, useLabel: Bool?, formattedText: (()->String)?)
}

extension ScorecardInputTextInput {
    func set(text: String?) {
        set(text: text, numeric: nil, unsigned: nil, decimalPlaces: nil, useLabel: nil, formattedText: nil)
    }
    func set(text: String?, numeric: Bool?, unsigned: Bool?, decimalPlaces: Int?) {
        set(text: text, numeric: numeric, unsigned: unsigned, decimalPlaces: decimalPlaces, useLabel: nil, formattedText: nil)
    }
    func set(text: String?, useLabel: Bool?, formattedText: (()->String)?) {
        set(text: text, numeric: nil, unsigned: nil, decimalPlaces: nil, useLabel: useLabel, formattedText: formattedText)
    }
}

class ScorecardInputTextView : UITextView, ScorecardInputTextInput, ScorecardInputResponder, UITextViewDelegate {
    public var textOnEntry: String?
    private var numeric: Bool = false
    private var unsigned: Bool = false
    private var decimalPlaces: Int = 0
    public var updateFocus: Bool = true
    private var label: FirstResponderLabel?
    public var forceFirstResponder: Bool = false
    private var validCharacters: String = ""
    private var formattedText: (()->String)? = nil
    
    public var textValue: String! { get { text } set { text = newValue} }
    override var isUserInteractionEnabled: Bool { didSet { enableControls() } }
    private var firstResponder: Bool = false { didSet { enableControls() } }
    private var isActive: Bool = false { didSet { enableControls() } }
    private var useLabel: Bool = false { didSet { enableControls() } }
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
    
    func set(text: String? = nil, numeric: Bool? = nil, unsigned: Bool? = nil, decimalPlaces: Int? = nil, useLabel: Bool? = nil, formattedText: (()->String)? = nil) {
        if let text = text {
            self.textValue = text
        }
        if let numeric = numeric {
            self.numeric = numeric
        }
        if let unsigned = unsigned {
            self.unsigned = unsigned
        }
        if let decimalPlaces = decimalPlaces {
            self.decimalPlaces = decimalPlaces
        }
        if let useLabel = useLabel {
            self.useLabel = useLabel
        }
        if let formattedText = formattedText {
            self.formattedText = formattedText
        }
        self.isActive = true
        keyboardType = self.numeric ? .numberPad : .default
        if self.numeric {
            validCharacters = "0123456789"
            if !self.unsigned {
                self.validCharacters += "-"
            }
            if decimalPlaces != 0 {
                self.validCharacters += "."
            }
        }
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
        textContainer.maximumNumberOfLines = 0
        textContainer.lineBreakMode = .byWordWrapping
        isUserInteractionEnabled = false
        formattedText = nil
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
        var result = true
        if numeric {
            let newText = NSString(string: textValue).replacingCharacters(in: range, with: text)
            let filtered = newText.filter({validCharacters.contains($0)})
            if filtered != newText {
                result = false
            } else if Float(filtered) == nil {
                result = false
            }
        }
        if result {
            if !(textInputDelegate?.inputTextSpecialCharacters(self, text: text) ?? false) {
                result = textInputDelegate?.inputTextShouldChangeCharacters(self, in: range, replacementString: text) ?? true
            } else {
                result = true
            }
        }
        return result
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textInputDelegate?.inputTextDidBeginEditing(self)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textInputDelegate?.inputTextDidEndEditing(self)
        label?.text = formattedText?() ?? text
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
    private var numeric: Bool = false
    private var unsigned: Bool = false
    private var decimalPlaces: Int = 0
    public var updateFocus: Bool = true
    public var forceFirstResponder: Bool = false
    private var label: FirstResponderLabel?
    private var validCharacters: String = ""
    private var formattedText: (()->String)? = nil
    
    var textValue: String! { get { text } set { text = newValue} }
    override var text: String? { didSet { label?.text = text } }
    override var isUserInteractionEnabled: Bool { didSet { enableControls() } }
    private var firstResponder: Bool = false { didSet { enableControls() } }
    private var isActive: Bool = false { didSet { enableControls() } }
    private var useLabel: Bool = false { didSet { enableControls() } }
    public var showLabel: Bool { (label != nil) && useLabel && (!isUserInteractionEnabled || (!firstResponder && !forceFirstResponder)) }
    
    let textInputDelegate: ScorecardInputDelegate?
    
    init(delegate: ScorecardInputDelegate? = nil, label: FirstResponderLabel? = nil) {
        self.textInputDelegate = delegate
        self.label = label
        super.init(frame: CGRect())
        self.delegate = self
        addTarget(self, action: #selector(ScorecardInputTextField.textFieldChanged), for: .editingChanged)
    }
    
    func set(text: String? = nil, numeric: Bool? = nil, unsigned: Bool? = nil, decimalPlaces: Int? = nil, useLabel: Bool? = nil, formattedText: (()->String)? = nil) {
        if let text = text {
            self.textValue = text
            label?.text = formattedText?() ?? text
        }
        if let numeric = numeric {
            self.numeric = numeric
        }
        if let unsigned = unsigned {
            self.unsigned = unsigned
        }
        if let decimalPlaces = decimalPlaces {
            self.decimalPlaces = decimalPlaces
        }
        if let useLabel = useLabel {
            self.useLabel = useLabel
        }
        if let formattedText = formattedText {
            self.formattedText = formattedText
        }
        self.isActive = true
        keyboardType = self.numeric ? .numberPad : .default
        if self.numeric {
            validCharacters = "0123456789"
            if !self.unsigned {
                self.validCharacters += "-"
            }
            if decimalPlaces != 0 {
                self.validCharacters += "."
            }
        }
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
        textAlignment = .center
        clearsOnBeginEditing = false
        clearButtonMode = .never
        keyboardType = .default
        autocapitalizationType = .none
        autocorrectionType = .no
        isUserInteractionEnabled = false
        formattedText = nil
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
        var result = true
        if numeric {
            let newText = NSString(string: textValue).replacingCharacters(in: range, with: string)
            let filtered = newText.filter({validCharacters.contains($0)})
            if filtered != newText {
                result = false
            } else if Float(filtered) == nil {
                result = false
            }
        }
        if result {
            result = textInputDelegate?.inputTextShouldChangeCharacters(self, in: range, replacementString: string) ?? true
        }
        return result
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textInputDelegate?.inputTextDidBeginEditing(self)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textInputDelegate?.inputTextDidEndEditing(self)
        label?.text = formattedText?() ?? text
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
