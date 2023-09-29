//
//  BBO Name View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 24/03/2022.
//

import UIKit

class BBONameReplaceView: UIView, UITableViewDataSource, UITableViewDelegate {
       
    private var backgroundView = UIView()
    private var contentView = UIView()
    private var instructionLabel = UILabel()
    private var closeButton = UILabel()
    private var valuesTableView: UITableView!
    private var values: [BBONameViewModel] = []
    private var selected: Int?
    private var completion: (()->())?
    private var instructionPanelHeight: CGFloat = 60
    private var instructionHeight: CGFloat = 50
    private var valuesTableViewHeight: CGFloat!
    private var buttonPanelHeight: CGFloat = 100
    private var buttonHeight: CGFloat = 50
    private var buttonWidth: CGFloat = 160
    private let rowHeight: CGFloat = 40
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        loadBBONameReplaceView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.roundCorners(cornerRadius: 20)
        closeButton.roundCorners(cornerRadius: 10)
        valuesTableView.roundCorners(cornerRadius: 10)
        valuesTableView.layer.borderColor = Palette.gridLine.cgColor
        valuesTableView.layer.borderWidth = 2
    }
    
    
       
    // MARK: - CollectionView Delegates ================================================================ -
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = BBONameReplaceCell.dequeue(tableView, for: indexPath)
        cell.set(bboName: (indexPath.row == 0 ? nil : values[indexPath.row - 1]), first: (indexPath.row == 1))
        return cell
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    // MARK: - Tap handlers ============================================================================ -
    
    @objc private func cancelPressed(_ sender: Any) {
        self.endEditing(true)
        completion?()
        hide()
    }
    
    func cancelTap(_: Int) {
        cancelPressed(self)
    }
    
    // MARK: - Show / Hide ============================================================================ -
    
    public func show(from sourceView: UIView, values: [BBONameViewModel], completion: @escaping ()->()) {
        self.values = values
        self.completion = completion
        self.frame = sourceView.frame
        backgroundView.frame = sourceView.frame
        valuesTableViewHeight = (CGFloat(min(5, values.count + 1)) * rowHeight)
        let height = instructionPanelHeight + valuesTableViewHeight + buttonPanelHeight
        contentView.frame = CGRect(x: sourceView.frame.midX - 300, y: sourceView.frame.midY - height - 70, width: 600, height: height)
        sourceView.addSubview(self)
        sourceView.bringSubviewToFront(self)
        valuesTableView.reloadData()
        self.bringSubviewToFront(contentView)
        contentView.isHidden = false
    }
    
    public func hide() {
        // self.contentView.isHidden = true
        removeFromSuperview()
    }
    
  // MARK: - View Setup ======================================================================== -
    
    private func loadBBONameReplaceView() {
        
        valuesTableView = UITableView(frame: frame)

        // Background
        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let cancelSelector = #selector(BBONameReplaceView.cancelPressed(_:))
        let backgroundTapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
        backgroundView.addGestureRecognizer(backgroundTapGesture)
        backgroundView.isUserInteractionEnabled = true
        
        // Content view
        addSubview(contentView)
        contentView.backgroundColor = UIColor(Palette.background.background)
        contentView.addShadow()

        // Instructions
        let instructionSpacing = (instructionPanelHeight - instructionHeight) / 2
        contentView.addSubview(instructionLabel, leading: 20, trailing: 20, top: instructionSpacing)
        Constraint.setHeight(control: instructionLabel, height: instructionHeight)
        instructionLabel.text = "Add or Modify Names"
        instructionLabel.font = replaceTitleFont.bold
        instructionLabel.textColor = UIColor(Palette.background.text)
        instructionLabel.textAlignment = .center
        
        // Table view
        loadTable(tableView: valuesTableView)
        Constraint.anchor(view: contentView, control: instructionLabel, to: valuesTableView, constant: instructionSpacing, toAttribute: .top, attributes: .bottom)
        
        // Close button
        let buttonSpacing = (buttonPanelHeight - buttonHeight) / 2
        contentView.addSubview(closeButton, anchored: .centerX)
        Constraint.setHeight(control: closeButton, height: buttonHeight)
        Constraint.setWidth(control: closeButton, width: buttonWidth)
        Constraint.anchor(view: contentView, control: closeButton, constant: buttonSpacing, attributes: .bottom)
        Constraint.anchor(view: contentView, control: closeButton, to: valuesTableView, constant: buttonSpacing, toAttribute: .bottom, attributes: .top)
        closeButton.backgroundColor = UIColor(Palette.highlightButton.background)
        closeButton.textColor = UIColor(Palette.highlightButton.text)
        closeButton.textAlignment = .center
        closeButton.text = "Close"
        closeButton.font = replaceTitleFont.bold
        let tapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
        closeButton.addGestureRecognizer(tapGesture)
        closeButton.isUserInteractionEnabled = true

        contentView.isHidden = true
    }
    
    func loadTable(tableView: UITableView) {
        contentView.addSubview(tableView, constant: 20, anchored: .leading, .trailing)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor(Palette.background.background)
        tableView.separatorStyle = .none
        
        BBONameReplaceCell.register(tableView)
    }
}

