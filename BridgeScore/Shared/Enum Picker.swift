//
//  Enum Picker.swift
//  BridgeScore
//
//  Created by Marc Shearer on 17/02/2022.
//

import UIKit
import SwiftUI

protocol EnumPickerDelegate {
    func enumPickerDidChange(to: Any)
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
    private var list: [EnumType]
    private var entryList: [ScrollPickerEntry]
    private(set) var selected: EnumType!
    private var selectedOnEntry: EnumType!
    public var delegate: EnumPickerDelegate?
    private var accumulatedCharacters: String = ""
    
    init(frame: CGRect, color: PaletteColor? = nil, allCases: Bool = false) {
        list = (allCases ? EnumType.allCases : EnumType.validCases).map{$0}
        entryList = list.map{ScrollPickerEntry(title: $0.short, caption: $0.string)}
        scrollPicker = ScrollPicker(frame: frame, list: entryList, color: color)
        super.init(frame: frame)
        scrollPicker.delegate = self
        addSubview(scrollPicker, anchored: .all)
    }
    
    public func set(_ selected: EnumType, isEnabled: Bool = true, color: PaletteColor? = nil, titleFont: UIFont? = nil, captionFont: UIFont? = nil, clearBackground: Bool = true) {
        if let index = list.firstIndex(where: {$0 == selected}) {
            self.selected = selected
            self.selectedOnEntry = selected
            scrollPicker.set(index, list: entryList, isEnabled: isEnabled, color: color, titleFont: titleFont, captionFont: captionFont, clearBackground: clearBackground)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollPickerDidChange(_ :ScrollPicker?,to value: Int?) {
        delegate?.enumPickerDidChange(to: list[value!])
    }
    
    public func processKeys(keyAction: KeyAction, characters: String) -> Bool {
        if keyAction == .characters && characters.trim() == "" {
            // Blank pressed - just popup window rather than blanking picker
            false
        } else {
            if let selected = list.firstIndex(where: {$0 == selected}) {
                ScrollPicker.processKeys(keyAction: keyAction, characters: characters, accumulatedCharacters: accumulatedCharacters, selected: selected, values: list.map({ $0.short}), completion: { [self] (characters, newSelected, keyAction) in
                    
                    accumulatedCharacters = characters
                    
                    if let newSelected = newSelected {
                        if newSelected != selected {
                            set(list[newSelected])
                            scrollPickerDidChange(self.scrollPicker, to: newSelected)
                        }
                    } else if let selectedOnEntry = selectedOnEntry {
                        if keyAction == .escape {
                            set(selectedOnEntry)
                        }
                    }
                })
            } else {
                false
            }
        }
    }
}
