//
//  Full Screen View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 07/05/2026.
//

import SwiftUI

struct FullScreenView <Content>: View where Content: View {
    @Environment(\.dismiss) var dismiss
    var insets: CGFloat
    var minWidth: CGFloat
    var minHeight: CGFloat
    var backgroundColor: ThemeBackgroundColorName = .background
    var escapeToDismiss: Bool
    var content: Content
    
    init(insets: CGFloat = 100, minWidth: CGFloat = 9999, minHeight: CGFloat = 9999, backgroundColor: ThemeBackgroundColorName = .background, escapeToDismiss: Bool = true, @ViewBuilder content: ()->Content) {
        self.insets = insets
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.backgroundColor = backgroundColor
        self.escapeToDismiss = escapeToDismiss
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = max(100, min(minWidth, geometry.size.width - insets))
            let height = max(100, min(minHeight, geometry.size.height - insets))
            ZStack {
                Color.black.opacity(0.4)
                MiddleCentered {
                    content
                        .frame(width: width, height: height)
                        .palette(backgroundColor)
                        .cornerRadius(20)
                }
                if escapeToDismiss {
                    Button("") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    .opacity(0)
                }
            }
            .background(BackgroundBlurView(opacity: 0.0))
            .edgesIgnoringSafeArea(.all)
            .background(.clear)
        }
    }
}
