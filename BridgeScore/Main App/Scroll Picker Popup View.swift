//
//  Scroll Picker Popup View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 25/02/2022.
//

import UIKit

class ScrollPickerPopupView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, CustomCollectionViewLayoutDelegate {
       
    private var backgroundView = UIView()
    private var contentView = UIView()
    private var clearLabel = UILabel()
    private var valuesCollectionView: UICollectionView!
    private var selected: Int?
    private var defaultValue: Int?
    private var values: [ScrollPickerEntry]!
    private var maxValues = 5
    private var buttonSize: CGSize!
    private var completion: ((Int?)->())?
    private var focusWidthConstraint: NSLayoutConstraint!
    private var clearLabelWidthConstraint: NSLayoutConstraint!
    private var topPadding: CGFloat = 0
    private var bottomPadding: CGFloat = 0
    private var extra: Int { Int(maxValues / 2) }
    private let focusThickness: CGFloat = 5
    private let clearHeight: CGFloat = 30
    private let clearPadding: CGFloat = 5

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
        collectionView?.reloadData()
    }
    
    // MARK: - Tap handlers ============================================================================ -
    
    private func valueTapped(value: Int) {
        completion?(value)
        hide()
    }
    
    @objc private func cancelPressed(_ sender: Any) {
        completion?(selected)
        hide()
    }
    
    @objc private func clearTapped(_ sender: Any) {
        completion?(nil)
        hide()
    }
    
    // MARK: - Show / Hide ============================================================================ -
    
    public func show(from sourceView: UIView, values: [ScrollPickerEntry], maxValues: Int = 5, selected: Int?, defaultValue: Int?, frame: CGRect, hideBackground: Bool = true, topPadding: CGFloat = 0, bottomPadding: CGFloat = 0, completion: @escaping (Int?)->()) {
        self.values = values
        self.maxValues = maxValues
        self.selected = selected
        self.defaultValue = defaultValue
        self.buttonSize = frame.size
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.completion = completion
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
        if let selected = self.selected ?? defaultValue {
            valuesCollectionView.scrollToItem(at: IndexPath(item: selected + Int(maxValues / 2), section: 0), at: .centeredHorizontally, animated: false)
        }
        self.contentView.isHidden = false
    }
    
    public func hide() {
        self.contentView.isHidden = true
        removeFromSuperview()
    }
    
  // MARK: - View Setup ======================================================================== -
    
    private func loadScrollPickerPopupView() {
        
        let layout = CustomCollectionViewLayout(alphaFactor: 1.0, scaleFactor: 1.0, direction: .horizontal)
        layout.delegate = self
        valuesCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        valuesCollectionView.contentInsetAdjustmentBehavior = .never

        // Background
        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let cancelSelector = #selector(ScrollPickerPopupView.cancelPressed(_:))
        let tapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
        backgroundView.addGestureRecognizer(tapGesture, identifier: "Scroll picker popup")
        backgroundView.isUserInteractionEnabled = true
        
        // Content
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
}
