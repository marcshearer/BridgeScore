//
//  Bidding Viewer.swift
//  BridgeScore
//
//  Created by Marc Shearer on 02/04/2026.
//

import SwiftUI

class Auction: ObservableObject, Equatable {
    @Published var bidList: [(bid: AttributedString, alerted: Bool, explain: String?)]
    @Published var manualAuction: Bool = true
    @Published var skip = 0
    
    init() {
        self.bidList = []
        self.manualAuction = false
        self.skip = 0
    }
    
    convenience init(playData: String, sitting: Seat, dealer: Seat, manualAuction: Bool = false) {
        self.init()
        set(from: playData, sitting: sitting, dealer: dealer)
        self.manualAuction = manualAuction
    }
    
    var count: Int { bidList.count }
    
    func focusable(_ index: Int) -> Bool {
        (index >= skip && index <= count)
    }
    
    func element(_ index: Int) -> (bid: AttributedString, alerted: Bool, explain: String?) {
        if index >= skip && index < count {
            bidList[index]
        } else {
            (AttributedString(""), false, nil)
        }
    }
    
    func add(bid: AttributedString, alerted: Bool, explain: String? = nil, updateManualAuction: Bool = true) {
        bidList.append((bid, alerted, explain))
        if updateManualAuction {
            manualAuction = true
        }
    }
    
    func replace(bid: AttributedString, with newBid: AttributedString, alerted: Bool? = nil, explain: String? = nil) {
        if let index = bidList.firstIndex(where: {$0.bid == bid}) {
            bidList[index].bid = newBid
            if let alerted = alerted {
                bidList[index].alerted = alerted
            }
            if let explain = explain {
                bidList[index].explain = explain
            }
            manualAuction = true
        }
    }
    
    func setLast(alerted: Bool? = nil, explain: String? = nil) {
        let lastIndex = bidList.count - 1
        if lastIndex >= 0 {
            if let alerted = alerted {
                bidList[lastIndex].alerted = alerted
            }
            if let explain = explain {
                bidList[lastIndex].explain = explain
            }
        }
    }
    
    func removeLast() {
        if !bidList.isEmpty {
            if (bidList.last?.bid ?? "") != "" {
                _ = bidList.popLast()
                manualAuction = true
            }
        }
    }
    
    static func == (lhs: Auction, rhs: Auction) -> Bool {
        var result = true
        if lhs.count != rhs.count {
            result = false
        } else {
            for index in lhs.bidList.indices {
                if lhs.bidList[index] != rhs.bidList[index] {
                    result = false
                    break
                }
            }
        }
        return result
    }
    
    var playData: String {
        var playData = "manualAuction|"
        for (bid, alert, announce) in bidList {
            if bid != "" {
                playData.append("mb|\(buildPlayData(bid: String(bid.characters)))")
                if alert {
                    playData.append("!")
                }
                if let announce = announce {
                    playData += "|an|\(announce.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
                }
                playData += "|"
            }
        }
        return playData
    }
    
    func set(from playData: String, sitting: Seat, dealer: Seat) {
        bidList = []
        manualAuction = false
        if !playData.isEmpty {
            let tokens = playData.removingPercentEncoding!.components(separatedBy: "|")
            if tokens.first == "manualAuction" {
                manualAuction = true
            }
            self.skip = sitting.offset(to: dealer)
            for (index, token) in tokens.enumerated() {
                if token == "mb" {
                    var bid = tokens[index + 1]
                    var alert = false
                    if bid.contains("!") {
                        alert = true
                        bid = bid.replacingOccurrences(of: "!", with: "")
                    }
                    var announce: String?
                    if index + 3 < tokens.count {
                        if tokens[index + 2] == "an" {
                            announce = tokens[index + 3]
                        }
                    }
                    add(bid: translatePlayData(bid: bid), alerted: alert, explain: announce, updateManualAuction: false)
                }
            }
        }
    }
        
    func translatePlayData(bid: String) -> AttributedString {
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
    
    func buildPlayData(bid: String) -> String {
        let bid = bid.uppercased()
        var result: String
        
        switch bid {
        case "PASS":
            result = "p"
        case "DBL":
            result = "d"
        case "RDBL":
            result = "r"
        default:
            if bid.right(2) == "NT" {
                result = bid.left(1) + "N"
            } else {
                result = bid.left(1) + Suit(symbol:bid.right(1)).words.left(1).lowercased()
            }
        }
        return result
    }
}

struct BiddingViewer : View {
    @ObservedObject var bids: Auction
    @Binding var sitting: Seat
    @Binding var boardNumber: Int
    @Binding var bidAnnounce: String
    @Binding var showClaim: Bool
    @Binding var editBidding: Bool
    var inEditMode: Bool = false
     
