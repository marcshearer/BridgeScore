//
//  Layout Setup View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 04/02/2022.
//

import SwiftUI

struct LayoutSetupView: View {
    @State private var title = "Layouts"
    @State private var layout: LayoutViewModel?
    
    var body: some View {
        StandardView() {
            VStack(spacing: 0) {
                Banner(title: $title, bottomSpace: false, back: true)
                DoubleColumnView {
                    LayoutSelectionView(layout: $layout)
                } rightView: {
                    if let layout = layout {
                        LayoutDetailView(layout: layout)
                    } else {
                        EmptyView()
                    }
                }
            }
        }
    }
}

struct LayoutSelectionView : View {
    @Binding var layout: LayoutViewModel?
    
    var body: some View {
        VStack {
            HStack {
                LazyVStack {
                    ForEach(MasterData.shared.layouts.compactMap{$0.value}.sorted(by: {$0.sequence < $1.sequence})) { layout in
                        VStack {
                            Spacer().frame(height: 16)
                            HStack {
                                Spacer().frame(width: 40)
                                Text(layout.desc)
                                    .font(.title)
                                Spacer()
                            }
                            Spacer().frame(height: 16)
                            Separator()
                        }
                        .background(Rectangle().fill(Palette.background.background))
                        .foregroundColor(Palette.background.text)
                        .onTapGesture {
                            self.layout = layout
                        }
                    }
                }
                Spacer()
            }
            Spacer()
        }
        .background(Palette.background.background)
    }
}

struct LayoutDetailView : View {
    @ObservedObject var layout: LayoutViewModel
    
    @State var minValue = 1
    
    var locations = MasterData.shared.locations.compactMap { $0.value }.sorted(by: {$0.sequence < $1.sequence})
    @State private var locationIndex: Int = 0
    
    let types = Type.allCases
    @State private var typeIndex: Int = 0
    
    let players = MasterData.shared.players.compactMap { $0.value }.sorted(by: {$0.sequence < $1.sequence})
    @State private var playerIndex: Int = 0
    var body: some View {
        VStack {
            HStack {
                VStack {
                    
                    InsetView(content: { AnyView( VStack {
                        
                        PickerInput(title: "Location", field: $locationIndex, values: locations.map {$0.name})
                        { index in
                            layout.location = locations[index]
                        }
                        
                        PickerInput(title: "Partner", field: $playerIndex, values: players.map {$0.name})
                        { index in
                            layout.partner = players[index]
                        }
                        
                        Input(title: "Description", field: $layout.desc, message: $layout.descMessage)
                        
                        Spacer().frame(height: 16)
                    })})
                    
                    InsetView(content: { AnyView( VStack {
                        
                        PickerInput(title: "Scoring Method", field: $typeIndex, values: types.map{$0.string})
                        { index in
                            layout.type = types[index]
                        }
                        
                        StepperInput(title: "Boards / Tables", field: $layout.boardsTable, label: { value in "\(value) boards per round" }, minValue: $minValue, width: 400) { (newValue) in
                            layout.boards = max(layout.boards, newValue)
                            layout.boards = max(newValue, ((layout.boards / newValue) * newValue))
                        }
                        
                        StepperInput(field: $layout.boards, label: boardsLabel, minValue: $layout.boardsTable, increment: $layout.boardsTable, topSpace: 0, width: 400)
                        
                        InputToggle(title: "Options", text: "Show table totals", field: $layout.tableTotal)
                        
                        Spacer().frame(height: 16)
                        
                    })})
                    
                    Spacer()
                }
                .onAppear {
                    locationIndex = locations.firstIndex(where: {$0 == layout.location}) ?? 0
                    playerIndex = players.firstIndex(where: {$0 == layout.partner}) ?? 0
                    typeIndex = types.firstIndex(where: {$0 == layout.type}) ?? 0
                }
            }
            Spacer()
        }
        .background(Palette.background.background)
    }
    
    func boardsLabel(boards: Int) -> String {
        let tables = boards / max(1, layout.boardsTable)
        return "\(tables) \(plural("table", tables)) - \(boards) \(plural("board", boards)) in total"
    }
    
    func plural(_ text: String, _ value: Int) -> String {
        return (value <= 1 ? text : text + "s")
    }
}

struct DoubleColumnView <LeftContent, RightContent> : View where LeftContent : View, RightContent : View {
    var leftView: LeftContent
    var rightView: RightContent
    var leftWidth: CGFloat = 300
    
    init(@ViewBuilder leftView: ()->LeftContent, @ViewBuilder rightView: ()->RightContent) {
        self.leftView = leftView()
        self.rightView = rightView()
    }
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                leftView
                Spacer()
            }
            .frame(width: leftWidth)
            Divider()
            VStack {
                rightView
                Spacer()
            }
            Spacer()
        }
    }
}

