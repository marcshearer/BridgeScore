//
//  Bidding Viewer.swift
//  BridgeScore
//
//  Created by Marc Shearer on 02/04/2026.
//

import SwiftUI

let passBid = Bid()
let doubleBid = Bid(double: .doubled)
let redoubleBid = Bid(double: .redoubled)

class Auction: ObservableObject, Equatable {
    @Published var manualAuction: Bool = true
    @Published var inEditMode: Bool = false
    @Published private(set) var selected: Int? = nil
    @Published private var bidList: [(bid: Bid, alerted: Bool, announce: String?)]
    @Published private var skip = 0
    @Published private(set) var lastAdded: Bool = false { didSet {
        
    }}
    
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
        set(selected: count)
        lastAdded = false
    }
    
    func clear() {
        bidList.removeAll()
        set(selected: count)
        lastAdded = false
    }
    
    var count: Int { bidList.count + skip }
    
    var isEmpty: Bool { bidList.isEmpty }
    
    func selectable(_ index: Int) -> Bool {
        (index >= skip && index <= count)
    }
    
    func element(_ index: Int) -> (bid: Bid?, alerted: Bool, announce: String?) {
        if index != count && selectable(index) {
            bidList[index - skip]
        } else {
            (nil, false, nil)
        }
    }
    
    func add(bid: Bid, alerted: Bool, announce: String? = nil, updateManualAuction: Bool = true) {
        bidList.append((bid, alerted, announce))
        selected = count
        lastAdded = true
        if updateManualAuction {
            manualAuction = true
        }
    }
    
    func set(selected index: Int?) {
        if index != selected {
            selected = index
            lastAdded = false
        }
    }
    
    func canEditAnnounce(index: Int?) -> Bool {
        if let index = index {
            (index >= skip && index < count)
        } else {
            false
        }
    }
    
    func can(bid: Bid, at position: Int? = nil) -> Bool {
        var result = true
        let position = position ?? selected ?? count
        let element = position - skip
        
        // Check previous passes
        if bidList.count == 3 && bidList.filter({$0.bid != passBid}).isEmpty && bid == passBid {
            // 4 passes at the beginning of the auction is OK
        } else {
            var passes = 0
            if element >= 3 {
                for index in ((element - 3)...(element-1)).reversed() {
                    if bidList[index].bid == passBid {
                        passes += 1
                    } else {
                        break
                    }
                }
            }
            if passes >= 3 {
                result = false
            }
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
                        if (index != element && bid != passBid) || passes > 3 {
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
                    // Only valid if previous bid was a normal bid by an opponent
                    if element == 0 {
                        result = false
                    } else {
                        var foundBid  = false
                        for index in (0..<element).reversed() {
                            if bidList[index].bid != passBid {
                                    // Not a pass
                                if bidList[index].bid.level.hasSuit {
                                        // Not a double or redouble
                                    if (element - index) % 2 == 0 {
                                            // By partner (or self)
                                        result = false
                                        break
                                    } else {
                                        foundBid = true
                                    }
                                } else {
                                        // Was a double or a redouble - can't double it
                                    result = false
                                }
                                break
                            }
                        }
                        if !foundBid {
                            result = false
                        }
                    }
                case .redoubled:
                    // Only valid if previous bid was a double by an opponent
                    if element == 0 {
                        result = false
                    } else {
                        var foundBid  = false
                        for index in (0..<element).reversed() {
                            if bidList[index].bid != passBid {
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
                                    } else {
                                        foundBid = true
                                    }
                                }
                                break
                            }
                        }
                        if !foundBid {
                            result = false
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
                set(selected: index)
                manualAuction = true
            }
        }
    }
    
    func set(alerted: Bool? = nil, announce: String? = nil, index: Int? = nil) {
        var index = index ?? selected ?? count
        if index >= skip && index < count {
            if let alerted = alerted {
                bidList[index - skip].alerted = alerted
            }
            if let announce = announce {
                bidList[index - skip].announce = announce
            }
        }
    }
    
    var contract: Contract {
        var result = Contract(level: .passout)
        for bid in bidList.map({$0.bid}) {
            if bid.level.hasSuit {
                result = bid
            } else if bid.double != .undoubled {
                result.double = bid.double
            }
        }
        return result
    }
    
    var ends3Passes: Bool {
        let bids = bidList.count
        return bids >= 3 && bidList.suffix(3).filter({$0.bid != passBid}).isEmpty
    }
    
    @discardableResult func removeLast() -> Bool {
        var result = false
        if !bidList.isEmpty {
            _ = bidList.popLast()
            set(selected: count)
            result = true
            manualAuction = true
        }
        return result
    }
    
    func remove(at index: Int) {
        if selectable(index) {
            bidList.remove(at: index - skip)
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
        set(selected: nil)
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
            set(selected: count)
        }
    }
        
    func translatePlayData(bid: String) -> Bid {
        let bid = bid.uppercased()
        var result: Bid
        
        switch bid {
        case "P":
            result = passBid
        case "D":
            result = doubleBid
        case "R":
            result = redoubleBid
        default:
            if let levelNumber = Int(bid.left(1)), let level = ContractLevel(rawValue: levelNumber) {
                if bid.right(2) == "NT" {
                    result = Bid(level: level, suit: .noTrumps)
                } else {
                    result = Bid(level: level, suit: Suit(string: bid.right(1)))
                }
            } else {
                result = passBid
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
    var cancelEdit: ((Bool)->())? = nil
     
    var body: some View {
        ZStack {
            Rectangle().fill(.clear)
            VStack(spacing: 0) {
                if !editBidding || !bids.inEditMode {
                    if !bids.isEmpty || bids.manualAuction || bids.inEditMode {
                        BiddingViewerTitles(sitting: $sitting, boardNumber: $boardNumber)
                        BiddingViewerBids(bids: bids, focusedField: _focusedField, sitting: $sitting, boardNumber: $boardNumber, bidAnnounce: $bidAnnounce, showClaim: $showClaim, cancelEdit: cancelEdit)
                    }
                    if (bids.isEmpty || bids.manualAuction) && !bids.inEditMode {
                        Spacer()
                        Button(bids.manualAuction ? "Edit auction" : "Enter auction") {
                            var transaction = Transaction()
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                editBidding = true
                                bids.reset()
                            }
                        }
                        .font(defaultFont.bold())
                        .minimumScaleFactor(0.6)
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
    @Environment(\.dismiss) var dismiss
    @ObservedObject var bids: Auction
    @FocusState.Binding var focusedField: BiddingFocusField?
    @Binding var sitting: Seat
    @Binding var boardNumber: Int
    @Binding var bidAnnounce: String
    @Binding var showClaim: Bool
    var height: CGFloat = 25
    var cancelEdit: ((Bool)->())? = nil
    @State var bidLevel: Int? = nil
    
    var otherFocused: Binding<Bool> {
        Binding {
            focusedField == .explain
        } set: { (newValue) in
            
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            GeometryReader { geometry in
                VStack(spacing: 4) {
                    let width = (geometry.size.width - 6) / 4
                    ForEach(0...(bids.count / 4), id: \.self) { row in
                        HStack(spacing: 2) {
                            ForEach(0...3, id: \.self) { column in
                                let index = (row * 4) + column
                                BidButton(bids: bids, focusedField: _focusedField, index: index, bidLevel: $bidLevel, bidAnnounce: $bidAnnounce, showClaim: $showClaim, width: width)
                            }
                        }
                        .frame(height: height)
                    }
                }
                .background {
                    KeyInterceptor(ignoreKeys: otherFocused) { key in
                        bids.set(selected: processKey(key: key, index: bids.selected ?? bids.count))
                    }
                }
            }
        }
        .background(Color.clear)
        .focusable(false)
        .onAppear {
            bids.set(selected: bids.count)
        }
        .palette(.handTable)
    }
    
    func processKey(key: UIKey, index: Int) -> Int {
        var index = index
        switch key.keyCode {
        case .keyboardDeleteOrBackspace:
            if index == bids.count {
                bids.removeLast()
                return index - 1
            }
        case .keyboardUpArrow:
            bidLevel = nil
            if bids.selectable(index - 4) {
                return index - 4
            }
        case .keyboardLeftArrow:
            bidLevel = nil
            if bids.selectable(index - 1) {
                return index - 1
            }
        case .keyboardDownArrow:
            bidLevel = nil
            if bids.selectable(index + 4) {
                return index + 4
            }
        case .keyboardRightArrow, .keyboardTab:
            bidLevel = nil
            if bids.selectable(index + 1) {
                return index + 1
            }
        case .keyboardEscape:
            if let cancelEdit = cancelEdit {
                cancelEdit(false)
            } else {
                dismiss()
            }
        default:
            if let character = key.characters.first {
                let string = String(character)
                switch string {
                case "1", "2", "3", "4", "5", "6", "7":
                    bidLevel = Int(string)
                case "c", "d", "h", "s", "n":
                    if let selected = bids.selected {
                        if let bidLevel = bidLevel, let level = ContractLevel(rawValue: bidLevel) {
                            let suit = Suit(string: string)
                            let bid = Bid(level: level, suit: suit)
                            bids.replace(at: selected, with: bid)
                        } else if string == "d" {
                            bids.replace(at: selected, with: doubleBid)
                        }
                        bidLevel = nil
                    }
                case "p", " ":
                    if let selected = bids.selected {
                        bids.replace(at: selected, with: passBid)
                    }
                    bidLevel = nil
                case "x":
                    if let selected = bids.selected {
                        bids.replace(at: selected, with: doubleBid)
                    }
                    bidLevel = nil
                case "r":
                    if let selected = bids.selected {
                        bids.replace(at: selected, with: redoubleBid)
                    }
                    bidLevel = nil
                default:
                    break
                }
                index = bids.selected ?? index
            }
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
    var width: CGFloat
    
    var body: some View {
        Button {
            if bids.inEditMode {
                if bids.selectable(index) {
                    Utility.mainThread {
                        bids.set(selected: index)
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
            let text = bids.element(index).bid?.colorCompact ?? AttributedString(index == bids.count && bids.inEditMode ? "-" : "")
            VStack(spacing: 0) {
                Spacer()
                HStack(spacing: 0) {
                    Spacer()
                    Text(text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                    Spacer()
                }
                .frame(width: width)
                .fixedSize()
                .palette((bids.element(index).announce ?? "") != "" ? .card : (bids.element(index).alerted ? .alternate : .clear))
                .cornerRadius(bids.inEditMode ? 8 : 4)
                .if(bids.inEditMode) { view in
                    view.overlay(RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Palette.gridLine, lineWidth: (bids.inEditMode && index == bids.selected ? 3 : 0)))
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onChange(of: bids.count) {
                bids.set(selected: bids.count)
            }
        }
        .buttonStyle(.plain)
        .focusable(false)
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
            AttributedString(compact)
        default:
            super.colorCompact
        }
    }
    
    override var compact: String {
        switch level {
        case .blank, .passout:
            switch double {
            case .undoubled:
                "Pass"
            case .doubled:
                "Dbl"
            case .redoubled:
                "Rdbl"
            }
        default:
            super.compact
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
