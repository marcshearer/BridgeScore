//
//  Auto Complete ListView.swift
//  BridgeScore
//
//  Created by Marc Shearer on 07/11/2023.
//

import UIKit

protocol AutoCompleteListViewDelegate {
    func replace(with: String, textInput: ScorecardInputTextInput, positionAt: NSRange)
    func autoCompleteDidMoveToSuperview(autoComplete: AutoCompleteListView)
    func autoCompleteWillMoveToSuperview(autoComplete: AutoCompleteListView)
}

class AutoCompleteListView: UIView, ObservableObject, UITableViewDataSource, UITableViewDelegate {
    var autoComplete: AutoComplete
    var tableView = UITableView()
    var textInput: ScorecardInputTextInput?
    var selectedRow: Int?
    var delegate: AutoCompleteListViewDelegate?
    var isActive: Bool = false {
        didSet {
            isHidden = !isActive
        }
    }
    
    init(autoComplete: AutoComplete? = nil) {
        self.autoComplete = autoComplete ?? AutoComplete()
        super.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 100, height: 100)))
        self.isHidden = true
        addSubview(tableView, leading: 2, trailing: 2, top: 2, bottom: 2)
        AutoCompleteCell.register(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
    }
    
    override func didMoveToSuperview() {
        delegate?.autoCompleteDidMoveToSuperview(autoComplete: self)
    }
    
    override func willMove(toSuperview: UIView?) {
        delegate?.autoCompleteWillMoveToSuperview(autoComplete: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func set(list: [AutoCompleteElement], consider: AutoCompleteConsider = .lastWord, adjustReplace: ((String, Bool, Bool)->String)? = nil, mustStart: Bool = true, searchDescription: Bool = false) {
        autoComplete.set(list: list, consider: consider, adjustReplace: adjustReplace, mustStart: mustStart, searchDescription: searchDescription)
    }
    
    public func set(text: String, textInput: ScorecardInputTextInput?, at range: NSRange?) -> Int {
        self.textInput = textInput
        self.superview?.bringSubviewToFront(self)
        self.bringSubviewToFront(tableView)
        let matches = self.autoComplete.set(text: text, at: range)
                
        isActive = (matches > 0)
        selectedRow = 0
        
        tableView.reloadData()
        return matches
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
            if (selectedRow ?? Int.max) < autoComplete.filteredList.count - 1 {
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
        return autoComplete.filteredList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = AutoCompleteCell.dequeue(tableView: tableView, for: indexPath)
        cell.set(text: autoComplete.filteredList[indexPath.row].replace, description: autoComplete.filteredList[indexPath.row].description, selected: indexPath.row == selectedRow)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let textInput = textInput {
            if let match = autoComplete.match, let range = autoComplete.range {
                let textLength = NSString(string: autoComplete.text).length
                let matchLength = NSString(string: match).length
                var with = autoComplete.filteredList[indexPath.row].with
                with = autoComplete.adjustReplace?(with, range.location - matchLength == 0, range.location + range.length == textLength) ?? with
                let withLength = NSString(string: with).length
                let result = NSString(string: autoComplete.text).replacingCharacters(in: NSRange(location: range.location - matchLength, length: matchLength), with: with)
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
