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
    var minValue: Binding<Int>? = nil
    var maxValue: Binding<Int>? = nil
    var increment: Binding<Int>? = nil
    var message: Binding<String>?
    var topSpace: CGFloat = 5
    var leadingSpace: CGFloat = 0
    var height: CGFloat = 45
    var width: CGFloat?
    var labelWidth: CGFloat?
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 150
    var onChange: ((Int)->())? = nil
    
    var body: some View {
            StepperInputAdditional<Int>(title: title, field: field, label: label, minValue: minValue, maxValue: maxValue, increment: increment, message: message, topSpace: topSpace, leadingSpace: leadingSpace, height: height, width: width, labelWidth: labelWidth, inlineTitle: inlineTitle, inlineTitleWidth: inlineTitleWidth, setAdditional: { (_, _) in}, onChange: onChange)
    }
}

struct StepperInputAdditional<Additional>: View where Additional: Equatable {
    
    var title: String?
    var field: Binding<Int>
    var label: ((Int)->String)?
    var minValue: Binding<Int>? = nil
    var maxValue: Binding<Int>? = nil
    var increment: Binding<Int>? = nil
    var message: Binding<String>?
    var topSpace: CGFloat = 5
    var leadingSpace: CGFloat = 0
    var height: CGFloat = 45
    var width: CGFloat?
    var labelWidth: CGFloat?
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 150
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
                        Stepper {
                            if let label = label {
                                Text(label(field.wrappedValue))
                            } else {
                                Text(String(field.wrappedValue))
                            }
                        } onIncrement: {
                            change(field, direction: +1)
                        } onDecrement: {
                            change(field, direction: -1)
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
        let increment = (self.increment?.wrappedValue ?? 1) * direction
        let minValue = self.minValue?.wrappedValue ?? 0
        let maxValue = self.maxValue?.wrappedValue ?? Int.max
        
        field.wrappedValue = max(min(field.wrappedValue + increment, maxValue), minValue)
        onChange?(field.wrappedValue)
        refresh.toggle()
    }
}
