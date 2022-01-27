    //
    // Date Picker Input.swift
    // Bridge Score
    //
    //  Created by Marc Shearer on 10/02/2021.
    //

    import SwiftUI

    struct DatePickerInput : View {
        
        var title: String?
        @Binding var field: Date
        var message: Binding<String>?
        var from: Date?
        var to: Date?
        var topSpace: CGFloat = 16
        var height: CGFloat = 40
        var onChange: ((String)->())?

        var body: some View {
            
            VStack(spacing: 0) {
                if title != nil {
                    InputTitle(title: title, message: message, topSpace: topSpace)
                    Spacer().frame(height: 8)
                }
                HStack {
                    Spacer().frame(width: 32)
                    if from == nil && to == nil {
                        DatePicker("", selection: $field, displayedComponents: .date)
                    } else if from == nil {
                        DatePicker("", selection: $field, in: ...to!, displayedComponents: .date)
                    } else if to == nil {
                        DatePicker("", selection: $field, in: from!..., displayedComponents: .date)
                    } else {
                        DatePicker("", selection: $field, in: from!...to!, displayedComponents: .date)
                    }
                    
                    Spacer()
                }
                .font(inputFont)
                .labelsHidden()
            }
            .frame(height: self.height + self.topSpace + (title == nil ? 0 : 30))
        }
    }
