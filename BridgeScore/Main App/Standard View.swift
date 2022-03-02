//
//  Standard View.swift
// Bridge Score
//
//  Created by Marc Shearer on 02/03/2021.
//

import SwiftUI

struct StandardView <Content> : View where Content : View {
    @ObservedObject private var messageBox = MessageBox.shared
    var slideIn: Bool
    var navigation: Bool
    var animate = false
    var content: Content
    var info: String
    var backgroundColor: PaletteColor

    init(_ info: String, slideIn: Bool = true, navigation: Bool = false, animate: Bool = false, backgroundColor: PaletteColor = Palette.background, @ViewBuilder content: ()->Content) {
        self.info = info
        self.slideIn = slideIn
        self.navigation = navigation
        self.animate = animate
        self.backgroundColor = backgroundColor
        self.content = content()
    }
        
    var body: some View {
        if navigation {
            NavigationView {
                contentView()
            }
            .navigationViewStyle(IosStackNavigationViewStyle())
        } else {
            contentView()
        }
    }
    
    private func contentView() -> some View {
        GeometryReader { (geometry) in
        ZStack {
            backgroundColor.background
                .ignoresSafeArea()
            
            VStack {
                Spacer().frame(height: geometry.safeAreaInsets.top)
                self.content
            }
            .ignoresSafeArea()
            if slideIn {
                SlideInMenuView()
            }
            if messageBox.isShown {
                Palette.maskBackground
                    .ignoresSafeArea(edges: .all)
                VStack() {
                    Spacer()
                    HStack {
                        Spacer()
                        let width = min(geometry.size.width - 40, 400)
                        let height = min(geometry.size.height - 40, 250)
                        MessageBoxView(showIcon: width >= 400)
                            .frame(width: width, height: height)
                            .cornerRadius(20)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .animation(animate || messageBox.isShown ? .easeInOut(duration: 1.0) : .none, value: messageBox.isShown)
        .noNavigationBar
        }
    }
}
