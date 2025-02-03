//
//  Widget Library.swift
//  BridgeScore
//
//  Created by Marc Shearer on 01/02/2025.
//

import SwiftUI
import AppIntents

enum WidgetTitlePosition: String, AppEnum {
    case left
    case top
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Title Position"
    static var caseDisplayRepresentations: [WidgetTitlePosition : DisplayRepresentation] = [
        .left : "Left",
        .top  : "Top"
    ]
}

struct WidgetContainer<Content>: View where Content: View {
    var label: String
    var palette: PaletteColor
    var titlePosition: WidgetTitlePosition
    var content: ()->Content
    let titleWidth: CGFloat = 40
    
    var body: some View {
        HStack(spacing: 0) {
            if titlePosition == .left {
                widgetContainerLeft
            } else {
                widgetContainerTop
            }
        }
    }
        
    var widgetContainerLeft: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ZStack {
                    Rectangle()
                        .foregroundColor(palette.background)
                        .frame(width: titleWidth)
                    HStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Spacer().frame(minWidth: 20)
                            Text(label)
                                .lineLimit(1)
                                .frame(width: geometry.size.height - 40)
                                .foregroundColor(palette.text)
                                .font(.title2).bold()
                                .minimumScaleFactor(0.3)
                            Spacer().frame(minWidth: 20)
                        }
                        .frame(width: geometry.size.height, height: titleWidth)
                        .rotationEffect(.degrees(270))
                        .ignoresSafeArea()
                    }
                    .frame(width: titleWidth)
                }
                content().frame(width: geometry.size.width - titleWidth, height: geometry.size.height)
            }
        }
    }
    
    var widgetContainerTop: some View {
        VStack {
            ZStack {
                Rectangle()
                    .foregroundColor(palette.background)
                    .frame(height: titleWidth)
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 0) {
                        Spacer().frame(width: 10)
                        Spacer()
                        Text(label)
                            .lineLimit(1)
                            .foregroundColor(palette.text)
                            .font(.title2).bold()
                            .minimumScaleFactor(0.3)
                        Spacer()
                        Spacer().frame(width: 10)
                    }
                    .ignoresSafeArea()
                    Spacer()
                }
                .frame(height: titleWidth)
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    content()
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

struct RectangleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(.tint)
      .background(.clear, in: Rectangle())
  }
}
