//
//  Picker.swift
// Bridge Score
//
//  Created by Marc Shearer on 14/02/2021.
//

import SwiftUI

struct PickerInputOld : View {
    var id: UUID
    var title: String? = nil
    var field: Binding<Int?>
    var values: ()->[String]
    var popupTitle: String? = nil
    var placeholder: String = ""
    var topSpace: CGFloat = 0
    var leadingSpace: CGFloat = 0
    var width: CGFloat?
    var height: CGFloat = 45
    var maxLabelWidth: CGFloat = 200
    var centered: Bool = false
    var color: PaletteColor = Palette.clear
    var selectedColor: PaletteColor? = nil
    var font: Font = inputFont
    var cornerRadius: CGFloat = 0
    var animation: ViewAnimation = .slideLeft
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 150
    var onChange: ((Int?)->())?
    
    var body: some View {
        PickerInputAdditional<Int>(id: id, title: title, field: field, values: values, popupTitle: popupTitle, placeholder: placeholder, topSpace: topSpace, leadingSpace: leadingSpace, width: width, height: height, maxLabelWidth: maxLabelWidth, centered: centered, color: color, selectedColor: selectedColor, font: font, cornerRadius: cornerRadius, animation: animation, inlineTitle: inlineTitle, inlineTitleWidth: inlineTitleWidth, setAdditional: { (_, _) in}, onChange: onChange)
    }
}

struct PickerInputAdditional<Additional>: View where Additional: Equatable  {
    
    var id: UUID
    var title: String? = nil
    var field: Binding<Int?>
    var values: ()->[String]
    var popupTitle: String? = nil
    var placeholder: String = ""
    var topSpace: CGFloat = 0
    var leadingSpace: CGFloat = 0
    var width: CGFloat?
    var height: CGFloat = 45
    var maxLabelWidth: CGFloat = 200
    var centered: Bool = false
    var color: PaletteColor = Palette.clear
    var selectedColor: PaletteColor?
    var font: Font = inputFont
    var cornerRadius: CGFloat = 0
    var animation: ViewAnimation = .slideLeft
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 150
    var additionalBinding: Binding<Additional>? = nil
    var setAdditional: ((Binding<Additional>?, Additional)->())? = nil
    var onChange: ((Int?)->())?
        
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !inlineTitle && title != nil {
                InputTitle(title: title, topSpace: topSpace, width: (width == nil ? nil : width! + leadingSpace + 16))
            } else {
                Spacer().frame(height: topSpace)
            }
            let values = values()
            HStack {
                Spacer().frame(width: leadingSpace)
                if inlineTitle && title != nil {
                    HStack {
                        Spacer().frame(width: 8)
                        Text(title!)
                        Spacer()
                    }
                    .frame(width: inlineTitleWidth)
                    Spacer().frame(width: 12)
                }
                if !centered {
                    Spacer().frame(width: 6)
                }
                
                GeometryReader { (geometry) in
                    HStack {
                        UndoWrapperAdditional(field, additionalBinding: additionalBinding, setAdditional: setAdditional) { (field) in
                            let top = geometry.frame(in: .global).minY - (slideInMenuRowHeight * 1.4)
                            let left = geometry.frame(in: .global).maxX + 30
                            
                            PopupMenu(id: id, field: field, values: values, title: popupTitle ?? title, animation: animation, top: top, left: left, width: 400, selectedColor: selectedColor, onChange: onChange) {
                                
                                HStack {
                                    if centered {
                                        Spacer()
                                    } else {
                                        Spacer().frame(width: 2)
                                    }
                                    Text(field.wrappedValue != nil && field.wrappedValue! < values.count && field.wrappedValue! >= 0 ? values[field.wrappedValue!] : placeholder)
                                        .foregroundColor(placeholder == "" ? color.themeText : color.text)
                                        .font(font)
                                        .frame(maxHeight: height)
                                        .minimumScaleFactor(0.7)
                                    if !centered {
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(color.themeText)
                                        Spacer().frame(width: 16)
                                    } else {
                                        Spacer()
                                    }
                                }
                                .background(color.background)
                            }
                        }
                    }
                }
            }
        }
        .if(width != nil) { (view) in
            view.frame(width: width!)
        }
        .frame(height: height)
        .background(color.background)
        .cornerRadius(cornerRadius)
    }
}
