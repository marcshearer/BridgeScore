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
    @State private var optionalField: Date? = nil
    var message: Binding<String>?
    var placeholder: String = ""
    var from: Date?
    var to: Date?
    var color: PaletteColor = Palette.clear
    var cornerRadius: CGFloat = 0
    var pickerColor: PaletteColor = Palette.datePicker
    var topSpace: CGFloat = 0
    var width: CGFloat? = nil
    var height: CGFloat = 45
    var centered: Bool = false
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 150
    var onChange: ((Date)->())?
    @State private var datePicker = false

    var body: some View {
        OptionalDatePickerInput(title: title, field: $optionalField, message: message, placeholder: placeholder, from: from, to: to, color: color, cornerRadius: cornerRadius, pickerColor: pickerColor, topSpace: topSpace, width: width, height: height, centered: centered, inlineTitle: inlineTitle, inlineTitleWidth: inlineTitleWidth, onChange: { (optionalDate) in
                            if let date = optionalDate {
                                onChange?(date)
                            }
                       })
            .onChange(of: $optionalField.wrappedValue) { (nullable) in
                if let nullable = nullable {
                    field = nullable
                }
            }
            .onAppear {
                optionalField = field
            }
    }
}


struct OptionalDatePickerInput : View {
    
    var title: String?
    @Binding var field: Date?
    @State private var nonNull: Date = Date()
    var message: Binding<String>?
    var placeholder: String = ""
    var clearText: String? = nil
    var from: Date?
    var to: Date?
    var color: PaletteColor = Palette.clear
    var cornerRadius: CGFloat = 0
    var pickerColor: PaletteColor = Palette.datePicker
    var topSpace: CGFloat = 0
    var width: CGFloat? = nil
    var height: CGFloat = 45
    var centered: Bool = false
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 150
    var onChange: ((Date?)->())?
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
                } else if !centered {
                    Spacer().frame(width: 32)
                }
                
                if centered {
                    Spacer()
                } else {
                    Spacer().frame(width: 16)
                }
                Button(action: {
                    datePicker = true
                }) {
                    Text(field == nil ? placeholder : Utility.dateString(field!, format: "EEEE dd MMMM yyyy"))
                }.id(1)
                
                Spacer()
            }
            .popover(isPresented: $datePicker, attachmentAnchor: .rect(.bounds)) {
                ZStack {
                    Rectangle()
                        .frame(width: 280)
                        .background(.clear)
                    VStack(spacing: 0) {
                        datePickerRange
                        if let clearText = clearText {
                            Button {
                                field = nil
                                datePicker = false
                                onChange?(field)
                            } label: {
                                VStack {
                                    Spacer().frame(height: 4)
                                    HStack {
                                        Spacer()
                                        Text(clearText).font(.title3)
                                        Spacer()
                                    }
                                    Spacer().frame(height: 4)
                                }
                                .background(pickerColor.background)
                                .foregroundColor(pickerColor.themeText)
                            }
                        }
                    }
                }
            }
            .font(inputFont)
            .labelsHidden()
        }
        .frame(height: self.height + self.topSpace + (title == nil || inlineTitle ? 0 : 30))
        .if(width != nil) { (view) in
            view.frame(width: width!)
        }
        .foregroundColor(color.text)
        .background(color.background)
        .cornerRadius(cornerRadius)
    }
    
    private var datePickerRange: some View {
        var picker: AnyView
            if from == nil && to == nil {
                picker = AnyView(DatePicker("",  selection: $nonNull, displayedComponents: .date))
            } else if from == nil {
                picker = AnyView(DatePicker("", selection: $nonNull, in: ...to!, displayedComponents: .date))
            } else if to == nil {
                picker = AnyView(DatePicker("", selection: $nonNull, in: from!..., displayedComponents: .date))
            } else {
                picker = AnyView(DatePicker("", selection: $nonNull, in: from!...to!, displayedComponents: .date))
            }
        return picker.datePickerStyle(GraphicalDatePickerStyle())
            .background(pickerColor.background)
            .foregroundColor(pickerColor.text)
            .onChange(of: $nonNull.wrappedValue) { (_) in
                field = nonNull
                datePicker = false
                onChange?(field)
            }
    }
}


