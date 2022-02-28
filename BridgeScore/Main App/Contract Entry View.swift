//
//  Contract Entry View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 19/02/2022.
//

import UIKit

fileprivate enum ContractCollection: Int {
    case level = 1
    case suit = 2
    case double = 3
    case declarer = 4
    
    var buttonWidth: CGFloat {
        switch self {
        case .level:
            return 60
        case .suit:
            return 60
        case .double:
            return passoutButtonWidth
        case .declarer:
            return 80
        }
    }
}

fileprivate let buttonHeight: CGFloat = 40
fileprivate let actionButtonWidth: CGFloat = 120
fileprivate let passoutButtonWidth: CGFloat = 320 / 3
fileprivate let buttonSpaceX: CGFloat = 10
fileprivate let buttonSpaceY: CGFloat = 20

class ContractEntryView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
       
    private var backgroundView = UIView()
    private var contentView = UIView()
    private var title = UILabel()
    private var levelCollectionView: UICollectionView!
    private var suitCollectionView: UICollectionView!
    private var doubleCollectionView: UICollectionView!
    private var declarerCollectionView: UICollectionView!
    private var passOutLabel = UILabel()
    private var declarerLabel = UILabel()
    private var cancelButton = UILabel()
    private var selectButton = UILabel()
    private var contract = Contract()
    private var declarer: Seat?
    private var completion: ((Contract, Seat?)->())?
    private var heightConstraint: NSLayoutConstraint!
    private var declarerList: [ScrollPickerEntry]!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadContractEntryView()
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        loadContractEntryView()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        title.roundCorners(cornerRadius: 20, corners: [.topLeft, .topRight])
        passOutLabel.roundCorners(cornerRadius: 10)
        cancelButton.roundCorners(cornerRadius: 10)
        selectButton.roundCorners(cornerRadius: 10)
    }
    
    // MARK: - CollectionView Delegates ================================================================ -
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let collection = ContractCollection(rawValue: collectionView.tag) {
            switch collection {
            case .level:
                return ContractLevel.validCases.count
            case .suit:
                return ContractSuit.validCases.count
            case .double:
                return ContractDouble.allCases.count
            case .declarer:
                return declarerList.count
            }
        } else {
            fatalError()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let collection = ContractCollection(rawValue: collectionView.tag) {
            let width = collection.buttonWidth + buttonSpaceX
            return CGSize(width: width, height: (collection == .declarer ? collection.buttonWidth : buttonHeight))
        } else {
            fatalError()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let collection = ContractCollection(rawValue: collectionView.tag) {
            switch collection {
            case .level:
                let level = ContractLevel.validCases[indexPath.row]
                let cell = ContractEntryCollectionCell<ContractLevel>.dequeue(collectionView, for: indexPath)
                cell.set(value: level, selected: (level == contract.level), tapAction: levelTapped)
                return cell
            case .suit:
                let suit = ContractSuit.validCases[indexPath.row]
                let cell = ContractEntryCollectionCell<ContractSuit>.dequeue(collectionView, for: indexPath)
                cell.set(value: suit, selected: (suit == contract.suit), disabled: !contract.level.hasSuit, tapAction: suitTapped)
                return cell
            case .double:
                let double = ContractDouble.allCases[indexPath.row]
                let cell = ContractEntryCollectionCell<ContractDouble>.dequeue(collectionView, for: indexPath)
                cell.set(value: double, selected: (double == contract.double), disabled: !contract.suit.hasDouble, tapAction: doubleTapped)
                return cell
            case .declarer:
                let declarer = Seat.allCases[indexPath.row]
                let cell = ScrollPickerCell.dequeue(collectionView, for: indexPath)
                let disabled = !contract.suit.hasDouble && contract.level != .passout
                let selected = (declarer == self.declarer)
                let color = (disabled ? Palette.contractDisabled : (selected ? Palette.contractSelected : Palette.contractUnselected))
                let entry = declarerList[indexPath.item]
                cell.set(titleText: entry.title, captionText: entry.caption, tag: indexPath.item, color: color, clearBackground: false, trailingSpace: buttonSpaceX, cornerRadius: 10, tapAction: { (value) in
                    self.declarerTapped(declarer: Seat(rawValue: value)!)
                })
                return cell
            }
        } else {
            fatalError()
        }
    }
    
    // MARK: - Tap handlers ============================================================================ -
    
    @objc private func passoutTapped(_ sender: UILabel) {
        levelTapped(level: .passout)
    }
    
    private func levelTapped(level: ContractLevel) {
        if level != contract.level {
            contract.level = level
            levelCollectionView.reloadData()
            suitCollectionView.reloadData()
            doubleCollectionView.reloadData()
            declarerCollectionView.reloadData()
            updateButtons()
        }
    }
    
    private func suitTapped(suit: ContractSuit) {
        if suit != contract.suit {
            contract.suit = suit
            suitCollectionView.reloadData()
            doubleCollectionView.reloadData()
            declarerCollectionView.reloadData()
            updateButtons()
        }

    }
    
    private func doubleTapped(double: ContractDouble) {
        if double != contract.double {
            contract.double = double
            doubleCollectionView.reloadData()
            updateButtons()
        }
    }
    
    private func declarerTapped(declarer: Seat) {
        if declarer != self.declarer {
            self.declarer = declarer
            declarerCollectionView.reloadData()
            updateButtons()
        }
    }
    
    // MARK: - Utility Routines ======================================================================== -
    
    private func updateButtons() {
        let selectEnabled = (contract.level == .passout || contract.suit != .blank)
        selectButton.isUserInteractionEnabled = selectEnabled

        let selectColor = (selectEnabled ? Palette.contractUnselected : Palette.contractDisabled)
        selectButton.backgroundColor = UIColor(selectColor.background)
        selectButton.textColor = UIColor(selectColor.text).withAlphaComponent(selectEnabled ? 1 : 0.3)
        
        let passoutColor = (contract.level == .passout ? Palette.contractSelected : Palette.contractUnselected)
        passOutLabel.backgroundColor = UIColor(passoutColor.background)
        passOutLabel.textColor = UIColor(passoutColor.text)
    }
    
    @objc private func cancelPressed(_ sender: UILabel) {
        hide()
    }
    
    @objc private func selectPressed(_ sender: UILabel) {
        self.completion?(Contract(copying: contract), declarer)
        hide()
    }
    
    // MARK: - Show / Hide ============================================================================ -
    
    public func show(from sourceView: UIView, contract: Contract, sitting: Seat, declarer: Seat, hideBackground: Bool = true, completion: @escaping (Contract, Seat?)->()) {
        self.contract = Contract(copying: contract)
        self.declarer = declarer
        self.completion = completion
        self.frame = sourceView.frame
        backgroundView.frame = sourceView.frame
        heightConstraint.constant = (sitting == .unknown ? 350 : 450)
        declarerLabel.isHidden = (sitting == .unknown)
        declarerCollectionView.isHidden = (sitting == .unknown)
        declarerList = Scorecard.declarerList(sitting: sitting)
        setNeedsLayout()
        layoutIfNeeded()
        layoutSubviews()
        sourceView.addSubview(self)
        sourceView.bringSubviewToFront(self)
        backgroundView.isHidden = !hideBackground
        contentView.isHidden = false
        levelCollectionView.reloadData()
        suitCollectionView.reloadData()
        doubleCollectionView.reloadData()
        declarerCollectionView.reloadData()
        updateButtons()
    }
    
    public func hide() {
        removeFromSuperview()
    }
    
  // MARK: - View Setup ======================================================================== -
    
    private func loadContractEntryView() {
        
        levelCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        suitCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        doubleCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        declarerCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())

        // Background
        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let cancelSelector = #selector(ContractEntryView.cancelPressed(_:))
        let tapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
        backgroundView.addGestureRecognizer(tapGesture)
        backgroundView.isUserInteractionEnabled = true
        
        // Content
        backgroundView.addSubview(contentView, anchored: .centerX, .centerY)
        Constraint.setWidth(control: contentView, width: 650)
        heightConstraint = Constraint.setHeight(control: contentView, height: 350)
        contentView.backgroundColor = UIColor(Palette.alternate.background)
        contentView.addShadow()
        contentView.layer.cornerRadius = 20
        let nullGesture = UITapGestureRecognizer(target: self, action: nil)
        contentView.addGestureRecognizer(nullGesture)
        contentView.isUserInteractionEnabled = true
                  
        // Title
        contentView.addSubview(title, anchored: .leading, .trailing, .top)
        Constraint.setHeight(control: title, height: 50)
        title.backgroundColor = UIColor(Palette.banner.background)
        title.textColor = UIColor(Palette.banner.text)
        title.font = windowTitleFont
        title.textAlignment = .center
        title.text = "Select Contract"
        
        // Pass Out
        contentView.addSubview(passOutLabel)
        Constraint.anchor(view: contentView, control: passOutLabel, to: title, constant: 20, toAttribute: .bottom, attributes: .top)
        Constraint.anchor(view: contentView, control: passOutLabel, constant: 20, attributes: .leading)
        Constraint.setHeight(control: passOutLabel, height: buttonHeight)
        Constraint.setWidth(control: passOutLabel, width: passoutButtonWidth)
        let passoutGesture = UITapGestureRecognizer(target: self, action: #selector(ContractEntryView.passoutTapped(_:)))
        passOutLabel.addGestureRecognizer(passoutGesture)
        passOutLabel.isUserInteractionEnabled = true
        passOutLabel.font = titleFont
        passOutLabel.textAlignment = .center
        passOutLabel.text = "Pass Out"

        // Level numbers
        loadCollection(collectionView: levelCollectionView, anchor: .trailing, yOffset: 0, buttonWidth: ContractCollection.level.buttonWidth, elements: ContractLevel.validCases.count, tag: ContractCollection.level.rawValue, collection: .level, type: ContractLevel.blank)

        // Suits
        loadCollection(collectionView: suitCollectionView, anchor: .trailing, yOffset: (buttonHeight + buttonSpaceY), buttonWidth: ContractCollection.suit.buttonWidth, elements: ContractSuit.validCases.count, tag: ContractCollection.suit.rawValue, collection: .suit, type: ContractSuit.blank)

        // Doubles
        loadCollection(collectionView: doubleCollectionView, anchor: .trailing, yOffset: 2 * (buttonHeight + buttonSpaceY), buttonWidth: ContractCollection.double.buttonWidth, elements: ContractDouble.allCases.count, tag: ContractCollection.double.rawValue, collection: .double, type: ContractDouble.undoubled)

        // Declarer
        let declarerOffset = 3.5 * (buttonHeight + buttonSpaceY)
        contentView.addSubview(declarerLabel)
        Constraint.anchor(view: self.contentView, control: declarerLabel, to: passOutLabel, attributes: .leading)
        Constraint.anchor(view: self.contentView, control: declarerLabel, to: passOutLabel, constant: declarerOffset, attributes: .top)
        Constraint.setHeight(control: declarerLabel, height: buttonHeight)
        Constraint.setWidth(control: declarerLabel, width: passoutButtonWidth)
        declarerLabel.font = titleFont
        declarerLabel.textAlignment = .left
        declarerLabel.textColor = UIColor(Palette.alternate.contrastText)
        declarerLabel.text = "Declarer"
        loadCollection(collectionView: declarerCollectionView, anchor: .trailing, yOffset: declarerOffset, buttonWidth: ContractCollection.declarer.buttonWidth, elements: Seat.allCases.count, tag: ContractCollection.declarer.rawValue, collection: .declarer, type: Seat.unknown)
    
        // Cancel button
        loadActionButton(button: cancelButton, xOffset: -((actionButtonWidth / 2) + buttonSpaceX), text: "Cancel", action: cancelSelector)
        
        // Select button
        loadActionButton(button: selectButton, xOffset: ((actionButtonWidth / 2) + buttonSpaceX), text: "Confirm", action: #selector(ContractEntryView.selectPressed(_:)))
    }
    
    func loadActionButton(button: UILabel, xOffset: CGFloat, text: String, action: Selector) {
        contentView.addSubview(button, constant: 20, anchored: .bottom)
        Constraint.anchor(view: contentView, control: button, constant: xOffset, attributes: .centerX)
        Constraint.setHeight(control: button, height: buttonHeight)
        Constraint.setWidth(control: button, width: actionButtonWidth)
        button.backgroundColor = UIColor(Palette.enabledButton.background)
        button.textColor = UIColor(Palette.enabledButton.text)
        button.font = titleFont
        button.textAlignment = .center
        button.text = text
        let tapGesture = UITapGestureRecognizer(target: self, action: action)
        button.addGestureRecognizer(tapGesture)
        button.isUserInteractionEnabled = true
    }
    
    private func loadCollection<EnumType>(collectionView: UICollectionView, anchor: ConstraintAnchor, yOffset: CGFloat, buttonWidth: CGFloat, elements: Int, tag: Int, collection: ContractCollection, type: EnumType) where EnumType: ContractEnumType {
        contentView.addSubview(collectionView)
        Constraint.anchor(view: contentView, control: collectionView, to: passOutLabel, constant: yOffset, attributes: .top)
        if anchor == .trailing {
            Constraint.anchor(view: contentView, control: collectionView, to: passOutLabel, constant: buttonSpaceX, toAttribute: .trailing, attributes: .leading)
        } else {
            Constraint.anchor(view: contentView, control: collectionView, to: passOutLabel, attributes: anchor)
        }
            
        Constraint.setWidth(control: collectionView, width: (CGFloat(elements) * (buttonWidth + buttonSpaceX)))
        Constraint.setHeight(control: collectionView, height: (collection == .declarer ? buttonWidth : buttonHeight))
        collectionView.tag = tag
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        if collection == .declarer {
            ScrollPickerCell.register(collectionView)
        } else {
            ContractEntryCollectionCell.register(collectionView, type: type)
        }
    }
}

// MARK: - Cell classes ================================================================ -

fileprivate let contractEntryCellIdentifier = "Board Collection Cell"

fileprivate class ContractEntryCollectionCell<EnumType>: UICollectionViewCell where EnumType: ContractEnumType {
    private var label = UILabel()
    private var value: EnumType?
    private var tapAction: ((EnumType)->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
                
        addSubview(label, anchored: .leading, .top, .bottom)
        Constraint.setWidth(control: label, width: frame.width - buttonSpaceX)
        label.textAlignment = .center
        label.minimumScaleFactor = 0.3
        label.backgroundColor = UIColor(Palette.tile.background)
        label.textColor = UIColor(Palette.tile.text)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ContractEntryCollectionCell.tapped(_:)))
        label.addGestureRecognizer(tapGesture)
        label.isUserInteractionEnabled = true
        tapGesture.isEnabled = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.roundCorners(cornerRadius: 10)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ collectionView: UICollectionView, type: EnumType) {
        collectionView.register(ContractEntryCollectionCell.self, forCellWithReuseIdentifier: contractEntryCellIdentifier)
    }

    public class func dequeue(_ collectionView: UICollectionView, for indexPath: IndexPath) -> ContractEntryCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: contractEntryCellIdentifier, for: indexPath) as! ContractEntryCollectionCell
        cell.prepareForReuse()
        return cell
    }
    
    override func prepareForReuse() {
    }
    
    func set(value: EnumType, selected: Bool, disabled: Bool = false, tapAction: @escaping (EnumType)->()) where EnumType: ContractEnumType {
        self.value = value
        label.text = value.string
        self.tapAction = tapAction
        self.label.isUserInteractionEnabled = !disabled
        let color = (disabled ? Palette.contractDisabled : (selected ? Palette.contractSelected : Palette.contractUnselected))
        self.label.backgroundColor = UIColor(color.background)
        self.label.textColor = UIColor(color.text).withAlphaComponent(disabled ? 0.5 : 1)
    }
    
    @objc func tapped(_ sender: UILabel) {
        if let value = value {
            tapAction?(value)
        }
    }
}
    
