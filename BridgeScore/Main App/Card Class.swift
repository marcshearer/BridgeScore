//
//  Card.swift
//  Contract Whist Scorecard
//
//  Created by Marc Shearer on 17/12/2016.
//  Copyright © 2016 Marc Shearer. All rights reserved.
//

import UIKit

class Card : CustomStringConvertible, CustomDebugStringConvertible, Hashable {
       
    // A simple class to hold details about a card - i.e. its rank and suit and allow that to be manipulated
    
    var suit: Suit!
    var rank: Int!
    var data: Any?
    
    init(rank: Int, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }
    
    var description: String {
        return self.string
    }
    
    var debugDescription: String {
        return self.string
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.suit == rhs.suit && lhs.rank == rhs.rank
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.suit)
        hasher.combine(self.rank)
    }
    
    convenience init(rankString: String, suitString: String) {
        let rankList = "23456789TJQKA"
        var rank: Int
        if let index = rankList.firstIndex(of: Character(rankString)) {
            rank = rankList.distance(from: rankList.startIndex, to: index) + 1
        } else {
            rank = 0
        }
        let suit = Suit(string: suitString)
        self.init(rank: rank, suit: suit)
    }
    
    init(fromNumber: Int) {
        self.fromNumber(fromNumber)
    }

    func fromNumber(_ cardNumber: Int) {
        // Convert a card number (1-52) into card
        self.rank = Int((cardNumber - 1) / 4) + 1
        self.suit = Suit(rawValue: Int((cardNumber - 1) % 4) + 1)
    }
    
    func toNumber() -> Int {
        return ((self.rank - 1) * 4) + self.suit.rawValue
    }
    
    public var rankString: String {
        var rankString = ""
        switch rank {
        case 10:
            rankString = "J"
        case 11:
            rankString = "Q"
        case 12:
            rankString = "K"
        case 13:
            rankString = "A"
        default:
            rankString = "\(rank+1)"
        }
        
        return rankString
    }
    
    public var string: String {
        return "\(self.rankString)\(self.suit.string)"
    }
    
    public var colorString: AttributedString {
        return AttributedString(self.string, color: self.suit.color)
    }
    
    public var hcp: Int {
        return max(0, rank - 9)
    }
}

class Hand : NSObject, NSCopying {
    
    public var cards: [Card]!
    public var handSuits: [HandSuit]!
    public var xrefSuit: [Suit : HandSuit]!
    public var xrefElement: [Suit: Int]!
    
    override init() {
        self.cards = []
        self.handSuits = []
        self.xrefSuit = [:]
        self.xrefElement = [:]
    }
    
    init(fromNumbers cardNumbers: [Int], sorted: Bool = false) {
        super.init()
        self.fromNumbers(cardNumbers)
        if sorted {
            self.sort()
        }
    }
    
    init(fromCards cards: [Card], sorted: Bool = false) {
        super.init()
        self.cards = cards
        if sorted {
            self.sort()
        }
    }
    
    public func toNumbers() -> [Int] {
        var result: [Int] = []
        for card in self.cards {
            result.append(card.toNumber())
        }
        return result
    }
    
    public func fromNumbers(_ cardNumbers: [Int]) {
        self.cards = []
        for cardNumber in cardNumbers {
            self.cards.append(Card(fromNumber: cardNumber))
        }
    }
    
    public var string: String {
        var sortedCards: [Card] = []
        var result = ""
        for handSuit in self.handSuits {
            for card in handSuit.cards {
                sortedCards.append(card)
            }
        }
        for card in sortedCards {
            let stringCard = card.string
            if result == "" {
                result = stringCard
            } else {
                result = result + " " + stringCard
            }
        }
        return result
    }
    
    public func remove(card: Card) -> Bool {
        var result = false
        
        let cardNumber = card.toNumber()
        if let index = self.cards.firstIndex(where: {$0.toNumber() == cardNumber}) {
            self.cards.remove(at: index)
            result = true
            let handSuit = self.xrefSuit[card.suit]!
            if let index = handSuit.cards.firstIndex(where: {$0.toNumber() == cardNumber}) {
                handSuit.cards.remove(at: index)
            }
        }
        return result
    }
    
