//
//  Scroll Picker Popup View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 25/02/2022.
//

import UIKit

class ScrollPickerPopupView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, CustomCollectionViewLayoutDelegate {
    
    private var backgroundView: UIView!
    private var sourceView: UIView!
    private var contentView: UIView!
    private var clearLabel: UILabel!
    private var valuesCollectionView: UICollectionView!
#if targetEnvironment(macCatalyst)
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var panStart: CGFloat = 0
#endif
    private var selected: Int?
    private var selectedOnEntry: Int?
    private var defaultValue: Int?
    private var values: [ScrollPickerEntry]!
    private var maxValues = 5
    private var buttonSize: CGSize!
    private var completion: ((Int?, KeyAction?)->())?
    private var focusWidthConstraint: NSLayoutConstraint!
    private var clearLabelWidthConstraint: NSLayoutConstraint!
    private var topPadding: CGFloat = 0
    private var bottomPadding: CGFloat = 0
    private var extra: Int { Int(maxValues / 2) }
    private let focusThickness: CGFloat = 5
    private let clearHeight: CGFloat = 30
    private let clearPadding: CGFloat = 5
    private var accumulatedCharacters = ""
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadScrollPickerPopupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        loadScrollPickerPopupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        clearLabel.roundCorners(cornerRadius: clearHeight / 2)
    }
    
        // MARK: - CollectionView Delegates ================================================================ -
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return values.count + Int(maxValues / 2) * 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return buttonSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = ScrollPickerCell.dequeue(collectionView, for: indexPath)
        let item = indexPath.item
        var text = ""
        var caption: String?
        var clearBackground = true
        var tag = -1
        var tapAction: ((Int)->())?
        if item >= extra && item - extra <= values.count - 1 {
            clearBackground = false
            text = values[item - extra].title
            caption = values[item - extra].caption
            tag = item - extra
            tapAction = valueTapped
        }
        cell.set(titleText: text, captionText: caption, tag: tag, color: Palette.alternate, clearBackground: clearBackground, topPadding: topPadding, bottomPadding: bottomPadding, borderWidth: (tapAction == nil ? 0 : 0.5), tapAction: tapAction)
        return cell
    }
    
    func cancelTap(_: Int) {
        cancelPressed(self)
    }
    
    func changed(_ collectionView: UICollectionView?, itemAtCenter: Int, forceScroll: Bool, animation: ViewAnimation) {
        selected = itemAtCenter - extra
            //collectionView?.reloadData()
    }
    
        // MARK: - Pan Gesture handlers
    
#if targetEnvironment(macCatalyst)
    @objc private func panned(_ collectionView: UICollectionView) {
        let translation = panGestureRecognizer.translation(in: valuesCollectionView!)
        switch panGestureRecognizer.state {
        case .began:
            panStart = valuesCollectionView.contentOffset.x
        case .changed:
            valuesCollectionView.setContentOffset(CGPoint(x: max(0, min(CGFloat(values.count - 1) * buttonSize.width, panStart - translation.x)), y: 0), animated: false)
        case .ended:
            let buttons = Int(((panStart - translation.x) / buttonSize.width).rounded())
            let newSelected = max(0, min(values.count - 1, buttons))
            valuesCollectionView.setContentOffset(CGPoint(x: CGFloat(newSelected) * buttonSize.width, y: 0), animated: true)
            changed(collectionView, itemAtCenter: newSelected + extra, forceScroll: false, animation: .none)
        default:
            break
        }
    }
