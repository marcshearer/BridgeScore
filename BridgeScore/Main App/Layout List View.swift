//
//  Layout List View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 03/02/2022.
//

import SwiftUI

struct LayoutListView: View {
    var id = UUID()
    @Environment(\.dismiss) var dismiss
    @Binding var selected: Bool
    @Binding var layout: LayoutViewModel
    @State private var title = "Select Template"
    @State private var linkToEdit = false
    var completion: (()->())? = nil
    @ObservedObject private var data = MasterData.shared
    
    var body: some View {
        let layouts = data.layouts
        
        StandardView("Layout List", slideInId: id) {
            VStack(spacing: 0) {
                
                Banner(title: $title, back: true, backAction: { self.selected = false ; completion?() ; return true }, optionMode: .none)
                
                LazyVStack {
                    ForEach(layouts) { (selectedLayout) in
                        VStack {
                            Spacer().frame(height: 16)
                            HStack {
                                Spacer().frame(width: 40)
                                Text(selectedLayout.desc)
                                    .font(.largeTitle)
                                Spacer()
                            }
                            Spacer().frame(height: 16)
                            Separator()
                        }
                        .background(Rectangle().fill(Palette.background.background))
                        .onTapGesture {
                            // Return this layout
                            completion?()
                            layout = selectedLayout
                            selected = true
                            dismiss()
                        }
                    }
                }
                
                Spacer()
                
            }
            
        }
    }
}
