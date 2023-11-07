//
//  Enum Picker.swift
//  BridgeScore
//
//  Created by Marc Shearer on 17/02/2022.
//

import UIKit
import SwiftUI

protocol EnumPickerDelegate {
    func enumPickerDidChange(to: Any, allowPopup: Bool)
}

extension EnumPickerDelegate {
    func enumPickerDidChange(to: Any) {
        enumPickerDidChange(to: to, allowPopup: false)
    }
}

protocol EnumPickerType : CaseIterable, Equatable {
    static var validCases: [Self] {get}
    static var allCases: [Self] {get}
    var string: String {get}
    var short: String {get}
    var rawValue: Int {get}
    init?(rawValue: Int)
}

class EnumPicker<EnumType> : UIView, ScrollPickerDelegate where EnumType : EnumPickerType {
    private var scrollPicker: ScrollPicker
    private var accumulatedView: ScrollPickerView!
    private var list: [EnumType]
    private var entryList: [ScrollPickerEntry]
    private(set) var selected: EnumType!
    private var selectedOnEntry: EnumType!
    private var defaultValue: EnumType?
    public var delegate: EnumPickerDelegate?
    private var accumulatedCharacters: String = ""
    
    init(frame: CGRect, color: PaletteColor? = nil, allCases: Bool = false) {
        list = (allCases ? EnumType.allCases : EnumType.validCases).map{$0}
        entryList = list.map{ScrollPickerEntry(title: $0.short, caption: $0.string)}
        scrollPicker = ScrollPicker(frame: frame, list: entryList, color: color)
        super.init(frame: frame)
        scrollPicker.delegate = self
        addSubview(scrollPicker, anchored: .all)
        accumulatedView = ScrollPickerView()
        self.addSubview(accumulatedView, anchored: .all)
    }
    
    public func set(_ selected: EnumType, defaultValue: EnumType? = nil, isEnabled: Bool = true, color: PaletteColor? = nil, titleFont: UIFont? = nil, captionFont: UIFont? = nil, clearBackground: Bool = true) {
        
        accumulatedView.prepareForReuse()
        accumulatedView.set(titleText: "", captionText: "", color: color, titleFont: titleFont, captionFont: captionFont, clearBackground: clearBackground)
        
        if let defaultValue = defaultValue {
            self.defaultValue = defaultValue
        }
        
        if let index = list.firstIndex(where: {$0 == selected}) {
            self.selected = selected
            scrollPicker.set(index, list: entryList, isEnabled: isEnabled, color: color, titleFont: titleFont, captionFont: captionFont, clearBackground: clearBackground)
        }
        self.selectedOnEntry = selected
        accumulatedCharacters = ""
        updateAccumulatedView()
    }
    
    public func setValue(_ selected: EnumType, force: Bool = false) {
        accumulatedCharacters = ""
        updateAccumulatedView()
        if self.selected != selected || force {
            self.selected = selected
            if let index = list.firstIndex(where: {$0 == selected}) {
                scrollPicker.setValue(index)
            }
        }
    }
    
    private func updateAccumulatedView() {
        let show = accumulatedCharacters != ""
        accumulatedView.isHidden = !show
        scrollPicker.isHidden = show
        accumulatedView.set(titleText: accumulatedCharacters.capitalized)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollPickerDidChange(_ :ScrollPicker?, to value: Int?, allowPopup: Bool) {
        delegate?.enumPickerDidChange(to: list[value!], allowPopup: allowPopup)
    }
    
    public func loseFocus() {
        delegate?.enumPickerDidChange(to: selected!)
        set(selected)
    }
    
    public func processKeys(keyAction: KeyAction, characters: String) -> Bool {
        if keyAction == .characters && characters.trim() == "" {
            // Blank pressed - just popup window rather than blanking picker
            false
        } else {
            if let index = list.firstIndex(where: {$0 == selected}) {
                ScrollPicker.processKeys(keyAction: keyAction, characters: characters, accumulatedCharacters: accumulatedCharacters, selected: index, values: list.map({ $0.short}), completion: { [self] (characters, newIndex, keyAction) in
                    
                    accumulatedCharacters = characters
                    if accumulatedCharacters != "" && keyAction == .characters && newIndex == nil {
                        updateAccumulatedView()
                    } else {
                        accumulatedCharacters = ""
                        updateAccumulatedView()
                        
                        if newIndex != index {
                            if let newIndex = newIndex {
                                setValue(list[newIndex])
                            }
                        }
                        
                        switch keyAction {
                        case .previous, .next, .up, .down, .enter:
                            delegate?.enumPickerDidChange(to: selected!, allowPopup: keyAction == .enter)
                            set(selected)
                        case .escape:
                            if let selectedOnEntry = selectedOnEntry {
                                setValue(selectedOnEntry)
                            }
                        case .delete, .backspace:
                            if let defaultValue = defaultValue {
                                delegate?.enumPickerDidChange(to: defaultValue)
                                set(defaultValue)
                            }
                        default:
                            break
                        }
                    }
                })
            } else {
                false
            }
        }
    }
}