    var body: some View {
        ZStack {
            Rectangle().fill(.clear)
                .debugPrint(bids.manualAuction)
            VStack {
                if !bids.bidList.filter({$0.bid != ""}).isEmpty || bids.manualAuction || inEditMode {
                    BiddingViewerTitles(sitting: $sitting, boardNumber: $boardNumber)
                    BiddingViewerBids(bids: bids, sitting: $sitting, boardNumber: $boardNumber, bidAnnounce: $bidAnnounce, showClaim: $showClaim, inEditMode: inEditMode)
                }
                if (bids.bidList.filter({$0.bid != ""}).isEmpty || bids.manualAuction) && !inEditMode {
                    Spacer()
                    Button(bids.manualAuction ? "Edit auction" : "Enter auction") {
                            editBidding = true
                        }
                        .font(defaultFont.bold())
                        .foregroundColor(Palette.handTable.contrastText)
                    HStack {
                        Spacer()
                    }
                }
                Spacer()
            }
            .onChange(of: bids, initial: false) {
                bids.manualAuction = true
            }
            .font(.title2)
            .palette(.handTable)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 4)
            .stroke(Palette.separator.background,  lineWidth: 2))
        }
    }
}

struct BiddingViewerTitles: View {
    @Binding var sitting: Seat
    @Binding var boardNumber: Int
    
    var body: some View {
        HStack {
            ForEach(Seat.validCases, id: \.self) { seat in
                let seat = seat.offset(by: sitting.rawValue - 1)
                let vulnerable = Vulnerability(board: boardNumber).isVulnerable(seat: seat)
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
        .focusable(false)
    }
}

struct BiddingViewerBids: View {
    @ObservedObject var bids: Auction
    @Binding var sitting: Seat
    @Binding var boardNumber: Int
    @Binding var bidAnnounce: String
    @Binding var showClaim: Bool
    var width: CGFloat = 60
    var height: CGFloat = 25
    var inEditMode: Bool
    @FocusState var focusedIndex: Int?
    
    var body: some View {
        // ScrollView(showsIndicators: false) {
            VStack(spacing: 2) {
                if !bids.bidList.isEmpty {
                    ForEach(0...((bids.count) / 4), id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0...3, id: \.self) { column in
                                let index = (row * 4) + column
                                let (bid, _, announce) = bids.element(index)
                                HStack {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            let text = (index >= bids.skip && index < bids.count ? bid : (index == bids.count ? "-" : ""))
                                            Button {
                                                if inEditMode {
                                                    if bids.focusable(index) {
                                                        focusedIndex = index
                                                    }
                                                } else {
                                                    showClaim = false
                                                    bidAnnounce = announce ?? ""
                                                }
                                            } label: {
                                                Text(text)
                                                    .lineLimit(1).minimumScaleFactor(0.4)
                                                    .frame(width: width, height: height)
                                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Palette.gridLine, lineWidth: (index == focusedIndex ? 3 : 0)))
                                            }
                                            .buttonStyle(.plain)
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                }
                                .cornerRadius(4)
                                .background((announce ?? "") != "" ? Palette.card.background : .clear)
                                .foregroundColor((announce ?? "") != "" ? Palette.card.text : Palette.handBidding.text)
                                .focusable(inEditMode && bids.focusable(index))
                                .focused($focusedIndex, equals: index)
                                .frame(height: height)
                                .cornerRadius(12)
                                .onKeyPress(keys: [KeyEquivalent.delete, .deleteForward]) { key in
                                    Utility.mainThread {
                                        bids.removeLast()
                                    }
                                    return .handled
                                }
                            }
                        }
                    }
                }
            }
        //}
        .palette(.handTable)
        .focusable(false)
        .focusEffectDisabled()
        .task {
            // Small yield to let the render cycle finish
            try? await Task.sleep(for: .seconds(1 as Double))
            focusedIndex = bids.count
        }
        //.defaultFocus($focusedIndex, bids.count)
    }
}
