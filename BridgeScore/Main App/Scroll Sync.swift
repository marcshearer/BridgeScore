//
//  Scroll Sync.swift
//  BridgeScore
//
//  Created by Marc Shearer on 02/05/2026.
//

import SwiftUI

// Designed to allow scrolling of various ScrollViews locked together. Also supports snap to column. Also supports dragging with the mouse

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
    
    @State private var startColumn: Int? = nil
    @GestureState private var isDragging: Bool = false
    @State var lastValidColumn: Int = 0
    @State var maxOffset: CGFloat = 0
    
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
            .clipped()
            .contentMargins(0, for: .scrollContent)
            .scrollClipDisabled()
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: self.binding(for: id), anchor: .leading)
            .simultaneousGesture(dragGesture)
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
            .onChange(of: activeColumn) { _, newValue in
                if let index = newValue {
                    lastValidColumn = index
                }
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentSize.width - geometry.containerSize.width
            } action: { [self] (_, newMaxOffset) in
                maxOffset = newMaxOffset
            }
            .onChange(of: isDragging) { _, nowDragging in
                if !nowDragging {
                    startColumn = nil
                }
            }
        }
    }
    
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                // let maxOffset = widths.reduce(0,+)
                scrollSync.activeId = id
                startColumn = startColumn ?? activeColumn ?? lastValidColumn
                let startOffset = offset(for: startColumn ?? 0)
                let offset = -value.translation.width
                let newOffset = max(0,min(maxOffset + (widths.last ?? 00),(startOffset + offset)))
                let newColumn = index(for: newOffset)
                if newColumn != activeColumn {
                    activeColumn = newColumn
                }
            }
            .onEnded { [self] _ in
                startColumn = nil
            }
    }
    
    func offset(for column: Int) -> CGFloat {
        widths.prefix(column).reduce(0,+) + (widths[column] / CGFloat(2))
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
