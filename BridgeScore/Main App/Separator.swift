//
//  Separator.swift
// Bridge Score
//
//  Created by Marc Shearer on 22/02/2021.
//

import SwiftUI

enum SeparatorDirection {
    case horizontal
    case vertical
}

struct Separator : View {
    
    var orientation: SeparatorDirection!
    var padding = false
    var thickness: CGFloat
    var color: Color
    
    init(direction: SeparatorDirection = .horizontal, padding: Bool = false, thickness: CGFloat = 1.0, color: Color = Palette.separator.background) {
        self.orientation = direction
        self.padding = padding
        self.thickness = thickness
        self.color = color
    }
    
    var body : some View {
        if orientation == .vertical {
            VStack(spacing: 0) {
                if padding {
                    Spacer().frame(height: 16)
                }
                Rectangle()
                    .foregroundColor(color)
                if padding {
                    Spacer().bottomSpacer
                }
            }
            .frame(width: thickness)
        } else {
            HStack(spacing: 0) {
                if padding {
                    Spacer().frame(width: 16)
                }
                Rectangle()
                    .foregroundColor(color)
                if padding {
                    Spacer().rightSpacer
                }
            }
            .frame(height: thickness)
        }
    }
}
