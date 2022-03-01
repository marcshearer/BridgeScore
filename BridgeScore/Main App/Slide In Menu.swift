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
    @Published public var top: CGFloat = 0
    @Published public var width: CGFloat = 0
    @Published public var animation: ViewAnimation = .slideLeft
    @Published public var completion: ((String?)->())?
    @Published public var shown: Bool = false
    
    public func show(title: String? = nil, options: [String], animation: ViewAnimation = .slideLeft, top: CGFloat? = nil, width: CGFloat? = nil, completion: ((String?)->())? = nil) {
        withAnimation(.none) {
            print(top!)
            SlideInMenu.shared.title = title
            SlideInMenu.shared.options = options
            SlideInMenu.shared.top = top ?? bannerHeight + 10
            SlideInMenu.shared.width = width ?? 300
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
    
    @State private var animate = false
    
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
                                            VStack(spacing: 0) {
                                                Spacer()
                                                HStack {
                                                    Spacer().frame(width: 20)
                                                    Text(option)
                                                        .animation(.none)
                                                        .foregroundColor(Palette.background.text)
                                                        .font(.title2)
                                                    Spacer()
                                                }
                                                Spacer()
                                            }
                                            .background(Palette.background.background)
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
            }
            .if(offset != 0 && values.animation == .fade) { (view) in
                view.hidden()
            }
            .if(values.animation == .slideLeft) { (view) in
                view.onChange(of: values.shown, perform: { value in
                    offset = values.shown ? 0 : values.width + 20
                    $animate.wrappedValue = true
                })
            }
            .animation($animate.wrappedValue || values.shown ? .easeInOut : .none, value: offset)
            .onAppear {
                SlideInMenu.shared.width = 300
            }
        }
    }
}
