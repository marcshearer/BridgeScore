//
//  AutoComplete.swift
//  BridgeScore
//
//  Created by Marc Shearer on 25/03/2026.
//

import Foundation

enum AutoCompleteConsider {
    case lastWord
    case trailingAlpha
    case trailingAlphaNumeric
}

protocol AutoCompleteDelegate {
    func replace(with: String, positionAt: NSRange)
}

class AutoCompleteElement: Hashable {
    var replace: String
    var with: String
    var description: String
    
    init(replace: String, with: String, description: String) {
        self.replace = replace
        self.with = with
        self.description = description
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(replace)
        hasher.combine(with)
    }
    
    static func == (lhs: AutoCompleteElement, rhs: AutoCompleteElement) -> Bool {
        lhs.replace == rhs.replace && lhs.with == rhs.with
    }
}

class AutoComplete: ObservableObject {
    var id = UUID()
    @Published var text: String = ""
    var list: [AutoCompleteElement] = []
    @Published var filteredList: [AutoCompleteElement] = []
    @Published var selected: Int? = nil
    var consider: AutoCompleteConsider!
    var mustStart: Bool = false
    var searchDescription: Bool = true
    @Published var range: NSRange?
    @Published var match: String?
    var adjustReplace: ((String, Bool, Bool)->String)?
    var delegate: AutoCompleteDelegate? = nil
    
    init() {
    }
    
    init(list: [AutoCompleteElement], consider: AutoCompleteConsider = .lastWord, adjustReplace: ((String, Bool, Bool)->String)? = nil, mustStart: Bool = true, searchDescription: Bool = false) {
        self.set(list: list, consider: consider, adjustReplace: adjustReplace, mustStart: mustStart, searchDescription: searchDescription)
    }
    
    func set(list: [AutoCompleteElement], consider: AutoCompleteConsider = .lastWord, adjustReplace: ((String, Bool, Bool)->String)? = nil, mustStart: Bool = true, searchDescription: Bool = false) {
        self.list = list
        self.consider = consider
        self.adjustReplace = adjustReplace
        self.mustStart = mustStart
        self.searchDescription = searchDescription
    }
    
    func keyPressed(keyAction: KeyAction) {
        switch keyAction {
        case .up:
            selected = max(0, (selected ?? 1) - 1)
        case .down:
            selected = min(filteredList.count - 1, (selected ?? -1) + 1)
        case .enter:
            if let selected = selected {
                replace(with: filteredList[selected].with)
            }
        default:
            break
        }
    }
    
    @discardableResult public func set(text: String, at range: NSRange?) -> Int {
        self.text = text
        self.range = range
        let string = NSString(string: text)
        
        selected = nil
        match = ""
        filteredList = []
        
        if let range = range {
            let previous = string.substring(with: NSRange(location: 0, length: range.location + range.length)) as String
            switch consider! {
            case .lastWord:
                match = previous.components(separatedBy: " ").last
            case .trailingAlpha, .trailingAlphaNumeric:
                match = trailingCharacters(text: previous, consider: consider)
            }
            if let match = match {
                if match.length > 0 {
                    for description in 0...(searchDescription ? 1 : 0) {
                        filteredList = filteredList + list.filter({(description == 1 ? $0.description : $0.replace).lowercased().matches(match.lowercased(), mustStart ? .starts : .contains)}).filter({$0.with != match})
                    }
                }
                if searchDescription {
                    filteredList = Array(Set(filteredList))
                }
            }
        }
        if !filteredList.isEmpty {
            if selected == nil {
                selected = 0
            }
        }
        return filteredList.count
    }
    
    public func replace(with: String) {
        if let match = match, let range = range {
            let textLength = NSString(string: text).length
            let matchLength = NSString(string: match).length
            var with = with
            with = adjustReplace?(with, range.location - matchLength == 0, range.location + range.length == textLength) ?? with
            let withLength = NSString(string: with).length
            let result = NSString(string: text).replacingCharacters(in: NSRange(location: range.location - matchLength, length: matchLength), with: with)
            delegate?.replace(with: result, positionAt: NSRange(location: range.location - matchLength + withLength, length: 0))
        }
    }
    
    public static func suitReplaceList() -> [AutoCompleteElement] {
        var list:[AutoCompleteElement] = []
        for rank in CardRank.allCases {
            list.append(contentsOf: Suit.realSuits.map({AutoCompleteElement(replace: rank.short + $0.short.uppercased(), with: rank.short + $0.string, description: "\(rank.string) \(rank.rawValue > 7 ? "of" : "") \($0.words)")}))
        }
        list.append(contentsOf: Suit.realSuits.map({AutoCompleteElement(replace: $0.short.uppercased(), with: $0.string, description: $0.words)}))
        list.append(contentsOf: Suit.realSuits.map({AutoCompleteElement(replace: "1" + $0.short.uppercased(), with: "1" + $0.string, description: "1 " + $0.singular)}))
        return list
    }
    
    func trailingCharacters(text: String, consider: AutoCompleteConsider) -> String? {
        var result = ""
        let characterSet: CharacterSet = (consider == .trailingAlpha ? .letters : .alphanumerics)
        for index in (0..<text.length).reversed() {
            let char = text.mid(index, 1)
            if char.rangeOfCharacter(from: characterSet) != nil {
                result = char + result
            } else {
                break
            }
        }
        return result
    }
}
