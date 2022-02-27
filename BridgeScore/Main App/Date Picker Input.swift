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
    var topSpace: CGFloat = 5
    var height: CGFloat = 45
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 150
    var onChange: ((String)->())?

    var body: some View {
        
        VStack(spacing: 0) {
            if title != nil && !inlineTitle {
                InputTitle(title: title, message: message, topSpace: topSpace)
                Spacer().frame(height: 8)
            } else {
                Spacer().frame(height: topSpace)
            }
            HStack {
                if inlineTitle && title != nil {
                    HStack {
                        Spacer().frame(width: 8)
                        Text(title!)
                        Spacer()
                    }
                    .frame(width: inlineTitleWidth)
                } else {
                    Spacer().frame(width: 32)
                }
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
        .frame(height: self.height + self.topSpace + (title == nil || inlineTitle ? 0 : 30))
    }
}
