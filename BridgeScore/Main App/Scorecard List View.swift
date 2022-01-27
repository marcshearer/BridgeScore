//
//  Scorecard List View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 21/01/2022.
//

import SwiftUI

struct ScorecardListView: View {
    @State var title = "Scorecards"
    @State var linkToNew = false
    @State var linkToEditScorecard: ScorecardViewModel?
    @State var linkToEdit = false
    
    var body: some View {
        let menuOptions = [BannerOption(text: "Standard layouts", action: { }),
                           BannerOption(text: "Players",  action: {  }),
                           BannerOption(text: "Locations", action: { })]
        StandardView(navigation: true) {
            VStack {
                Banner(title: $title, back: false, optionMode: .menu, options: menuOptions)
                Spacer().frame(height: 12)
                ListTileView(content: { AnyView( HStack {
                    Image(systemName: "plus.square")
                    Text("New Scorecard")
                })})
                .onTapGesture {
                    self.linkToNew = true
                }
                LazyVStack {
                    ForEach(MasterData.shared.scorecards.map{$1}) { (scorecard) in
                        ListTileView(content: { AnyView(Text("Scorecard")) } )
                        .onTapGesture {
                            self.linkToEdit = true
                            self.linkToEditScorecard = scorecard
                        }
                    }
                }
                Spacer()
            }
            NavigationLink(destination: NewScorecardView(), isActive: $linkToNew) {EmptyView()}
        }
    }
}

struct ListTileView: View {
    @State var content: (()->AnyView)
    @State var color: PaletteColor = Palette.tile
    @State var font: Font = .largeTitle
   
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
