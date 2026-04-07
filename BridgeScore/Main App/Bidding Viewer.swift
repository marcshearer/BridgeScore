//
//  Bidding Viewer.swift
//  BridgeScore
//
//  Created by Marc Shearer on 02/04/2026.
//

import SwiftUI

class Auction: ObservableObject, Equatable {
    @Published var bidList: [(bid: Bid, alerted: Bool, announce: String?)]
    @Published var manualAuction: Bool = true
    @Published var inEditMode: Bool = false
    @Published var selected: Int? = nil
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
    
    func reset() {
        selected = count
    }
    
    func clear() {
        bidList.removeAll()
        selected = count
    }
    
    var count: Int { bidList.count + skip }
    
    func focusable(_ index: Int) -> Bool {
        (index >= skip && index <= count)
    }
    
    func element(_ index: Int) -> (bid: Bid?, alerted: Bool, announce: String?) {
        if index != count && focusable(index) {
            bidList[index - skip]
        } else {
            (nil, false, nil)
        }
    }
    
    func add(bid: Bid, alerted: Bool, announce: String? = nil, updateManualAuction: Bool = true) {
        bidList.append((bid, alerted, announce))
        selected = count
        if updateManualAuction {
            manualAuction = true
        }
    }
    
    func can(bid: Bid, at position: Int? = nil) -> Bool {
        var result = true
        let position = position ?? selected ?? count
        let element = position - skip
        
        // Check previous passes
        var passes = 0
        if element >= 3 {
            for index in ((element - 3)...(element-1)).reversed() {
                if bidList[index].bid == Bid() {
                    passes += 1
                } else {
                    break
                }
            }
        }
        if passes >= 3 {
            result = false
        }

        if result {
            if bid.level.hasSuit {
                // Actual bid - check lower bid
                var index = element
                while index > 0 {
                    index -= 1
                    let lowerBid = bidList[index].bid
                    if lowerBid.level.hasSuit {
                        if bid <= lowerBid {
                            result = false
                            break
                        } else {
                            break
                        }
                    }
                }
                
                if result {
                    // Check higher bid
                    var index = element
                    while index < bidList.count - 1 {
                        index += 1
                        let upperBid = bidList[index].bid
                        if upperBid.level.hasSuit {
                            if bid >= upperBid {
                                result = false
                                break
                            } else {
                                break
                            }
                        }
                    }
                }
            } else {
                // Pass double etc
                switch bid.double {
                case .undoubled:
                    // A pass - check for too many passes in a row
                    var passes = 0
                    for (index, bid) in bidList.map({$0.bid}).enumerated() {
                        if (index != element && bid != Bid()) || passes > 3 {
                            // End of sequence of passes - check it
                            if passes > 3 {
                                result = false
                                break
                            }
                            passes = 0
                        }
                        passes += 1
                    }
                case .doubled:
                    // Only valid if previous bid was a noarmal bid by an opponent
                    if element == 0 {
                        result = false
                    } else {
                        for index in (0..<element).reversed() {
                            if bidList[index].bid != Bid() {
                                    // Not a pass
                                if bidList[index].bid.level.hasSuit {
                                        // Not a double or redouble
                                    if (element - index) % 2 == 0 {
                                            // By partner (or self)
                                        result = false
                                        break
                                    }
                                } else {
                                        // Was a double or a redouble - can't double it
                                    result = false
                                }
                                break
                            }
                        }
                    }
                case .redoubled:
                    // Only valid if previous bid was a double by an opponent
                    if element == 0 {
                        result = false
                    } else {
                        for index in (0..<element).reversed() {
                            if bidList[index].bid != Bid() {
                                    // Not a pass
                                if bidList[index].bid.double != .doubled {
                                        // Not a double
                                    result = false
                                    break
                                } else {
                                        // Was a double
                                    if (element - index) % 2 == 0 {
                                            // By partner (or self)
                                        result = false
                                        break
                                    }
                                }
                                break
                            }
                        }
                    }
                }
            }
        }
        return result
    }
    
    func replace(at index: Int, with newBid: Bid, alerted: Bool? = nil, announce: String? = nil) {
        if can(bid: newBid, at: index) {
            if index == count {
                add(bid: newBid, alerted: alerted ?? false, announce: announce)
            } else if index >= skip {
                bidList[index - skip].bid = newBid
                if let alerted = alerted {
                    bidList[index - skip].alerted = alerted
                }
                if let announce = announce {
                    bidList[index - skip].announce = announce
                }
                selected = index
                manualAuction = true
            }
        }
    }
    
    func set(alerted: Bool? = nil, announce: String? = nil) {
        let selected = selected ?? count
        if selected >= skip && selected < count {
            if let alerted = alerted {
                bidList[selected - skip].alerted = alerted
            }
            if let announce = announce {
                bidList[selected - skip].announce = announce
            }
        }
    }
    
