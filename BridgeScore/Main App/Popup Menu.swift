//
//  Popup Menu.swift
//  BridgeScore
//
//  Created by Marc Shearer on 01/03/2022.
//

import SwiftUI

struct PopupMenu<Label>: View where Label : View {
    var field: Binding<Int>
    let label: Label
    let values: [String]
    var top: CGFloat?
    var left: CGFloat?
    var width: CGFloat?
    var animation: ViewAnimation
    var title: String?
    let onChange: ((Int)->())?
    @State private var showPopup = false
    
    init(field: Binding<Int>, values: [String], title: String? = nil, animation: ViewAnimation = .slideLeft, top: CGFloat? = nil, left: CGFloat? = nil, width: CGFloat, onChange: ((Int)->())? = nil, @ViewBuilder label: ()->Label) {
        self.field = field
        self.values = values
        self.title = title
        self.top = top
        self.left = left
        self.animation = animation
        self.width = width
        self.onChange = onChange
        self.label = label()
    }
    
    public var body: some View {
        label
            .onTapGesture {
                SlideInMenu.shared.show(title: title, options: values, animation: animation, top: top, left: left, width: width, completion: { (selected) in
                    if let index = values.firstIndex(where: {$0 == selected}) {
                        field.wrappedValue = index
                        onChange?(field.wrappedValue)
                    }
                })
            }
    }
    
}
