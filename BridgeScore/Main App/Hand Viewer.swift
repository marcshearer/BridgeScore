//
//  Hand Viewer.swift
//  BridgeScore
//
//  Created by Marc Shearer on 28/08/2023.
//

import SwiftUI
import UIKit

struct HandViewerForm: View {
    @State var board: BoardViewModel
    @State var traveller: TravellerViewModel
    @State var sitting: Seat
    @State var from: UIView
    @State var bidAnnounce = ""
    @State var trickNumber = 0
    @State var deal = Deal()
    @State var tricks: [Trick] = []
    @State var visible = Array(repeating: false, count: 4)
    @State var animate = 0
    @State var showClaim = false
    
    var body: some View {
        
        StandardView("HandViewerForm") {
            VStack {
                HandViewer(board: $board, traveller: $traveller, sitting: $sitting, from: from, bidAnnounce: $bidAnnounce)
                Spacer().frame(height: 2)
                HandViewButtonBar()
                Spacer().frame(height: 2)
            }.background(Palette.handTable.background)
        }
    }
    
    struct HandViewButtonBar: View {
        @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
        var body: some View {
            VStack {
                
                Spacer()
                HStack {
                    Spacer()
                    HandViewButton(label: "Close", highlight: true) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    Spacer()
                }
                Spacer()
            }.frame(height: 80)
        }
        
        private func HandViewButton(label: String, highlight: Bool = false, disabled: (()->(Bool))? = { false }, action: @escaping ()->()) -> some View {
            
            VStack {
                let enabled = !(disabled?() ?? false)
                Button {
                    action()
                } label: {
                    let color = highlight ? Palette.highlightButton : (enabled ? Palette.enabledButton : Palette.disabledButton)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(label)
                            Spacer()
                        }
                        Spacer()
                    }.background(color.background).frame(width: 120, height: 50).foregroundColor(enabled ? color.text : color.faintText).cornerRadius(10).font(.title2).minimumScaleFactor(0.5)
                }.disabled(!enabled)
            }
        }
    }
}

struct HandViewer: View {
    @Binding var board: BoardViewModel
    @Binding var traveller: TravellerViewModel
    @Binding var sitting: Seat
    @State var from: UIView
    @Binding var bidAnnounce: String
    @State var trickNumber = 0
    @State var deal = Deal()
    @State var tricks: [Trick] = []
    @State var visible = Array(repeating: false, count: 4)
    @State var animate = 0
    @State var showClaim = false
    
