//
//  Inset View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 26/01/2022.
//

import SwiftUI

struct InsetView <Content>: View where Content: View {
    var color: PaletteColor
    var font: Font
    var content: Content

    init(color: PaletteColor = Palette.inset, font: Font = .body, @ViewBuilder content: ()->Content) {
        self.color = color
        self.font = font
        self.content = content()
    }
    
    var body: some View {
        VStack {
            Spacer().frame(height: 16)
            HStack {
                Spacer().frame(width: 16)
                HStack {
                    Spacer().frame(width: 16)
                    content
                    Spacer()
                }
                .background(color.background)
                .cornerRadius(16)
                Spacer().frame(width: 16)
            }
        }
        .foregroundColor(color.text)
        .font(font)
    }
}
