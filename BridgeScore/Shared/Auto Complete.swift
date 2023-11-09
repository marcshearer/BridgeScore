//
//  Auto Complete View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 07/11/2023.
//

import UIKit

protocol AutoCompleteDelegate {
    func replace(with: String, textInput: ScorecardInputTextInput, positionAt: NSRange)
}

enum AutoCompleteConsider {
    case lastWord
    case trailingAlpha
    case trailingAlphaNumeric
}

class AutoCompleteElement: Hashable {
    var replace: String
    var with: String
    var description: String
    
    init(element: (replace: String, with: String, description: String)) {
        replace = element.replace
        with = element.with
        description = element.description
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(replace)
        hasher.combine(with)
    }
    
    static func == (lhs: AutoCompleteElement, rhs: AutoCompleteElement) -> Bool {
        lhs.replace == rhs.replace && lhs.with == rhs.with
    }
}

class AutoComplete: UIView, UITableViewDataSource, UITableViewDelegate {
    var tableView = UITableView()
    var text: String = ""
    var list: [AutoCompleteElement] = []
    var filteredList: [AutoCompleteElement] = []
    var textInput: ScorecardInputTextInput?
    var consider: AutoCompleteConsider!
    var mustStart: Bool = false
    var searchDescription: Bool = true
    var range: NSRange!
    var match: String?
    var selectedRow: Int?
    var adjustReplace: ((String, Bool, Bool)->String)?
    var delegate: AutoCompleteDelegate?
    var isActive: Bool = false {
        didSet {
            isHidden = !isActive
        }
    }
    
    init() {
        super.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 100, height: 100)))
        self.isHidden = true
        addSubview(tableView, leading: 2, trailing: 2, top: 2, bottom: 2)
        AutoCompleteCell.register(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func set(list: [(replace: String, with: String, description: String)], consider: AutoCompleteConsider = .lastWord, adjustReplace: ((String, Bool, Bool)->String)? = nil, mustStart: Bool = true, searchDescription: Bool = false) {
        self.list = list.map({AutoCompleteElement(element: $0)})
        self.consider = consider
        self.adjustReplace = adjustReplace
        self.mustStart = mustStart
        self.searchDescription = searchDescription
    }
    
    public func set(text: String, textInput: ScorecardInputTextInput?, at range: NSRange) -> Int {
        self.textInput = textInput
        self.text = text
        self.range = range
        let string: NSString = NSString(string: text)
        
        match = ""
        filteredList = []
        
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
        
        isActive = !filteredList.isEmpty
        selectedRow = 0
        
        tableView.reloadData()
        return filteredList.count
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
    
    public func keyPressed(keyAction: KeyAction) -> Bool {
        var handled = false
        switch keyAction {
        case .up:
            if (selectedRow ?? 0) > 0 {
                let oldSelectedRow = selectedRow
                selectedRow = selectedRow! - 1
                tableView.reloadRows(at: [IndexPath(row: selectedRow!, section: 0), IndexPath(row: oldSelectedRow!, section: 0)], with: .automatic)
                tableView.scrollToRow(at: IndexPath(row: selectedRow!, section: 0), at: .none, animated: true)
            }
            handled = true

        case .down:
            if (selectedRow ?? Int.max) < filteredList.count - 1 {
                let oldSelectedRow = selectedRow
                selectedRow = selectedRow! + 1
                tableView.reloadRows(at: [IndexPath(row: selectedRow!, section: 0), IndexPath(row: oldSelectedRow!, section: 0)], with: .automatic)
                tableView.scrollToRow(at: IndexPath(row: selectedRow!, section: 0), at: .none, animated: true)
            }
            handled = true
        case .enter:
            if let selectedRow = selectedRow {
                tableView(tableView, didSelectRowAt: IndexPath(row: selectedRow, section: 0))
                handled = true
            }
        default:
            break
        }
        return handled
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = AutoCompleteCell.dequeue(tableView: tableView, for: indexPath)
        cell.set(text: filteredList[indexPath.row].replace, description: filteredList[indexPath.row].description, selected: indexPath.row == selectedRow)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let textInput = textInput {
            if let match = match {
                let textLength = NSString(string: text).length
                let matchLength = NSString(string: match).length
                var with = filteredList[indexPath.row].with
                with = adjustReplace?(with, range.location - matchLength == 0, range.location + range.length == textLength) ?? with
                let withLength = NSString(string: with).length
                let result = NSString(string: text).replacingCharacters(in: NSRange(location: range.location - matchLength, length: matchLength), with: with)
                delegate?.replace(with: result, textInput: textInput, positionAt: NSRange(location: range.location - matchLength + withLength, length: 0))
            }
        }
    }
}

class AutoCompleteCell: UITableViewCell {
    private var spacer = UILabel()
    private var label = UILabel()
    private var desc = UILabel()
    static public var cellIdentifier = "Auto Complete Cell"
    private var descWidth: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(spacer, leading: 0, top: 0, bottom: 0)
        Constraint.setWidth(control: spacer, width: 8)
        addSubview(label, top: 0, bottom: 0)
        addSubview(desc, trailing: 0, top: 0, bottom: 0)
        Constraint.anchor(view: self, control: spacer, to: label, constant: 0, toAttribute: .leading, attributes: .trailing)
        Constraint.anchor(view: self, control: label, to: desc, constant: 0, toAttribute: .leading, attributes: .trailing)
        descWidth = Constraint.setWidth(control: desc, width: 0)
        
        self.backgroundColor = UIColor(Palette.autoComplete.background)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    public class func register(_ tableView: UITableView, forTitle: Bool = false) {
        tableView.register(AutoCompleteCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    public class func dequeue(tableView: UITableView, for indexPath: IndexPath) -> AutoCompleteCell {
        return tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! AutoCompleteCell
    }
    
    public func set(text: String, description: String = "", selected: Bool) {
        label.text = text
        desc.text = description
        label.font = cellFont
        let color = selected ? Palette.autoCompleteSelected : Palette.autoComplete
        spacer.backgroundColor = UIColor(color.background)
        label.backgroundColor = UIColor(color.background)
        label.textColor = UIColor(color.textColor(.normal))
        desc.backgroundColor = UIColor(color.background)
        desc.textColor = UIColor(color.textColor(.contrast))
        desc.font = cellFont
        descWidth.constant = (description == "" ? 0 : self.frame.width / 2)
    }
}

extension String {
    
    enum StartsOrContainsMode {
        case starts
        case contains
    }
    
    func matches(_ value: String, _ mode: StartsOrContainsMode) -> Bool {
        switch mode {
        case .starts:
            self.starts(with: value)
        case .contains:
            self.contains(value)
        }
    }
}
