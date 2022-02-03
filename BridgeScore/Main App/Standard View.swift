//
//  Standard View.swift
// Bridge Score
//
//  Created by Marc Shearer on 02/03/2021.
//

import SwiftUI

struct StandardView <Content> : View where Content : View {
    @ObservedObject var messageBox = MessageBox.shared
    var navigation: Bool
    @State var animate = false
    var content: Content
    
    init(navigation: Bool = false, @ViewBuilder content: ()->Content) {
        self.navigation = navigation
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
        return ZStack {
            Palette.background.background
                .ignoresSafeArea(edges: .all)
            self.content
            if messageBox.isShown {
                Palette.maskBackground
                    .ignoresSafeArea(edges: .all)
                GeometryReader { geometry in
                    VStack() {
                        Spacer()
                        HStack {
                            Spacer()
                            let width = min(geometry.size.width - 40, 400)
                            let height = min(geometry.size.height - 40, 250)
                            MessageBoxView(suppressIcon: width < 400)
                                .frame(width: width, height: height)
                                .cornerRadius(20)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
        .noNavigationBar
    }
}

