//
// Input.swift
// Bridge Score
//
//  Created by Marc Shearer on 10/02/2021.
//

import SwiftUI

struct Input : View {
    
    #if canImport(UIKit)
    typealias KeyboardType = UIKeyboardType
    #else
    enum KeyboardType {
        case `default`
        case URL
    }
    #endif
    
    #if canImport(UIKit)
    typealias CapitalizationType = UITextAutocapitalizationType
    #else
    enum CapitalizationType {
        case sentences
        case none
    }
    #endif
    
    var title: String?
    @Binding var field: String
    var message: Binding<String>?
    var topSpace: CGFloat = 16
    var height: CGFloat = 40
    var keyboardType: KeyboardType = .default
    var autoCapitalize: CapitalizationType = .sentences
    var autoCorrect: Bool = true
    var clearText: Bool = true
    @State private var refresh = false

    var body: some View {
        
        VStack(spacing: 0) {
            
            // Just to trigger view refresh
            if refresh { EmptyView() }
            
            if title != nil {
                InputTitle(title: title, message: message, topSpace: topSpace)
                Spacer().frame(height: 8)
            }
            HStack {
                Spacer().frame(width: 32)
                TextEditor(text: $field)
                    .background(Palette.input.background)
                    .lineLimit(1)
                    .padding(.all, 1)
                    .keyboardType(self.keyboardType)
                    .autocapitalization(autoCapitalize)
                    .disableAutocorrection(!autoCorrect)
                    .cornerRadius(12)
                
                Spacer().frame(width: 8)
                
                if clearText {
                    VStack {
                        Spacer().frame(height: 8)
                        Button {
                            field = ""
                        } label: {
                            Image(systemName: "xmark.circle").font(inputTitleFont).foregroundColor(Palette.input.strongText)
                        }
                        Spacer()
                    }
                }
                
                Spacer().frame(width: 8)
            }
            .font(inputFont)
        }
        .frame(height: self.height + self.topSpace + (title == nil ? 0 : 30))
    }
}
