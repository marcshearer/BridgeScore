//
//  Scorecard List View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 21/01/2022.
//

import SwiftUI

struct ScorecardListView: View {
    @State var title = "Scorecards"
    @State var scorecard = ScorecardViewModel()
    @State var layout = LayoutViewModel()
    @State var layoutSelected = false
    @State var linkToNew = false
    @State var linkToEdit = false
    @State var linkToLayouts = false
    @State var linkToPlayers = false
    @State var linkToLocations = false
    @ObservedObject var data = MasterData.shared
    
    var body: some View {
        let menuOptions = [BannerOption(text: "Standard layouts", action: { linkToLayouts = true }),
                           BannerOption(text: "Players",  action: { linkToPlayers = true }),
                           BannerOption(text: "Locations", action: { linkToLocations = true }),
                           BannerOption(text: "About \(appName)", action: { MessageBox.shared.show("A Bridge scoring app from\nShearer Online Ltd", showIcon: true, showVersion: true) })]
        
        StandardView(navigation: true) {
            let scorecards = data.scorecards.map{$1}.sorted(by: {$0.date > $1.date})
            
            VStack {
                Banner(title: $title, back: false, optionMode: .menu, menuTitle: "Setup", options: menuOptions)
                Spacer().frame(height: 12)
                
                ListTileView(color: Palette.contrastTile) { AnyView(
                    HStack {
                        Image(systemName: "plus.square")
                        Text("New Scorecard")
                    }
                )}
                .onTapGesture {
                    self.linkToNew = true
                }
                
                LazyVStack {
                    ForEach(scorecards) { (scorecard) in
                        ScorecardSummaryView(scorecard: scorecard)
                        .onTapGesture {
                            // Copy this entry to current scorecard
                            self.scorecard = scorecard
                            self.linkToEdit = true
                        }
                    }
                }
                
                Spacer()
            }
            .onAppear {
                if UserDefault.currentUnsaved.bool {
                    scorecard.restoreCurrent()
                    linkToEdit = true
                }
            }
            NavigationLink(destination: LayoutSetupView(), isActive: $linkToLayouts) {EmptyView()}
            NavigationLink(destination: ScorecardDetailView(scorecard: $scorecard), isActive: $linkToEdit) {EmptyView()}
        }
        .sheet(isPresented: $linkToNew, onDismiss: {
            print("Dismissed \(layoutSelected) \(layout.desc)")
            if layoutSelected {
                self.scorecard = ScorecardViewModel(layout: layout)
                self.linkToEdit = true
            }
        }) {
            LayoutListView(selected: $layoutSelected, layout: $layout)
        }
    }
}

struct ScorecardSummaryView: View {
    @ObservedObject var scorecard: ScorecardViewModel
    
    var body: some View {
        ListTileView(content: { AnyView(
            GeometryReader { geometry in
                AnyView(
                HStack {
                    VStack {
                        Spacer().frame(height: 10)
                        HStack {
                            HStack {
                                Text(scorecard.desc)
                                Spacer()
                                Text(scorecard.totalScore)
                                    
                                Spacer().frame(width: 30)
                            }
                            Spacer()
                        }
                        .foregroundColor(Palette.tile.text)
                        .font(.title)
                        Spacer()
                        HStack {
                            // Text(scorecard.date.toFullString()).font(.callout).bold()
                            Text(Utility.dateString(Date.startOfDay(from: scorecard.date)!, style: .short, doesRelativeDateFormatting: true, localized: false)).font(.callout).bold()
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
                        .foregroundColor(Palette.tile.contrastText)
                        .font(.callout)
                        .minimumScaleFactor(0.5)
                        Spacer().frame(height: 8)
                    }
                    VStack {
                        Spacer()
                        Button {
                            MessageBox.shared.show("This will delete the scorecard permanently.\nAre you sure you want to do this?", cancelText: "Cancel", okText: "Confirm", okAction: {
                                scorecard.remove()
                            })
                        } label: {
                            Image(systemName: "trash.circle.fill").font(.largeTitle)
                        }
                        Spacer()
                    }
                }
                )
            }
        )} )
        
    }
}

struct ListTileView: View {
    @State var color: PaletteColor = Palette.tile
    @State var font: Font = .largeTitle
    @State var content: (()->AnyView)

    var body: some View {
        VStack {
            Spacer().frame(height: 6)
            HStack {
                Spacer().frame(width: 16)
                HStack {
                    Spacer().frame(width: 16)
                    content()
                    Spacer()
                }
                .frame(height: 80)
                .background(color.background)
                .cornerRadius(16)
            Spacer().frame(width: 16)
            }
            Spacer().frame(height: 6)
        }
        .foregroundColor(color.text)
        .font(font)
    }
}

struct DefaultView_Previews: PreviewProvider {
    static var previews: some View {
        ScorecardListView()
    }
}
