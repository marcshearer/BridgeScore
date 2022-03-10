//
//  Double Column View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 05/02/2022.
//

import SwiftUI

struct DoubleColumnView <LeftContent, RightContent> : View where LeftContent : View, RightContent : View {
    var leftWidth: CGFloat
    var leftView: LeftContent
    var rightView: RightContent
    
    init(leftWidth: CGFloat = 350, @ViewBuilder leftView: ()->LeftContent, @ViewBuilder rightView: ()->RightContent) {
        self.leftWidth = leftWidth
        self.leftView = leftView()
        self.rightView = rightView()
    }
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                leftView
                Spacer()
            }
            .frame(width: leftWidth)
            Separator(direction: .vertical, thickness: 2.0)
                .foregroundColor(Palette.banner.background)
            VStack {
                rightView
                Spacer()
            }
        }
    }
}
