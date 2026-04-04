//
//  Bidding Editor View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 02/04/2026.
//

import SwiftUI

struct BiddingEditorView: View {
    @ObservedObject var bids: Auction
    @Binding var traveller: TravellerViewModel
    @Binding var sitting: Seat
    @State var dealer: Seat
    @Binding var boardNumber: Int
    @Binding var bidAnnounce: String
    @State var showClaim: Bool = false
    @State var editBidding: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
            VStack(spacing: 0) {
                Spacer().frame(height: 30)
                HStack {
                    Spacer()
                    BiddingViewer(bids: bids, sitting: $sitting, boardNumber: $boardNumber, bidAnnounce: $bidAnnounce, showClaim: $showClaim, editBidding: $editBidding, inEditMode: true)
                        .frame(width: 300, height: 260)
                    Spacer()
                }
                Spacer().frame(height: 30)
                BiddingBoxView(bids: bids)
                Spacer().frame(height: 30)
                BiddingEditorButtons(bids: bids, traveller: $traveller, sitting: $sitting, dealer: dealer)
                Spacer()
            }
        }
        .font(inputTitleFont)
        .background(BackgroundBlurView(opacity: 0.0))
    }
}

struct BiddingEditorButtons : View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var bids: Auction
    @Binding var traveller: TravellerViewModel
    @Binding var sitting: Seat
    @State var dealer: Seat
    
    var body: some View {
        HStack {
            button("Cancel") {
                bids.set(from: traveller.playData, sitting: sitting, dealer: dealer)
                dismiss()
            }
            Spacer().frame(width: 50)
            button("Update") {
                traveller.playData = bids.playData
                dismiss()
            }
        }
        .focusable(false)
    }
    
    func button(_ text: String, action: @escaping ()->()) -> some View {
        Button {
            action()
        } label: {
            MiddleCentered {
                Text(text)
            }
            .frame(width: 130, height: 40)
            .font(.callout)
            .palette(.enabledButton)
            .cornerRadius(20)
        }
    }
}


struct BiddingBoxView : View {
    @ObservedObject var bids: Auction
    var body: some View {
        HStack {
            Spacer().frame(width: 10)
            VStack {
                Spacer().frame(height: 10)
                let levels = ContractLevel.validCases
                ForEach(levels) { level in
                    BiddingBoxRowView(bids: bids, level: level)
                }
                Spacer().frame(height: 10)
                HStack {
                    let bidData = [("Pass", Palette.pass), ("Dbl", Palette.double), ("Rdbl", Palette.redouble)]
                    ForEach(0..<3) { (index) in
                        let (bidName, palette) = bidData[index]
                        Button {
                            bids.add(bid: AttributedString(bidName), alerted: false, explain: nil)
                        } label: {
                            BidView(bid: AttributedString(bidName), palette: palette, width: 106)
                        }
                    }
                }
                Spacer().frame(height: 10)
            }
            Spacer().frame(width: 10)
        }
        .background(Palette.tile.background)
        .focusable(false)
        .cornerRadius(10)
    }
}

struct BiddingBoxRowView : View {
    @ObservedObject var bids: Auction
    var level: ContractLevel
    
    var body: some View {
        HStack(spacing: 9) {
            let suits = Suit.validCases
            ForEach(suits, id:\.self) { suit in
                let contract = Contract(level: level, suit: suit, double: .undoubled)
                Button {
                    bids.add(bid: contract.colorCompact, alerted: false, explain: nil)
                } label: {
                    BidView(bid: contract.colorString, palette: Palette.card, width: 60)
                }
            }
        }
    }
}

struct BidView : View {
    @State var bid: AttributedString
    @State var palette: PaletteColor
    @State var width: CGFloat
    
    var body: some View {
        ZStack {
            UnevenRoundedRectangle(cornerRadii: .init(topLeading: 6, bottomLeading: 0, bottomTrailing: 0, topTrailing: 12), style: .continuous)
                .foregroundColor(palette.background)
            HStack {
                Text(bid)
            }
            .foregroundColor(palette.text)
        }
        .frame(width: width, height: 40)
    }
}

