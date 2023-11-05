//
//  Contract Picker View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 04/11/2023.
//

import UIKit

class ContractEntryView: UILabel {
    var parent: ScorecardInputCollectionCell
    var contract: Contract!
    var contractOnEntry: Contract!
    private var suitCharacters: String
    private var levelCharacters: String
    private var doubleCharacters: String
    
    init(from parent: ScorecardInputCollectionCell) {
        self.parent = parent
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
        self.backgroundColor = UIColor.clear
    }
    
    public func set(contract: Contract) {
        attributedText = contract.attributedString
        self.contract.copy(from: contract)
        self.contractOnEntry = contract
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var canBecomeFirstResponder: Bool {
        true
    }
    
    @discardableResult override func becomeFirstResponder() -> Bool {
        parent.getFocus(becomeFirstResponder: false)
        return super.becomeFirstResponder()
    }
    
    @discardableResult override func resignFirstResponder() -> Bool {
        parent.loseFocus(resignFirstResponder: false)
        return super.resignFirstResponder()
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !processPressedKeys(presses, with: event, allowCharacters: true, action: { (keyAction, _) in
            switch keyAction {
            case .previous, .next, .up, .down, .escape, .enter, .characters:
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
                if !contract.level.valid || !contract.suit.valid {
                    set(contract: contractOnEntry)
                    parent.keyPressed(keyAction: keyAction)
                }
            case .escape:
                set(contract: contractOnEntry)
            case .enter:
                if !contract.level.valid || !contract.suit.valid {
                    contractOnEntry.copy(from: contract)
                }
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
                } else if characters.trim() == "" && contract.canClear {
                    contract.level = .blank
                }
            default:
                result = false
                break
            }
            return result
        }) {
            super.pressesEnded(presses, with: event)
        }
    }
}

