//
//  Double Column View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 05/02/2022.
//

import SwiftUI

struct DoubleColumnView <LeftContent, RightContent> : View where LeftContent : View, RightContent : View {
    var leftView: LeftContent
    var rightView: RightContent
    var leftWidth: CGFloat = 300
    
    init(@ViewBuilder leftView: ()->LeftContent, @ViewBuilder rightView: ()->RightContent) {
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
            Divider()
            VStack {
                rightView
                Spacer()
            }
            Spacer()
        }
    }
}
