//
//  Bidding Editor View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 02/04/2026.
//

import SwiftUI

enum BiddingFocusField : Hashable {
    case explain
}

enum BiddingId {
    case biddingViewer
}

struct BiddingEditorView: View {
    @ObservedObject var bids: Auction
    @Binding var traveller: TravellerViewModel
    @Binding var sitting: Seat
    @State var dealer: Seat
    @Binding var boardNumber: Int
    @Binding var bidAnnounce: String
    @State var showClaim: Bool = false
    @State var editBidding: Bool = false
    var cancelEdit: ((Bool)->())
    @Namespace private var biddingViewerNameSpace
    @FocusState var focusedField: BiddingFocusField?
    
    var body: some View {
        StandardView("Bidding Editor") {
            ZStack {
                Color.black.opacity(0.65)
                    .focusable(false)
                HStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 0) {
                        Spacer().frame(height: 30)
                        
                        BiddingViewer(bids: bids, focusedField: $focusedField, sitting: $sitting, boardNumber: $boardNumber, bidAnnounce: $bidAnnounce, showClaim: $showClaim, editBidding: $editBidding, cancelEdit: cancelEdit)
                            .matchedGeometryEffect(id: BiddingId.biddingViewer, in: biddingViewerNameSpace, anchor: .topTrailing, isSource: true)
                            .frame(width: 300, height: 260)
                        
                        Spacer().frame(height: 20)
                        
                        BiddingAnnounceView(bids: bids, focusedField: $focusedField)
                        
                        Spacer().frame(height: 40)
                        
                        BiddingBoxView(bids: bids)
                        
                        Spacer().frame(height: 30)
                        
                        BiddingEditorButtons(bids: bids, requiredContract: traveller.contract, traveller: $traveller, sitting: $sitting, dealer: dealer, cancelEdit: cancelEdit)
                        
                        Spacer()
                        
                    }
                    Spacer().frame(width: 100)
                    Spacer()
                }
                .zIndex(2)
                .overlay(alignment: .trailing) {
                    VStack {
                        HStack {
                            Spacer().frame(width: 40)
                            BiddingViewerToolbar(bids: bids)
                            Spacer()
                        }
                        Spacer().layoutPriority(999)
                    }
                    .focusable(false)
                    .matchedGeometryEffect(
                        id: BiddingId.biddingViewer,
                        in: biddingViewerNameSpace,
                        properties: .position,
                        anchor: .topLeading,
                        isSource: false)
                }
            }
            .font(inputTitleFont)
            .background(BackgroundBlurView(opacity: 0.0))
            .onAppear {
                bids.set(inEditMode: true)
            }
            .focusable(false)
        }
    }
}

struct BiddingAnnounceView : View {
    @Environment(\.isFocused) var isFocused
    @ObservedObject var bids: Auction
    @FocusState.Binding var focusedField: BiddingFocusField?
    
    var nonOptional: Binding<String> {
        Binding {
            bids.element(bids.selected!).announce ?? ""
        } set: { (newValue) in
            bids.bidList[bids.selected! - bids.skip].announce = (newValue == "" ? nil : newValue)
        }
    }
    
    var body : some View {
        VStack(spacing: 0) {
            Spacer()
            if let selected = bids.selected, bids.element(selected).bid != nil {
                InputFocused(title: "", field: nonOptional, focusedField: $focusedField, focusValue: BiddingFocusField.explain, placeHolder: "Enter explanation", width: 230, color: Palette.clear, font: inputTitleFont, multiLine: false, inlineTitleWidth: 0, accessibilityIdentifier: "Explanation", onLoseFocus: {
                    Utility.mainThread {
                        focusedField = nil
                    }
                })
            } else {
                HStack {
                    Spacer().frame(width: 27)
                    Text("No explanation allowed")
                        .font(inputTitleFont)
                        .background(.clear)
                        .foregroundColor(Palette.input.faintText.opacity(0.5))
                    Spacer()
                }
            }
            Spacer()
        }
        .frame(width: 300)
        .background(Palette.handTable.background)
        .frame(height: 50)
        .cornerRadius(20)
        .focusable(false)
    }
}

struct BiddingViewerToolbar : View {
    @ObservedObject var bids: Auction
    
