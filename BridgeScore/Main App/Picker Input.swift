//
//  Picker.swift
// Bridge Score
//
//  Created by Marc Shearer on 14/02/2021.
//

import SwiftUI

struct PickerInput : View {
    
    var title: String
    @Binding var field: Int
    var values: ()->[String]
    var topSpace: CGFloat = 6
    var leadingSpace: CGFloat = 0
    var width: CGFloat?
    var height: CGFloat = 45
    var pickerWidth: CGFloat?
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 150
    var onChange: ((Int)->())?
        
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !inlineTitle {
                InputTitle(title: title, topSpace: topSpace, width: (width == nil ? nil : width! + leadingSpace + 16))
            } else {
                Spacer().frame(height: topSpace)
            }
            let values = values()
            HStack {
                Spacer().frame(width: leadingSpace)
                if inlineTitle {
                    HStack {
                        Spacer().frame(width: 8)
                        Text(title)
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
                        Text(field < values.count ? values[field] : "")
                            .foregroundColor(Palette.background.faintText)
                            .font(inputFont)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Palette.background.themeText)
                        Spacer().frame(width: 16)
                    }
                }
                .if(pickerWidth != nil) { (view) in
                    view.frame(width: pickerWidth! - 6)
                }
                .frame(height: height)
                .background(Color.clear)
                .frame(height: self.height)
            }
        }
    }
}
