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
    let onChange: ((Int)->())?
    @State private var showPopup = false
    
    init(field: Binding<Int>, values: [String], onChange: ((Int)->())? = nil, @ViewBuilder label: ()->Label) {
        self._field = field
        self.values = values
        self.onChange = onChange
        self.label = label()
    }
    
    public var body: some View {
        label
            .onTapGesture {
                showPopup = true
            }
            .popover(isPresented: $showPopup, attachmentAnchor: .point(.trailing), arrowEdge: .trailing) {
                VStack {
                    ForEach(values, id: \.self) { (value) in
                        if let index = values.firstIndex(where: {$0 == value}) {
                            Button {
                                field = index
                                onChange?(field)
                                showPopup = false
                            } label: {
                                VStack {
                                    Spacer().frame(height: 10)
                                    HStack {
                                        Spacer().frame(width: 20)
                                        Text(value)
                                        Spacer().frame(width: 20)
                                        Spacer()
                                    }
                                    Spacer().frame(height: 10)
                                    if value != values.last! {
                                        Separator(padding: true)
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
    }
    
}
