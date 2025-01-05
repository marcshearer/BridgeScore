//
//  Input Toggle.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 15/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

struct InputToggle : View {
    
    var title: String?
    var text: String?
    var field: Binding<Bool>
    @Binding var disabled: Bool
    var message: Binding<String>?
    var messageOffset: CGFloat = 0.0
    var topSpace: CGFloat = 10
    var leadingSpace: CGFloat = 0
    var height: CGFloat = 30
    var width: CGFloat?
    var labelWidth: CGFloat?
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 180
    var onChange: ((Bool)->())?
    
    var body: some View {
        VStack(spacing: 0) {
            if title != nil && !inlineTitle {
                InputTitle(title: title, message: message, topSpace: topSpace, width: (width == nil ? nil : width! + leadingSpace + 16))
                Spacer().frame(height: 8)
            } else {
                Spacer().frame(height: topSpace)
            }
            
            HStack {
                Spacer().frame(width: leadingSpace)
                if inlineTitle {
                    HStack {
                        Spacer().frame(width: 8)
                        Text(title ?? "")
                            .foregroundColor(disabled ? Palette.background.faintText : Palette.background.text)
                        Spacer()
                    }
                    .frame(width: inlineTitleWidth)
                    Spacer().frame(width: 12)
                }
                Spacer()
                UndoWrapper(field) { field in
                    Toggle(isOn: field) {
                        Text(text ?? "")
                            .font(inputFont)
                    }
                    .fixedSize()
                    .scaleEffect(0.8)
                    .offset(x: 5)
                }
                .if(labelWidth != nil) { (view) in
                    view.frame(width: labelWidth! + 55)
                }
                .onChange(of: field.wrappedValue, initial: false) {
                    onChange?(field.wrappedValue)
                }
                Spacer().frame(width: 16)
            }
            .if(width != nil) { view in
                view.frame(width: width! + (inlineTitle ? inlineTitleWidth + 12 : 0) + (labelWidth != nil ? labelWidth! + 55 : 0) + leadingSpace)
            }
            Spacer()
        }
        .frame(height: self.height + self.topSpace + (title == nil || inlineTitle ? 0 : 30) + 16)
        .disabled(disabled)
    }
}