    @discardableResult func removeLast() -> Bool {
        var result = false
        if !bidList.isEmpty {
            _ = bidList.popLast()
            selected = bidList.count
            result = true
            manualAuction = true
        }
        return result
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
            playData.append("mb|\(bid.playData)")
            if alert {
                playData.append("!")
            }
            if let announce = announce {
                playData += "|an|\(announce.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
            }
            playData += "|"
        }
        return playData
    }
    
    func set(inEditMode: Bool) {
        self.inEditMode = inEditMode
    }
    
    func set(from playData: String, sitting: Seat, dealer: Seat) {
        bidList = []
        skip = sitting.offset(to: dealer)
        selected = nil
        manualAuction = false
        if !playData.isEmpty {
            let tokens = playData.removingPercentEncoding!.components(separatedBy: "|")
            if tokens.first == "manualAuction" {
                manualAuction = true
            }
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
                    add(bid: translatePlayData(bid: bid), alerted: alert, announce: announce, updateManualAuction: false)
                }
            }
            selected = count
        }
    }
        
    func translatePlayData(bid: String) -> Bid {
        let bid = bid.uppercased()
        var result: Bid
        
        switch bid {
        case "P":
            result = Bid()
        case "D":
            result = Bid(double: .doubled)
        case "R":
            result = Bid(double: .redoubled)
        default:
            if let levelNumber = Int(bid.left(1)), let level = ContractLevel(rawValue: levelNumber) {
                if bid.right(2) == "NT" {
                    result = Bid(level: level, suit: .noTrumps)
                } else {
                    result = Bid(level: level, suit: Suit(string: bid.right(1)))
                }
            } else {
                result = Bid()
            }
        }
        return result
    }
    
}

struct BiddingViewer : View {
    @ObservedObject var bids: Auction
    @FocusState.Binding var focusedField: BiddingFocusField?
    @Binding var sitting: Seat
    @Binding var boardNumber: Int
    @Binding var bidAnnounce: String
    @Binding var showClaim: Bool
    @Binding var editBidding: Bool
    var font: Font = .title2
     
    var body: some View {
        ZStack {
            Rectangle().fill(.clear)
            VStack {
                if !editBidding || !bids.inEditMode {
                    if !bids.bidList.isEmpty || bids.manualAuction || bids.inEditMode {
                        BiddingViewerTitles(sitting: $sitting, boardNumber: $boardNumber)
                        BiddingViewerBids(bids: bids, focusedField: _focusedField, sitting: $sitting, boardNumber: $boardNumber, bidAnnounce: $bidAnnounce, showClaim: $showClaim)
                    }
                    if (bids.bidList.isEmpty || bids.manualAuction) && !bids.inEditMode {
                        Spacer()
                        Button(bids.manualAuction ? "Edit auction" : "Enter auction") {
                            editBidding = true
                            bids.reset()
                        }
                        .font(defaultFont.bold())
                        .foregroundColor(Palette.handTable.contrastText)
                        HStack {
                            Spacer()
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                    }
                }
                Spacer()
            }
            .onChange(of: bids, initial: false) {
                bids.manualAuction = true
            }
            .font(font)
            .palette(.handTable)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 4)
                .stroke(Palette.separator.background,  lineWidth: 2))
        }
        .focusable(false)
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
        .accessibilityHidden(true)
        .accessibilityRespondsToUserInteraction(false)
        .focusable(false)
    }
}

