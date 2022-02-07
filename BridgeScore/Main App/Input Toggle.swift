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
    @Binding var field: Bool
    var message: Binding<String>?
    var messageOffset: CGFloat = 0.0
    var topSpace: CGFloat = 16
    var leadingSpace: CGFloat = 32
    var height: CGFloat = 30
    var width: CGFloat?
    var labelWidth: CGFloat = 300
    var onChange: ((Bool)->())?
    
    var body: some View {
        VStack(spacing: 0) {
            if title != nil {
                InputTitle(title: title, message: message, topSpace: topSpace, width: (width == nil ? nil : width! + leadingSpace + 16))
                Spacer().frame(height: 8)
            }
            
            HStack {
                Spacer().frame(width: leadingSpace)
                Toggle(isOn: $field) {
                    Text(text ?? "")
                        .font(inputFont)
                }
                .frame(width: labelWidth + 55)
                .onChange(of: field) { (value) in
                    onChange?(value)
                }
                Spacer()
            }
            .if(width != nil) { view in
                view.frame(width: width! + leadingSpace + 16)
            }
        }
        .frame(height: self.height + self.topSpace + (title == nil ? 0 : 30))
    }
}
