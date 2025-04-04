//
//  Stepper Input.swift
//
//  Bridge Score
//
//  Created by Marc Shearer on 10/02/2021.
//

import SwiftUI
import Combine

struct StepperInput: View {
    var title: String?
    var field: Binding<Int>
    var label: ((Int)->String)?
    var isEnabled: Bool = true
    var minValue: (()->Int)? = nil
    var maxValue: (()->Int)? = nil
    var increment: (()->Int)? = nil
    var message: Binding<String>?
    var topSpace: CGFloat = 5
    var leadingSpace: CGFloat = 0
    var height: CGFloat = 45
    var width: CGFloat?
    var labelWidth: CGFloat?
    var buttonWidth: ()->(CGFloat) = {MyApp.format == .phone && !isLandscape ? 25 : 35}
    var buttonHeight: ()->(CGFloat) = {25}
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 180
    var onChange: ((Int)->())? = nil
    
    var body: some View {
            StepperInputAdditional<Int>(title: title, field: field, label: label, isEnabled: isEnabled, minValue: minValue, maxValue: maxValue, increment: increment, message: message, topSpace: topSpace, leadingSpace: leadingSpace, height: height, width: width, labelWidth: labelWidth, buttonWidth: buttonWidth, buttonHeight: buttonHeight, inlineTitle: inlineTitle, inlineTitleWidth: inlineTitleWidth, setAdditional: { (_, _) in}, onChange: onChange)
    }
}

struct StepperInputAdditional<Additional>: View where Additional: Equatable {
    @Environment(\.verticalSizeClass) var sizeClass
    
    var title: String?
    var field: Binding<Int>
    var label: ((Int)->String)?
    var isEnabled: Bool = true
    var minValue: (()->Int)? = nil
    var maxValue: (()->Int)? = nil
    var increment: (()->Int)? = nil
    var message: Binding<String>?
    var topSpace: CGFloat = 5
    var leadingSpace: CGFloat = 0
    var height: CGFloat = 40
    var width: CGFloat?
    var labelWidth: CGFloat?
    var buttonWidth: ()->(CGFloat) = {MyApp.format == .phone && !isLandscape ? 25 : 35}
    var buttonHeight: ()->(CGFloat) = {25}
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 180
    var additionalBinding: Binding<Additional>? = nil
    var setAdditional: ((Binding<Additional>?, Additional)->())? = nil
    var onChange: ((Int)->())? = nil

    @State private var refresh = false
    
    var body: some View {

        VStack(spacing: 0) {
            
            // Just to refresh view
            if refresh { EmptyView() }
            
            if title != nil && !inlineTitle {
                InputTitle(title: title, message: message, topSpace: topSpace, width: (width == nil ? nil : width! + leadingSpace + 16))
                Spacer().frame(height: 8)
            } else {
                Spacer().frame(height: topSpace)
            }
            HStack {
                HStack {
                    Spacer().frame(width: leadingSpace)
                    if inlineTitle {
                        HStack {
                            Spacer().frame(width: 8)
                            Text(title ?? "")
                            Spacer()
                        }
                        .frame(width: inlineTitleWidth)
                        Spacer().frame(width: 12)
                    }
                    Spacer().frame(width: 8)
                    UndoWrapperAdditional(field, additionalBinding: additionalBinding, setAdditional: setAdditional) { (field) in
                        HStack(spacing: 2) {
                            if let label = label {
                                Text(label(field.wrappedValue))
                            } else {
                                Text(String(field.wrappedValue))
                            }
                            Spacer()
                            if isEnabled {
                                let plusDisabled = field.wrappedValue + (increment?() ?? 1) > (maxValue?() ?? Int.max)
                                let minusDisabled = field.wrappedValue - (increment?() ?? 1) < (minValue?() ?? -Int.max)
                                Button {
                                    change(field, direction: +1)
                                } label: {
                                    let palette = (plusDisabled ? Palette.disabledButton : Palette.enabledButton)
                                    Image(systemName: "plus")
                                        .frame(width: buttonWidth(), height: buttonHeight())
                                        .background(palette.background)
                                        .foregroundColor(palette.text)
                                        .cornerRadius(4)
                                }
                                .disabled(plusDisabled)
                                Button {
                                    change(field, direction: -1)
                                } label: {
                                    let palette = (minusDisabled ? Palette.disabledButton : Palette.enabledButton)
                                    Image(systemName: "minus")
                                        .frame(width: buttonWidth(), height: buttonHeight())
                                        .background(palette.background)
                                        .foregroundColor(palette.text)
                                        .cornerRadius(4)
                                }
                                .disabled(minusDisabled)
                            }
                        }
                        .if(labelWidth != nil) { (view) in
                            view.frame(width: labelWidth! + 100)
                        }
                    }
                    Spacer().frame(width: 8)
                }
                .font(inputFont)
                if width == nil {
                    Spacer()
                }
            }
        }
        .frame(height: self.height + self.topSpace + (title == nil || inlineTitle ? 0 : 30))
        .onAppear {
            self.change(field)
        }
    }
    
    func change(_ field: Binding<Int>, direction: Int = 0) {
        let increment = (self.increment?() ?? 1) * direction
        let minValue = self.minValue?() ?? 0
        let maxValue = self.maxValue?() ?? Int.max
        
        let newValue = max(min(field.wrappedValue + increment, maxValue), minValue)
        Utility.mainThread {
            // Need to do this on main thread to avoid multiple updates in parallel
            onChange?(newValue)
            field.wrappedValue = newValue
            refresh.toggle()
        }
    }
}
