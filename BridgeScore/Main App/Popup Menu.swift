//
//  Popup Menu.swift
//  BridgeScore
//
//  Created by Marc Shearer on 01/03/2022.
//

import SwiftUI

struct PopupMenu<Label>: View where Label : View {
    @Binding var field: Int
    let label: Label
    let values: [String]
    var top: CGFloat?
    var title: String?
    let onChange: ((Int)->())?
    @State private var showPopup = false
    
    init(field: Binding<Int>, values: [String], title: String? = nil, top: CGFloat? = nil, onChange: ((Int)->())? = nil, @ViewBuilder label: ()->Label) {
        self._field = field
        self.values = values
        self.title = title
        self.top = top
        self.onChange = onChange
        self.label = label()
    }
    
    public var body: some View {
        label
            .onTapGesture {
                SlideInMenu.shared.show(title: title, options: values, top: top, width: 400, completion: { (selected) in
                    if let index = values.firstIndex(where: {$0 == selected}) {
                        field = index
                        onChange?(field)
                    }
                })
            }
    }
    
}