    var body: some View {
        
        StandardView("HandViewer") {
            VStack {
                Spacer().frame(height: 10)
                HStack {
                    Spacer().frame(width: 10)
                    HandViewBoardDetails(board:$board, traveller: $traveller)
                    Spacer().frame(width: 10)
                    HandViewHand(board: $board, traveller: $traveller, sitting: $sitting, player: .partner, deal: $deal, trickNumber: $trickNumber)
                    Spacer().frame(width: 10)
                    if board.doubleDummy.count != 0 || board.optimumScore != nil {
                        HandViewOptimum(board: $board, sitting: $sitting)
                    } else {
                        Rectangle().fill(.clear)
                    }
                    Spacer().frame(width: 10)
                }
                Spacer().frame(height: 10)
                HStack() {
                    Spacer().frame(width: 10)
                    HandViewHand(board: $board, traveller: $traveller, sitting: $sitting, player: .lhOpponent, deal: $deal, trickNumber: $trickNumber)
                    Spacer().frame(width: 10)
                    VStack(spacing: 0) {
                        if trickNumber > 0 {
                            HandViewPlay(board: $board, traveller: $traveller, sitting: $sitting, tricks: $tricks, trickNumber: $trickNumber, visible: $visible, animate: $animate, showClaim: $showClaim)
                        } else {
                            Rectangle().fill(.clear)
                        }
                    }.cornerRadius(6)
                    Spacer().frame(width: 10)
                    HandViewHand(board: $board, traveller: $traveller, sitting: $sitting, player: .rhOpponent, deal: $deal, trickNumber: $trickNumber)
                    Spacer().frame(width: 10)
                }
                Spacer().frame(height: 10)
                HStack {
                    Spacer().frame(width: 10)
                    HandViewBidding(board: $board, traveller: $traveller, sitting: $sitting, bidAnnounce: $bidAnnounce, showClaim: $showClaim)
                    Spacer().frame(width: 10)
                    HandViewHand(board: $board, traveller: $traveller, sitting: $sitting, player: .player, deal: $deal, trickNumber: $trickNumber)
                    Spacer().frame(width: 10)
                    VStack {
                        ZStack {
                            Rectangle().fill(.clear)
                            if tricks.count > 0 || traveller.playData != "" {
                                VStack {
                                    if showClaim || bidAnnounce == "" {
                                        HandViewTrickCount(traveller: $traveller, sitting: $sitting, tricks: $tricks, trickNumber: $trickNumber, showClaim: $showClaim, declarer: traveller.declarer)
                                    } else {
                                        HandViewBidAnnounce(announce: $bidAnnounce)
                                    }
                                    Spacer()
                                    if tricks.count > 0 {
                                        HandViewPlayerBar(board: $board, traveller: $traveller, from: $from, tricks: $tricks, trickNumber: $trickNumber, visible: $visible, animate: $animate, showClaim: $showClaim, bidAnnounce: $bidAnnounce)
                                            .frame(height: 50)
                                    }
                                }.overlay(RoundedRectangle(cornerRadius: 4).stroke(Palette.separator.background,  lineWidth: 2))
                            }
                        }
                    }
                    Spacer().frame(width: 10)
                }
                Spacer().frame(height: 10)
            }.background(Palette.handTable.background)
        }
        .onAppear() {
            reflectChange()
        }
        .onChange(of: board.boardNumber) { boardNumber in
            reflectChange()
        }
        .onChange(of: traveller) { traveller in
            reflectChange()
        }
    }
    
    func reflectChange() {
        trickNumber = 0
        deal = constructCards(cards: board.hand, playData: traveller.playData)
        tricks = constructTricks(playData: traveller.playData, declarer: traveller.declarer, trumps: traveller.contract.suit)
        setTrick(deal: deal, tricks: tricks)
    }
    
    func constructCards(cards: String, playData: String) -> Deal {
        var cardArray: [String] = []
        
        if cards == "" {
            let data = playData.removingPercentEncoding!.components(separatedBy: "|")
            for (index, element) in data.enumerated() {
                if element == "md" && index + 1 < data.count {
                    let handData = data[index + 1]
                    let cardData = handData.mid(2, handData.count - 1).components(separatedBy: ",")
                    cardArray = constructHand(cards: cardData[2]) + ["", "", "", ""] + constructHand(cards: cardData[0]) + constructHand(cards: cardData[1])
                    cardArray = addFourthHand(hands: cardArray, index: 1)
                }
            }
        } else {
            cardArray = cards.replacingOccurrences(of: "-", with: "").components(separatedBy: ",")
        }
        return Deal(fromCards: cardArray)
    }
    
    func constructHand(cards: String) -> [String] {
        var suitData: [String] = cards.replacingOccurrences(of: "S", with: ",").replacingOccurrences(of: "H", with: ",").replacingOccurrences(of: "D", with: ",").replacingOccurrences(of: "C", with: ",").components(separatedBy: ",")
        for (index, suit) in suitData.enumerated() {
            suitData[index] = String(suit.reversed())
        }
        suitData.remove(at: 0)
        return suitData
    }
    
    func addFourthHand(hands: [String], index fourthIndex: Int) -> [String] {
        var result: [String] = hands
        for suit in 0...3 {
            result[(fourthIndex * 4) + suit] = "AKQJT98765432"
            for index in 0...3 {
                if index != fourthIndex {
                    for char in hands[(index * 4) + suit] {
                        result[(fourthIndex * 4) + suit].removeAll(where: {$0 == char})
                    }
                }
            }
        }
        return result
    }
    
