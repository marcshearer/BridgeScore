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
    var onChange: ((Int)->())?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                Spacer().frame(width: 5)
                Menu {
                    ForEach(0..<(values.count)) { (index) in
                        Button(values[index]) {
                            onChange?(index)
                            field = index
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text(values[field])
                            .foregroundColor(Palette.background.themeText)
                        Spacer().frame(width: 5)
                        Image(systemName: "chevron.right")
                            .foregroundColor(Palette.background.themeText)
                        Spacer().frame(width: 2)
                    }
                }
                .background(Color.clear)
            }
        }
    }
}
