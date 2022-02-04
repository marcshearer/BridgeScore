//
//  InputTitle.swift
// Bridge Score
//
//  Created by Marc Shearer on 14/02/2021.
//

import SwiftUI

struct InputTitle : View {
    
    @State var title: String?
    var message: Binding<String>? = nil
    var topSpace: CGFloat = 16
    var buttonImage: AnyView?
    var buttonText: String?
    var buttonAction: (()->())?
    
    var body: some View {

        VStack {
            Spacer().frame(height: topSpace)
                
            if let title = self.title {
                HStack(alignment: .center, spacing: nil) {
                    Spacer().frame(width: 16)
                    Text(title)
                        .foregroundColor(Palette.background.text)
                        .font(inputTitleFont)
                    
                    if let action = buttonAction {
                        Spacer().frame(width: 16)
                        Button {
                            action()
                        } label: {
                            if let image = buttonImage {
                                image
                            }
                            if let text = buttonText {
                                if buttonImage != nil {
                                    Spacer().frame(width: 8)
                                }
                                Text(text)
                                    .foregroundColor(Palette.background.themeText)
                                    .font(inputFont)
                            }
                        }
                        .menuStyle(DefaultMenuStyle())
                    }
                    Spacer()
                    if let message = message?.wrappedValue {
                        VStack(spacing: 0) {
                            Spacer()
                            Text(message)
                                .foregroundColor(Palette.background.strongText)
                                .font(messageFont)
                        }
                        Spacer().frame(width: 16)
                    }
                }
            }
        }
    }
}
