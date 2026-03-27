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
    @discardableResult func getFocus(becomeFirstResponder: Bool) -> Bool
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
    @discardableResult func getFocus() -> Bool {
        getFocus(becomeFirstResponder: false)
    }
}

protocol ScorecardInputDelegate: ScorecardResponderDelegate {
    func inputTextChanged(_ textInput: ScorecardInputTextInput)
    func inputTextRangeChanged(_ textInput: ScorecardInputTextInput)
    func inputTextShouldChangeCharacters(_ textInput: ScorecardInputTextInput, in range: NSRange, replacementString string: String) -> Bool
    func inputTextDidBeginEditing(_ textInput: ScorecardInputTextInput)
    func inputTextDidEndEditing(_ textInput: ScorecardInputTextInput)
    func inputTextShouldReturn(_ textInput: ScorecardInputTextInput) -> Bool
    func inputTextSpecialCharacters(_ inputText: ScorecardInputTextView, text: String) -> Bool
}

protocol ScorecardInputTextInput : ScorecardResponder, UITextInput, ScorecardInputResponder {
    var textValue: String! {get set}
    var textAlignment: NSTextAlignment {get set}
    var autoComplete: AutoComplete? {get set}
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
    var isActive: Bool {get}
    var isNumeric: Bool {get}
    var useLabel: Bool {get}
    var attributed: ((String)->NSAttributedString)? {get set}
    func becomeFirstResponder() -> Bool
    func resignFirstResponder() -> Bool
    func prepareForReuse()
    func set(text: String?, numeric: Bool?, unsigned: Bool?, decimalPlaces: Int?, useLabel: Bool?, formattedText: (()->String)?, attributed: ((String)->NSAttributedString)?, columnType: ColumnType?)
}

extension ScorecardInputTextInput {
    func set(text: String?, columnType: ColumnType?) {
        set(text: text, numeric: nil, unsigned: nil, decimalPlaces: nil, useLabel: nil, formattedText: nil, attributed: nil, columnType: columnType)
    }
    func set(text: String?, numeric: Bool?, unsigned: Bool?, decimalPlaces: Int?, columnType: ColumnType?) {
        set(text: text, numeric: numeric, unsigned: unsigned, decimalPlaces: decimalPlaces, useLabel: nil, formattedText: nil, attributed: nil, columnType: columnType)
    }
    func set(text: String?, useLabel: Bool?, formattedText: (()->String)?, columnType: ColumnType?) {
        set(text: text, numeric: nil, unsigned: nil, decimalPlaces: nil, useLabel: useLabel, formattedText: formattedText, attributed: nil, columnType: columnType)
    }
    func set(text: String?, useLabel: Bool?, formattedText: (()->String)?, attributed: ((String)->NSAttributedString)?, columnType: ColumnType?) {
        set(text: text, numeric: nil, unsigned: nil, decimalPlaces: nil, useLabel: useLabel, formattedText: formattedText, attributed: attributed, columnType: columnType)
    }
    func set(text: String?, numeric: Bool?, unsigned: Bool?, decimalPlaces: Int?, useLabel: Bool?, formattedText: (()->String)?, columnType: ColumnType?) {
        set(text: text, numeric: nil, unsigned: nil, decimalPlaces: nil, useLabel: useLabel, formattedText: formattedText, attributed: nil, columnType: columnType)
    }
}

class ScorecardInputTextView : UITextView, ScorecardInputTextInput, ScorecardInputResponder, UITextViewDelegate {
    public var columnType: ColumnType? = nil
    public var autoComplete: AutoComplete? = nil
    public var textOnEntry: String?
    private var numeric: Bool = false
    private var unsigned: Bool = false
    private var decimalPlaces: Int = 0
    public var updateFocus: Bool = false
    private var label: FirstResponderLabel?
    public var forceFirstResponder: Bool = false
    private var validCharacters: String = ""
    private var formattedText: (()->String)? = nil
    internal var attributed: ((String)->NSAttributedString)? = nil
    
