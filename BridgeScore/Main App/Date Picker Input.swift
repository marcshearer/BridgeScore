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
    var color: PaletteColor = Palette.datePicker
    var topSpace: CGFloat = 5
    var height: CGFloat = 45
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 150
    var onChange: ((String)->())?
    @State private var datePicker = false

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
                
                Spacer().frame(width: 16)
                Button(action: {
                    datePicker = true
                }) {
                    Text(Utility.dateString(field, format: "EEEE dd MMMM yyyy"))
                }.id(1)
                
                Spacer()
            }
            .popover(isPresented: $datePicker, attachmentAnchor: .rect(.bounds)) {
                ZStack {
                    Rectangle()
                        .frame(width: 280)
                        .background(.clear)
                    datePickerRange
                }
            }
            .font(inputFont)
            .labelsHidden()
        }
        .frame(height: self.height + self.topSpace + (title == nil || inlineTitle ? 0 : 30))
    }
    
    private var datePickerRange: some View {
        var picker: AnyView
            if from == nil && to == nil {
                picker = AnyView(DatePicker("",  selection: $field, displayedComponents: .date))
            } else if from == nil {
                picker = AnyView(DatePicker("", selection: $field, in: ...to!, displayedComponents: .date))
            } else if to == nil {
                picker = AnyView(DatePicker("", selection: $field, in: from!..., displayedComponents: .date))
            } else {
                picker = AnyView(DatePicker("", selection: $field, in: from!...to!, displayedComponents: .date))
            }
        return picker.datePickerStyle(GraphicalDatePickerStyle())
            .background(color.background)
            .foregroundColor(color.text)
            .onChange(of: $field.wrappedValue) { (_) in
                datePicker = false
            }
    }
}