    public func find(card: Card) -> (Int, Int)? {
        if let suitNumber = self.xrefElement[card.suit] {
            let cardAsNumber = card.toNumber()
            if let cardNumber = self.handSuits[suitNumber].toNumbers().firstIndex(where: {$0 == cardAsNumber}) {
                return (suitNumber, cardNumber)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    private func sort() {
        var handSuits: [HandSuit] = []
        self.xrefSuit = [:]
        self.xrefElement = [:]
        
        // Create empty suits
        for _ in 1...4 {
            let handSuit = HandSuit()
            handSuits.append(handSuit)
        }
        
        // Sort hand
        self.cards = self.cards.sorted(by: { $0.toNumber() > $1.toNumber() })
        
        // Put hand in suits
        for card in self.cards {
            handSuits[card.suit.rawValue-1].cards.append(card)
        }
        
        // Remove empty suits
        for suitNumber in (1...4).reversed() {
            if handSuits[suitNumber - 1].cards.count == 0 {
                handSuits.remove(at: suitNumber - 1)
            }
        }
        
        self.handSuits = handSuits.reversed()
        self.setupXref()
        
    }
    
    private func setupXref() {
        for suitNumber in 0..<self.handSuits.count {
            self.xrefSuit[self.handSuits[suitNumber].cards.first!.suit] = self.handSuits[suitNumber]
            self.xrefElement[self.handSuits[suitNumber].cards.first!.suit] = suitNumber
        }
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        // Copy elements rather than pointers
        let copy = Hand()
        // Copy cards
        for card in self.cards {
            copy.cards.append(card)
        }
        // Copy suits
        if self.handSuits.count > 0 {
            for handSuit in self.handSuits {
                copy.handSuits.append(handSuit.copy() as! HandSuit)
            }
        }
        // Create xref
        for (suit, element) in self.xrefElement {
            copy.xrefSuit[suit] = copy.handSuits[element]
            copy.xrefElement[suit] = element
        }
        return copy
    }
    
    public var hcp: Int {
        return cards.map{$0.hcp}.reduce(0,+)
    }
    
    public var shape: String {
        var suitLength: [Int] = []
        for suit in Suit.realSuits {
            suitLength.append(xrefSuit[suit]?.cards.count ?? 0)
        }
        return suitLength.sorted(by: {$0 > $1}).map{"\($0)"}.joined(separator: "-")
    }
}

class HandSuit: NSObject, NSCopying {
    
    public var cards: [Card]!
    
    override init() {
        cards = []
    }
    
    init(fromNumbers: [Int]) {
        cards = []
        for number in fromNumbers {
            self.cards.append(Card(fromNumber: number))
        }
    }
    
    public func toNumbers() -> [Int] {
        var result: [Int] = []
        for card in self.cards {
            result.append(card.toNumber())
        }
        return result
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        // Copy elements rather than pointers
        let copy = HandSuit(fromNumbers: self.toNumbers())
        return copy
    }
}

class Deal: NSObject, NSCopying {
    
    public var hands: [Seat:Hand]!
    
    override init() {
        hands = [:]
    }
    
    init(fromCards: [String]) {
        hands = [:]
        if fromCards.count >= 16 {
            for hand in (0...3) {
                var cards: [Card] = []
                let start = hand * 4
                for suit in (0...3) {
                    if fromCards[start + suit].count > 0 {
                        for card in 0...(fromCards[start + suit].count - 1) {
                            cards.append(Card(rankString: fromCards[start + suit].mid(card,1), suitString: "SHDC".mid(suit, 1)))
                        }
                    }
                }
                hands[Seat(rawValue: hand + 1)!] = Hand(fromCards: cards, sorted: true)
            }
        }
    }
    
    public func toNumbers() -> [[Int]] {
        var result: [[Int]] = []
        for (_, hand) in self.hands {
            result.append(hand.toNumbers())
        }
        return result
    }
    
    public func toString() -> String {
        var result = "["
        for (index, (_, hand)) in self.hands.enumerated() {
            if index != 0 {
                result += ", "
            }
            result += "[\(hand.string)]"
        }
        result += "]"
        return result
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = Deal()
        for (seat, hand) in self.hands {
            copy.hands[seat] = hand.copy() as? Hand
        }
        return copy
    }
}

class Trick : CustomStringConvertible, CustomDebugStringConvertible {
    var trickNumber: Int
    var lead: Seat
    var cards: [Card]
    var winner: Seat
    var nsTricks: Int
    
    init(trick: Int, lead: Seat, cards: [Card], winner: Seat, nsTricks: Int) {
        self.trickNumber = trick
        self.lead = lead
        self.cards = cards
        self.winner = winner
        self.nsTricks = nsTricks
    }
    
    var description: String {
        return "Trick: \(trickNumber), Lead: \(lead.string), Cards: \(cards), Winner: \(winner.string), N/S Tricks: \(nsTricks)"
    }
    
    var debugDescription: String {
        return description
    }
}
