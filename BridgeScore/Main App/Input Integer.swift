//
//  Input Number.swift
//  BridgeScore
//
//  Created by Marc Shearer on 07/02/2022.
//

import SwiftUI

struct InputInt : View {
    
    var title: String?
    @Binding var field: Int
    var message: Binding<String>?
    var topSpace: CGFloat = 16
    var leadingSpace: CGFloat = 32
    var height: CGFloat = 40
    var width: CGFloat?
    var onChange: ((Int)->())?
    
    @State private var keyboardType: UIKeyboardType = .numberPad
    @State private var refresh = false
    @State private var text: String = "0"
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            // Just to trigger view refresh
            if refresh { EmptyView() }
            
            if title != nil {
                HStack {
                    InputTitle(title: title, message: message, topSpace: topSpace, width: (width == nil ? nil : width! + leadingSpace + 16))
                }
                Spacer().frame(height: 8)
            }
            HStack {
                Spacer().frame(width: leadingSpace)
                HStack {
                    Spacer().frame(width: 8)
                    TextField("", value: $field, format: .number)
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
        }
        .onAppear {
            text = "\(field)"
        }
        .onChange(of: field) { (field) in
            text = "\(field)"
        }
        .frame(height: self.height + self.topSpace + (title == nil ? 0 : 30))
        .if(width != nil) { (view) in
            view.frame(width: width! + leadingSpace + 16)
        }
    }
}