struct BiddingViewerBids: View {
    @Environment(\.isFocused) var isFocused
    @ObservedObject var bids: Auction
    @FocusState.Binding var focusedField: BiddingFocusField?
    @Binding var sitting: Seat
    @Binding var boardNumber: Int
    @Binding var bidAnnounce: String
    @Binding var showClaim: Bool
    var width: CGFloat = 60
    var height: CGFloat = 25
    @State var bidLevel: Int? = nil
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 2) {
                ForEach(0...(bids.count / 4), id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0...3, id: \.self) { column in
                            let index = (row * 4) + column
                            VStack(spacing: 0) {
                                Spacer()
                                HStack(spacing: 0) {
                                    Spacer()
                                    BidButton(bids: bids, focusedField: _focusedField, index: index, bidLevel: $bidLevel, bidAnnounce: $bidAnnounce, showClaim: $showClaim)
                                    Spacer()
                                }
                                .background((bids.element(index).announce ?? "") != "" ? Palette.card.background : (bids.element(index).alerted ? Palette.alternate.background : .clear))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Palette.gridLine, lineWidth: (bids.inEditMode && index == bids.selected ? 3 : 0)))
                                Spacer()
                            }
                            .cornerRadius(8)
                            .foregroundColor((bids.element(index).announce ?? "") != "" ? Palette.card.text : Palette.handBidding.text)
                            .frame(height: height)
                            .onChange(of: bids.count) {
                                bids.selected = bids.count - 1
                            }
                        }
                    }
                    .onKeyPress(keys: [.delete, .deleteForward, .upArrow, .downArrow, .leftArrow, .rightArrow, .tab, "1", "2", "3", "4", "5", "6", "7", "c", "d", "h", "s", "n", "p", "r", "x", " "]) { press in
                        if (press.key == .delete || press.key == .deleteForward) && bids.selected == nil { bids.selected = bids.count }
                        Utility.mainThread {
                            bids.selected = processKey(press: press, index: bids.selected ?? bids.count)
                        }
                        return .handled
                    }
                }
            }
        }
        .background(Color.clear)
        .focusable(false)
        .onAppear {
            Utility.executeAfter(delay: 1) {
                bids.selected = bids.count - 1
            }
        }
        .onChange(of: bids.selected, initial: true) {
            let target = BiddingFocusField.biddingViewer(index: bids.selected ?? bids.count)
            if focusedField != target {
                focusedField = target
            }
        }
        .palette(.handTable)
        // .focusEffectDisabled()
    }
    
    func processKey(press: KeyPress, index: Int) -> Int {
        switch press.key {
        case .delete, .deleteForward:
            if index == bids.count {
                bids.removeLast()
                return index - 1
            }
        case .upArrow:
            bidLevel = nil
            if index - 4 >= bids.skip {
                return index - 4
            }
        case .leftArrow:
            bidLevel = nil
            if index - 1 >= bids.skip {
                return index - 1
            }
        case .downArrow:
            bidLevel = nil
            if index + 4 <= bids.count {
                return index + 4
            } else {
                if index != bids.count {
                    focusedField = .explain
                }
            }
        case .rightArrow, .tab:
            bidLevel = nil
            if index + 1 <= bids.count {
                return index + 1
            } else {
                if index != bids.count {
                    focusedField = .explain
                }
            }
        case "1", "2", "3", "4", "5", "6", "7":
            bidLevel = Int(String(press.characters.first!))
        case "c", "d", "h", "s", "n":
            if let selected = bids.selected {
                if let bidLevel = bidLevel, let level = ContractLevel(rawValue: bidLevel) {
                    let suit = Suit(string: String(press.characters.first!))
                    let bid = Bid(level: level, suit: suit)
                    bids.replace(at: selected, with: bid)
                } else if press.characters.first! == "d" {
                    bids.replace(at: selected, with: Bid(double: .doubled))
                }
                bidLevel = nil
            }
        case "p", " ":
            if let selected = bids.selected {
                bids.replace(at: selected, with: Bid())
            }
            bidLevel = nil
        case "x":
            if let selected = bids.selected {
                bids.replace(at: selected, with: Bid(double: .doubled))
            }
            bidLevel = nil
        case "r":
            if let selected = bids.selected {
                bids.replace(at: selected, with: Bid(double: .redoubled))
            }
            bidLevel = nil
        default:
            break
        }
        return index
    }
}
    
struct BidButton : View {
    @Environment(\.isFocused) var isFocused
    @ObservedObject var bids: Auction
    @FocusState.Binding var focusedField: BiddingFocusField?
    var index: Int
    @Binding var bidLevel: Int?
    @Binding var bidAnnounce: String
    @Binding var showClaim: Bool
    
    var body: some View {
        Button {
            if bids.inEditMode {
                if bids.focusable(index) {
                    Utility.mainThread {
                        bids.selected = index
                        focusedField = nil
                        Utility.executeAfter(delay: 0.2) {
                            focusedField = .biddingViewer(index: index)
                        }
                    }
                }
            } else {
                showClaim = false
                if let announce = bids.element(index).announce {
                    bidAnnounce = announce
                } else if bids.element(index).alerted {
                    bidAnnounce = "Alerted"
                } else {
                    bidAnnounce = ""
                }
            }
        } label: {
            let text = bids.element(index).bid?.colorCompact ?? AttributedString(index == bids.count ? "-" : "")
            Text(text)
                .layoutPriority(99)
                .contentShape(Rectangle())
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .fixedSize()
        }
        .buttonStyle(.plain)
        .focusable(true)
        .focused($focusedField, equals: .biddingViewer(index: index))
    }
}


class Bid : Contract {
    
    override init(level: ContractLevel = .blank, suit: Suit = .blank, double: ContractDouble = .undoubled) {
        super.init(level: level, suit: suit, double: double)
        if level == .blank {
            // Allow double to be specified with a blank level
            self.double = double
        }
    }
    
    override var colorCompact: AttributedString {
        switch level {
        case .blank, .passout:
            switch double {
            case .undoubled:
                AttributedString("Pass")
            case .doubled:
                AttributedString("Dbl")
            case .redoubled:
                AttributedString("Rdbl")
            }
        default:
            super.colorCompact
        }
    }
    
    public var playData: String {
        if level == .blank  {
            switch double {
            case .undoubled:
                return "p"
            case .doubled:
                return "d"
            case .redoubled:
                return "r"
            }
        } else {
            return "\(level.short)\(suit.playData)"
        }
    }
    
    var palette: PaletteColor {
        switch level {
        case .blank, .passout:
            switch double {
            case .undoubled:
                Palette.pass
            case .doubled:
                Palette.double
            case .redoubled:
                Palette.redouble
            }
        default:
            Palette.card
        }
    }

}
