//
//  Enum Picker.swift
//  BridgeScore
//
//  Created by Marc Shearer on 17/02/2022.
//

import UIKit

protocol EnumPickerDelegate {
    func enumPickerDidChange(to: Any)
}

protocol EnumPickerType : CaseIterable, Equatable {
    var string: String {get}
    var short: String {get}
}

class EnumPicker<EnumType> : UIView, ScrollPickerDelegate where EnumType : EnumPickerType {
     
    private var scrollPicker: ScrollPicker
    private var list: [EnumType]
    private var entryList: [ScrollPickerEntry]
    private(set) var selected: EnumType!
    public var delegate: EnumPickerDelegate?
    
    init(frame: CGRect, color: PaletteColor? = nil) {
        list = EnumType.allCases.map{$0}
        entryList = list.map{ScrollPickerEntry(title: $0.short, caption: $0.string)}
        scrollPicker = ScrollPicker(frame: frame, list: entryList, color: color)
        super.init(frame: frame)
        scrollPicker.delegate = self
        addSubview(scrollPicker, anchored: .all)
    }
    
    public func set(_ selected: EnumType, color: PaletteColor? = nil, titleFont: UIFont? = nil, captionFont: UIFont? = nil) {
        if let index = list.firstIndex(where: {$0 == selected}) {
            scrollPicker.set(index, list: entryList, color: color, titleFont: titleFont, captionFont: captionFont)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollPickerDidChange(to value: Int) {
        delegate?.enumPickerDidChange(to: list[value])
    }
}
