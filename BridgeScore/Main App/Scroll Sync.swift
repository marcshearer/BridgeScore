//
//  Scroll Sync.swift
//  BridgeScore
//
//  Created by Marc Shearer on 02/05/2026.
//

import SwiftUI

class ScrollSync<ID: Hashable> : ObservableObject {
    fileprivate var activeId: ID? = nil
}


struct HorizontalScrollView<ID,Content> : View where Content : View, ID : Hashable {
    var showsIndicators: Bool = false
    var id: ID
    var widths: [CGFloat]
    @State var scrollSync: ScrollSync<ID>
    @Binding var activeColumn: Int?
    var content: () -> Content
    
    @State private var position: CGFloat = 0
    @State private var lastOffset: CGFloat? = nil
    @State private var startColumn: Int? = nil
    
    var body : some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: showsIndicators) {
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 0) {
                        ForEach(widths.enumerated(), id: \.offset) { index, width in
                            Color.clear.frame(width: width, height: 1)
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                    content()
                }
            }
            .contentMargins(0, for: .scrollContent)
            .scrollClipDisabled()
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: self.binding(for: id), anchor: .leading)
            .onScrollPhaseChange { [self] (_, newPhase) in
                if newPhase != .idle {
                    scrollSync.activeId = id
                } else if newPhase == .idle {
                    scrollSync.activeId = nil
                }
            }
            .onChange(of: activeColumn) {
                if scrollSync.activeId != id {
                    withAnimation(.spring(duration: 0.3, bounce: 0)) {
                        proxy.scrollTo(activeColumn, anchor: .leading)
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        scrollSync.activeId = id
                        startColumn = startColumn ?? activeColumn ?? 0
                        lastOffset = lastOffset ?? value.startLocation.x
                        let lastColumnOffset = offset(for:startColumn ?? 0)
                        let offset = lastOffset! - value.startLocation.x
                        let newOffset = (lastColumnOffset - offset) * CGFloat(2)
                        let newColumn = index(for: newOffset)
                        if newColumn != activeColumn {
                            activeColumn = newColumn
                        }
                        lastOffset = value.location.x
                    }
                    .onEnded { [self] _ in
                        startColumn = nil
                        lastOffset = nil
                    })
        }
    }
    
    func offset(for column: Int) -> CGFloat {
        widths.prefix(column).reduce(0,+)
    }
    
    func index(for offset: CGFloat) -> Int {
        var current: CGFloat = 0
        if offset < 0 {
            return 0
        }
        for (index, width) in widths.enumerated() {
            let next = current + width
            if offset >= current && offset < next {
                return index
            }
            current = next
        }
        return widths.count - 1
    }
        
    func binding(for id: ID) -> Binding<Int?> {
        Binding (get: {
            activeColumn
        }, set: { newValue in
            if let newValue = newValue {
                if self.activeColumn != newValue {
                    self.activeColumn = newValue
                    scrollSync.activeId = id
                }
            }
        })
    }
}