    func constructTricks(playData: String, declarer: Seat, trumps: Suit) -> [Trick] {
        let data = playData.removingPercentEncoding!.components(separatedBy: "|")
        var tricks: [Trick] = []
        var nsTricks = 0
        var cards: [Card] = []
        
        func saveLast() {
            if let last = tricks.last {
                if !cards.isEmpty {
                    last.cards = cards
                    last.winner = winner(trick: last, trumps: trumps, lead: last.lead)
                    if last.winner.pair == .ns {
                        nsTricks += 1
                    }
                    last.nsTricks = nsTricks
                }
            }
        }
        
        
        for (index, element) in data.enumerated() {
            if element == "pc" && index + 1 < data.count {
                let played = data[index + 1]
                if tricks.count == 0 || cards.count == 4 {
                    saveLast()
                    let lead = tricks.last?.winner ?? declarer.leftOpponent
                    tricks.append(Trick(trick: tricks.count + 1, lead: lead, cards: cards, winner: .unknown, nsTricks: 0))
                    cards = []
                }
                cards.append(Card(rankString: played.right(1), suitString: played.left(1)))
            }
        }
        saveLast()
        return tricks
    }
    
    func winner(trick: Trick, trumps: Suit, lead: Seat) -> Seat {
        let cards = trick.cards
        if trick.cards.count < 4 {
            return .unknown
        } else {
            var winner = 0
            for card in 1...3 {
                if (cards[card].suit == cards[winner].suit && (cards[card].rank > cards[winner].rank) || (cards[card].suit == trumps && cards[winner].suit != trumps)) {
                    winner = card
                }
            }
            return lead.offset(by: winner)
        }
    }
    
    func setTrick(deal: Deal, tricks: [Trick]) {
        for (_, hand) in deal.hands {
            for card in hand.cards {
                if let trick = tricks.first(where: {$0.cards.contains(card)}) {
                    card.data = trick.trickNumber
                } else {
                    card.data = 14
                }
            }
        }
    }
        
    struct HandViewPlayerBar: View {
        @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
        @Binding var board: BoardViewModel
        @Binding var traveller: TravellerViewModel
        @State var from: Binding<UIView>
        @Binding var tricks: [Trick]
        @Binding var trickNumber: Int
        @Binding var visible: [Bool]
        @Binding var animate: Int
        @Binding var showClaim: Bool
        @Binding var bidAnnounce: String
        @State var sliderValue = 0.0
        
