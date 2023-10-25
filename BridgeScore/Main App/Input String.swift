    //
    // Input String.swift
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
    var field: Binding<String>
    var message: Binding<String>?
    var topSpace: CGFloat = 0
    var leadingSpace: CGFloat = 0
    var height: CGFloat = 50
    var width: CGFloat?
    var color: PaletteColor = Palette.input
    var keyboardType: KeyboardType = .default
    var autoCapitalize: CapitalizationType = .sentences
    var autoCorrect: Bool = true
    var multiLine: Bool = false
    var clearText: Bool = true
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 150
    var onChange: ((String)->())?
    @FocusState var focused: Bool
    @State private var refresh = false
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            // Just to trigger view refresh
            if refresh { EmptyView() }
            
            if title != nil && !inlineTitle {
                HStack {
                    InputTitle(title: title, message: message, topSpace: topSpace, width: (width == nil ? nil : width! + leadingSpace + 16 + (clearText ? 20 : 0)))
                    Spacer().frame(width: clearText ? 20 : 0)
                }
                .frame(height: 22)
                Spacer().frame(height: 8)
            } else if let message = message?.wrappedValue {
                HStack {
                    Spacer()
                    Text(message)
                        .foregroundColor(Palette.background.strongText)
                        .font(messageFont)
                    Spacer().frame(width: 16)
                }
                .frame(height: 16)
            } else {
                Spacer().frame(height: topSpace)
            }
            HStack {
                Spacer().frame(width: leadingSpace)
                if title != nil && inlineTitle {
                    HStack {
                        Spacer().frame(width: 8)
                        VStack(spacing: 0) {
                            Spacer()
                            Text(title!)
                            Spacer().frame(height: 14)
                        }
                        Spacer()
                    }
                    .frame(width: inlineTitleWidth)
                }
                Spacer().frame(width: 10)
                HStack {
                    Spacer().frame(width: 4)
                    VStack(spacing: 0) {
                        Spacer()
                        UndoWrapper(field) { field in
                            if multiLine {
                                TextEditor(text: field)
                                    .lineLimit(1)
                                    .padding(.all, 1)
                                    .keyboardType(self.keyboardType)
                                    .autocapitalization(autoCapitalize)
                                    .disableAutocorrection(!autoCorrect)
                                    .foregroundColor(color.text)
                                    .onChange(of: field.wrappedValue, initial: false) { (_, field) in
                                        onChange?(field)
                                    }
                            } else {
                                TextEditor(text: field)
                                    .onChange(of: field.wrappedValue, initial: false) {
                                        if field.wrappedValue.contains("\n") {
                                            field.wrappedValue = field.wrappedValue.replacingOccurrences(of: "\n", with: "")
                                            focused = false
                                        }
                                    }
                                    .focused($focused)
                                    .padding(.all, 1)
                                    .keyboardType(self.keyboardType)
                                    .autocapitalization(autoCapitalize)
                                    .disableAutocorrection(!autoCorrect)
                                    .foregroundColor(color.text)
                                    .onChange(of: field.wrappedValue, initial: false) { (_, field) in
                                        onChange?(field)
                                    }
                            }
                        }
                        Spacer().frame(height: 0)
                    }
                }
                .background(color.background)
                .if(width != nil) { (view) in
                    view.frame(width: width)
                }

                if width == nil {
                    Spacer()
                }
                
                if clearText {
                    VStack {
                        Spacer()
                        Button {
                            field.wrappedValue = ""
                        } label: {
                            Image(systemName: "x.circle.fill").font(inputTitleFont).foregroundColor(Palette.clearText)
                        }
                        Spacer()
                    }.frame(width: 20)
                }
                
                Spacer().frame(width: 16)
            }
            
            .font(inputFont)
        }
        .frame(height: self.height + self.topSpace + (title != nil && !inlineTitle ? 30 : (message != nil ? 16 : 0)))
        .if(width != nil) { (view) in
            view.frame(width: width! + leadingSpace + 16 + (clearText ? 20 : 0))
        }
    }
}
