//
//  Inset View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 26/01/2022.
//

import SwiftUI

struct InsetView: View {
    @State var content: (()->AnyView)
    @State var color: PaletteColor = Palette.inset
    @State var font: Font = .body
   
    var body: some View {
        VStack {
            Spacer().frame(height: 16)
            HStack {
                Spacer().frame(width: 16)
                HStack {
                    Spacer().frame(width: 16)
                    content()
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
