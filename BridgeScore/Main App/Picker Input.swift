//
//  Picker.swift
// Bridge Score
//
//  Created by Marc Shearer on 14/02/2021.
//

import SwiftUI

struct PickerInput : View {
    
    var title: String? = nil
    @Binding var field: Int
    var values: ()->[String]
    var placeholder: String = ""
    var topSpace: CGFloat = 0
    var leadingSpace: CGFloat = 0
    var width: CGFloat?
    var height: CGFloat = 45
    var color: PaletteColor = Palette.clear
    var cornerRadius: CGFloat = 0
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 150
    var onChange: ((Int)->())?
        
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
                Spacer().frame(width: 6)
                
                Menu {
                    ForEach(values, id: \.self) { (value) in
                        if let index = values.firstIndex(where: {$0 == value}) {
                            Button(values[index]) {
                                field = index
                                onChange?(field)
                            }
                        }
                    }
                } label: {
                    HStack {
                        if placeholder != "" {
                            Spacer()
                        }
                        Text(field < values.count && field >= 0 ? values[field] : placeholder)
                            .foregroundColor(placeholder == "" ? color.faintText : color.text)
                            .font(inputFont)
                        if placeholder == "" {
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(color.themeText)
                            Spacer().frame(width: 16)
                        } else {
                            Spacer()
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
        .frame(height: self.height)
    }
}
