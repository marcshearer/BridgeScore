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
    @State var linkToEdit = false
    @ObservedObject var data = MasterData.shared
    
    var body: some View {
        let menuOptions = [BannerOption(text: "Standard layouts", action: { }),
                           BannerOption(text: "Players",  action: {  }),
                           BannerOption(text: "Locations", action: { }),
                           BannerOption(text: "About \(appName)", action: { MessageBox.shared.show("A Bridge scoring app from\nShearer Online Ltd", showIcon: true, showVersion: true) })]
        
        StandardView(navigation: true) {
            let scorecards = data.scorecards.map{$1}.sorted(by: {$0.date > $1.date})
            
            VStack {
                Banner(title: $title, back: false, optionMode: .menu, options: menuOptions)
                Spacer().frame(height: 12)
                ListTileView(color: Palette.contrastTile) { AnyView(
                    HStack {
                        Image(systemName: "plus.square")
                        Text("New Scorecard")
                    }
                )}
                .onTapGesture {
                    self.scorecard = ScorecardViewModel()
                    self.scorecard.reset()
                    self.scorecard.backupCurrent()
                    self.linkToEdit = true
                }
                LazyVStack {
                    ForEach(scorecards) { (scorecard) in
                        ListTileView(content: { AnyView(
                            GeometryReader { geometry in
                                HStack {
                                    VStack {
                                        Spacer().frame(height: 10)
                                        HStack {
                                            Spacer().frame(width: 50)
                                            Text(scorecard.desc)
                                            Spacer()
                                        }
                                        .font(.title)
                                        Spacer()
                                        HStack {
                                            Spacer().frame(width: 50)
                                            HStack {
                                                Text("Partner: ")
                                                Text(scorecard.partner?.name ?? "").font(.callout).bold()
                                                Spacer()
                                            }
                                            .frame(width: geometry.size.width * 0.33)
                                            HStack {
                                                Text("Location: ")
                                                Text(scorecard.location?.name ?? "").font(.callout).bold()
                                                
                                                Spacer()
                                            }
                                            .frame(width: geometry.size.width * 0.30)
                                            Text("Date: ")
                                                // Text(scorecard.date.toFullString()).font(.callout).bold()
                                            Text(Utility.dateString(Date.startOfDay(from: scorecard.date)!, style: .short, doesRelativeDateFormatting: true, localized: false)).font(.callout).bold()
                                            Spacer()
                                        }
                                        .font(.callout)
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
                            }
                        )} )
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
            NavigationLink(destination: ScorecardDetailsView(scorecard: $scorecard), isActive: $linkToEdit) {EmptyView()}
        }
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
