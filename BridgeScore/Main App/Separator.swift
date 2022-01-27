//
//  Separator.swift
// Bridge Score
//
//  Created by Marc Shearer on 22/02/2021.
//

import SwiftUI

struct Separator : View {
    
    @State var padding = true
    
    var body : some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 16)
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Palette.separator.background)
            Spacer().rightSpacer
        }
    }
}
