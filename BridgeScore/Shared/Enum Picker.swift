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
    var rawValue: Int {get}
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
    
    public func set(_ selected: EnumType, isEnabled: Bool = true, color: PaletteColor? = nil, titleFont: UIFont? = nil, captionFont: UIFont? = nil, clearBackground: Bool = true) {
        if let index = list.firstIndex(where: {$0 == selected}) {
            scrollPicker.set(index, list: entryList, isEnabled: isEnabled, color: color, titleFont: titleFont, captionFont: captionFont, clearBackground: clearBackground)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollPickerDidChange(_ :ScrollPicker?,to value: Int?) {
        delegate?.enumPickerDidChange(to: list[value!])
    }
}