class BBONameReplaceCell: UITableViewCell, UITextFieldDelegate {
    private var bboNameLabel: UILabel!
    private var realNameTextField: UITextField!
    private var bboName: BBONameViewModel!
    private static let identifier = "BBO Name Replace Cell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        bboNameLabel = UILabel()
        bboNameLabel.minimumScaleFactor = 0.3
        bboNameLabel.textAlignment = .left
        contentView.addSubview(bboNameLabel, leading: 16, top: 0, bottom: 0)
        Constraint.setWidth(control: bboNameLabel, width: 200)

        realNameTextField = UITextField()
        realNameTextField.isEnabled = true
        realNameTextField.isUserInteractionEnabled = true
        realNameTextField.autocapitalizationType = .words
        realNameTextField.autocorrectionType = .no
        realNameTextField.delegate = self
        realNameTextField.addTarget(self, action: #selector(BBONameReplaceCell.textFieldChanged), for: .editingChanged)
        contentView.addSubview(realNameTextField, trailing: 16, top: 0, bottom: 0)
        Constraint.anchor(view: contentView, control: bboNameLabel, to: realNameTextField, constant: 16, toAttribute: .leading, attributes: .trailing)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func getFocus(_ sender: Any) {
        realNameTextField.becomeFirstResponder()
    }
    
    @objc private func textFieldChanged(_ textField: UITextField) {
        bboName.name = textField.text!
    }
    
    internal func textFieldDidEndEditing(_ textField: UITextField) {
        if Scorecard.current.scorecard?.importSource == .bbo {
            bboName.save()
        }
    }
    
    public class func register(_ tableView: UITableView) {
        tableView.register (BBONameReplaceCell.self, forCellReuseIdentifier: identifier)
    }
    
    public class func dequeue(_ tableView: UITableView, for indexPath: IndexPath) -> BBONameReplaceCell {
        let cell = tableView.dequeueReusableCell (withIdentifier: identifier, for: indexPath) as! BBONameReplaceCell
        return cell
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    internal override func prepareForReuse() {
        self.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = false
        self.bboName = nil
        bboNameLabel.text = ""
        realNameTextField.text = ""
    }
    
    public func set(bboName: BBONameViewModel?, first: Bool) {
        self.bboName = bboName
        
        if let bboName = bboName {
            // Real row
            bboNameLabel.text = bboName.bboName
            realNameTextField.text = bboName.name
            realNameTextField.isEnabled = true
            backgroundColor = UIColor(Palette.background.background)
            bboNameLabel.textColor = UIColor(Palette.background.text)
            realNameTextField.textColor = UIColor(Palette.background.text)
            bboNameLabel.font = replaceTitleFont.bold
            realNameTextField.font = replaceFont
            if first {
                realNameTextField.becomeFirstResponder()
            }
        } else {
            // Titles
            bboNameLabel.text = (Scorecard.current.scorecard?.importSource == .bbo ? "BBO Name" : "Current Name")
            realNameTextField.text = "Real Name"
            realNameTextField.isEnabled = false
            backgroundColor = UIColor(Palette.alternate.background)
            bboNameLabel.textColor = UIColor(Palette.alternate.text)
            realNameTextField.textColor = UIColor(Palette.alternate.text)
            bboNameLabel.font = replaceTitleFont.bold
            realNameTextField.font = replaceTitleFont.bold
        }
    }
}