        var body: some View {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HandViewPlayerButton(name: "backward.frame", disabled: {trickNumber <= 0}) {
                        bidAnnounce = ""
                        showClaim = false
                        for index in 0..<visible.count {
                            visible[index] = false
                        }
                        trickNumber -= 1
                        Utility.executeAfter(delay: 0.01) {
                            animate += 1
                        }
                    }
                    Spacer().frame(width: 6)
                    Slider(value: $sliderValue, in: 0...Double(tricks.count), step: 1.0, onEditingChanged: { editing in
                        if !editing {
                            if trickNumber != Int(sliderValue) {
                                trickNumber = Int(sliderValue)
                                bidAnnounce = ""
                                for index in 0..<visible.count {
                                    visible[index] = false
                                }
                                showClaim = (trickNumber >= tricks.count || (trickNumber == tricks.count - 1 && tricks[trickNumber - 1].cards.count < 3))
                                Utility.executeAfter(delay: 0.01) {
                                    animate += 1
                                }
                            }
                        }
                    })
                    Spacer().frame(width: 6)
                    HandViewPlayerButton(name: "forward.frame", disabled: {trickNumber >= tricks.count}) {
                        bidAnnounce = ""
                        for index in 0..<visible.count {
                            visible[index] = false
                        }
                        trickNumber += 1
                        showClaim = (trickNumber >= tricks.count || (trickNumber == tricks.count - 1 && tricks[trickNumber - 1].cards.count < 3))
                        Utility.executeAfter(delay: 0.01) {
                            animate += 1
                        }
                    }
                    Spacer()
                }
                Spacer()
            }
            .onChange(of: trickNumber) { trickNumber in
                sliderValue = Double(trickNumber)
            }
        }
        
        private func HandViewPlayerButton(name: String, disabled: (()->(Bool))? = { false }, action: @escaping ()->()) -> some View {
            
            VStack {
                let enabled = !(disabled?() ?? false)
                Button {
                    action()
                } label: {
                    Image(systemName: name).font(.title).foregroundColor((enabled ? Palette.listButton : Palette.disabledButton).background)
                }.disabled(!enabled)
            }
        }
    }
    
    struct HandViewBoardDetails: View {
        @Binding var board: BoardViewModel
        @Binding var traveller: TravellerViewModel
        
        var body: some View {
            ZStack {
                Rectangle().fill(.clear)
                HStack {
                    Spacer().frame(width: 10)
                    VStack {
                        Spacer().frame(height: 10)
                        if Scorecard.current.scorecard!.resetNumbers {
                            HStack {
                                Text("Table:")
                                Spacer()
                            }
                        }
                        HStack {
                            Text("Board:")
                            Spacer()
                        }
                        HStack {
                            Text("Dealer:")
                            Spacer()
                        }
                        HStack {
                            Text("Vul:")
                            Spacer()
                        }
                        HStack {
                            Text("Contract:")
                            Spacer()
                        }
                        if traveller.contract.level != .passout {
                            HStack {
                                Text("Declarer:")
                                Spacer()
                            }
                            HStack {
                                Text("Made:")
                                Spacer()
                            }
                        }
                        Spacer()
                    }.foregroundColor(Palette.handTable.contrastText).frame(width: 100)
                    Spacer().frame(width: 10)
                    VStack {
                        Spacer().frame(height: 10)
                        if Scorecard.current.scorecard!.resetNumbers {
                            HStack {
                                Text("\(board.tableNumber)")
                                Spacer()
                            }
                        }
                        HStack {
                            Text("\(board.board)")
                            Spacer()
                        }
                        HStack {
                            Text("\(board.dealer.string)")
                            Spacer()
                        }
                        HStack {
                            Text("\(board.vulnerability.string)")
                            Spacer()
                        }
                        HStack {
                            Text("\(traveller.contract.colorCompact)")
                            Spacer()
                        }
                        if traveller.contract.level != .passout {
                            HStack {
                                Text("\(traveller.declarer.string)")
                                Spacer()
                            }
                            HStack {
                                Text((traveller.made == 0 ? "=" : (
                                    traveller.made > 0 ? "+\(traveller.made)" : (
                                        "\(traveller.made)"))))
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    .foregroundColor(Palette.handTable.text)
                    Spacer().frame(width: 2)
                }.font(.title3).overlay(RoundedRectangle(cornerRadius: 4).stroke(Palette.separator.background,  lineWidth: 2)).lineLimit(1).minimumScaleFactor(0.5)
            }
        }
    }
    
    struct HandViewBidAnnounce: View {
        @Binding var announce: String
        
        var body: some View {
            if announce != "" {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack {
                            Spacer().frame(width: 10)
                            VStack {
                                Spacer().frame(height: 10)
                                Text("Explanation:").foregroundColor(Palette.handTable.contrastText)
                                Text(announce).foregroundColor(Palette.handTable.text)
                                Spacer().frame(height: 10)
                            }
                            Spacer().frame(width: 10)
                        }.font(.title2)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
    
    struct HandViewHand: View {
        @Binding var board: BoardViewModel
        @Binding var traveller: TravellerViewModel
        @Binding var sitting: Seat
        @State var player: SeatPlayer
        @Binding var deal: Deal
        @Binding var trickNumber: Int
        
        var body: some View {
            ZStack {
                Rectangle().fill(Palette.handCards.background).cornerRadius(6)
                VStack {
                    ZStack {
                        Rectangle().fill(Palette.handPlayer.background).frame(height: 50)
                        HStack{
                            Spacer().frame(width: 10)
                            Text(sitting.seatPlayer(player).short).font(.title).bold().foregroundColor(Palette.handPlayer.text)
                            Spacer().frame(width: 10)
                            Text(name).font(.title).minimumScaleFactor(0.2).lineLimit(1).foregroundColor(Palette.handPlayer.contrastText)
                            Spacer()
                        }
                    }
                    ForEach((Suit.realSuits).reversed(), id: \.self) { suit in
                        HandViewSuit(board: $board, traveller: $traveller, suit: suit, deal: $deal, sitting: $sitting, player: player, trickNumber: $trickNumber)
                    }
                    Spacer()
                    
                }.cornerRadius(6)
            }
        }
        
        var start: Int {
            return (sitting.seatPlayer(player).rawValue - 1) * 4
        }
        
        var name: String {
            var name = "Unknown"
            if let ranking = traveller.ranking(seat: sitting.seatPlayer(player)) {
                name = (ranking.players[sitting.seatPlayer(player)] ?? name)
                if Scorecard.current.scorecard?.importSource == .bbo {
                    if let realName = MasterData.shared.realName(bboName: name) {
                        name = realName
                    }
                }
            }
            return name
        }
    }
    
    struct HandViewSuit: View {
        @Binding var board: BoardViewModel
        @Binding var traveller: TravellerViewModel
        @State var suit: Suit
        @Binding var deal: Deal
        @Binding var sitting: Seat
        @State var player: SeatPlayer
        @Binding var trickNumber: Int
        
        var body: some View {
            VStack {
                Spacer().frame(height: 4)
                HStack(spacing: 2) {
                    Spacer().frame(width: 4)
                    Text(suit.colorString).font(.title2).minimumScaleFactor(0.2).frame(minWidth: 24)
                    Spacer().frame(width: 1)
                    if let cards = deal.hands[sitting.seatPlayer(player)]?.xrefSuit[suit]?.cards {
                        if cards.reduce(false, {$0 || trickNumber < ($1.data as! Int)}) {
                            ForEach(0..<cards.count, id: \.self) { index in
                                if trickNumber < cards[index].data as! Int {
                                    Text(cards[index].rankString).font(.title2).minimumScaleFactor(0.2)
                                }
                            }
                        } else {
                            Text("A").font(.title2).minimumScaleFactor(0.2).foregroundColor(.clear)
                        }
                    }
                    Spacer()
                }
            }
        }
    }
    
    struct HandViewBidding : View {
        @Binding var board: BoardViewModel
        @Binding var traveller: TravellerViewModel
        @Binding var sitting: Seat
        @Binding var bidAnnounce: String
        @Binding var showClaim: Bool
        
        var body: some View {
            ZStack {
                Rectangle().fill(.clear)
                if traveller.playData != "" {
                    VStack {
                        HandViewBiddingTitles(board: $board, sitting: $sitting)
                        HandViewBiddingBids(board: $board, traveller: $traveller, sitting: $sitting, bidAnnounce: $bidAnnounce, showClaim: $showClaim)
                        Spacer()
                    }.cornerRadius(6).overlay(RoundedRectangle(cornerRadius: 4).stroke(Palette.separator.background,  lineWidth: 2))
                }
            }
        }
    }
    
    struct HandViewBiddingTitles: View {
        @Binding var board: BoardViewModel
        @Binding var sitting: Seat
        
        var body: some View {
            HStack {
                ForEach(Seat.validCases, id: \.self) { seat in
                    let seat = seat.offset(by: sitting.rawValue - 1)
                    let vulnerable = board.vulnerability.isVulnerable(seat: seat)
                    ZStack {
                        HStack(spacing: 0) {
                            if seat != sitting {
                                Rectangle().foregroundColor(Palette.handBidding.background).frame(width: 3, height: 30)
                            }
                            Rectangle().frame(height: 30).foregroundColor(vulnerable ? Palette.vulnerable.background : Palette.nonVulnerable.background)
                        }
                        HStack {
                            Spacer()
                            Text(seat.short).foregroundColor(vulnerable ? Palette.vulnerable.text : Palette.nonVulnerable.text).bold()
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    struct HandViewBiddingBids: View {
        @Binding var board: BoardViewModel
        @Binding var traveller: TravellerViewModel
        @Binding var sitting: Seat
        @Binding var bidAnnounce: String
        @Binding var showClaim: Bool
        
        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack {
                    let bids = bids
                    if !bids.isEmpty {
                        ForEach(0...((bids.count - 1) / 4), id: \.self) { row in
                            HStack {
                                ForEach(0...3, id: \.self) { column in
                                    let index = (row * 4) + column
                                    HStack {
                                        Spacer().frame(width: 1)
                                        if index < bids.count {
                                            let (bid, alert, announce) = bids[index]
                                            VStack {
                                                Spacer().frame(height: 2)
                                                HStack {
                                                    Spacer()
                                                    Text(bid).bold().lineLimit(1).minimumScaleFactor(0.4)
                                                    Spacer()
                                                }
                                                .onTapGesture {
                                                    showClaim = false
                                                    bidAnnounce = announce ?? ""
                                                }
                                                Spacer().frame(height: 1)
                                            }.background((announce ?? "") != "" ? Palette.card.background : .clear).foregroundColor((announce ?? "") != "" ? Palette.card.text : Palette.handBidding.text).cornerRadius(4).overlay(RoundedRectangle(cornerRadius: 4).stroke(Palette.handBidding.strongText,  lineWidth: (alert ? 2 : 0)))
                                        } else {
                                            HStack {
                                                Spacer()
                                                Text("")
                                                Spacer()
                                            }
                                            Spacer().frame(width: 1)
                                        }
                                        Spacer().frame(width: 1)
                                    }
                                }
                            }
                            Spacer().frame(height: 5)
                        }
                    }
                }.background(Palette.handBidding.background).foregroundColor(Palette.handBidding.contrastText)
            }
        }
        
        var bids: [(AttributedString, Bool, String?)] {
            var result: [(AttributedString, Bool, String?)] = []
            let tokens = traveller.playData.removingPercentEncoding!.components(separatedBy: "|")
            let skip = sitting.offset(to: board.dealer)
            if skip > 0 {
                for _ in 1...skip {
                    result.append(("", false, nil))
                }
            }
            for (index, token) in tokens.enumerated() {
                if token == "mb" {
                    var bid = tokens[index + 1]
                    var alert = false
                    if bid.contains("!") {
                        alert = true
                        bid = bid.replacingOccurrences(of: "!", with: "")
                    }
                    var announce = ""
                    if index + 3 < tokens.count {
                        if tokens[index + 2] == "an" {
                            announce = tokens [index + 3]
                        }
                    }
                    result.append((replace(bid: bid), alert, announce))
                }
            }
            return result
        }
        
        func replace(bid: String) -> AttributedString {
            let bid = bid.uppercased()
            var result: AttributedString
            
            switch bid {
            case "P":
                result = AttributedString("Pass")
            case "D":
                result = AttributedString("Dbl")
            case "R":
                result = AttributedString("Rdbl")
            default:
                if bid.right(2) == "NT" {
                    result = AttributedString(bid)
                } else {
                    result = AttributedString(bid.left(1)) + Suit(string: bid.right(1)).colorString
                }
            }
            return result
        }
    }
    
    struct HandViewPlay : View {
        @Binding var board: BoardViewModel
        @Binding var traveller: TravellerViewModel
        @Binding var sitting: Seat
        @Binding var tricks: [Trick]
        @Binding var trickNumber: Int
        @Binding var visible: [Bool]
        @Binding var animate: Int
        @Binding var showClaim: Bool
        let interval = 0.2
        let height = 40.0
        let width = 70.0
        
        var body: some View {
            ZStack {
                Rectangle().fill(.clear)
                let trick = tricks[max(0, trickNumber - 1)]
                VStack {
                    Spacer()
                    HStack(spacing: 0) {
                        if visible[0] {
                            let cardNumber = trick.lead.offset(to: sitting.partner)
                            if cardNumber < trick.cards.count {
                                HStack(spacing: 0) {
                                    Spacer()
                                    Text(trick.cards[cardNumber].colorString)
                                    Spacer()
                                }.frame(width: width, height: height).background(Palette.card.background).cornerRadius(4).transition(.opacity)
                            }
                        }
                    }.frame(width: width, height: height)
                    Spacer().frame(height: 20)
                    HStack {
                        Spacer().frame(width: 10)
                        HStack(spacing: 0) {
                            if visible[3] {
                                let cardNumber = trick.lead.offset(to: sitting.leftOpponent)
                                if cardNumber < trick.cards.count {
                                    HStack(spacing: 0) {
                                        Spacer()
                                        Text(trick.cards[cardNumber].colorString)
                                        Spacer()
                                    }.frame(width: width, height: height).background(Palette.card.background).cornerRadius(4).transition(.opacity)
                                }
                            }
                        }.frame(width: width, height: height)
                        Spacer()
                        HStack(spacing: 0) {
                            if visible[1] {
                                let cardNumber = trick.lead.offset(to: sitting.rightOpponent)
                                if cardNumber < trick.cards.count {
                                    HStack(spacing: 0) {
                                        Spacer()
                                        Text(trick.cards[cardNumber].colorString)
                                        Spacer()
                                    }.frame(width: width, height: height).background(Palette.card.background).cornerRadius(4).transition(.opacity)
                                }
                            }
                        }.frame(width: width, height: height)
                        Spacer().frame(width: 10)
                    }
                    Spacer().frame(height: 20)
                    HStack {
                        HStack(spacing: 0) {
                            if visible[2] {
                                let cardNumber = trick.lead.offset(to: sitting)
                                if cardNumber < trick.cards.count {
                                    HStack(spacing: 0) {
                                        Spacer()
                                        Text(trick.cards[cardNumber].colorString)
                                        Spacer()
                                    }.frame(width: width, height: height).background(Palette.card.background).cornerRadius(4).transition(.opacity)
                                }
                            }
                        }.frame(width: width, height: height)
                    }
                    Spacer()
                }.font(.title2).bold()
            }.onChange(of: animate) { newValue in
                animation()
            }
            .onAppear {
                animation()
            }
        }
        
        func animation() {
            let start = sitting.partner.offset(to: tricks[max(0, trickNumber - 1)].lead)
            withAnimation(.linear(duration: interval)) {
                visible[start % 4] = true
            }
            withAnimation(.linear(duration: interval).delay(interval)) {
                visible[(start + 1) % 4] = true
            }
            withAnimation(.linear(duration: interval).delay(interval * 2)) {
                visible[(start + 2) % 4] = true
            }
            withAnimation(.linear(duration: interval).delay(interval * 3)) {
                visible[(start + 3) % 4] = true
            }
        }
    }
    
    struct HandViewTrickCount: View {
        @Binding var traveller: TravellerViewModel
        @Binding var sitting: Seat
        @Binding var tricks: [Trick]
        @Binding var trickNumber: Int
        @Binding var showClaim: Bool
        @State var declarer: Seat
        
        var body: some View {
            HStack {
                Spacer().frame(width: 10)
                Spacer()
                HStack {
                    Spacer().frame(width: 2)
                    VStack {
                        Spacer().frame(height: 30)
                        if trickNumber == 0 {
                            VStack {
                                HStack {
                                    Spacer()
                                    Text(traveller.contract.colorCompact)
                                    if traveller.contract.level != .passout {
                                        HStack(spacing: 0) {
                                            Text("\(traveller.declarer.short) ")
                                            Text((traveller.made == 0 ? "=" : (
                                                traveller.made > 0 ? "+\(traveller.made)" : (
                                                    "\(traveller.made)"))))
                                        }
                                    }
                                    Spacer()
                                }.foregroundColor(Palette.handTable.text).bold().font(bannerFont)
                                if traveller.contract.level != .passout {
                                    Spacer().frame(height: 20)
                                    HStack {
                                        if traveller.contract.level != .passout {
                                            if sitting.pair != traveller.declarer.pair {
                                                Text("Defence")
                                            } else if sitting == traveller.declarer {
                                                Text("Declarer")
                                            } else {
                                                Text("Dummy")
                                            }
                                        }
                                    }.foregroundColor(Palette.handTable.contrastText).font(defaultFont)
                                }
                            }
                        } else if showClaim || trickNumber == 13 {
                            Text("\(Values.trickOffset + traveller.contractLevel + traveller.made) tricks \(trickNumber != 0 && trickNumber < 13 ? "agreed" : "made")").foregroundColor(Palette.handTable.text).bold()
                            Spacer().frame(height: 10)
                            Text((traveller.made == 0 ? "Made exactly" : (traveller.made < 0 ? "Down " : "Made plus ") + "\(abs(traveller.made))"))
                        } else {
                            let trick = tricks[max(0, trickNumber - 1)]
                            HStack {
                                Spacer()
                                Text("Tricks made").foregroundColor(Palette.handTable.text).bold()
                                Spacer()
                            }
                            Spacer().frame(height: 20)
                            HStack {
                                Spacer()
                                HStack {
                                    Text("Declarer: ")
                                    Spacer()
                                }.frame(width: 100)
                                Text("\(declarer.pair == .ns ?  trick.nsTricks : trick.trickNumber - trick.nsTricks)")
                                Spacer()
                            }
                            HStack {
                                Spacer()
                                HStack {
                                   
                                    Text("Defence: ")
                                    Spacer()
                                }.frame(width: 100)
                                Text("\(declarer.pair == .ew ?  trick.nsTricks : trick.trickNumber - trick.nsTricks)")
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    .foregroundColor(Palette.handTable.contrastText)
                    Spacer()
                }
                Spacer().frame(width: 10)
            }.font(.title2).minimumScaleFactor(0.5).lineLimit(1).minimumScaleFactor(0.5)
        }
    }
    
    struct HandViewOptimum: View {
        @Binding var board: BoardViewModel
        @Binding var sitting: Seat
        
        var body: some View {
            ZStack {
                Rectangle().fill(.clear)
                HStack {
                    Spacer().frame(width: 4)
                    VStack {
                        Spacer().frame(height: 5)
                        if board.doubleDummy.count > 0 {
                            HStack {
                                Text("").frame(width: 20)
                                ForEach(Suit.validCases, id: \.self) { suit in
                                    Spacer()
                                    Text(suit.colorString).frame(width:20).font(.title2)
                                }
                            }
                            ForEach([Seat.north, Seat.south, Seat.east, Seat.west], id: \.self) { declarer in
                                Spacer().frame(height: 4)
                                HStack {
                                    Text(declarer.short).frame(width: 20).bold()
                                    ForEach(Suit.validCases, id: \.self) { suit in
                                        Spacer()
                                        let made = board.doubleDummy[declarer]?[suit]?.made ?? 0
                                        Text(made >= 7 ? "\(made - Values.trickOffset)" : "-").frame(width:20).foregroundColor(Palette.handTable.text)
                                    }
                                }.font(.body).bold()
                            }
                        }
                        Spacer()
                        if let optimumScore = board.optimumScore {
                            Spacer().frame(height: 10)
                            HStack {
                                Spacer().frame(width: 4)
                                VStack {
                                    Text("Optimum: ").foregroundColor(Palette.handTable.contrastText).bold()
                                    Text(" ")
                                }
                                VStack {
                                    HStack {
                                        Text("\(optimumScore.declarer.short) \(optimumScore.contract.colorCompact) \(optimumScore.made == 0 ? "=" : String(format: "%+d", optimumScore.made))")
                                        Spacer()
                                    }
                                    HStack {
                                        Text("\(String(format: "%+d", (sitting.pair == .ns ? 1 : -1) * optimumScore.nsPoints))")
                                        Spacer()
                                    }
                                }
                                Spacer()
                            }.font(.body)
                        }
                        Spacer().frame(height: 5)
                    }
                    Spacer().frame(width: 4)
                }.minimumScaleFactor(0.5).overlay(RoundedRectangle(cornerRadius: 4).stroke(Palette.separator.background,  lineWidth: 2)).lineLimit(1)
            }
        }
    }
}
