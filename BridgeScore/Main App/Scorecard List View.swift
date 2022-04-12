//
//  Scorecard List View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 21/01/2022.
//

import SwiftUI

struct ScorecardListView: View {
    @Environment(\.verticalSizeClass) var sizeClass
    private let id = scorecardListViewId
    private let inputId = UUID()
    @StateObject private var selected = ScorecardViewModel(scorecardId: nullUUID)
    @StateObject private var filterValues = ScorecardFilterValues(.list)
    @ObservedObject private var data = MasterData.shared
    @State private var title = "Scorecards"
    @State private var layout = LayoutViewModel()
    @State private var layoutSelected = false
    @State private var linkToNew = false
    @State private var linkToEdit = false
    @State private var linkToLayouts = false
    @State private var linkToPlayers = false
    @State private var linkToLocations = false
    @State private var linkToStats = false
    @State private var linkToDownload = false
    @State private var highlighted = false
    @State private var startAt: UUID?
    @State private var closeFilter = false
    @State private var importScorecard: ImportSource = .none
    @State private var importTapped: ImportSource = .none

    var body: some View {
        let scorecards = MasterData.shared.scorecards.filter({filterValues.filter($0)})
        
        var menuOptions = [BannerOption(text: "Statistics", action: { linkToStats = true }),
                           BannerOption(text: "Templates", action: { linkToLayouts = true }),
                           BannerOption(text: "Players",  action: { linkToPlayers = true }),
                           BannerOption(text: "Locations", action: { linkToLocations = true }),
                           BannerOption(text: "Import BBO Names", action: { ImportBBO.importNames() }),
                           BannerOption(text: "Backup", action: { Backup.shared.backup() })]
        if Utility.isSimulator || true {
            menuOptions.append(
                           BannerOption(text: "Restore", action: {
                              Backup.shared.restore(dateString: "Latest") }))
        }
        menuOptions.append(contentsOf:
                          [BannerOption(text: "About \(appName)", action: { MessageBox.shared.show("A Bridge scoring app from\nShearer Online Ltd", showIcon: true, showVersion: true) })])
        
        return StandardView("Scorecard List", slideInId: id, navigation: true) {
            
            VStack {
                Banner(title: $title, back: false, optionMode: .menu, menuImage: AnyView(Image(systemName: "gearshape")), menuTitle: "Setup", menuId: id, options: menuOptions)
                Spacer().frame(height: 8)
                
                ListTileView(color: Palette.contrastTile) {
                    HStack {
                        Image(systemName: "plus.square")
                        Text("New Scorecard")
                    }
                }
                .onTapGesture {
                    self.linkToNew = true
                }
                
                ScrollView {
                    Spacer().frame(height: 4)
                    ScorecardFilterView(id: id, filterValues: filterValues, closeFilter: $closeFilter)
                    ScrollViewReader { scrollViewProxy in
                        LazyVStack {
                            ForEach(scorecards) { (scorecard) in
                                ScorecardSummaryView(slideInId: id, scorecard: scorecard, highlighted: highlighted, selected: selected, importTapped: $importTapped)
                                    .id(scorecard.scorecardId)
                                    .onTapGesture {
                                        // Copy this entry to current scorecard
                                        self.selected.copy(from: scorecard)
                                        linkAction()
                                    }
                            }
                        }
                        .onChange(of: importTapped) { (newValue) in
                            if newValue != .none {
                                linkAction(importTapped: newValue)
                            }
                            importTapped = .none
                        }
                        .onChange(of: self.startAt) { (newValue) in
                            if let newValue = newValue {
                                scrollViewProxy.scrollTo(newValue, anchor: .top)
                                startAt = nil
                            }
                        }
                        .onChange(of: self.closeFilter) { (newValue) in
                            if newValue {
                                if let scorecard = data.scorecards.first {
                                    self.startAt = scorecard.scorecardId
                                }
                                closeFilter = false
                            }
                        }
                    }
                }
                Spacer()
            }
            .onAppear {
                if selected.scorecardId == nullUUID {
                    Utility.mainThread {
                        if let scorecard = scorecards.first {
                            if  filterValues.isClear {
                                self.startAt = scorecard.scorecardId
                            }
                        }
                    }
                    if UserDefault.currentUnsaved.bool {
                        // Unsaved version - restore it and link to it
                        let scorecard = ScorecardViewModel()
                        scorecard.restoreCurrent()
                        self.selected.copy(from: scorecard)
                        Scorecard.current.load(scorecard: scorecard)
                        linkToEdit = true
                    }
                }
            }
            NavigationLink(destination: LayoutSetupView(), isActive: $linkToLayouts) {EmptyView()}
            NavigationLink(destination: PlayerSetupView(), isActive: $linkToPlayers) {EmptyView()}
            NavigationLink(destination: LocationSetupView(), isActive: $linkToLocations) {EmptyView()}
            NavigationLink(destination: StatsView(), isActive: $linkToStats) {EmptyView()}
            NavigationLink(destination: ScorecardInputView(scorecard: selected, importScorecard: importScorecard), isActive: $linkToEdit) {EmptyView()}
        }
        .sheet(isPresented: $linkToNew, onDismiss: {
            if layoutSelected {
                self.selected.reset(from: layout)
                Scorecard.current.load(scorecard: selected)
                linkToEdit = true
            }
        }) {
            LayoutListView(selected: $layoutSelected, layout: $layout)
        }
    }
    
    private func linkAction(importTapped: ImportSource = .none) {
        Scorecard.current.load(scorecard: self.selected)
        if !Scorecard.current.isSensitive {
            importScorecard = importTapped
            linkToEdit = true
        } else {
            LocalAuthentication.authenticate(reason: "You must authenticate to access the scorecard detail") {
                importScorecard = importTapped
                linkToEdit = true
            } failure: {
                Scorecard.current.clear()
            }
        }
    }
}

