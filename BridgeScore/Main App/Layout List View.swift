//
//  Layout List View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 03/02/2022.
//

import SwiftUI

struct LayoutListView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selected: Bool
    @Binding var layout: LayoutViewModel
    @State private var title = "Select Layout"
    @State private var linkToEdit = false
    @ObservedObject private var data = MasterData.shared
 
    var body: some View {
        let layouts = data.layouts.map{$1}.sorted(by: {$0.sequence < $1.sequence})
        
        StandardView {
            VStack(spacing: 0) {
            
                Banner(title: $title, back: true, backAction: { self.selected = false ; return true }, optionMode: .none)
                
                LazyVStack {
                    ForEach(layouts) { (layout) in
                        VStack {
                            Spacer().frame(height: 16)
                            HStack {
                                Spacer().frame(width: 40)
                                Text(layout.desc)
                                    .font(.largeTitle)
                                Spacer()
                            }
                            Spacer().frame(height: 16)
                            Separator()
                        }
                        .background(Rectangle().fill(Palette.background.background))
                        .onTapGesture {
                            // Return this layout
                            self.layout = layout
                            self.selected = true
                            dismiss()
                        }
                    }
                }
                
                Spacer()
                
            }
        }
    }
}
