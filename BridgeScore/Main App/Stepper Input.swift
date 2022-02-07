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
    @Binding var field: Int
    var label: ((Int)->String)?
    var minValue: Binding<Int>? = nil
    var maxValue: Binding<Int>? = nil
    var increment: Binding<Int>? = nil
    var message: Binding<String>?
    var topSpace: CGFloat = 16
    var leadingSpace: CGFloat = 32
    var height: CGFloat = 40
    var width: CGFloat?
    var labelWidth: CGFloat = 300
    var onChange: ((Int)->())? = nil

    @State private var refresh = false
    
    var body: some View {

        VStack(spacing: 0) {
            
            // Just to refresh view
            if refresh { EmptyView() }
            
            if title != nil {
                InputTitle(title: title, message: message, topSpace: topSpace, width: (width == nil ? nil : width! + leadingSpace + 16))
                Spacer().frame(height: 8)
            } else {
                Spacer().frame(height: topSpace)
            }
            HStack {
                HStack {
                    Spacer().frame(width: leadingSpace)
                    Stepper {
                        if let label = label {
                            Text(label(field))
                        } else {
                            Text(String(field))
                        }
                    } onIncrement: {
                        change(direction: 1)
                    } onDecrement: {
                        change(direction: -1)
                    }
                    .frame(width: labelWidth + 100)
                }
                .font(inputFont)
                if width == nil {
                    Spacer()
                }
            }
        }
        .frame(height: self.height + self.topSpace + (title == nil ? 0 : 30))
        .onAppear {
            self.change()
        }
    }
    
    func change(direction: Int = 0) {
        let increment = (self.increment?.wrappedValue ?? 1) * direction
        let minValue = self.minValue?.wrappedValue ?? 0
        let maxValue = self.maxValue?.wrappedValue ?? Int.max
        
        field = max(min(field + increment, maxValue), minValue)
        onChange?(field)
        refresh.toggle()
    }
}
