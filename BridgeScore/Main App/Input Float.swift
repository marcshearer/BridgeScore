//  Input Float.swift
//  BridgeScore
//
//  Created by Marc Shearer on 07/02/2022.
//

import SwiftUI

struct InputFloat : View {
    
    var title: String?
    @Binding var field: Float?
    var message: Binding<String>?
    var topSpace: CGFloat = 5
    var leadingSpace: CGFloat = 0
    var height: CGFloat = 45
    var width: CGFloat?
    var places: Int = 2
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 150
    var onChange: ((Float?)->())?
    
    @State private var keyboardType: UIKeyboardType = .numberPad
    @State private var refresh = false
    @State private var text: String = ""
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            // Just to trigger view refresh
            if refresh { EmptyView() }
            
            if title != nil && !inlineTitle {
                HStack {
                    InputTitle(title: title, message: message, topSpace: topSpace, width: (width == nil ? nil : width! + leadingSpace + 16))
                }
                Spacer().frame(height: 8)
            } else {
                Spacer().frame(height: topSpace)
            }
            HStack {
                Spacer().frame(width: leadingSpace)
                if title != nil && inlineTitle {
                    HStack {
                        Spacer().frame(width: 6)
                        Text(title!)
                        Spacer()
                    }
                    .frame(width: inlineTitleWidth)
                }

                HStack {
                    Spacer().frame(width: 8)
                    
                    TextField("", text: $text, onEditingChanged: {(editing) in
                        text = Float(text)?.toString(places: places) ?? ""
                        field = Float(text)
                    })
                    .onSubmit {
                        text = Float(text)?.toString(places: places) ?? ""
                        field = Float(text)
                    }
                    .onChange(of: text) { newValue in
                        let filtered = newValue.filter { "0123456789-.".contains($0) }
                        let oldField = field
                        if filtered != newValue {
                            text = filtered
                            field = Float(text)
                        } else {
                            field = Float(text)
                        }
                        if oldField != field {
                            onChange?(field)
                        }
                    }
                    .lineLimit(1)
                    .padding(.all, 1)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(false)
                }
                .if(width != nil) { (view) in
                    view.frame(width: width)
                }
                .frame(height: height)
                .background(Palette.input.background)
                .cornerRadius(12)
    
                if width == nil {
                    Spacer()
                }
            }
            .font(inputFont)
            .onAppear {
                text = (field == nil ? "" : field!.toString(places: places))
            }
        }
        .frame(height: self.height + ((self.inlineTitle ? 0 : self.topSpace) + (title == nil || inlineTitle ? 0 : 30)))
        .if(width != nil) { (view) in
            view.frame(width: width! + leadingSpace + (inlineTitle ? inlineTitleWidth : 0) + 16)
        }
    }
}
