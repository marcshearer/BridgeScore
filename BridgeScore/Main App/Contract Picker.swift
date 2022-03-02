//
//  Contract Picker.swift
//  BridgeScore
//
//  Created by Marc Shearer on 17/02/2022.
//

import UIKit

// MARK: - Note this is not used - replaced by bidding box ======================== -

protocol ContractPickerDelegate {
    func contractPickerDidChange(to: Contract)
}

class ContractPicker: UIView, ScrollPickerDelegate {
    
    private var levelPicker: ScrollPicker
    private var suitPicker: ScrollPicker
    private var doublePicker: ScrollPicker
    private var contract: Contract
    private let levelList = ContractLevel.allCases
    private var suitList = ContractSuit.allCases
    private var doubleList = ContractDouble.allCases
    private var color: PaletteColor?
    private var font: UIFont?
    public var delegate: ContractPickerDelegate?
    
    init(frame: CGRect, contract: Contract = Contract(), color: PaletteColor? = nil, font: UIFont? = nil) {
        self.contract = contract
        levelPicker = ScrollPicker(frame: frame, list: levelList.map{$0.short}, color: color, titleFont: font)
        levelPicker.tag = ContractElement.level.rawValue
        suitPicker = ScrollPicker(frame: frame, list: suitList.map{$0.short}, color: color, titleFont: font)
        suitPicker.tag = ContractElement.suit.rawValue
        doublePicker = ScrollPicker(frame: frame, list: doubleList.map{$0.short}, color: color, titleFont: font)
        doublePicker.tag = ContractElement.double.rawValue
        super.init(frame: frame)
        levelPicker.delegate = self
        suitPicker.delegate = self
        doublePicker.delegate = self
        let container = UIView()
        self.addSubview(container, anchored: .centerX, .top, .bottom)
        Constraint.setWidth(control: container, width: 90)
        container.addSubview(levelPicker, anchored: .leading, .top, .bottom)
        container.addSubview(suitPicker, anchored: .top, .bottom)
        container.addSubview(doublePicker, anchored: .trailing, .top, .bottom)
        Constraint.setWidth(control: levelPicker, width: 20)
        Constraint.setWidth(control: suitPicker, width: 40)
        Constraint.setWidth(control: doublePicker, width: 30)
        Constraint.anchor(view: container, control: levelPicker, to: suitPicker, toAttribute: .leading, attributes: .trailing)
        Constraint.anchor(view: container, control: suitPicker, to: doublePicker, toAttribute: .leading, attributes: .trailing)
        set(level: contract.level, reflect: true, force: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollPickerDidChange(_ scrollPicker: ScrollPicker?, to index: Int?) {
        if let scrollPicker = scrollPicker {
            if let element = ContractElement(rawValue: scrollPicker.tag) {
                switch element {
                case .level:
                    let newValue = levelList[index!]
                    if newValue != contract.level {
                        delegate?.contractPickerDidChange(to: Contract(level: newValue, suit: contract.suit, double: contract.double))
                        set(level: newValue, reflect: true)
                    }
                case .suit:
                    let newValue = suitList[index!]
                    if newValue != contract.suit {
                        delegate?.contractPickerDidChange(to: Contract(level: contract.level, suit: newValue, double: contract.double))
                        set(suit: newValue, reflect: true)
                    }
                case .double:
                    let newValue = doubleList[index!]
                    if newValue != contract.double {
                        delegate?.contractPickerDidChange(to: Contract(level: contract.level, suit: contract.suit, double: newValue))
                        set(double: newValue, reflect: true)
                    }
                }
            }
        }
    }
    
    public func set(_ contract: Contract, color: PaletteColor? = nil, font: UIFont? = nil, clearBackground: Bool = true, force: Bool = false) {
        if let color = color {
            self.color = color
        }
        if let font = font {
            self.font = font
        }
        set(level: contract.level, clearBackground: clearBackground, reflect: true)
        set(suit: contract.suit, clearBackground: clearBackground, reflect: true)
        set(double: contract.double, clearBackground: clearBackground, reflect: true)
    }
    
    @discardableResult private func set(level newValue: ContractLevel, clearBackground: Bool = true, reflect: Bool = false, force: Bool = false) -> Bool {
        var changed = false
        if newValue != contract.level || force {
            if !newValue.hasSuit && (contract.suit != .blank || force) {
                set(suit: .blank, reflect: reflect, force: force)
            }
            contract.level = newValue
            if reflect {
                suitPicker.isUserInteractionEnabled = newValue.hasSuit
                if let index = self.levelList.firstIndex(where: {$0 == contract.level}) {
                    self.levelPicker.set(index, color: color, titleFont: font, clearBackground: clearBackground)
                }
            }
            changed = true
        }
        return changed
    }
    
    @discardableResult private func set(suit newValue: ContractSuit, clearBackground: Bool = true, reflect: Bool = false, force: Bool = false)  -> Bool {
        var changed = false
        if newValue != contract.suit || force {
            if !newValue.hasDouble && (contract.double != .undoubled || force) {
                set(double: .undoubled, reflect: reflect, force: force)
            }
            contract.suit = newValue
            if reflect {
                doublePicker.isUserInteractionEnabled = newValue.hasDouble
                if let index = self.suitList.firstIndex(where: {$0 == contract.suit}) {
                    self.suitPicker.set(index, color: color, titleFont: font, clearBackground: clearBackground)
                }
            }
            changed = true
        }
        return changed
    }
    
    @discardableResult private func set(double newValue: ContractDouble, clearBackground: Bool = true, reflect: Bool = false, force: Bool = false)  -> Bool {
        var changed = false
        if newValue != contract.double || force {
            contract.double = newValue
            if reflect {
                if let index = self.doubleList.firstIndex(where: {$0 == contract.double}) {
                    self.doublePicker.set(index, color: color, titleFont: titleFont, clearBackground: clearBackground)
                }
            }
            changed = true
        }
        return changed
    }
}

