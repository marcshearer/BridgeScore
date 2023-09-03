//
//  Hand Viewer.swift
//  BridgeScore
//
//  Created by Marc Shearer on 28/08/2023.
//

import SwiftUI
import UIKit

struct HandViewer: View {
    @State var board: BoardViewModel
    @State var traveller: TravellerViewModel
    @State var sitting: Seat
    @State var from: UIView
    @State var bidding = true
    @State var bidAnnounce = ""
    @State var trickNumber = 0
    @State var deal = Deal()
    @State var tricks: [Trick] = []
    @State var visible = Array(repeating: false, count: 4)
    @State var animate = 0
    @State var showClaim = false
    
    init(board: BoardViewModel, traveller: TravellerViewModel,sitting: Seat, from: UIView) {
        self.board = board
        self.traveller = traveller
        self.sitting = sitting
        self.from = from
        _deal = State(initialValue: constructCards(cards: board.hand, playData: traveller.playData))
        _tricks = State(initialValue: constructTricks(playData: traveller.playData, declarer: traveller.declarer, trumps: traveller.contract.suit))
        setTrick(deal: deal, tricks: tricks)
    }
    
    var body: some View {
        
        StandardView("HandView") {
            VStack {
                VStack {
                    Spacer().frame(height: 10)
                    HStack {
                        Spacer().frame(width: 10)
                        HandViewBoardDetails(board: board, traveller: traveller)
                        Spacer().frame(width: 10)
                        let partner = sitting.partner
                        HandViewHand(board: board, traveller: traveller, seat: partner, hand: deal.hands[partner] ?? Hand(), trickNumber: $trickNumber)
                        Spacer().frame(width: 10)
                        if showClaim || !bidding {
                            HandViewTrickCount(traveller: traveller, tricks: $tricks, trickNumber: $trickNumber, showClaim: $showClaim, declarer: traveller.declarer)
                        } else {
                            HandViewBidAnnounce(announce: $bidAnnounce)
                        }
                        Spacer().frame(width: 10)
                    }
                    Spacer().frame(height: 10)
                    HStack() {
                        Spacer().frame(width: 10)
                        let lhOpponent = sitting.leftOpponent
                        HandViewHand(board: board, traveller: traveller, seat: lhOpponent, hand: deal.hands[lhOpponent] ?? Hand(), trickNumber: $trickNumber)
                        Spacer().frame(width: 10)
                        VStack(spacing: 0) {
                            if bidding {
                                HandViewBidding(board: board, traveller: traveller, sitting: sitting, bidAnnounce: $bidAnnounce, showClaim: $showClaim)
                            } else {
                                HandViewPlay(board: board, traveller: traveller, sitting: sitting, tricks: $tricks, trickNumber: $trickNumber, visible: $visible, animate: $animate, bidding: $bidding, showClaim: $showClaim)
                            }
                        }.cornerRadius(6)
                        Spacer().frame(width: 10)
                        let rhOpponent = sitting.rightOpponent
                        HandViewHand(board: board, traveller: traveller, seat: rhOpponent, hand: deal.hands[rhOpponent] ?? Hand(), trickNumber: $trickNumber)
                        Spacer().frame(width: 10)
                    }
                    Spacer().frame(height: 10)
                    HStack {
                        Spacer().frame(width: 10)
                        Rectangle().fill(.clear)
                        Spacer().frame(width: 10)
                        HandViewHand(board: board, traveller: traveller, seat: sitting, hand: deal.hands[sitting] ?? Hand(), trickNumber: $trickNumber)
                        Spacer().frame(width: 10)
                        Rectangle().fill(.clear)
                        Spacer().frame(width: 10)
                    }
                    Spacer().frame(height: 30)
                }.background(.green)
                Spacer().frame(height: 10)
                // Separator(thickness: 2, color: .gray)
                HandViewButtons(board: board, traveller: traveller, from: $from, bidding: $bidding, tricks: $tricks, trickNumber: $trickNumber, visible: $visible, animate: $animate, showClaim: $showClaim)
                Spacer().frame(height: 10)
            }
        }
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
    
    struct HandViewButtons: View {
        @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
        @State var board: BoardViewModel
        @State var traveller: TravellerViewModel
        @State var from: Binding<UIView>
        @Binding var bidding: Bool
        @Binding var tricks: [Trick]
        @Binding var trickNumber: Int
        @Binding var visible: [Bool]
        @Binding var animate: Int
        @Binding var showClaim: Bool
        
        var body: some View {
            VStack {
                
                Spacer()
                HStack {
                    Spacer()
                    HandViewButton(label: "Close", highlight: true) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    if bidding {
                        Spacer().frame(width: 40)
                        HandViewButton(label: "Play") {
                            for index in 0..<visible.count {
                                visible[index] = false
                            }
                            bidding = false
                            showClaim = false
                            trickNumber = 1
                            Utility.executeAfter(delay: 0.01) {
                                animate += 1
                            }
                        }
                    } else {
                        Spacer().frame(width: 40)
                        HandViewButton(label: "Bidding") {
                            bidding = true
                            trickNumber = 0
                        }
                    }
                    Spacer().frame(width: 40)
                    HandViewButton(label: "Next", disabled: {trickNumber >= tricks.count || bidding}) {
                        for index in 0..<visible.count {
                            visible[index] = false
                        }
                        trickNumber += 1
                        Utility.executeAfter(delay: 0.01) {
                            animate += 1
                        }
                    }
                    Spacer().frame(width: 40)
                    HandViewButton(label: "Previous", disabled: {trickNumber <= 1 || bidding}) {
                        for index in 0..<visible.count {
                            visible[index] = false
                        }
                        trickNumber -= 1
                        Utility.executeAfter(delay: 0.01) {
                            animate += 1
                        }
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
                    if enabled {
                        action()
                    }
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
    
    struct HandViewBoardDetails: View {
        @State var board: BoardViewModel
        @State var traveller: TravellerViewModel
        
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
                    }.foregroundColor(.white).frame(width: 100)
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
                            Text("\(traveller.contract.compact)")
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
                    .foregroundColor(.black)
                    Spacer().frame(width: 2)
                }.font(.title2).overlay(RoundedRectangle(cornerRadius: 4).stroke(.gray,  lineWidth: 2)).lineLimit(1).minimumScaleFactor(0.5)
            }
            
        }
    }
    
    struct HandViewBidAnnounce: View {
        @Binding var announce: String
        
        var body: some View {
            ZStack {
                Rectangle().fill(.clear)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if announce != "" {
                            HStack {
                                Spacer().frame(width: 10)
                                VStack {
                                    Spacer().frame(height: 10)
                                    Text("Bid explanation:").foregroundColor(.white)
                                    Text(announce).foregroundColor(.black)
                                    Spacer().frame(height: 10)
                                }
                                Spacer().frame(width: 10)
                            }.font(.title2).overlay(RoundedRectangle(cornerRadius: 4).stroke(.gray,  lineWidth: 2))
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
    
    struct HandViewHand: View {
        @State var board: BoardViewModel
        @State var traveller: TravellerViewModel
        @State var seat: Seat
        @State var hand: Hand
        @Binding var trickNumber: Int
        
        var body: some View {
            ZStack {
                Rectangle().fill(.white).cornerRadius(6)
                VStack {
                    ZStack {
                        Rectangle().fill(.teal).frame(height: 50)
                        HStack{
                            Spacer().frame(width: 10)
                            Text(seat.short).font(.title).bold().foregroundColor(.white)
                            Spacer().frame(width: 10)
                            Text(name).font(.title).minimumScaleFactor(0.2).lineLimit(1)
                            Spacer()
                        }
                    }
                    ForEach((Suit.realSuits).reversed(), id: \.self) { suit in
                        HandViewSuit(board: board, traveller: traveller, suit: suit, handSuit: hand.xrefSuit[suit], trickNumber: $trickNumber)
                    }
                    Spacer()
                    
                }.cornerRadius(6)
            }
        }
        
        var start: Int {
            return (seat.rawValue - 1) * 4
        }
        
        var name: String {
            var name = "Unknown"
            if let ranking = traveller.ranking(seat: seat) {
                name = (ranking.players[seat] ?? name)
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
        @State var board: BoardViewModel
        @State var traveller: TravellerViewModel
        @State var suit: Suit
        @State var handSuit: HandSuit?
        @Binding var trickNumber: Int
        
        var body: some View {
            VStack {
                Spacer().frame(height: 4)
                HStack(spacing: 2) {
                    Spacer().frame(width: 4)
                    Text(suit.string)
                    if let cards = handSuit?.cards {
                        if cards.reduce(false, {$0 || trickNumber < ($1.data as! Int)}) {
                            ForEach(0..<cards.count, id: \.self) { index in
                                if trickNumber < cards[index].data as! Int {
                                    Text(cards[index].rankString).font(.title).minimumScaleFactor(0.2)
                                }
                            }
                        } else {
                            Text("A").font(.title).minimumScaleFactor(0.2).foregroundColor(.clear)
                        }
                    }
                    Spacer()
                }
                Spacer().frame(height: 4)
            }
        }
    }
    
    struct HandViewBidding : View {
        @State var board: BoardViewModel
        @State var traveller: TravellerViewModel
        @State var sitting: Seat
        @Binding var bidAnnounce: String
        @Binding var showClaim: Bool
        
        var body: some View {
            VStack {
                HandViewBiddingTitles(board: board, sitting: sitting)
                HandViewBiddingBids(board: board, traveller: traveller, sitting: sitting, bidAnnounce: $bidAnnounce, showClaim: $showClaim)
                Spacer()
            }.background(Palette.tile.background)
        }
    }
    
    struct HandViewBiddingTitles: View {
        @State var board: BoardViewModel
        @State var sitting: Seat
        
        var body: some View {
            HStack {
                ForEach(Seat.validCases, id: \.self) { seat in
                    let seat = seat.offset(by: sitting.rawValue - 1)
                    let vulnerable = board.vulnerability.isVulnerable(seat: seat)
                    ZStack {
                        HStack(spacing: 0) {
                            if seat != sitting {
                                Rectangle().foregroundColor(.gray).frame(width: 3, height: 30)
                            }
                            Rectangle().frame(height: 30).foregroundColor(vulnerable ? .red : .white)
                        }
                        HStack {
                            Spacer()
                            Text(seat.short).foregroundColor(vulnerable ? .white : .black).bold()
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    struct HandViewBiddingBids: View {
        @State var board: BoardViewModel
        @State var traveller: TravellerViewModel
        @State var sitting: Seat
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
                                            }.background((announce ?? "") != "" ? .white : .clear).cornerRadius(4).overlay(RoundedRectangle(cornerRadius: 4).stroke(.blue,  lineWidth: (alert ? 2 : 0)))
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
                }
            }
        }
        
        var bids: [(String, Bool, String?)] {
            var result: [(String, Bool, String?)] = []
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
        
        func replace(bid: String) -> String {
            var bid = bid.uppercased()
            switch bid {
            case "P":
                bid = "Pass"
            case "D":
                bid = "Dbl"
            case "R":
                bid = "Rdbl"
            default:
                if bid.right(2) == "NT" {
                        // Leave unchanged
                } else {
                    bid = bid.left(1) + Suit(string: bid.right(1)).string
                }
            }
            return bid
        }
    }
    
    struct HandViewPlay : View {
        @State var board: BoardViewModel
        @State var traveller: TravellerViewModel
        @State var sitting: Seat
        @Binding var tricks: [Trick]
        @Binding var trickNumber: Int
        @Binding var visible: [Bool]
        @Binding var animate: Int
        @Binding var bidding: Bool
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
                                    Text(trick.cards[cardNumber].string)
                                    Spacer()
                                }.frame(width: width, height: height).background(.white).cornerRadius(4).transition(.opacity)
                            }
                        }
                    }.frame(width: width, height: height)
                    Spacer().frame(height: 10)
                    HStack {
                        Spacer().frame(width: 10)
                        HStack(spacing: 0) {
                            if visible[3] {
                                let cardNumber = trick.lead.offset(to: sitting.leftOpponent)
                                if cardNumber < trick.cards.count {
                                    HStack(spacing: 0) {
                                        Spacer()
                                        Text(trick.cards[cardNumber].string)
                                        Spacer()
                                    }.frame(width: width, height: height).background(.white).cornerRadius(4).transition(.opacity)
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
                                        Text(trick.cards[cardNumber].string)
                                        Spacer()
                                    }.frame(width: width, height: height).background(.white).cornerRadius(4).transition(.opacity)
                                }
                            }
                        }.frame(width: width, height: height)
                        Spacer().frame(width: 10)
                    }
                    Spacer().frame(height: 10)
                    HStack {
                        HStack(spacing: 0) {
                            if visible[2] {
                                let cardNumber = trick.lead.offset(to: sitting)
                                if cardNumber < trick.cards.count {
                                    HStack(spacing: 0) {
                                        Spacer()
                                        Text(trick.cards[cardNumber].string)
                                        Spacer()
                                    }.frame(width: width, height: height).background(.white).cornerRadius(4).transition(.opacity)
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
                if trickNumber >= tricks.count {
                    showClaim = true
                }
            }
            withAnimation(.default) {
                let saveAnimate = animate
                if trickNumber >= tricks.count {
                    Utility.executeAfter(delay: (interval * 3) + 5) {
                        if !bidding && animate == saveAnimate {
                            trickNumber = 0
                            showClaim = true
                            bidding = true
                        }
                    }
                }
            }
        }
    }
    
    struct HandViewTrickCount: View {
        @State var traveller: TravellerViewModel
        @Binding var tricks: [Trick]
        @Binding var trickNumber: Int
        @Binding var showClaim: Bool
        @State var declarer: Seat

        var body: some View {
            let trick = tricks[max(0, trickNumber - 1)]
            ZStack {
                Rectangle().fill(.clear)
                HStack {
                    Spacer().frame(width: 10)
                    Spacer()
                    HStack {
                        VStack {
                            Spacer()
                            if showClaim {
                                HStack {
                                    Text("\(6 + traveller.contractLevel + traveller.made) tricks \(trickNumber != 0 && trickNumber < 13 ? "claimed" : "made")").foregroundColor(.white).bold()
                                }
                            } else {
                                HStack {
                                    Text("Tricks made:").bold()
                                    Spacer()
                                }
                                Spacer().frame(height: 10)
                                HStack {
                                    HStack {
                                        Text("Declarer: ")
                                        Spacer()
                                    }.frame(width: 130)
                                    Text("\(declarer.pair == .ns ?  trick.nsTricks : trick.trickNumber - trick.nsTricks)").foregroundColor(.white)
                                    Spacer()
                                }
                                HStack {
                                    HStack {
                                        Text("Defence: ")
                                        Spacer()
                                    }.frame(width: 130)
                                    Text("\(declarer.pair == .ew ?  trick.nsTricks : trick.trickNumber - trick.nsTricks)").foregroundColor(.white)
                                    Spacer()
                                }
                            }
                            Spacer()
                        }
                        .foregroundColor(.black)
                        Spacer().frame(width: 2)
                    }
                    Spacer()
                }.font(.title2).minimumScaleFactor(0.5).overlay(RoundedRectangle(cornerRadius: 4).stroke(.gray,  lineWidth: 2)).lineLimit(1).minimumScaleFactor(0.5)
            }
        }
    }
}
