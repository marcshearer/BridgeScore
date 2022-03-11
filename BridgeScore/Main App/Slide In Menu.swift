//
//  Slide In Menu.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 07/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

class SlideInMenu : ObservableObject {
    
    public static let shared = SlideInMenu()
    
    @Published public var title: String? = nil
    @Published public var options: [String] = []
    @Published public var selected: Int?
    @Published public var top: CGFloat = 0
    @Published public var left: CGFloat? = nil
    @Published public var width: CGFloat = 0
    @Published public var animation: ViewAnimation = .slideLeft
    @Published public var selectedColor: PaletteColor?
    @Published public var completion: ((String?)->())?
    @Published public var shown: Bool = false
    
    public func show(title: String? = nil, options: [String], selected: Int? = nil, animation: ViewAnimation = .slideLeft, top: CGFloat? = nil, left: CGFloat? = nil, width: CGFloat? = nil, selectedColor: PaletteColor? = nil, completion: ((String?)->())? = nil) {
        withAnimation(.none) {
            SlideInMenu.shared.title = title
            SlideInMenu.shared.options = options
            SlideInMenu.shared.selected = selected
            SlideInMenu.shared.top = top ?? bannerHeight + 10
            SlideInMenu.shared.left = left
            SlideInMenu.shared.width = width ?? 300
            SlideInMenu.shared.selectedColor = selectedColor
            SlideInMenu.shared.animation = animation
            SlideInMenu.shared.completion = completion
            Utility.mainThread {
                SlideInMenu.shared.shown = true
            }
        }
    }
}

struct SlideInMenuView : View {
    @ObservedObject var values = SlideInMenu.shared
    @State private var offset: CGFloat = 320
    
    var body: some View {
        GeometryReader { (fullGeometry) in
            GeometryReader { (geometry) in
                ZStack {
                    Rectangle()
                        .foregroundColor(values.shown ? Palette.maskBackground : Color.clear)
                        .onTapGesture {
                            values.shown = false
                        }
                        .frame(width: fullGeometry.size.width, height: fullGeometry.size.height + fullGeometry.safeAreaInsets.top + fullGeometry.safeAreaInsets.bottom)
                        .ignoresSafeArea()
                    VStack(spacing: 0) {
                        let proposedTop = values.top
                        let contentHeight = (CGFloat(values.options.count) + 2.4) * slideInMenuRowHeight
                        let top = min(proposedTop,
                                      max(bannerHeight + 8,
                                          geometry.size.height - contentHeight))
                        
                        Spacer().frame(height: top)
                        HStack {
                            Spacer()
                            VStack(spacing: 0) {
                                if let title = values.title {
                                    VStack(spacing: 0) {
                                        Spacer()
                                        HStack {
                                            Spacer().frame(width: 20)
                                            Text(title)
                                                .font(.title)
                                                .foregroundColor(Palette.header.text)
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                    .frame(height: slideInMenuRowHeight * 1.4)
                                    .background(Palette.header.background)
                                }
                                
                                let options = $values.options.wrappedValue
                                ScrollView {
                                    VStack(spacing: 0) {
                                        ForEach(options, id: \.self) { (option) in
                                            let color = (values.selected != nil && values.selectedColor != nil && option == values.options[values.selected!] ? values.selectedColor! :  Palette.background)
                                            VStack(spacing: 0) {
                                                Spacer()
                                                HStack {
                                                    Spacer().frame(width: 20)
                                                    Text(option)
                                                        .animation(.none)
                                                        .foregroundColor(color.text)
                                                        .font(.title2)
                                                    Spacer()
                                                }
                                                Spacer()
                                            }
                                            .background(color.background)
                                            .onTapGesture {
                                                values.completion?(option)
                                                values.shown = false
                                            }
                                            .background(Palette.background.background)
                                            .frame(height: slideInMenuRowHeight)
                                        }
                                            //.listRowInsets(EdgeInsets())
                                        .listStyle(PlainListStyle())
                                    }
                                }
                                .background(Palette.background.background)
                                .environment(\.defaultMinListRowHeight, slideInMenuRowHeight)
                                .frame(height: max(0, min(CGFloat(values.options.count) * slideInMenuRowHeight, geometry.size.height - top - (2.4 * slideInMenuRowHeight))))
                                .layoutPriority(.greatestFiniteMagnitude)
                                
                                VStack(spacing: 0) {
                                    Spacer()
                                    HStack {
                                        Spacer().frame(width: 20)
                                        Text("Cancel")
                                            .foregroundColor(Palette.background.text)
                                            .font(Font.title2.bold())
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                .background(Palette.background.background)
                                .onTapGesture {
                                    values.shown = false
                                }
                                .frame(height: slideInMenuRowHeight).layoutPriority(.greatestFiniteMagnitude)
                            }
                            .background(Palette.background.background)
                            .frame(width: values.width)
                            .cornerRadius(20)
                            Spacer().frame(width: 20)
                        }
                        Spacer()
                        
                    }
                    .offset(x: offset)
                }
                
                .if(offset != 0 && values.animation == .fade) { (view) in
                    view.hidden()
                }
                .onChange(of: values.shown, perform: { value in
                    offset = (values.shown ? (values.left == nil ? 0 : min(0, (values.left! + values.width - geometry.size.width))) : values.width + 20)
                })
                .animation(values.animation == .none ? .none : .easeInOut, value: offset)
                .onAppear {
                    SlideInMenu.shared.width = 300
                }
            }
        }
    }
}
