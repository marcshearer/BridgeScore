//
//  Contract Picker.swift
//  BridgeScore
//
//  Created by Marc Shearer on 04/11/2023.
//

import UIKit

class ContractPicker: UILabel, ScorecardResponder {
    private var responderDelegate: ScorecardResponderDelegate
    private(set) var contract: Contract!
    private var contractOnEntry: Contract!
    private var suitCharacters: String
    private var levelCharacters: String
    private var doubleCharacters: String
    private var completion: ((Contract?, KeyAction?, String?)->())?
    var updateFocus: Bool = true
    
    init(from responderDelegate: ScorecardResponderDelegate) {
        self.responderDelegate = responderDelegate
        levelCharacters = ""
        suitCharacters = ""
        doubleCharacters = "*X"
        super.init(frame: CGRect())
        for level in ContractLevel.validCases {
            levelCharacters += level.string.left(1)
        }
        
        for suit in Suit.validCases {
            suitCharacters += suit.character
        }
        backgroundColor = UIColor.clear
    }
    
    public func prepareForReuse() {
        isUserInteractionEnabled = false
        contract = nil
        contractOnEntry = nil
        font = cellFont
        attributedText = NSAttributedString(string: "")
        textAlignment = .center
        minimumScaleFactor = 0.3
        adjustsFontSizeToFitWidth = true
    }
    
    public func set(contract: Contract, completion: ((Contract?, KeyAction?, String?)->())? = nil) {
        attributedText = contract.attributedString
        if let completion = completion {
            self.completion = completion
        }
        self.contractOnEntry = Contract(copying: contract)
        self.contract = Contract(copying: contract)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var canBecomeFirstResponder: Bool {
        true
    }
    
    @discardableResult override func becomeFirstResponder() -> Bool {
        if updateFocus {
            responderDelegate.getFocus()
        }
        return super.becomeFirstResponder()
    }
    
    @discardableResult override func resignFirstResponder() -> Bool {
        if contract.isValid {
            completion?(Contract(copying: contract), .save, nil)
        } else {
            contract.copy(from: contractOnEntry)
            attributedText = contract.attributedString
        }
        let result = super.resignFirstResponder()
        if updateFocus {
            responderDelegate.resignedFirstResponder(from: self)
        }
        return result
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !processPressedKeys(presses, with: event, allowCharacters: true, action: { (keyAction, _) in
            switch keyAction {
            case .previous, .next, .up, .down, .escape, .enter, .backspace, .delete, .characters:
                true
            default:
                false
            }
        }) {
            super.pressesBegan(presses, with: event)
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        
        if !processPressedKeys(presses, with: event, allowCharacters: true, action: { [self] (keyAction, characters) in
            var result = true
            switch keyAction {
            case .previous, .next, .up, .down:
                var newContract: Contract?
                if contract.isValid {
                    newContract = Contract(copying: contract)
                } else {
                    contract.copy(from: contractOnEntry)
                }
                completion?(newContract, keyAction, nil)
            case .enter:
                completion?(nil, keyAction, nil)
            case .escape:
                contract.copy(from: contractOnEntry)
            case .delete, .backspace:
                contract.level = .blank
                completion?(contract, keyAction == .backspace ? .previous : nil, nil)
            case .left, .right:
                break
            case .characters:
                if characters.trim().left(1).uppercased() == "P" {
                    contract.level = .passout
                } else if levelCharacters.contains(characters.uppercased()) {
                    contract.level = ContractLevel(character: characters)
                } else if suitCharacters.contains(characters.uppercased()) {
                    contract.suit = Suit(string: characters.uppercased())
                } else if doubleCharacters.contains(characters.uppercased()) {
                    let current = contract.double
                    contract.double = ContractDouble(rawValue: (current.rawValue + 1) % ContractDouble.allCases.count)!
                } else if characters.trim() == "" {
                    completion?(nil, keyAction, characters)
                }
            default:
                result = false
                break
            }
            attributedText = contract.attributedString
            return result
        }) {
            super.pressesEnded(presses, with: event)
        }
    }
}

