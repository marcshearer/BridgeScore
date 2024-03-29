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
    case sitting = 5
    
    var buttonWidth: CGFloat {
        switch self {
        case .level, .suit, .double, .sitting:
            return MyApp.format == .phone ? 40 : 60
        case .declarer:
            return MyApp.format == .phone ? 50 : 80
        }
    }
    
    var buttonHeight: CGFloat {
        return buttonWidth
    }
}

fileprivate let actionButtonWidth: CGFloat = MyApp.format == .phone ? 100 : 120
fileprivate let actionButtonHeight: CGFloat = 40
fileprivate let buttonSpaceX: CGFloat = 10
fileprivate let buttonSpaceY: CGFloat = 20
fileprivate var contractLeadingSpace: CGFloat { MyApp.format == .phone && isLandscape ? 0 : 30 }
fileprivate var contractTopSpace: CGFloat { MyApp.format == .phone && !isLandscape ? 50 : 0}

class ScorecardContractEntryView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
       
    private var sourceView: UIView!
    private var backgroundView = UIView()
    private var contentView = UIView()
    private var declarerView = UIView()
    private var title = UILabel()
    private var levelCollectionView: UICollectionView!
    private var suitCollectionView: UICollectionView!
    private var doubleCollectionView: UICollectionView!
    private var sittingCollectionView: UICollectionView!
    private var declarerCollectionView: UICollectionView!
    private var declarerLabel = UILabel()
    private var sittingLabel = UILabel()
    private var passOutButton = UILabel()
    private var cancelButton = UILabel()
    private var clearButton = UILabel()
    private var selectButton = UILabel()
    private var contract = Contract()
    private var canClear = false
    private var sitting: Seat!
    private var inputSitting: Bool!
    private var inputDeclarer: Bool!
    private var declarer: Seat?
    private var completion: ((Contract?, Seat?, Seat?, KeyAction?)->())?
    private var heightConstraint: NSLayoutConstraint!
    private var widthConstraint: NSLayoutConstraint!
    private var declarerLabelToViewConstraint: NSLayoutConstraint!
    private var declarerLabelToSittingConstraint: NSLayoutConstraint!
    private var declarerCollectionTopConstraint: NSLayoutConstraint!
    private var declarerWidth: NSLayoutConstraint!
    private var declarerHeight: NSLayoutConstraint!
    private var portraitConstraints: [NSLayoutConstraint]!
    private var landscapeConstraints: [NSLayoutConstraint]!
    private var declarerList: [(seat: Seat, entry: ScrollPickerEntry)]!
    private var seatList: [(seat: Seat, entry: ScrollPickerEntry)]!
    private var lastLandscape: Bool?
    private var contractLeadingSpaceConstraints: [NSLayoutConstraint] = []
    private var contractTopSpaceConstraints: [NSLayoutConstraint] = []
    private var firstResponder: FirstResponderLabel!
    private var suitCharacters: String
    private var levelCharacters: String
    private var doubleCharacters: String

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override init(frame: CGRect) {
        inputDeclarer = MyApp.target != .macOS
        levelCharacters = ""
        suitCharacters = ""
        doubleCharacters = "*X"
        super.init(frame: frame)
        for level in ContractLevel.validCases {
            levelCharacters += level.string.left(1)
        }
        
        for suit in Suit.validCases {
            suitCharacters += suit.character
        }
        loadContractEntryView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setOrientationConstraints()
        layoutIfNeeded()
        
        contentView.roundCorners(cornerRadius: 20)
        passOutButton.roundCorners(cornerRadius: 10)
        cancelButton.roundCorners(cornerRadius: 10)
        clearButton.roundCorners(cornerRadius: 10)
        selectButton.roundCorners(cornerRadius: 10)
    }
    
    func setOrientationConstraints() {
        if isLandscape != lastLandscape {
            if MyApp.format != .phone {
                backgroundView.frame = sourceView?.frame ?? CGRect()
                heightConstraint.constant = (isLandscape ? 450 : (inputSitting ? 800 : (inputDeclarer ? 700 : 450)))
                widthConstraint.constant = (!isLandscape ? 540 : (inputDeclarer ? 940 : 600))
            }
                 
            if inputDeclarer {
                declarerHeight.constant = (isLandscape ? 0 : (inputSitting ? 420 : 320))
                declarerWidth.constant = (!isLandscape ? 0 : 400)
                
                    // Need to deactivate all constraints before activating relevant ones
                for pass in 1...2 {
                    landscapeConstraints.forEach { (constraint) in constraint.isActive = isLandscape && pass == 2 }
                    portraitConstraints.forEach { (constraint) in constraint.isActive = !isLandscape && pass == 2 }
                }
            }
            
            contractLeadingSpaceConstraints.forEach { (constraint) in
                constraint.constant = contractLeadingSpace
            }
            contractTopSpaceConstraints.forEach { (constraint) in
                constraint.constant = buttonSpaceY + contractTopSpace
            }
            
            setNeedsLayout()
            lastLandscape = isLandscape
        }
    }
    
    // MARK: - CollectionView Delegates ================================================================ -
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let collection = ContractCollection(rawValue: collectionView.tag) {
            switch collection {
            case .level:
                return ContractLevel.validCases.count
            case .suit:
                return Suit.validCases.count
            case .double:
                return ContractDouble.allCases.count
            case .sitting:
                return seatList?.count ?? 0
            case .declarer:
                return declarerList?.count ?? 0
            }
        } else {
            fatalError()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let collection = ContractCollection(rawValue: collectionView.tag) {
            var width: CGFloat = collection.buttonWidth + buttonSpaceX
            if collection == .declarer && (indexPath.item == 0 || indexPath.item == Seat.allCases.count - 1) {
                width = width * 3
            }
            return CGSize(width: width, height: collection.buttonHeight)
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
                let cell = ScorecardContractEntryCollectionCell<ContractLevel>.dequeue(collectionView, for: indexPath)
                cell.set(value: level, selected: (level == contract.level), tapAction: levelTapped)
                return cell
            case .suit:
                let suit = Suit.validCases[indexPath.row]
                let cell = ScorecardContractEntryCollectionCell<Suit>.dequeue(collectionView, for: indexPath)
                cell.set(value: suit, color: UIColor(suit.color), selected: (suit == contract.suit), tapAction: suitTapped)
                return cell
            case .double:
                let double = ContractDouble.allCases[indexPath.row]
                let cell = ScorecardContractEntryCollectionCell<ContractDouble>.dequeue(collectionView, for: indexPath)
                cell.set(value: double, selected: (double == contract.double && contract.level != .passout), font: smallCellFont, tapAction: doubleTapped)
                return cell
            case .sitting:
                let seat = seatList[indexPath.row].seat
                let cell = ScrollPickerCell.dequeue(collectionView, for: indexPath)
                let selected = (seat == sitting)
                let color = (selected ? Palette.contractSelected : Palette.contractUnselected)
                let entry = seatList[indexPath.item].entry
                cell.set(titleText: entry.title, captionText: entry.caption, tag: indexPath.item, color: color, clearBackground: false, trailingSpace: buttonSpaceX, cornerRadius: 10) { (value) in
                    self.sittingTapped(seat: self.seatList[value].seat)
                }
                return cell
            case .declarer:
                let declarer = declarerList[indexPath.row].seat
                let cell = ScrollPickerCell.dequeue(collectionView, for: indexPath)
                let selected = (declarer == self.declarer && contract.level != .passout)
                let color = (selected ? Palette.contractSelected : Palette.contractUnselected)
                let entry = declarerList[indexPath.item].entry
                let leadingSpace = ((collection == .declarer && (indexPath.item == 0 || indexPath.item == Seat.allCases.count - 1)) ? collection.buttonWidth + buttonSpaceX : 0)
                cell.set(titleText: entry.title, captionText: (sitting == .unknown ? "" : entry.caption), tag: indexPath.item, color: color, clearBackground: false, leadingSpace: leadingSpace, trailingSpace: leadingSpace + buttonSpaceX, cornerRadius: 10) { (value) in
                    self.declarerTapped(declarer: self.declarerList[value].seat)
                }
                return cell
            }
        } else {
            fatalError()
        }
    }
    
    // MARK: - Tap handlers ============================================================================ -
    
    @objc private func passoutTapped(_ sender: UIView) {
        levelTapped(level: .passout)
        selectPressed(sender)
    }
    
    private func levelTapped(level: ContractLevel) {
        if level != contract.level {
            contract.level = level
            if level == .passout {
                declarer = .unknown
            }
            levelCollectionView.reloadData()
            suitCollectionView.reloadData()
            doubleCollectionView.reloadData()
            declarerCollectionView.reloadData()
            updateButtons()
        }
    }
    
    private func suitTapped(suit: Suit) {
        if suit != contract.suit {
            contract.suit = suit
            suitCollectionView.reloadData()
            doubleCollectionView.reloadData()
            declarerCollectionView.reloadData()
            updateButtons()
        }

    }
    
    private func doubleTapped(double: ContractDouble) {
        if double != contract.double || contract.level == .passout {
            if contract.level == .passout {
                contract.level = .blank
            }
            contract.double = double
            doubleCollectionView.reloadData()
            updateButtons()
        }
    }
    
    private func sittingTapped(seat: Seat) {
        if sitting != seat {
            let offset = sitting?.offset(to: seat)
            if (declarer ?? .unknown) != .unknown && (sitting ?? .unknown) != .unknown {
                declarer = declarer!.offset(by: offset!)
            } else {
                declarer = .unknown
            }
            sitting = seat
            updateDeclarerList()
            sittingCollectionView.reloadData()
            declarerCollectionView.reloadData()
            updateButtons()
        }
    }
    
    private func declarerTapped(declarer: Seat) {
        if declarer != self.declarer || contract.level == .passout {
            if contract.level == .passout {
                contract.level = .blank
            }
            self.declarer = declarer
            declarerCollectionView.reloadData()
            updateButtons()
        }
    }
    
    // MARK: - Utility Routines ======================================================================== -
    
    private func updateButtons() {
        selectButton.isUserInteractionEnabled = contract.isValid
        
        let canClear = (canClear && contract.canClear)
        cancelButton.isHidden = canClear
        clearButton.isHidden = !canClear
        
        let selectColor = (contract.isValid ? Palette.highlightButton : Palette.disabledButton)
        selectButton.backgroundColor = UIColor(selectColor.background)
        selectButton.textColor = UIColor(selectColor.text).withAlphaComponent(contract.isValid ? 1 : 0.3)
    }
    
    @objc private func cancelPressed(_ sender: Any) {
        self.completion?(nil, nil, nil, nil)
        hide()
    }
    
    @objc private func selectPressed(_ sender: Any) {
        self.completion?(Contract(copying: contract), (inputDeclarer ? declarer : nil), (inputSitting ? sitting :nil), nil)
        hide()
    }
    
    @objc private func clearPressed(_ sender: Any) {
        self.completion?(Contract(), (inputDeclarer ? .unknown : nil), (inputSitting ? sitting : nil), nil)
        hide()
    }
    
    // MARK: - Show / Hide ============================================================================ -
    
    public func show(from sourceView: UIView, contract: Contract, sitting: Seat, declarer: Seat, hideBackground: Bool = true, completion: @escaping (Contract?, Seat?, Seat?, KeyAction?)->()) {
        self.sourceView = sourceView
        self.contract = Contract(copying: contract)
        self.canClear = contract.canClear
        self.sitting = sitting
        self.inputSitting = (inputDeclarer && sitting == .unknown)
        self.declarer = declarer
        self.completion = completion
        self.frame = sourceView.frame
        if MyApp.format == .phone {
            sourceView.addSubview(self, anchored: .all)
        } else {
            sourceView.addSubview(self)
        }
        sourceView.bringSubviewToFront(self)
        if inputDeclarer {
            updateDeclarerList()
            seatList = Seat.validCases.map{($0, ScrollPickerEntry(title: $0.short, caption: $0.string))}
            if inputSitting {
                declarerLabelToSittingConstraint.isActive = true
                declarerLabelToViewConstraint.isActive = false
                declarerCollectionTopConstraint.constant = 10
                sittingLabel.isHidden = false
                sittingCollectionView.isHidden = false
            } else {
                declarerLabelToSittingConstraint.isActive = false
                declarerLabelToViewConstraint.isActive = true
                declarerCollectionTopConstraint.constant = 70
                sittingLabel.isHidden = true
                sittingCollectionView.isHidden = true
            }
        }
        setNeedsLayout()
        layoutIfNeeded()
        layoutSubviews()
        backgroundView.isHidden = !hideBackground
        contentView.isHidden = false
        levelCollectionView.reloadData()
        suitCollectionView.reloadData()
        doubleCollectionView.reloadData()
        declarerCollectionView.reloadData()
        updateButtons()
        
        firstResponder.becomeFirstResponder()
    }
    
    func updateDeclarerList() {
        declarerList = Scorecard.orderedDeclarerList(sitting: sitting)
    }
    
    public func hide() {
        removeFromSuperview()
    }
    
  // MARK: - View Setup ======================================================================== -
    
    private func loadContractEntryView() {
        contractLeadingSpaceConstraints = []
        contractTopSpaceConstraints  = []
        
        levelCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        suitCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        doubleCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        declarerCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        sittingCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        
        // Background
        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let cancelSelector = #selector(ScorecardContractEntryView.cancelPressed(_:))
        let tapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
        backgroundView.addGestureRecognizer(tapGesture)
        backgroundView.isUserInteractionEnabled = true
        
        // Content
        contentView.accessibilityIdentifier = "content"
        if MyApp.format == .phone {
            addSubview(contentView, anchored: .all)
        } else {
            backgroundView.addSubview(contentView, anchored: .centerX, .centerY)
            contentView.addShadow()
            contentView.layer.cornerRadius = 20
            widthConstraint = Constraint.setWidth(control: contentView, width: 0)
            heightConstraint = Constraint.setHeight(control: contentView, height: 0)
        }
        contentView.backgroundColor = UIColor(Palette.alternate.background)
        let nullGesture = UITapGestureRecognizer(target: self, action: nil)
        contentView.addGestureRecognizer(nullGesture)
        contentView.isUserInteractionEnabled = true
                  
        // Title
        title.accessibilityIdentifier = "title"
        let titleBackground = UIView()
        titleBackground.backgroundColor = UIColor(Palette.banner.background)
        contentView.addSubview(titleBackground, anchored: .leading, .trailing, .top)
        Constraint.anchor(view: contentView, control: contentView, to: titleBackground, constant: -50, toAttribute: .bottom, attributes: .safeTop)
        titleBackground.addSubview(title, anchored: .leading, .trailing, .bottom)
        Constraint.setHeight(control: title, height: 50)
        title.textColor = UIColor(Palette.banner.text)
        title.font = windowTitleFont
        title.textAlignment = .center
        title.text = "Select Contract"
        
        // Level numbers
        loadCollection(collectionView: levelCollectionView, xOffset: contractLeadingSpace, yOffset: buttonSpaceY, additionalYOffset: contractTopSpace, from: title, elements: ContractLevel.validCases.count, tag: ContractCollection.level.rawValue, collection: .level, type: ContractLevel.blank)

        // Suits
        loadCollection(collectionView: suitCollectionView, xOffset: contractLeadingSpace, yOffset: buttonSpaceY, from: levelCollectionView, elements: Suit.validCases.count, tag: ContractCollection.suit.rawValue, collection: .suit, type: Suit.blank)

        // Doubles
        loadCollection(collectionView: doubleCollectionView, xOffset: contractLeadingSpace, yOffset: buttonSpaceY, from: suitCollectionView, elements: ContractDouble.allCases.count, tag: ContractCollection.double.rawValue, collection: .double, type: ContractDouble.undoubled)
        
        // Pass Out button
        passOutButton.accessibilityIdentifier = "passOut"
        loadActionButton(button: passOutButton, xOffset: -(actionButtonWidth + buttonSpaceX), text: "Pass Out", action: #selector(ScorecardContractEntryView.passoutTapped(_:)))
        
        // Cancel button
        cancelButton.accessibilityIdentifier = "cancel"
        loadActionButton(button: cancelButton, xOffset: 0, text: "Cancel", action: cancelSelector)
        
        // Clear button
        clearButton.accessibilityIdentifier = "clear"
        loadActionButton(button: clearButton, xOffset: 0, text: "Clear", action: #selector(ScorecardContractEntryView.clearPressed(_:)))

        // Select button
        selectButton.accessibilityIdentifier = "select"
        loadActionButton(button: selectButton, xOffset: (actionButtonWidth + buttonSpaceX), text: "Confirm", action: #selector(ScorecardContractEntryView.selectPressed(_:)))
        
        if inputDeclarer {
                // Declarer view
            declarerView.accessibilityIdentifier = "declarerView"
            contentView.addSubview(declarerView, anchored: .safeTrailing)
            contentView.sendSubviewToBack(declarerView)
            let declarerSeparator = UIView()
            declarerView.addSubview(declarerSeparator)
            declarerSeparator.backgroundColor = UIColor(Palette.highlightButton.background)
            
                // Constraints in landscape mode
            landscapeConstraints = []
            landscapeConstraints.append(contentsOf: Constraint.anchor(view: contentView, control: declarerView, to: title, toAttribute: .bottom, attributes: .top))
            landscapeConstraints.append(contentsOf: Constraint.anchor(view: contentView, control: declarerView, attributes: .bottom))
            declarerWidth = Constraint.setWidth(control: declarerView, width: 0)
            landscapeConstraints.append(declarerWidth)
            landscapeConstraints.append(contentsOf: Constraint.anchor(view: declarerView, control: declarerSeparator, constant: 0, attributes: .leading))
            landscapeConstraints.append(contentsOf: Constraint.anchor(view: declarerView, control: declarerSeparator, constant: 10, attributes: .top, .bottom))
            landscapeConstraints.append(Constraint.setWidth(control: declarerSeparator, width: 1))
            
                // Constraints in portrait mode
            portraitConstraints = []
            portraitConstraints.append(contentsOf: Constraint.anchor(view: contentView, control: declarerView, attributes: .leading))
            portraitConstraints.append(contentsOf: Constraint.anchor(view: contentView, control: declarerView, to: cancelButton, constant: 0, toAttribute: .top, attributes: .bottom))
            declarerHeight = Constraint.setHeight(control: declarerView, height: 0)
            portraitConstraints.append(declarerHeight)
            portraitConstraints.append(contentsOf: Constraint.anchor(view: declarerView, control: declarerSeparator, constant: 0, attributes: .top))
            portraitConstraints.append(contentsOf: Constraint.anchor(view: declarerView, control: declarerSeparator, constant: 10, attributes: .leading, .trailing))
            portraitConstraints.append(Constraint.setHeight(control: declarerSeparator, height: 1))
            
                // Sitting
            declarerView.addSubview(sittingLabel, leading: 20, top: 10)
            Constraint.setHeight(control: sittingLabel, height: actionButtonHeight)
            sittingLabel.font = sectionTitleFont.bold
            sittingLabel.textAlignment = .left
            sittingLabel.textColor = UIColor(Palette.background.text)
            sittingLabel.text = "Sitting"
            sittingLabel.sizeToFit()
            loadCollection(collectionView: sittingCollectionView, to: declarerView, elements: Seat.validCases.count, tag: ContractCollection.sitting.rawValue, collection: .sitting, type: Seat.unknown)
            Constraint.anchor(view: declarerView, control: sittingCollectionView, to: sittingLabel, constant: 20, toAttribute: .trailing, attributes: .leading)
            Constraint.anchor(view: declarerView, control: sittingCollectionView, to: sittingLabel, constant: 10, attributes: .top)
            
            
                // Declarer picker
            declarerView.addSubview(declarerLabel, leading: 20)
            declarerLabelToViewConstraint = Constraint.anchor(view: declarerView, control: declarerLabel, constant: 10, attributes: .top).first!
            declarerLabelToViewConstraint.isActive = false
            declarerLabelToSittingConstraint = Constraint.anchor(view: declarerView, control: declarerLabel, to: sittingCollectionView, constant: 20, toAttribute: .bottom, attributes: .top).first!
            declarerLabelToSittingConstraint.isActive = false
            Constraint.setHeight(control: declarerLabel, height: actionButtonHeight)
            declarerLabel.font = sectionTitleFont.bold
            declarerLabel.textAlignment = .left
            declarerLabel.textColor = UIColor(Palette.background.text)
            declarerLabel.text = "Declarer"
            loadCollection(collectionView: declarerCollectionView, to: declarerView, yOffset: 20, from: declarerLabel, elements: Seat.allCases.count, tag: ContractCollection.declarer.rawValue, across: 3, down: 3, collection: .declarer, type: Seat.unknown, xAnchor: .centerX)
            declarerCollectionTopConstraint = Constraint.anchor(view: declarerView, control: declarerCollectionView, to: declarerLabel, constant: 0, attributes: .top).first!
         
            // Avoid warnings
            portraitConstraints.forEach{ $0.isActive = false}
            landscapeConstraints.forEach{ $0.isActive = false}
        }
        
        // First responder
        firstResponder = FirstResponderLabel(view: self)
        addSubview(firstResponder)
    }
    
    func loadActionButton(button: UILabel, xOffset: CGFloat, text: String, action: Selector) {
        button.accessibilityIdentifier = text
        contentView.addSubview(button)
        Constraint.anchor(view: contentView, control: button, to: contentView, constant: -(actionButtonHeight + 20), toAttribute: .safeBottom, attributes: .top)
        Constraint.anchor(view: contentView, control: button, to: levelCollectionView, constant: xOffset - (buttonSpaceX / 2), attributes: .centerX)
        Constraint.setHeight(control: button, height: actionButtonHeight)
        Constraint.setWidth(control: button, width: actionButtonWidth)
        button.backgroundColor = UIColor(Palette.enabledButton.background)
        button.textColor = UIColor(Palette.enabledButton.contrastText)
        button.font = titleFont.bold
        button.textAlignment = .center
        button.text = text
        let tapGesture = UITapGestureRecognizer(target: self, action: action)
        button.addGestureRecognizer(tapGesture)
        button.isUserInteractionEnabled = true
    }
    
    private func loadCollection<EnumType>(collectionView: UICollectionView, to view: UIView? = nil, xOffset: CGFloat = 0, yOffset: CGFloat = 0, additionalYOffset: CGFloat = 0, from toView: UIView? = nil, elements: Int, tag: Int, across: Int? = nil, down: Int? = nil, collection: ContractCollection, type: EnumType, xAnchor: ConstraintAnchor? = nil) where EnumType: ContractEnumType {
        let across = across ?? elements
        let down = down ?? 1
        let view = view ?? contentView

        if view == declarerView {
            // Sitting / Declarer
            let anchors = xAnchor != nil ? [xAnchor!] : nil
            view.addSubview(collectionView, constant: xOffset, anchored: anchors)
        } else {
            // Other collections
            view.addSubview(collectionView)
            contractLeadingSpaceConstraints.append(contentsOf: Constraint.anchor(view: view, control: collectionView, constant: xOffset, attributes: .safeLeading))
            let constraints = Constraint.anchor(view: view, control: collectionView, to: toView, constant: yOffset + additionalYOffset, toAttribute: .bottom, attributes: .top)
            if additionalYOffset != 0 {
                contractTopSpaceConstraints.append(contentsOf: constraints)
            }
        }
        Constraint.setWidth(control: collectionView, width: (CGFloat(across) * (collection.buttonWidth + buttonSpaceX)))
        Constraint.setHeight(control: collectionView, height: (CGFloat(down) * (collection.buttonHeight)) + (CGFloat(down - 1) * buttonSpaceY))
        collectionView.tag = tag
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        if collection == .declarer || collection == .sitting {
            ScrollPickerCell.register(collectionView)
        } else {
            ScorecardContractEntryCollectionCell.register(collectionView, type: type)
        }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !processPressedKeys(presses, with: event, allowCharacters: true, action: { (keyAction, _) in
            switch keyAction {
            case .previous, .next, .escape, .enter, .backspace, .delete, .characters:
                true
            default:
                false
            }
        }) {
            super.pressesBegan(presses, with: event)
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        
        if !processPressedKeys(presses, with: event, allowCharacters: true, action: { [self] (keyAction, characters) in
            var result = true
            switch keyAction {
            case .previous, .next:
                if selectButton.isEnabled {
                    self.completion?(Contract(copying: contract), (inputDeclarer ? declarer : nil), (inputSitting ? sitting : nil), keyAction)
                    hide()
                } else {
                    self.completion?(nil, nil, nil, keyAction)
                    hide()
                }
            case .escape:
                self.completion?(nil, nil, nil, keyAction)
                hide()
            case .enter:
                if selectButton.isUserInteractionEnabled {
                    selectPressed(self)
                }
            case .backspace, .delete:
                clearPressed(self)
            case .characters:
                if characters.trim().left(1).uppercased() == "P" {
                    passoutTapped(self)
                } else if levelCharacters.contains(characters.uppercased()) {
                    levelTapped(level: ContractLevel(character: characters))
                } else if suitCharacters.contains(characters.uppercased()) {
                    suitTapped(suit: Suit(string: characters.uppercased()))
                } else if doubleCharacters.contains(characters.uppercased()) {
                    let current = contract.double
                    doubleTapped(double: ContractDouble(rawValue: (current.rawValue + 1) % ContractDouble.allCases.count)!)
                }
            default:
                result = false
                break
            }
            return result
        }) {
            super.pressesEnded(presses, with: event)
        }
    }
}

// MARK: - Cell classes ================================================================ -

fileprivate let contractEntryCellIdentifier = "Board Collection Cell"

fileprivate class ScorecardContractEntryCollectionCell<EnumType>: UICollectionViewCell where EnumType: ContractEnumType {
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardContractEntryCollectionCell.tapped(_:)))
        label.addGestureRecognizer(tapGesture)
        label.isUserInteractionEnabled = true
        label.font = boardFont
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
        collectionView.register(ScorecardContractEntryCollectionCell.self, forCellWithReuseIdentifier: contractEntryCellIdentifier)
    }

    public class func dequeue(_ collectionView: UICollectionView, for indexPath: IndexPath) -> ScorecardContractEntryCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: contractEntryCellIdentifier, for: indexPath) as! ScorecardContractEntryCollectionCell
        cell.prepareForReuse()
        return cell
    }
    
    override func prepareForReuse() {
    }
    
    func set(value: EnumType, color: UIColor? = nil, selected: Bool, disabled: Bool = false, font: UIFont? = nil, tapAction: @escaping (EnumType)->()) where EnumType: ContractEnumType {
        self.value = value
        label.text = value.button
        self.tapAction = tapAction
        self.label.isUserInteractionEnabled = !disabled
        let defaultColor = (disabled ? Palette.contractDisabled : (selected ? Palette.contractSelected : Palette.contractUnselected))
        self.label.backgroundColor = UIColor(defaultColor.background)
        if let color = color {
            self.label.textColor = color
        } else {
            self.label.textColor = UIColor(defaultColor.text).withAlphaComponent(disabled ? 0.5 : 1)
        }
        if let font = font {
            self.label.font = font
        }
    }
    
    @objc func tapped(_ sender: UILabel) {
        if let value = value {
            tapAction?(value)
        }
    }
}
    