struct ScorecardSummaryView: View {
    @Environment(\.verticalSizeClass) var sizeClass

    var slideInId: UUID
    @ObservedObject var scorecard: ScorecardViewModel
    @State var highlighted: Bool
    @ObservedObject var selected: ScorecardViewModel
    @Binding var importTapped: ImportSource
    @State var selectImport = false
    @State var importSelected: Int?
    
    var body: some View {
        if MyApp.format == .phone && !isLandscape {
            portraitPhoneView
        } else {
            normalView
        }
    }
    
    var normalView: some View {
        let color = (highlighted ? Palette.highlightTile : Palette.tile)
        return ListTileView(color: color) {
            GeometryReader { geometry in
                HStack {
                    VStack {
                        Spacer().frame(height: 4)
                        HStack {
                            description
                            Spacer()
                            position.frame(width: 100)
                            score.frame(width: 150)
                            Spacer().frame(width: 30)
                        }
                        .minimumScaleFactor(0.7)
                        .foregroundColor(color.contrastText)
                        .font(.title)
                        HStack {
                            datePlayed
                            Spacer()
                            HStack {
                                playedWith
                                Spacer()
                            }
                            .frame(width: geometry.size.width * 0.3)
                            playedAt
                            .frame(width: geometry.size.width * 0.37)
                        }
                        .foregroundColor(color.text)
                        .font(.callout)
                        .minimumScaleFactor(0.5)
                        Spacer().frame(height: 12)
                    }
                    importButton
                    deleteButton
                }
            }
        }
    }
    
    var portraitPhoneView: some View {
        let color = (highlighted ? Palette.highlightTile : Palette.tile)
        return ListTileView(color: color, height: 120) {
            VStack {
                Spacer().frame(height: 4)
                HStack {
                    description
                    Spacer()
                    score
                }
                .minimumScaleFactor(0.7)
                .foregroundColor(color.contrastText)
                .font(.title)
                HStack {
                    VStack {
                        HStack {
                            datePlayed
                            Spacer()
                        }
                        Spacer().frame(height: 2)
                        HStack {
                            playedWith
                            Spacer()
                        }
                        Spacer().frame(height: 2)
                        HStack {
                            playedAt
                            Spacer()
                        }
                    }
                    .foregroundColor(color.text)
                    .font(.callout)
                    .minimumScaleFactor(0.5)
                    deleteButton
                    
                }
                Spacer().frame(height: 8)
            }
        }
    }
    
    var description: some View {
        HStack {
            let text = scorecard.desc + (scorecard.comment == "" || portraitPhone ? "" : " (\(scorecard.comment))")
            Text(text).lineLimit(portraitPhone ? 1 : 2)
                .if(MyApp.format == .phone) { (view) in
                    view.minimumScaleFactor(1)
                }
        }
    }
    
    var portraitPhone: Bool {
        MyApp.format == .phone && !isLandscape
    }
    
    var position: some View {
        HStack {
            if scorecard.position != 0 && scorecard.entry != 0 {
                Text("\(scorecard.position) / \(scorecard.entry)")
                    
            }
        }
    }
    
    var score: some View {
        HStack {
            if scorecard.score != nil {
                if !portraitPhone {
                    Text(scorecard.scoreString)
                } else {
                    Text(scorecard.score!.toString(places: scorecard.type.matchPlaces))
                }
            }
        }
    }
    
    var datePlayed: some View {
        Text(Utility.dateString(Date.startOfDay(from: scorecard.date)!, format: "dd MMM yyyy", style: .short, doesRelativeDateFormatting: true)).font(.callout).bold()
    }
    
    var playedWith: some View {
        HStack {
            if scorecard.type.players > 1 {
                HStack {
                    Text("With: ")
                    Text(scorecard.partner?.name ?? "").font(.callout).bold()
                    Spacer()
                }
            }
        }
    }
    
    var playedAt: some View {
        HStack {
            HStack {
                Text("At: ")
                Text(scorecard.location?.name ?? "").font(.callout).bold()
                Spacer()
            }
        }
    }
    
    var importButton: some View {
        let color = (highlighted ? Palette.highlightTile : Palette.tile)
        return HStack {
            if scorecard.importSource == .none {
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        PopupMenu(id: slideInId, field: $importSelected, values: ImportSource.validCases.map{$0.string}, animation: .none, top: geometry.frame(in: .global).minY - 30, left: geometry.frame(in: .global).minX - 290, width: 300) { (selectedIndex) in
                            if let selectedIndex = selectedIndex {
                                importTapped = ImportSource.validCases[selectedIndex]
                                selected.copy(from: scorecard)
                            }
                            importSelected = nil
                        } label: {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(color.contrastText)
                        }
                        Spacer()
                    }
                }
            }
        }
        .frame(width: 50)
    }
    
    var deleteButton: some View {
        button("trash.circle.fill") {
            highlighted = true
            MessageBox.shared.show("This will delete the scorecard permanently.\nAre you sure you want to do this?", cancelText: "Cancel", okText: "Confirm", cancelAction: {
                highlighted = false
            }, okAction: {
                highlighted = false
                scorecard.remove()
            })
        }
    }
    
    func button(_ imageName: String, action: @escaping ()->()) -> some View {
        let color = (highlighted ? Palette.highlightTile : Palette.tile)
        return VStack {
            Spacer()
            Button {
                action()
            } label: {
                Image(systemName: imageName)
                    .font(.largeTitle)
                    .foregroundColor(color.contrastText)
            }
            Spacer()
        }
    }
}
