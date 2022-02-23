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
    var topSpace: CGFloat = 16
    var leadingSpace: CGFloat = 32
    var width: CGFloat?
    var height: CGFloat = 40
    var pickerWidth: CGFloat = 300
    var onChange: ((Int)->())?
        
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            InputTitle(title: title, topSpace: topSpace, width: (width == nil ? nil : width! + leadingSpace + 16))
            let values = values()
            HStack {
                Spacer().frame(width: leadingSpace + 6)
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
                            .foregroundColor(Palette.background.text)
                            .font(inputFont)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Palette.background.themeText)
                        Spacer().frame(width: 24)
                    }
                }
                .frame(width: pickerWidth - 6, height: height)
                .background(Color.clear)
                .frame(height: self.height)
                
            }
        }
    }
}
