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
}

fileprivate let buttonHeight: CGFloat = 40
fileprivate let buttonWidth: CGFloat = 150
fileprivate let buttonSpaceX: CGFloat = 20
fileprivate let buttonSpaceY: CGFloat = 10

class ContractEntryView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
       
    private var backgroundView = UIView()
    private var contentView = UIView()
    private var title = UILabel()
    private var levelCollectionView: UICollectionView!
    private var suitCollectionView: UICollectionView!
    private var doubleCollectionView: UICollectionView!
    private var passOutLabel = UILabel()
    private var cancelButton = UILabel()
    private var selectButton = UILabel()
    private var editContract = Contract()
    private var inputContract: Contract!
    private var completion: ((Contract)->())?

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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let collection = ContractCollection(rawValue: collectionView.tag) {
            switch collection {
            case .level:
                print("numberOfItems \(collectionView.tag) \(ContractLevel.validCases.count)")
                return ContractLevel.validCases.count
            case .suit:
                print("numberOfItems \(collectionView.tag) \(ContractSuit.validCases.count)")
                return ContractSuit.validCases.count
            case .double:
                print("numberOfItems \(collectionView.tag) \(ContractDouble.allCases.count)")
                return ContractDouble.allCases.count
            }
        } else {
            fatalError()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: buttonWidth, height: buttonHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("cellForItemAt \(collectionView.tag) \(indexPath)")
        if let collection = ContractCollection(rawValue: collectionView.tag) {
            switch collection {
            case .level:
                let level = ContractLevel.validCases[indexPath.row]
                let cell = ContractEntryCollectionCell<ContractLevel>.dequeue(collectionView, for: indexPath)
                cell.set(value: level, selected: (level == editContract.level), tapAction: levelTapped)
                return cell
            case .suit:
                let suit = ContractSuit.validCases[indexPath.row]
                let cell = ContractEntryCollectionCell<ContractSuit>.dequeue(collectionView, for: indexPath)
                cell.set(value: suit, selected: (suit == editContract.suit), disabled: !editContract.level.hasSuit, tapAction: suitTapped)
                return cell
            case .double:
                let double = ContractDouble.allCases[indexPath.row]
                let cell = ContractEntryCollectionCell<ContractDouble>.dequeue(collectionView, for: indexPath)
                cell.set(value: double, selected: (double == editContract.double), disabled: !editContract.suit.hasDouble, tapAction: doubleTapped)
                return cell
            }
        } else {
            fatalError()
        }
    }
    
    @objc private func passoutTapped(_ sender: UILabel) {
        levelTapped(level: .passout)
    }
    
    private func levelTapped(level: ContractLevel) {
        if level != editContract.level {
            editContract.level = level
            levelCollectionView.reloadData()
            suitCollectionView.reloadData()
            doubleCollectionView.reloadData()
            updateButtons()
        }
    }
    
    private func suitTapped(suit: ContractSuit) {
        if suit != editContract.suit {
            editContract.suit = suit
            suitCollectionView.reloadData()
            doubleCollectionView.reloadData()
            updateButtons()
        }

    }
    
    private func doubleTapped(double: ContractDouble) {
        if double != editContract.double {
            editContract.double = double
            doubleCollectionView.reloadData()
            updateButtons()
        }
    }
    
    private func updateButtons() {
        let selectEnabled = (editContract.level == .passout || editContract.suit != .blank)
        selectButton.isUserInteractionEnabled = selectEnabled

        let contractText = editContract.string
        selectButton.text = (!selectEnabled ? "Select" : "\(contractText)")
        
        let selectColor = (selectEnabled ? Palette.enabledButton : Palette.disabledButton)
        selectButton.backgroundColor = UIColor(selectColor.background)
        selectButton.textColor = UIColor(selectColor.contrastText).withAlphaComponent(selectEnabled ? 1 : 0.5)
        
        let passoutColor = (editContract.level == .passout ? Palette.contractSelected : Palette.contractUnselected)
        passOutLabel.backgroundColor = UIColor(passoutColor.background)
        passOutLabel.textColor = UIColor(passoutColor.text)
    }
    
    public func show(from sourceView: UIView, contract: Contract, hideBackground: Bool = true, completion: @escaping (Contract)->()) {
        self.inputContract = contract
        self.editContract.copy(from: contract)
        self.completion = completion
        self.frame = sourceView.frame
        backgroundView.frame = sourceView.frame
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
        updateButtons()
    }
    
    public func hide() {
        removeFromSuperview()
    }
    
    @objc private func cancelPressed(_ sender: UILabel) {
        hide()
    }
    
    @objc private func selectPressed(_ sender: UILabel) {
        self.completion?(editContract)
        hide()
    }
    
    private func loadContractEntryView() {
        
        levelCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        suitCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        doubleCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())

        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let cancelSelector = #selector(ContractEntryView.cancelPressed(_:))
        let tapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
        backgroundView.addGestureRecognizer(tapGesture)
        backgroundView.isUserInteractionEnabled = true
        
        backgroundView.addSubview(contentView, anchored: .centerX, .centerY)
        Constraint.setWidth(control: contentView, width: 600)
        Constraint.setHeight(control: contentView, height: 550)
        contentView.backgroundColor = UIColor(Palette.alternate.background)
        contentView.addShadow()
        contentView.layer.cornerRadius = 20
        let nullGesture = UITapGestureRecognizer(target: self, action: nil)
        contentView.addGestureRecognizer(nullGesture)
        contentView.isUserInteractionEnabled = true
                        
        contentView.addSubview(title, anchored: .leading, .trailing, .top)
        Constraint.setHeight(control: title, height: 50)
        title.backgroundColor = UIColor(Palette.banner.background)
        title.textColor = UIColor(Palette.banner.text)
        title.font = windowTitleFont
        title.textAlignment = .center
        title.text = "Select Contract"
        
        contentView.addSubview(passOutLabel)
        Constraint.anchor(view: contentView, control: passOutLabel, to: title, constant: 20, toAttribute: .bottom, attributes: .top)
        Constraint.anchor(view: contentView, control: passOutLabel, attributes: .centerX)
        Constraint.setHeight(control: passOutLabel, height: buttonHeight)
        Constraint.setWidth(control: passOutLabel, width: (3 * buttonWidth) + (2 * buttonSpaceX))
        let passoutGesture = UITapGestureRecognizer(target: self, action: #selector(ContractEntryView.passoutTapped(_:)))
        passOutLabel.addGestureRecognizer(passoutGesture)
        passOutLabel.isUserInteractionEnabled = true
        passOutLabel.font = titleFont
        passOutLabel.textAlignment = .center
        passOutLabel.text = "Pass Out"

        loadCollection(collectionView: levelCollectionView, anchor: .leading, elements: ContractLevel.validCases.count, tag: ContractCollection.level.rawValue, type: ContractLevel.blank)

        loadCollection(collectionView: suitCollectionView, anchor: .centerX, elements: ContractSuit.validCases.count, tag: ContractCollection.suit.rawValue, type: ContractSuit.blank)

        loadCollection(collectionView: doubleCollectionView, anchor: .trailing, elements: ContractDouble.allCases.count, tag: ContractCollection.double.rawValue, type: ContractDouble.undoubled)

        loadActionButton(button: cancelButton, offset: -((buttonWidth / 2) + buttonSpaceX), text: "Cancel", action: cancelSelector)
        
        loadActionButton(button: selectButton, offset: ((buttonWidth / 2) + buttonSpaceX), text: "Select", action: #selector(ContractEntryView.selectPressed(_:)))
    }
    
    func loadActionButton(button: UILabel, offset: CGFloat, text: String, action: Selector) {
        contentView.addSubview(button, constant: 20, anchored: .bottom)
        Constraint.anchor(view: contentView, control: button, constant: offset, attributes: .centerX)
        Constraint.setHeight(control: button, height: buttonHeight)
        Constraint.setWidth(control: button, width: buttonWidth)
        button.backgroundColor = UIColor(Palette.enabledButton.background)
        button.textColor = UIColor(Palette.enabledButton.text)
        button.font = titleFont
        button.textAlignment = .center
        button.text = text
        let tapGesture = UITapGestureRecognizer(target: self, action: action)
        button.addGestureRecognizer(tapGesture)
        button.isUserInteractionEnabled = true
    }
    
    func loadCollection<EnumType>(collectionView: UICollectionView, anchor: ConstraintAnchor, elements: Int, tag: Int, type: EnumType) where EnumType: ContractEnumType {
        contentView.addSubview(collectionView)
        Constraint.anchor(view: contentView, control: collectionView, to: passOutLabel, constant: buttonSpaceY, toAttribute: .bottom, attributes: .top)
        Constraint.anchor(view: contentView, control: collectionView, to: passOutLabel, attributes: anchor)
        Constraint.setHeight(control: collectionView, height: CGFloat(elements) * (buttonHeight + buttonSpaceY))
        Constraint.setWidth(control: collectionView, width: buttonWidth)
        collectionView.tag = tag
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        ContractEntryCollectionCell.register(collectionView, type: type)
    }
}

// MARK: - Cell classes ================================================================ -

fileprivate let contractEntryCellIdentifier = "Board CollectionCell"

fileprivate class ContractEntryCollectionCell<EnumType>: UICollectionViewCell where EnumType: ContractEnumType {
    private var label = UILabel()
    private var value: EnumType?
    private var tapAction: ((EnumType)->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
                
        addSubview(label, anchored: .leading, .trailing, .bottom)
        Constraint.setHeight(control: label, height: buttonHeight)
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
    