    public var textValue: String! { get { text } set {
            text = newValue
        }
    }
    override var text: String? {
        didSet {
            updateLabel()
        }
    }
    override var isUserInteractionEnabled: Bool { didSet { enableControls() } }
    private var firstResponder: Bool = false { didSet { enableControls() } }
    private(set) var isActive: Bool = false { didSet { enableControls() } }
    private(set) var useLabel: Bool = false { didSet { enableControls() } }
    public var showLabel: Bool { (label != nil) && useLabel && (!isUserInteractionEnabled || (!firstResponder && !forceFirstResponder)) }
    public var isNumeric: Bool { numeric }

    let textInputDelegate: ScorecardInputDelegate?
    
    public var adjustsFontSizeToFitWidth: Bool {
        get { adjustsFontForContentSizeCategory }
        set { adjustsFontForContentSizeCategory = newValue}
    }

    init(delegate: ScorecardInputDelegate? = nil, label: FirstResponderLabel? = nil, autoComplete: AutoComplete? = nil) {
        self.textInputDelegate = delegate
        self.label = label
        super.init(frame: CGRect(), textContainer: nil)
        label?.backgroundColor = .lightGray
        self.updateFocus = true
        self.autoComplete = autoComplete
        self.delegate = self
    }
    
    func set(text: String? = nil, numeric: Bool? = nil, unsigned: Bool? = nil, decimalPlaces: Int? = nil, useLabel: Bool? = nil, formattedText: (()->String)? = nil, attributed: ((String)->NSAttributedString)? = nil, columnType: ColumnType? = nil) {
        if let attributed = attributed {
            self.attributed = attributed
        }
        if let columnType = columnType {
            self.columnType = columnType
        }
        if let text = text, text != textValue {
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
        columnType = nil
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
        autoComplete = nil
    }
    
    func enableControls() {
        label?.isHidden = !showLabel || !isActive
        isHidden = showLabel || !isActive
    }
    
    func updateLabel() {
        if let attributed = attributed, let text = text {
            label?.attributedText = attributed(text)
        } else {
            label?.text = text
        }
        enableControls()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textChanged(_ : Any) {
        textViewDidChange(self)
    }
    
    // MARK: - Text View Delegates
    
    override var keyCommands: [UIKeyCommand]? {
        return [ UIKeyCommand(input: "\t", modifierFlags: .shift, action: #selector(handleShiftTab)),
                 UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(handleEscape))
        ]
    }
    
    @objc func handleShiftTab(sender: UIKeyCommand) {

    }
    
    @objc func handleEscape(sender: UIKeyCommand) {
        
    }
    
    func textViewDidChange(_ textView: UITextView) {
        textInputDelegate?.inputTextChanged(self)
        updateLabel()
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
                result = false
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
        if let attributed = attributed, let label = label, let text = label.text {
            label.attributedText = attributed(text)
        }
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if let autoComplete = autoComplete {
            if let textRange = textView.selectedTextRange {
                let location = textView.offset(from: textView.beginningOfDocument, to: textRange.end)
                let range = NSRange(location: location, length: 0)
                Utility.mainThread {
                    autoComplete.set(text: textView.text, at: range)
                }
            }
        }
        textInputDelegate?.inputTextRangeChanged(self)
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
        label?.isHidden = true
        self.isHidden = false
        firstResponder = isFirstResponder
        forceFirstResponder = false
        textInputDelegate?.inputTextRangeChanged(self)
        return result
    }
    
    @discardableResult override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if updateFocus {
            textInputDelegate?.resignedFirstResponder(from: self)
        }
        firstResponder = isFirstResponder
        forceFirstResponder = false
        textInputDelegate?.inputTextRangeChanged(self)
        return result
    }
    
    // Don't seem to need this anymore!
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !processPressedKeys(presses, with: event, action: { (keyAction, _) in
            keyAction.navigationKey || keyAction == .enter || (!(autoComplete?.filteredList.isEmpty ?? true) && keyAction.upDownKey)
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
    public var columnType: ColumnType? = nil
    public var autoComplete: AutoComplete?
    public var textOnEntry: String?
    private var numeric: Bool = false
    private var unsigned: Bool = false
    private var decimalPlaces: Int = 0
    public var updateFocus: Bool = true
    public var forceFirstResponder: Bool = false
    private var label: FirstResponderLabel?
    private var validCharacters: String = ""
    private var formattedText: (()->String)? = nil
    internal var attributed: ((String)->NSAttributedString)?

    var textValue: String! { get { text } set { text = newValue} }
    override var text: String? {
        didSet {
            if let attributed = attributed, let text = text {
                label?.attributedText = attributed(text)
            } else {
                label?.text = text
            }
        }
    }
    override var isUserInteractionEnabled: Bool { didSet { enableControls() } }
    private var firstResponder: Bool = false { didSet { enableControls() } }
    private(set) var isActive: Bool = false { didSet { enableControls() } }
    private(set) var useLabel: Bool = false { didSet { enableControls() } }
    public var showLabel: Bool { (label != nil) && useLabel && (!isUserInteractionEnabled || (!firstResponder && !forceFirstResponder)) }
    public var isNumeric: Bool { numeric }

    let textInputDelegate: ScorecardInputDelegate?
    
    init(delegate: ScorecardInputDelegate? = nil, label: FirstResponderLabel? = nil) {
        self.textInputDelegate = delegate
        self.label = label
        super.init(frame: CGRect())
        self.delegate = self
        addTarget(self, action: #selector(ScorecardInputTextField.textFieldChanged), for: .editingChanged)
    }
    
    func set(text: String? = nil, numeric: Bool? = nil, unsigned: Bool? = nil, decimalPlaces: Int? = nil, useLabel: Bool? = nil, formattedText: (()->String)? = nil, attributed: ((String)->(NSAttributedString))? = nil, columnType: ColumnType? = nil) {
        if let attributed = attributed {
            self.attributed = attributed
        }
        if let columnType = columnType {
            self.columnType = columnType
        }
        if let text = text, textValue != text {
            self.textValue = text
            updateLabel()
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
        columnType = nil
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
    
    func updateLabel() {
        if let attributed = attributed, let text = text {
            label?.attributedText = attributed(text)
        } else {
            label?.text = text
        }
        enableControls()
    }
    
    override var canBecomeFocused : Bool { false }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func textChanged(_ : Any) {
        textFieldChanged(self)
    }
    
    // MARK: - Text Field Delegates
    
    override var keyCommands: [UIKeyCommand]? {
        return [ UIKeyCommand(input: "\t", modifierFlags: .shift, action: #selector(handleShiftTab)),
                 UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(handleEscape))
        ]
    }
    
    @objc func handleShiftTab(sender: UIKeyCommand) {
        
    }
    
    @objc func handleEscape(sender: UIKeyCommand) {
        
    }
        
    @objc internal func textFieldChanged(_ textField: UITextField) {
        textInputDelegate?.inputTextChanged(self)
    }
    
    @objc internal func textFieldDidChangeSelection(_ textField: UITextField) {
        if let autoComplete = autoComplete {
            if let textRange = textField.selectedTextRange {
                let location = textField.offset(from: textField.beginningOfDocument, to: textRange.end)
                let range = NSRange(location: location, length: 0)
                Utility.mainThread {
                    autoComplete.set(text: textField.text!, at: range)
                }
            }
        }
        textInputDelegate?.inputTextRangeChanged(self)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var result = true
        if numeric {
            let newText = NSString(string: textValue).replacingCharacters(in: range, with: string)
            let filtered = newText.filter({validCharacters.contains($0)})
            if filtered != newText {
                result = false
            } else if filtered != "" && Float(filtered) == nil {
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
        if let attributed = attributed, let label = label, let text = label.text {
            label.attributedText = attributed(text)
        }
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
        textInputDelegate?.inputTextRangeChanged(self)
        return result
    }
    
    @discardableResult override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if updateFocus {
            textInputDelegate?.resignedFirstResponder(from: self)
        }
        firstResponder = isFirstResponder
        forceFirstResponder = false
        textInputDelegate?.inputTextRangeChanged(self)
        return result
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !processPressedKeys(presses, with: event, action: { (keyAction, _) in
            keyAction.movementKey || keyAction == .enter
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

