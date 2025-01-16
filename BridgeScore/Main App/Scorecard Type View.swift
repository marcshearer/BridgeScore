//
//  Scorecard Type View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 15/01/2025.
//

import SwiftUI

enum CompositeEventType: Int, CaseIterable {
    case pairs = 2
    case multipleTeams = 4
    case headToHeadTeams = -4
    case individual = 1
    case unknown = 0
    
    init(_ eventType: EventType, _ headToHead: Bool) {
        if headToHead && eventType == .teams {
            self = .headToHeadTeams
        } else {
            self = CompositeEventType(rawValue: abs(eventType.rawValue)) ?? .unknown
        }
    }
    
    var headToHead: Bool {
        self.rawValue < 0
    }
    
    var eventType: EventType {
        EventType(rawValue: abs(self.rawValue)) ?? .unknown
    }
    
    static var validCases: [CompositeEventType] {
        CompositeEventType.allCases.filter({$0 != .unknown})
    }
    
    var string: String {
        switch self {
        case .headToHeadTeams:
            "Head-to-head Teams"
        case .multipleTeams:
            "Multiple Teams"
        default:
            self.eventType.string
        }
    }
}

enum FieldUpdateType: Int {
    case all = 0
    case eventType = 1
    case headToHead = 2
    case boardScoringType = 3
    case aggregateType = 4
    case vpType = 5
    
    static func <= (lhs: FieldUpdateType, rhs: FieldUpdateType) -> Bool {
        lhs.rawValue <= rhs.rawValue
    }
}

struct ScorecardTypeView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State var id: UUID
    @Binding var type: ScorecardType
    @Binding var dismiss: Bool
    @State var eventTypes: [CompositeEventType] = []
    @State var eventTypeIndex:Int? = 0
    @State var scoreTypes: [ScoreType] = []
    @State var scoreTypeIndex:Int? = 0
    @State var aggregateTypes: [AggregateType] = []
    @State var aggregateTypeIndex:Int? = 0
    
    var body : some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                InsetView(title: "Scorecard Type") {
                    VStack(spacing: 0) {
                        
                        PickerInput(id: id, title: "Event type", field: $eventTypeIndex, values: {eventTypes.map{$0.string}})
                        { index in
                            if let index = index {
                                type.eventType = eventTypes[index].eventType
                                type.headToHead = eventTypes[index].headToHead
                                updateData(from: .eventType)
                            }
                        }
                        
                        Separator()
                        
                        PickerInput(id: id, title: "Board scoring", field: $scoreTypeIndex, values: {scoreTypes.map{$0.string}}, disabled: scoreTypes.count <= 1)
                        { index in
                            if let index = index {
                                type.boardScoreType = scoreTypes[index]
                                updateData(from: .boardScoringType)
                            }
                        }.opacity(scoreTypes.isEmpty ? 0.1 : 1.0)
                        
                        Separator()
                        
                        PickerInput(id: id, title: "Match scoring", field: $aggregateTypeIndex, values: {aggregateTypes.map{aggregateDescription($0)}}, disabled: aggregateTypes.count <= 1)
                        { index in
                            if let index = index {
                                type.aggregateType = aggregateTypes[index]
                                updateData(from: .aggregateType)
                            }
                        }.opacity(aggregateTypes.isEmpty ? 0.1 : 1.0)
                        
                        Spacer()
                    }
                    .frame(width: 550, height: 135)
                }
                VStack(spacing: 0) {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            print("\(type.aggregateType.string)")
                            dismiss = true
                        } label: {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text("Close")
                                    Spacer()
                                }
                                Spacer()
                            }
                            .frame(width: 100, height: 40)
                            .palette(.enabledButton)
                            .cornerRadius(10)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .frame(width: 600, height: 250)
        .background(Palette.alternate.background)
        .cornerRadius(10)
        .onAppear {
            updateData(from: .all)
        }
    }
    
    func aggregateDescription(_ aggregateType: AggregateType) -> String {
        switch aggregateType {
        case .vp:
            aggregateType.verbose
        default:
            "\(type.boardScoreType.string) \(aggregateType.verbose)"
        }
    }
    
    func updateData(from updateFrom: FieldUpdateType) {
        if updateFrom <= .eventType {
            eventTypes = CompositeEventType.validCases
            eventTypeIndex = eventTypes.firstIndex(where: {$0 == CompositeEventType(type.eventType, type.headToHead)})
            if eventTypeIndex == nil {
                // Not valid - set to first
                if eventTypes.isEmpty {
                    eventTypeIndex = -1
                    type.eventType = .unknown
                    type.headToHead = false
                } else {
                    eventTypeIndex = 0
                    type.eventType = eventTypes[0].eventType
                    type.headToHead = eventTypes[0].headToHead
                }
            }
        }
        if updateFrom <= .boardScoringType {
            scoreTypes = type.validScoreTypes
            scoreTypeIndex = scoreTypes.firstIndex(where: {$0 == type.boardScoreType})
            if scoreTypeIndex == nil {
                // Not valid - set to first
                if scoreTypes.isEmpty {
                    scoreTypeIndex = -1
                    type.boardScoreType = .unknown
                } else {
                    scoreTypeIndex = 0
                    type.boardScoreType = scoreTypes[0]
                }
            }
        }
        if updateFrom <= .aggregateType {
            aggregateTypes = aggregateTypeList
            aggregateTypeIndex = aggregateTypes.firstIndex(where: {$0 == type.aggregateType})
            if aggregateTypeIndex == nil {
                // Not valid - set to first
                if aggregateTypes.isEmpty {
                    aggregateTypeIndex = -1
                    type.aggregateType = .unknown
                } else {
                    aggregateTypeIndex = 0
                    type.aggregateType = aggregateTypes[0]
                }
            }
        }
    }
    
    var aggregateTypeList: [AggregateType] {
        var aggregateTypeList = type.validAggregateTypes
        if let vpIndex = aggregateTypeList.firstIndex(where: {$0 ~= .vp(type: .unknown)}) {
            aggregateTypeList.remove(at: vpIndex)
            let vpTypeList = type.validVpTypes(overrideType: .vp(type: .unknown)).map{AggregateType.vp(type: $0)}
            if !vpTypeList.isEmpty {
                aggregateTypeList.insert(contentsOf: vpTypeList, at: vpIndex)
            }
        }
        return aggregateTypeList
    }
}

struct ScorecardTypePrompt : View {
    @Binding var type: ScorecardType
    var inLineTitleWidth: CGFloat = 180
    var onTapGesture: ()->()
    
    var body: some View {
        HStack {
            HStack {
                Spacer().frame(width: 8)
                Text("Scoring")
                Spacer()
            }
            .frame(width: inLineTitleWidth)
            Spacer().frame(width: 20)
            Text(type.string)
                .foregroundColor(!Scorecard.current.isImported ? Palette.input.themeText : Palette.input.text)
                .font(inputFont)
                .frame(maxHeight: inputDefaultHeight)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(!Scorecard.current.isImported ? Palette.input.themeText : Palette.input.text)
            Spacer().frame(width: 16)
        }
        .frame(height: 45)
        .contentShape(Rectangle())
        .onTapGesture {
            if !Scorecard.current.isImported {
                withAnimation(.linear(duration: 0.25)) {
                    onTapGesture()
                }
            }
        }
    }
}