    var body: some View {
        let selected = bids.selected ?? bids.count
        
        VStack(spacing: 20) {
            
            BiddingEditorButton(text: "Delete") {
                bids.removeLast()
            }
            .disabled(bids.selected != bids.count || bids.bidList.isEmpty)
            
            BiddingEditorButton(text: "Clear") {
                bids.clear()
            }
            .disabled(bids.bidList.isEmpty)
            
            BiddingEditorButton(text: bids.element(selected).alerted ? "Un-Alert" : "Alert") {
                bids.set(alerted: !bids.element(selected).alerted)
            }
            .disabled(selected == bids.count)
            
            Spacer()
        }
        .focusable(false)
    }
}

struct BiddingEditorButtons : View {
    @ObservedObject var bids: Auction
    var requiredContract: Contract
    @Binding var traveller: TravellerViewModel
    @Binding var sitting: Seat
    @State var dealer: Seat
    var cancelEdit: ((Bool)->())
    
    var body: some View {
        HStack {
            BiddingEditorButton(text: "Cancel") {
                cancelEdit(false)
            }
            Spacer().frame(width: 50)
            BiddingEditorButton(text: "Update") {
                var message = ""
                if bids.contract != requiredContract {
                    message = "The contract was \(requiredContract.compact), but the result of this auction is \(bids.contract.compact)"
                } else if !bids.ends3Passes {
                    message = "This auction does not end with 3 passes"
                }
                
                MessageBox.shared.show("\(message)\n\nAre you sure you want to save this auction?", if: message != "", cancelText: "Re-edit", okText: "Save", okAction: {
                    cancelEdit(true)
                })
            }
        }
        .focusable(false)
    }
}

struct BiddingEditorButton : View {
    @Environment(\.isEnabled) private var isEnabled
    var text: String
    var action: ()->()
    
    var body : some View {
        Button {
            action()
        } label: {
            MiddleCentered {
                Text(text)
            }
            .bold()
            .frame(width: 130, height: 40)
            .font(inputTitleFont)
            .palette(isEnabled ? .enabledButton : .disabledButton)
            .opacity(isEnabled ? 1 : 0.7)
            .cornerRadius(20)
        }
        .focusable(false)
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
                    ForEach(ContractDouble.allCases) { doubleValue in
                        let bid = Bid(double: doubleValue)
                        let canBid = bids.can(bid: bid, at: bids.selected)
                        Button {
                            bids.replace(at: (bids.selected ?? bids.count), with: bid, alerted: false, announce: nil)
                        } label: {
                           if canBid {
                                BidView(bid: bid, canBid: true, width: 106)
                            } else {
                                BidView(bid: bid, canBid: false, width: 106)
                            }
                        }
                        .disabled(!canBid)
                    }
                }
                Spacer().frame(height: 10)
            }
            Spacer().frame(width: 10)
        }
        .background(Palette.handTable.background)
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
                let bid = Bid(level: level, suit: suit, double: .undoubled)
                let canBid = bids.can(bid: bid, at: bids.selected)
                Button {
                    bids.replace(at: (bids.selected ?? bids.count), with: bid, alerted: false, announce: nil)
                } label: {
                    if canBid {
                        BidView(bid: bid, canBid: true, width: 60)
                    } else {
                        BidView(bid: bid, canBid: false, width: 60)
                    }
                }
                .disabled(!canBid)
            }
        }
        .focusable(false)
    }
}

struct BidView : View {
    @Environment(\.isEnabled) private var isEnabled
    @State var bid: Bid
    var canBid: Bool
    @State var width: CGFloat
    
    var body: some View {
        ZStack {
            UnevenRoundedRectangle(cornerRadii: .init(topLeading: 6, bottomLeading: 0, bottomTrailing: 0, topTrailing: 12), style: .continuous)
                .foregroundColor(bid.palette.background)
            HStack {
                Text(bid.colorCompact)
            }
            .foregroundColor(bid.double != .undoubled && !isEnabled ? bid.palette.faintText :  bid.palette.text)
        }
        .opacity(canBid ? 1 : 0.4)
        .frame(width: width, height: 40)
        .focusable(false)
    }
}

