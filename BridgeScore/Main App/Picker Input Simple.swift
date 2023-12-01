//
//  Picker.swift
//  Wots4T
//
//  Created by Marc Shearer on 14/02/2021.
//

import SwiftUI

struct PickerInputSimple : View {
    var title: String
    @Binding var field: Int
    var values: [String]
    var topSpace: CGFloat = 24
    var width: CGFloat = 200
    var height: CGFloat = 40
    var titleWidth: CGFloat = 200
    var onChange: ((Int)->())?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: topSpace)
            HStack {
                HStack {
                    Text(title)
                    Spacer()
                }
                .frame(width: titleWidth)
                Spacer().frame(width: 5)
                HStack {
                    Menu {
                        ForEach(values, id: \.self) { value in
                            Button(value) {
                                let index = values.firstIndex(where: {$0 == value})!
                                onChange?(index)
                                field = index
                            }
                        }
                    } label: {
                        HStack {
                            Text(values[field])
                                .foregroundColor(Palette.background.themeText)
                            Spacer().frame(width: 5)
                            Image(systemName: "chevron.right")
                                .foregroundColor(Palette.background.themeText)
                            Spacer().frame(width: 2)
                        }
                    }
                    .background(Color.clear)
                    Spacer()
                }
                Spacer()
            }
            Spacer()
        }
        .frame(width: width + titleWidth + 5, height: topSpace + height)
    }
}
