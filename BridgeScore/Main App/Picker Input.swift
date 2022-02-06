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
    var values: [String]
    var topSpace: CGFloat = 16
    var width: CGFloat = 200
    var height: CGFloat = 40
    var onChange: ((Int)->())?
        
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            InputTitle(title: title, topSpace: topSpace)
            HStack {
                Spacer().frame(width: 38)
                Menu {
                    ForEach(0..<(values.count)) { (index) in
                        Button(values[index]) {
                            field = index
                            onChange?(field)
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
                .frame(width: width, height: height)
                .background(Color.clear)
                .frame(height: self.height)
                
            }
        }
    }
}
