//
//  Inset View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 26/01/2022.
//

import SwiftUI

struct InsetView <Content>: View where Content: View {
    var title: String?
    var color: PaletteColor
    var font: Font
    var info: String?
    var infoWidth: CGFloat
    var content: Content
    
    @State var showInfo: Bool = false

    init(title: String? = nil, color: PaletteColor = Palette.inset, font: Font = .body, info: String? = nil, infoHeight: CGFloat = 400, @ViewBuilder content: ()->Content) {
        self.title = title
        self.color = color
        self.font = font
        self.info = info
        self.infoWidth = infoHeight
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)
            if let title = title {
                VStack {
                    HStack {
                        Spacer().frame(width: 40)
                        Text(title.uppercased()).foregroundColor(Palette.alternate.faintText)
                        Spacer()
                        if info != nil {
                            Button {
                                showInfo = true
                            } label: {
                                Image(systemName: "info.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Palette.alternate.themeText)
                            }
                            .popover(isPresented: $showInfo, attachmentAnchor: .point(.bottomLeading), arrowEdge: .leading) {
                                InsetInfoView(text: info ?? "", font: font)
                                    .frame(width: infoWidth)
                            }
                            Spacer().frame(width: 24)
                        }
                    }
                    Spacer().frame(height: 4)
                }
            }
            HStack {
                Spacer().frame(width: 16)
                VStack(spacing: 0) {
                    Spacer().frame(height: 8)
                    HStack {
                        Spacer().frame(width: 16)
                        content
                    }
                }
                .background(color.background)
                .cornerRadius(10)
                Spacer().frame(width: 16)
            }
        }
        .foregroundColor(color.text)
        .font(font)
    }
}

struct InsetInfoView : View {
    @Environment(\.dismiss) var dismiss
    var text: String
    var font: Font
    
    var body: some View {
        VStack {
            Spacer().frame(height: 6)
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    TrailingText("􀆄")
                        .font(.title2)
                }
                Spacer().frame(width: 16)
            }
            .frame(height: 30)
            HStack {
                Spacer().frame(width: 30)
                Text(text)
                    .multilineTextAlignment(.leading)
                    .font(font)
                Spacer().frame(width: 30)
                Spacer()
            }
            Spacer().frame(height: 30)
        }
    }
}
