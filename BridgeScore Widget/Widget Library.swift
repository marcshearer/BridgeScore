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

enum WidgetDateRange: String, AppEnum {
    case last3Months
    case last6Months
    case lastYear
    case all
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Date Range"
    static var caseDisplayRepresentations: [WidgetDateRange : DisplayRepresentation] = [
        .last3Months : "Last 3 months",
        .last6Months : "Last 6 months",
        .lastYear : "Last year",
        .all : "All dates"
    ]
    
    var startDate: Date {
        switch self {
        case .last3Months:
            Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        case .last6Months:
            Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        case .lastYear:
            Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        default:
            Date(timeIntervalSinceReferenceDate: 0)
        }
    }
}

enum WidgetEventType: String, AppEnum {
    case individual
    case pairs
    case teams
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Event Types"
    static var caseDisplayRepresentations: [WidgetEventType : DisplayRepresentation] = [
        .pairs : "Pairs",
        .teams: "Teams",
        .individual : "Individual"
    ]
    
    var eventType: EventType {
        switch self {
        case .individual:
            .individual
        case .pairs:
            .pairs
        case .teams:
            .teams
        }
    }
}

struct WidgetContainer<Content>: View where Content: View {
    var label: String?
    var palette: PaletteColor
    var titlePosition: WidgetTitlePosition
    var content: ()->Content
    
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
        let titleWidth: CGFloat = (label == nil || label!.trimmingCharacters(in: .whitespaces).isEmpty ? 0 : 40)
        return GeometryReader { geometry in
            HStack(spacing: 0) {
                if let label = label, titleWidth != 0 {
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
                }
                content()
                    .frame(width: geometry.size.width - titleWidth, height: geometry.size.height)
                    .ignoresSafeArea()
            }
        }
    }
    
    var widgetContainerTop: some View {
        let titleHeight: CGFloat = (label == nil || label!.trimmingCharacters(in: .whitespaces).isEmpty ? 0 : 40)
        return GeometryReader { geometry in
            VStack {
                if let label = label, titleHeight != 0 {
                    ZStack {
                        Rectangle()
                            .foregroundColor(palette.background)
                            .frame(height: titleHeight)
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
                        .frame(height: titleHeight)
                    }
                }
                content()
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

struct WidgetFont {
    let macOSSize: CGFloat
    let iOSSize: CGFloat
    let phoneSize: CGFloat
    
    var font: Font {
        Font.system(size: (MyApp.format == .phone ? phoneSize : (MyApp.target == .macOS ? macOSSize : iOSSize)))
    }
}


var widgetBigFont =         WidgetFont(macOSSize: 60, iOSSize: 60, phoneSize: 30).font
var widgetTitleFont =       WidgetFont(macOSSize: 22, iOSSize: 22, phoneSize: 18).font
var widgetHeadingFont =     WidgetFont(macOSSize: 28, iOSSize: 28, phoneSize: 20).font
var widgetSubHeadingFont =  WidgetFont(macOSSize: 26, iOSSize: 26, phoneSize: 20).font
var WidgetTextFont =        WidgetFont(macOSSize: 20, iOSSize: 20, phoneSize: 17).font
var WidgetMessageFont =     WidgetFont(macOSSize: 22, iOSSize: 22, phoneSize: 18).font
