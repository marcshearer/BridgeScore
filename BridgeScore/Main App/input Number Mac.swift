    //
    //  Input Number Mac.swift
    //  BridgeScore
    //
    //  Created by Marc Shearer on 07/02/2022.
    //

import SwiftUI

struct InputNumberMac : View {
    
    var title: String?
    @Binding var field: Float?
    var message: Binding<String>?
    var topSpace: CGFloat = 0
    var leadingSpace: CGFloat = 0
    var height: CGFloat = 45
    var width: CGFloat?
    var places: Int = 2
    var negative: Bool
    var maxCharacters: Int
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 180
    var onChange: ((Float?)->())?
    
    @State private var keyboardType: UIKeyboardType = .numbersAndPunctuation
    @State private var refresh = false
    @State private var wrappedText = ""
    var text: Binding<String> {
        Binding {
            wrappedText
        } set: { (newValue) in
            wrappedText = newValue
        }
    }
    @FocusState var focused: Bool
    
    
    var body: some View {
        let characters = "0123456789" + (places > 0 ? "." : "") + (negative ? "-" : "")
        
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
                if inlineTitle {
                    VStack(spacing: 0) {
                        Spacer()
                        HStack {
                            if let title = title {
                                Spacer().frame(width: 6)
                                Text(title)
                                Spacer()
                            }
                        }
                        Spacer().frame(height: 13)
                    }
                    .frame(width: inlineTitleWidth, height: height)
                }

                HStack {
                    Spacer().frame(width: 4)
                    
                    UndoWrapper(text) { text in
                        Spacer()
                        TextEditor(text: text)
                        .onChange(of: text.wrappedValue, initial: false) { (_, newValue) in
                            if text.wrappedValue.contains("\n") {
                                text.wrappedValue = Float(text.wrappedValue)?.toString(places: places) ?? ""
                                focused = false
                            } else {
                                let filtered = newValue.filter { characters.contains($0) }
                                let oldField = field
                                if filtered != newValue {
                                    text.wrappedValue = filtered
                                }
                                let trailingDecimal = (places > 0 && text.wrappedValue.rtrim().right(1) == "." ? ("." + text.wrappedValue.components(separatedBy: ".").last!) : "")
                                if text.wrappedValue != "" && text.wrappedValue != "-" {
                                    if let float = Float(text.wrappedValue) {
                                        text.wrappedValue = float.toString(places: places) + trailingDecimal
                                    } else {
                                        text.wrappedValue = field?.toString(places: places) ?? ""
                                    }
                                }
                                if text.wrappedValue.length > min(maxCharacters, 7 + places + (negative ? 1 : 0)) {
                                    text.wrappedValue = (field?.toString(places: places) ?? "")
                                } else {
                                    field = Float(text.wrappedValue)
                                    if oldField != field {
                                        onChange?(field)
                                    }
                                }
                            }
                        }
                        .focused($focused)
                        .lineLimit(1)
                        .padding(.all, 1)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .disableAutocorrection(false)
                    }
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
                text.wrappedValue = (field == nil ? "" : field!.toString(places: places))
            }
        }
        .frame(height: self.height + ((self.inlineTitle ? 0 : self.topSpace) + (title == nil || inlineTitle ? 0 : 30)))
        .if(width != nil) { (view) in
            view.frame(width: width! + leadingSpace + (inlineTitle && title != nil ? inlineTitleWidth : 0) + 16)
        }
    }
}
