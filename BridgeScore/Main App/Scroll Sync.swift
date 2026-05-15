//
//  Scroll Sync.swift
//  BridgeScore
//
//  Created by Marc Shearer on 02/05/2026.
//

import SwiftUI

class ScrollSync<ID: Hashable & CaseIterable> : ObservableObject {
    @Published private var position: [ID:ScrollPosition] = [:]
    private var lastOffset: [ID:CGFloat] = [:]
    private var activeId: ID? = nil
    private var maxScroll: CGFloat = 0
    
    init() {
        for id in ID.allCases {
            position[id] = ScrollPosition(point: .zero)
        }
    }
    
    @ViewBuilder func horizontalScrollView<Content: View>(showsIndicators: Bool = false, id: ID, @ViewBuilder content: @escaping () -> Content) -> some View {
        
        ScrollView(.horizontal, showsIndicators: showsIndicators) {
            content()
                .scrollTargetLayout()
        }
        .onScrollPhaseChange { [self] (_, newPhase) in
            if newPhase != .idle {
                activeId = id
            } else if newPhase == .idle {
                activeId = nil
            }
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentSize.width - geometry.containerSize.width
        } action: { [self] (_, newMaxScroll) in
            maxScroll = newMaxScroll
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.x
        } action: { [self] (_, newOffset) in
            if activeId == id {
                let newPosition = ScrollPosition(point: CGPoint(x: newOffset, y: 0))
                for index in position.keys {
                    if index != id {
                        position[index]! = newPosition
                        self.objectWillChange.send()
                    }
                }
            }
        }
        .scrollPosition(binding(for: id))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { [self] value in
                    lastOffset[id] = lastOffset[id] ?? value.startLocation.x
                    let newX = min(maxScroll, max(0, position[id]!.point!.x + lastOffset[id]! - value.location.x))
                    let newPosition = ScrollPosition(point: CGPoint(x: newX, y: 0))
                    position[id] = newPosition
                    for index in position.keys {
                        if index != id {
                            position[index] = newPosition
                        }
                    }
                    lastOffset[id] = value.location.x
                    self.objectWillChange.send()
                }
                .onEnded { [self] _ in
                    lastOffset[id] = nil
                })
    }
    
    @ViewBuilder func verticalScrollView<Content: View>(showsIndicators: Bool = false, id: ID, @ViewBuilder content: @escaping () -> Content) -> some View {
        
        ScrollView(.vertical, showsIndicators: showsIndicators) {
            content()
                .scrollTargetLayout()
        }
        .onScrollPhaseChange { [self] (_, newPhase) in
            if newPhase != .idle {
                activeId = id
            } else if newPhase == .idle {
                activeId = nil
            }
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentSize.height - geometry.containerSize.height
        } action: { [self] (_, newMaxScroll) in
            maxScroll = newMaxScroll
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { [self] (_, newOffset) in
            if activeId == id {
                let newPosition = ScrollPosition(point: CGPoint(x: 0, y: newOffset))
                for index in position.keys {
                    if index != id {
                        position[index]! = newPosition
                        self.objectWillChange.send()
                    }
                }
            }
        }
        .scrollPosition(binding(for: id))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { [self] value in
                    lastOffset[id] = lastOffset[id] ?? value.startLocation.y
                    let newY = min(maxScroll, max(0, position[id]!.point!.y + lastOffset[id]! - value.location.y))
                    let newPosition = ScrollPosition(point: CGPoint(x: 0, y: newY ))
                    position[id] = newPosition
                    for index in position.keys {
                        if index != id {
                            position[index] = newPosition
                        }
                    }
                    lastOffset[id] = value.location.y
                    self.objectWillChange.send()
                }
                .onEnded { [self] _ in
                    lastOffset[id] = nil
                })
    }
    
    func binding(for id: ID) -> Binding<ScrollPosition> {
        Binding (get: { self.position[id]! }, set: { self.position[id] = $0 })
    }
}
