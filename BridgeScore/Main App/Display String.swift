//
//  Display String.swift
//  BridgeScore
//
//  Created by Marc Shearer on 01/11/2026.
//

import SwiftUI

struct Display : View {
    
    var title: String?
    var field: String
    var topSpace: CGFloat = 0
    var leadingSpace: CGFloat = 0
    var height: CGFloat = 40
    var width: CGFloat?
    var color: PaletteColor = Palette.input
    var cornerRadius: CGFloat = 0
    var multiLine: Bool = false
    var inlineTitle: Bool = true
    var inlineTitleWidth: CGFloat = 180
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            if title != nil && !inlineTitle {
                HStack {
                    InputTitle(title: title, topSpace: topSpace, width: (width == nil ? nil : width! + leadingSpace + 16))
                }
                .frame(height: 22)
                Spacer().frame(height: 8)
            } else {
                Spacer().frame(height: topSpace)
            }
            HStack(spacing: 0) {
                Spacer().frame(width: leadingSpace)
                if title != nil && inlineTitle {
                    HStack {
                        Spacer().frame(width: 8)
                        VStack(spacing: 0) {
                            Spacer()
                            Text(title!)
                                .frame(height: height - 8)
                            Spacer()
                        }
                        Spacer()
                    }
                    .frame(width: inlineTitleWidth)
                    .frame(height: height).layoutPriority(999)
                    Spacer().frame(width: 14)
                }
                HStack {
                    ZStack {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 4)
                            
                            HStack {
                                Spacer().frame(width: 6)
                                Text(field)
                                    .truncationMode(.tail)
                                    .foregroundColor(color.text)
                                    .if(multiLine) { view in
                                        view.lineLimit(1)
                                    }
                            }
                        }
                        .frame(height: height).layoutPriority(999)
                    }
                }
                .background(color.background)
                .cornerRadius(cornerRadius)
                .if(width != nil) { (view) in
                    view.frame(width: width)
                }
                
                if width == nil {
                    Spacer()
                }
                
                Spacer().frame(width: 16)
            }
            
            .font(inputFont)
        }
        .frame(height: self.height + self.topSpace + (title != nil && !inlineTitle ? 24 : 0))
        .if(width != nil) { (view) in
            view.frame(width: width! + leadingSpace + 16)
        }
    }
}