#endif
    
        // MARK: - Tap handlers ============================================================================ -
    
    private func valueTapped(value: Int) {
        completion?(value, nil)
        hide()
    }
    
    @objc private func cancelPressed(_ sender: Any) {
        completion?(selected, nil)
        hide()
    }
    
    @objc private func clearTapped(_ sender: Any) {
        completion?(nil, nil)
        hide()
    }
    
        // MARK: - Show / Hide ============================================================================ -
    
    public func show(from sourceView: UIView, values: [ScrollPickerEntry], maxValues: Int = 5, selected: Int?, defaultValue: Int?, frame: CGRect, hideBackground: Bool = true, topPadding: CGFloat = 0, bottomPadding: CGFloat = 0, completion: @escaping (Int?, KeyAction?)->()) {
        self.values = values
        self.maxValues = maxValues
        self.selected = selected
        self.selectedOnEntry = selected
        self.defaultValue = defaultValue
        self.buttonSize = frame.size
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.completion = completion
        self.sourceView = sourceView
        self.frame = sourceView.frame
        backgroundView.frame = sourceView.frame
        let valuesVisible = maxValues
        contentView.frame = CGRect(x: frame.minX - (CGFloat(Int(valuesVisible / 2)) * buttonSize.width), y: frame.minY - focusThickness, width: buttonSize.width * CGFloat(valuesVisible), height: buttonSize.height + (2 * focusThickness) + clearHeight + clearPadding)
        focusWidthConstraint.constant = buttonSize.width + (2 * focusThickness)
        clearLabelWidthConstraint.constant = buttonSize.width
        clearLabel.isHidden = (self.defaultValue == nil)
        setNeedsLayout()
        layoutIfNeeded()
        layoutSubviews()
        sourceView.addSubview(self)
        sourceView.bringSubviewToFront(self)
        backgroundView.isHidden = !hideBackground
        valuesCollectionView.reloadData()
        if let value = self.selected ?? defaultValue {
            set(value)
        }
        contentView.isHidden = false
        accumulatedCharacters = ""
        let firstResponder = FirstResponderLabel(view: self)
        addSubview(firstResponder)
        firstResponder.becomeFirstResponder()
    }
    
    private func set(_ value: Int) {
        selected = value
        valuesCollectionView.scrollToItem(at: IndexPath(item: value + Int(maxValues / 2), section: 0), at: .centeredHorizontally, animated: false)
    }
    
    public func hide(keyAction: KeyAction? = nil) {
        self.removeFromSuperview()
    }
    
        // MARK: - View Setup ======================================================================== -
    
    private func loadScrollPickerPopupView() {
        
        let layout = CustomCollectionViewLayout(alphaFactor: 1.0, scaleFactor: 1.0, direction: .horizontal)
        layout.delegate = self
        valuesCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        valuesCollectionView.contentInsetAdjustmentBehavior = .never
        
            // Background
        backgroundView = UIView()
        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let cancelSelector = #selector(ScrollPickerPopupView.cancelPressed(_:))
        let tapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
        backgroundView.addGestureRecognizer(tapGesture, identifier: "Scroll picker popup")
        backgroundView.isUserInteractionEnabled = true
        
#if targetEnvironment(macCatalyst)
            // Mac catalyst pan gesture
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ScrollPickerPopupView.panned(_:)))
        valuesCollectionView.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.isEnabled = true
#endif
        
            // Content
        contentView = UIView()
        backgroundView.addSubview(contentView)
        contentView.backgroundColor = UIColor.clear
        contentView.addShadow()
        
        loadCollection(collectionView: valuesCollectionView)
        
        let focusWindow = UILabel()
        focusWindow.layer.borderColor = Palette.alternate.contrastText.cgColor
        focusWindow.layer.borderWidth = focusThickness
        contentView.addSubview(focusWindow, anchored: .centerX, .top)
        Constraint.anchor(view: contentView, control: focusWindow, constant: clearHeight + clearPadding, attributes: .bottom)
        focusWidthConstraint = Constraint.setWidth(control: focusWindow, width: 0)
        
        clearLabel = UILabel()
        contentView.addSubview(clearLabel, anchored: .bottom, .centerX)
        Constraint.setHeight(control: clearLabel, height: clearHeight)
        clearLabelWidthConstraint = Constraint.setWidth(control: clearLabel, width: 0)
        clearLabel.text = "Clear"
        clearLabel.backgroundColor = UIColor(Palette.alternate.background)
        clearLabel.textColor = UIColor(Palette.alternate.themeText)
        clearLabel.font = titleFont.bold
        clearLabel.textAlignment = .center
        let clearTapGesture = UITapGestureRecognizer(target: self, action: #selector(ScrollPickerPopupView.clearTapped(_:)))
        clearLabel.addGestureRecognizer(clearTapGesture, identifier: "Scroll picker popup (clear)")
        clearLabel.isUserInteractionEnabled = true
        
        contentView.isHidden = true
    }
    
    func loadCollection(collectionView: UICollectionView) {
        contentView.addSubview(collectionView, leading: 0, trailing: 0, top: focusThickness)
        Constraint.anchor(view: contentView, control: collectionView, constant: focusThickness + clearHeight + clearPadding, attributes: .bottom)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        ScrollPickerCell.register(collectionView)
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !processPressedKeys(presses, with: event, allowCharacters: true, action: { (keyAction, _) in
            switch keyAction {
            case .previous, .next, .left, .right, .up, .down, .escape, .enter, .backspace, .delete, .characters:
                true
            default:
                false
            }
        }) {
            super.pressesBegan(presses, with: event)
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        
        if !processPressedKeys(presses, with: event, allowCharacters: true, action: { (keyAction, characters) in

            ScrollPicker.processKeys(keyAction: keyAction, characters: characters, accumulatedCharacters: accumulatedCharacters, selected: selected, values: values.map({$0.title}), completion: { [self] (characters, newSelected, keyAction) in
                
                accumulatedCharacters = characters
                
                if keyAction == .characters && characters.trim() == "" && (values.first(where: {$0.title == ""}) == nil) && self.defaultValue != nil {
                    // Space pressed, blank is not valid and there is a clear button - 'tap' it
                    self.clearTapped(self)
                    
                } else {
    
                    if let newSelected = newSelected {
                        set(newSelected)
                    } else if let selectedOnEntry = selectedOnEntry {
                        set(selectedOnEntry)
                    }
                    
                    if keyAction != .characters && !(keyAction?.arrowKey ?? false) {
                        completion?(selected, keyAction)
                        hide()
                    }
                }
            })
        }) {
            super.pressesEnded(presses, with: event)
        }
    }
}
