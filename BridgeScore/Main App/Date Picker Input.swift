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
    var optionalField: Binding<Date?> {
        Binding {
            field
        } set: { (newValue) in
            field = newValue ?? Date()
        }
    }
    var message: Binding<String>?
    var placeholder: String = ""
    var from: Date?
    var to: Date?
    var color: PaletteColor = Palette.clear
    var textType: ThemeTextType = .theme
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
        OptionalDatePickerInput(title: title, field: optionalField, message: message, placeholder: placeholder, from: from, to: to, color: color, textType: textType, cornerRadius: cornerRadius, pickerColor: pickerColor, topSpace: topSpace, width: width, height: height, centered: centered, inlineTitle: inlineTitle, inlineTitleWidth: inlineTitleWidth, onChange: { (optionalDate) in
                            if let date = optionalDate {
                                onChange?(date)
                            }
                       })
    }
}


struct OptionalDatePickerInput : View {
    
    var title: String?
    var field: Binding<Date?>
    @State private var nonNullDate = Date()
    private var nonNull: Binding<Date> {
        Binding {
            nonNullDate }
        set: { newValue in
            nonNullDate = newValue
            field.wrappedValue = newValue
         }
    }
    var message: Binding<String>?
    var placeholder: String = ""
    var clearText: String? = nil
    var from: Date?
    var to: Date?
    var color: PaletteColor = Palette.clear
    var textType: ThemeTextType = .theme
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
    @State private var picker: AnyView!

    init(title: String? = nil, field: Binding<Date?>, message: Binding<String>? = nil, placeholder: String = "", clearText: String? = nil, from: Date? = nil, to: Date? = nil, color: PaletteColor = Palette.clear, textType: ThemeTextType = .theme, cornerRadius: CGFloat = 0, pickerColor: PaletteColor = Palette.datePicker, topSpace: CGFloat = 0, width: CGFloat? = nil, height: CGFloat = 45, centered: Bool = false, inlineTitle: Bool = true, inlineTitleWidth: CGFloat = 150, onChange: ((Date?)->())? = nil) {
        
        self.title = title
        self.field = field
        self.message = message
        self.placeholder = placeholder
        self.clearText = clearText
        self.from = from
        self.to = to
        self.color = color
        self.textType = textType
        self.cornerRadius = cornerRadius
        self.pickerColor = pickerColor
        self.topSpace = topSpace
        self.width = width
        self.height = height
        self.centered = centered
        self.inlineTitle = inlineTitle
        self.inlineTitleWidth = inlineTitleWidth
        self.onChange = onChange
        if let value = field.wrappedValue {
            self.nonNullDate = value
        }
    }
    
    var body: some View {
        
        UndoWrapper(nonNull) { nonNull in
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
                    Spacer().frame(width: 4)
                    Text(field.wrappedValue == nil ? placeholder : Utility.dateString(nonNull.wrappedValue, format: "EEEE dd MMMM yyyy"))
                        .foregroundColor(color.textColor(textType))
                    
                    Spacer()
                }
                .popover(isPresented: $datePicker, attachmentAnchor: .rect(.bounds)) {
                    ZStack {
                        Rectangle()
                            .frame(width: 280)
                            .background(.clear)
                        VStack(spacing: 0) {
                            HStack {
                                if from == nil && to == nil {
                                    DatePicker("",  selection: nonNull, displayedComponents: .date)
                                        .datePickerStyle(GraphicalDatePickerStyle())
                                } else if from == nil {
                                    DatePicker("", selection: nonNull, in: ...to!, displayedComponents: .date)
                                        .datePickerStyle(GraphicalDatePickerStyle())
                                } else if to == nil {
                                    DatePicker("", selection: nonNull, in: from!..., displayedComponents: .date)
                                        .datePickerStyle(GraphicalDatePickerStyle())
                                } else {
                                    DatePicker("", selection: nonNull, in: from!...to!, displayedComponents: .date)
                                        .datePickerStyle(GraphicalDatePickerStyle())
                                }
                            }
                            .background(pickerColor.background)
                            .foregroundColor(pickerColor.text)
                            .onChange(of: nonNull.wrappedValue) { (_) in
                                datePicker = false
                                onChange?(field.wrappedValue)
                            }
                            if let clearText = clearText {
                                Button {
                                    field.wrappedValue = nil
                                    datePicker = false
                                    onChange?(field.wrappedValue)
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
            .onTapGesture {
                datePicker = true
            }
            .onAppear{
                if let value = field.wrappedValue {
                    self.nonNull.wrappedValue = value
                }
            }
        }
    }
    
    private var datePickerRange: some View {
        var picker: AnyView
            if from == nil && to == nil {
                picker = AnyView(DatePicker("",  selection: nonNull, displayedComponents: .date))
            } else if from == nil {
                picker = AnyView(DatePicker("", selection: nonNull, in: ...to!, displayedComponents: .date))
            } else if to == nil {
                picker = AnyView(DatePicker("", selection: nonNull, in: from!..., displayedComponents: .date))
            } else {
                picker = AnyView(DatePicker("", selection: nonNull, in: from!...to!, displayedComponents: .date))
            }
        return picker
            .datePickerStyle(GraphicalDatePickerStyle())
            .background(pickerColor.background)
            .foregroundColor(pickerColor.text)
            .onChange(of: nonNull.wrappedValue) { (_) in
                datePicker = false
                onChange?(field.wrappedValue)
            }
    }
}


