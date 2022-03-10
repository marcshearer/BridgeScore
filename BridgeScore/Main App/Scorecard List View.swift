//
//  Scorecard List View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 21/01/2022.
//

import SwiftUI

struct ScorecardListView: View {
    @StateObject private var selected = ScorecardViewModel()
    @StateObject private var filterValues = ScorecardFilterValues()
    @ObservedObject private var data = MasterData.shared
    @State private var title = "Scorecards"
    @State private var layout = LayoutViewModel()
    @State private var layoutSelected = false
    @State private var linkToNew = false
    @State private var linkToEdit = false
    @State private var linkToLayouts = false
    @State private var linkToPlayers = false
    @State private var linkToLocations = false
    @State private var highlighted = false
    @State private var startAt: UUID?
    @State private var closeFilter = false

    var body: some View {
        let scorecards = MasterData.shared.scorecards.filter({self.filter($0)})
        
        let menuOptions = [BannerOption(text: "Templates", action: { linkToLayouts = true }),
                           BannerOption(text: "Players",  action: { linkToPlayers = true }),
                           BannerOption(text: "Locations", action: { linkToLocations = true }),
                           BannerOption(text: "Backup", action: { Backup.shared.backup() }),
                           /* BannerOption(text: "Restore", action: {
                              Backup.shared.restore(dateString: "2022-02-10-15-10-42-407") }),*/
                           BannerOption(text: "About \(appName)", action: { MessageBox.shared.show("A Bridge scoring app from\nShearer Online Ltd", showIcon: true, showVersion: true) })]
        
        StandardView("Scorecard List", navigation: true) {
            
            VStack {
                Banner(title: $title, back: false, optionMode: .menu, menuTitle: "Setup", options: menuOptions)
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
                    Spacer().frame(height: 8)
                    ScorecardFilterView(values: filterValues, closeFilter: $closeFilter)
                    ScrollViewReader { scrollViewProxy in
                        LazyVStack {
                            ForEach(scorecards) { (scorecard) in
                                ScorecardSummaryView(scorecard: scorecard, highlighted: highlighted)
                                    .id(scorecard.scorecardId)
                                    .onTapGesture {
                                            // Copy this entry to current scorecard
                                        self.selected.copy(from: scorecard)
                                        Scorecard.current.load(scorecard: self.selected)
                                        self.linkAction()
                                    }
                            }
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
                Utility.mainThread {
                    if let scorecard = scorecards.first {
                        self.startAt = scorecard.scorecardId
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
            NavigationLink(destination: LayoutSetupView(), isActive: $linkToLayouts) {EmptyView()}
            NavigationLink(destination: PlayerSetupView(), isActive: $linkToPlayers) {EmptyView()}
            NavigationLink(destination: LocationSetupView(), isActive: $linkToLocations) {EmptyView()}
            NavigationLink(destination: ScorecardInputView(scorecard: selected), isActive: $linkToEdit) {EmptyView()}
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
    
    private func linkAction() {
        if !Scorecard.current.isSensitive {
            linkToEdit = true
        } else {
            LocalAuthentication.authenticate(reason: "You must authenticate to access the scorecard detail") {
                linkToEdit = true
            } failure: {
                Scorecard.current.clear()
            }
        }
    }
    
    private func filter(_ scorecard: ScorecardViewModel) -> Bool {
        var include = true
        if filterValues.searchText != "" {
            include = self.wordSearch(for: filterValues.searchText, in: scorecard.desc + " " + scorecard.comment)
        }
        
        if let partner = filterValues.partner {
            if partner != scorecard.partner {
                include = false
            }
        }

        if let location = filterValues.location {
            if location != scorecard.location {
                include = false
            }
        }

        if let dateFrom = filterValues.dateFrom {
            if scorecard.date < Date.startOfDay(from: dateFrom)! {
                include = false
            }
        }

        if let dateTo = filterValues.dateTo {
            if scorecard.date > Date.endOfDay(from: dateTo)! {
                include = false
            }
        }
        
        return include
    }
    
    private func wordSearch(for searchWords: String, in target: String) -> Bool {
        var result = true
        let searchList = searchWords.uppercased().components(separatedBy: " ")
        let targetList = target.uppercased().components(separatedBy: " ")
        
        for searchWord in searchList {
            var found = false
            for targetWord in targetList {
                if targetWord.starts(with: searchWord) {
                    found = true
                }
            }
            if !found {
                result = false
            }
        }
        
        return result
        
    }
}

struct ScorecardSummaryView: View {
    @ObservedObject var scorecard: ScorecardViewModel
    @State var highlighted: Bool
    
    var body: some View {
        let color = (highlighted ? Palette.highlightTile : Palette.tile)
        ListTileView(color: color) {
            GeometryReader { geometry in
                HStack {
                    VStack {
                        Spacer().frame(height: 4)
                        HStack {
                            HStack {
                                Text(scorecard.desc)
                                Spacer()
                                if scorecard.position != 0 && scorecard.entry != 0 {
                                    Text("\(scorecard.position) / \(scorecard.entry)")
                                        .frame(width: 100)
                                }
                                HStack {
                                    Spacer()
                                    if let score = scorecard.score {
                                        Text("\(score.toString(places: scorecard.type.matchPlaces))\(scorecard.type.matchSuffix(tables: scorecard.tables))")
                                    }
                                }
                                .frame(width: 150)
                                    
                                Spacer().frame(width: 30)
                            }
                            Spacer()
                        }
                        .minimumScaleFactor(0.7)
                        .foregroundColor(color.contrastText)
                        .font(.title)
                        Spacer()
                        HStack {
                            // Text(scorecard.date.toFullString()).font(.callout).bold()
                            Text(Utility.dateString(Date.startOfDay(from: scorecard.date)!, format: "dd MMM yyyy", style: .short, doesRelativeDateFormatting: true)).font(.callout).bold()
                            Spacer()
                            HStack {
                                Text("With: ")
                                Text(scorecard.partner?.name ?? "").font(.callout).bold()
                                Spacer()
                            }
                            .frame(width: geometry.size.width * 0.3)
                            HStack {
                                Text("At: ")
                                Text(scorecard.location?.name ?? "").font(.callout).bold()
                                Spacer()
                            }
                            .frame(width: geometry.size.width * 0.37)
                        }
                        .foregroundColor(color.text)
                        .font(.callout)
                        .minimumScaleFactor(0.5)
                        Spacer().frame(height: 12)
                    }
                    VStack {
                        Spacer()
                        Button {
                            highlighted = true
                            MessageBox.shared.show("This will delete the scorecard permanently.\nAre you sure you want to do this?", cancelText: "Cancel", okText: "Confirm", cancelAction: {
                                highlighted = false
                            }, okAction: {
                                highlighted = false
                                scorecard.remove()
                            })
                        } label: {
                            Image(systemName: "trash.circle.fill").font(.largeTitle)
                                .foregroundColor(color.contrastText)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}
