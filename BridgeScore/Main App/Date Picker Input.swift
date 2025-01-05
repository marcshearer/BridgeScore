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
    var font: Font = inputFont
    var cornerRadius: CGFloat = 0
    var pickerColor: PaletteColor = Palette.datePicker
    var topSpace: CGFloat = 0
    var width: CGFloat? = nil
    var height: CGFloat = 45
    var centered: Bool = false
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 180
    var onChange: ((Date)->())?
    @State private var datePicker = false

    var body: some View {
        OptionalDatePickerInput(title: title, field: optionalField, message: message, placeholder: placeholder, from: from, to: to, color: color, textType: textType, font: font, cornerRadius: cornerRadius, pickerColor: pickerColor, topSpace: topSpace, width: width, height: height, centered: centered, inlineTitle: inlineTitle, inlineTitleWidth: inlineTitleWidth, onChange: { (optionalDate) in
                            if let date = optionalDate {
                                onChange?(date)
                            }
                       })
    }
}


struct OptionalDatePickerInput : View {
    
    var title: String?
    var field: Binding<Date?>
    var message: Binding<String>?
    var placeholder: String = ""
    var clearText: String? = nil
    var from: Date?
    var to: Date?
    var color: PaletteColor = Palette.clear
    var textType: ThemeTextType = .theme
    var font: Font = inputFont
    var cornerRadius: CGFloat = 0
    var pickerColor: PaletteColor = Palette.datePicker
    var topSpace: CGFloat = 0
    var width: CGFloat? = nil
    var height: CGFloat = 45
    var centered: Bool = false
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 180
    var onChange: ((Date?)->())?
    @State private var datePicker = false
    @State private var picker: AnyView!

    init(title: String? = nil, field: Binding<Date?>, message: Binding<String>? = nil, placeholder: String = "", clearText: String? = nil, from: Date? = nil, to: Date? = nil, color: PaletteColor = Palette.clear, textType: ThemeTextType = .theme, font: Font = inputFont, cornerRadius: CGFloat = 0, pickerColor: PaletteColor = Palette.datePicker, topSpace: CGFloat = 0, width: CGFloat? = nil, height: CGFloat = 45, centered: Bool = false, inlineTitle: Bool = true, inlineTitleWidth: CGFloat = 180, onChange: ((Date?)->())? = nil) {
        
        self.title = title
        self.field = field
        self.message = message
        self.placeholder = placeholder
        self.clearText = clearText
        self.from = from
        self.to = to
        self.color = color
        self.textType = textType
        self.font = font
        self.cornerRadius = cornerRadius
        self.pickerColor = pickerColor
        self.topSpace = topSpace
        self.width = width
        self.height = height
        self.centered = centered
        self.inlineTitle = inlineTitle
        self.inlineTitleWidth = inlineTitleWidth
        self.onChange = onChange
    }
    
    var body: some View {
        
        UndoWrapper(field) { field in
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
                    Text(field.wrappedValue == nil ? placeholder : Utility.dateString(field.wrappedValue!, format: (width ?? 200 < 200 ? "dd/MM/yyyy" : "EEEE d MMMM yyyy")))
                        .foregroundColor(color.textColor(textType))
                    
                    Spacer()
                }
                .popover(isPresented: $datePicker, attachmentAnchor: .rect(.bounds)) {
                    ZStack {
                        Rectangle()
                            .frame(width: 280, height: 300)
                            .background(.clear)
                        VStack(spacing: 0) {
                            HStack {
                                GeometryReader { (geometry) in
                                    DatePickerWrapper(frame: geometry.frame(in: .local), selection: field, from: from, to: to) { (selected) in
                                        datePicker = false
                                        onChange?(selected)
                                    }
                                    .onDisappear {
                                        
                                    }
                                }
                            }
                            .background(pickerColor.background)
                            .foregroundColor(pickerColor.text)
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
                .font(font)
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
        }
    }
}

struct DatePickerWrapper: UIViewRepresentable {
    var frame: CGRect
    var selection: Binding<Date?>
    var from: Date? = nil
    var to: Date? = nil
    var completion: ((Date)->())?
    
    func makeUIView(context: Context) -> DatePickerUIView {
        
        let view = DatePickerUIView(frame: frame, selection: selection, from: from, to: to, completion: completion)
       
        return view
    }

    func updateUIView(_ uiView: DatePickerUIView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        
        override init() {
            
        }
    }
}

class DatePickerUIView: UIView {
    private var picker: UIDatePicker!
    private var selection: Binding<Date?>
    private var completion: ((Date)->())?
    
    init(frame: CGRect, selection: Binding<Date?>, from: Date? = nil, to: Date? = nil, completion: ((Date)->())?) {
        self.selection = selection
        self.completion = completion
        super.init(frame: frame)
        picker = UIDatePicker(frame: CGRect())
        if let date = selection.wrappedValue {
            picker.date = date
        }
        picker.datePickerMode = .date
        if let from = from {
            picker.minimumDate = from
        }
        if let to = to {
            picker.maximumDate = to
        }
        picker.preferredDatePickerStyle = .inline
        self.addSubview(picker, anchored: .all)
        picker.addTarget(self, action: #selector(DatePickerUIView.valueChanged(_:)), for: .valueChanged)
        
    }
    
    @objc func valueChanged(_ sender: UIView) {
        selection.wrappedValue = picker.date
        completion?(picker.date)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
