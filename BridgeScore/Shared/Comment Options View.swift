//
//  Comment Options.swift
//  BridgeScore
//
//  Created by Marc Shearer on 01/04/2026.
//

import UIKit

enum CommentOption: CaseIterable {
    case hide
    case hideIfBlank
    case show
    case toggle
    
    var string: String {
        switch self {
        case .hide:
            "No Comments"
        case .show:
            "All Comments"
        case .hideIfBlank:
            "Non-Blank Only"
        case .toggle:
            "Toggle"
        }
    }
    
    static var allBoardOptions: [CommentOption] {
        allCases.filter{$0 != .toggle}
    }
}

class CommentOptionsView: UIView, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    var panel = UIView()
    var tableView = UITableView()
    var selected: CommentOption?
    var completion: ((CommentOption?) -> ())?
    let values = CommentOption.allBoardOptions
    let rowHeight: CGFloat = 60
    let width: CGFloat = 240
    let padding: CGFloat = 4
    override var canBecomeFirstResponder: Bool { true }
    
    init(completion: ((CommentOption?) -> ())? = nil) {
        self.completion = completion
        super.init(frame: CGRect())
        self.addSubview(panel)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(CommentOptionsView.frameTapped(_:)))
        self.addGestureRecognizer(tapGesture)
        tapGesture.isEnabled = true
        tapGesture.delegate = self
        panel.addSubview(tableView, leading: 4, trailing: 4, top: 4, bottom: 4)
        panel.roundCorners(cornerRadius: 8)
        self.tableView.roundCorners(cornerRadius: 7)
        panel.backgroundColor = UIColor(Palette.gridLine)
        CommentOptionCell.register(tableView)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func didMoveToSuperview() {
            // Cover the superview
        super.didMoveToSuperview()
        self.frame = superview!.frame
    }
    
    func set(selected: CommentOption?) {
        self.selected = selected
    }
    
    func set(position: CGPoint) {
        let size = CGSize(width: width, height: (CGFloat(values.count) * rowHeight) + (CGFloat(2) * padding))
        panel.frame = CGRect(origin: CGPoint(x: position.x - size.width, y: position.y), size: size)
    }
    
    func set(visible: Bool) {
        self.isHidden = !visible
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func frameTapped(_ sender: UITapGestureRecognizer) {
        set(visible: false)
        completion?(nil)
    }
    
    @objc(gestureRecognizer:shouldReceiveTouch:) func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view?.isDescendant(of: tableView) ?? false)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = CommentOptionCell.dequeue(tableView: tableView, for: indexPath)
        cell.set(text: values[indexPath.row].string, selected: values[indexPath.row] == selected)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        completion?(values[indexPath.row])
        selected = values[indexPath.row]
        tableView.reloadData()
        self.set(visible: false)
        completion?(selected)
    }
    
    override func resignFirstResponder() -> Bool {
        self.isHidden = true
        return true
    }
}

class CommentOptionCell: UITableViewCell {
    private var inset = UIView()
    private var label = UILabel()
    static public var cellIdentifier = "Comment Option Cell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(inset, leading: 4, trailing: 4, top: 4, bottom: 4)
        inset.addSubview(label, leading: 8, trailing: 8, top: 8, bottom: 8)
        inset.roundCorners(cornerRadius: 7)
        self.roundCorners(cornerRadius: 7)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    public class func register(_ tableView: UITableView, forTitle: Bool = false) {
        tableView.register(CommentOptionCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    public class func dequeue(tableView: UITableView, for indexPath: IndexPath) -> CommentOptionCell {
        return tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CommentOptionCell
    }
    
    public func set(text: String, selected: Bool) {
        let color = selected ? Palette.autoCompleteSelected : Palette.background
        label.text = text
        inset.backgroundColor = UIColor(color.background)
        label.backgroundColor = .clear
        label.textColor = UIColor(color.text)
        label.font = smallCellFont
        self.selectionStyle = .none
    }
}
