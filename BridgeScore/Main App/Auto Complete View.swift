//
//  Auto Complete.swift
//  ImportUsebio
//
//  Created by Marc Shearer on 19/02/2026.
//

import SwiftUI

struct AutoCompleteView<ID:Hashable> : View {
    @ObservedObject var autoComplete: AutoComplete
    var nameSpace: Namespace.ID
    var field: ID
    var selected: Binding<Int?>
    var codeWidth: CGFloat
    var valid: Bool = false
    var width: CGFloat = 270
    var inset: CGFloat = 12
    var elementHeight: CGFloat = 40
    var maxElements: Int = 6
    var selectAction: (AutoCompleteElement) -> ()
    
    var body: some View {
        VStack(spacing: 0) {
            if autoComplete.filteredList.count > 0 {
                HStack {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            let list = autoComplete.filteredList
                            ForEach(0..<list.count, id: \.self) { index in
                                let element = list[index]
                                VStack(spacing: 0) {
                                    HStack {
                                        Spacer().frame(width: 12)
                                        HStack(spacing: 0) {
                                            Text(element.replace)
                                                .font(inputTitleFont)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                                .padding(0)
                                            Spacer()
                                        }
                                        .frame(width: codeWidth - 12)
                                        Text(element.description)
                                            .font(inputTitleFont)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .padding(0)
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectAction(element)
                                    }
                                }
                                .frame(height: elementHeight)
                                .background((autoComplete.selected == index) ? Palette.autoCompleteSelected.background : Palette.autoComplete.background)
                                .foregroundColor((autoComplete.selected == index) ? Palette.autoCompleteSelected.text : Palette.autoComplete.text)
                            }
                        }
                        .scrollTargetLayout()
                        .listStyle(DefaultListStyle())
                    }
                    .scrollPosition(id: selected)
                    .clipShape(
                        .rect(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 8,
                            bottomTrailingRadius: 8,
                            topTrailingRadius: 0
                        )
                    )
                    Spacer().frame(width: inset)
                }
            }
        }
        .zIndex(1)
        .matchedGeometryEffect(
            id: field,
            in: nameSpace,
            properties: .position,
            anchor: .topTrailing,
            isSource: false)
        .frame(width: width, height: CGFloat(min(maxElements, autoComplete.filteredList.count)) * elementHeight)
    }
}

