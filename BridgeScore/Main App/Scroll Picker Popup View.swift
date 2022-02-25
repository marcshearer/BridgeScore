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
    private var valuesCollectionView: UICollectionView!
    private var selected: Int!
    private var values: [String]!
    private var maxValues = 5
    private var buttonSize: CGSize!
    private var completion: ((Int?)->())?
    private var focusWidthConstraint: NSLayoutConstraint!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadScrollPickerPopupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        loadScrollPickerPopupView()
        
    }
       
    // MARK: - CollectionView Delegates ================================================================ -
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(values.count + Int(maxValues / 2) * 2)
        return values.count + Int(maxValues / 2) * 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return buttonSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = ScrollPickerPopupCollectionCell.dequeue(collectionView, for: indexPath)
        let item = indexPath.item
        var text = ""
        var tag = -1
        var tapAction: ((Int)->())?
        let extra = Int(maxValues / 2)
        if item >= extra && item - extra <= values.count - 1 {
            text = values[item - extra]
            tag = item - extra
            tapAction = valueTapped
        }
        cell.set(text: text, tag: tag, selected: (tag == selected), tapAction: tapAction)
        return cell
    }
    
    func changed(_ collectionView: UICollectionView?, itemAtCenter: Int, forceScroll: Bool, animation: ViewAnimation) {
        selected = itemAtCenter
        collectionView?.reloadData()
    }
    
    // MARK: - Tap handlers ============================================================================ -
    
    private func valueTapped(value: Int) {
        completion?(value)
        hide()
    }
    
    @objc private func cancelPressed(_ sender: Any) {
        hide()
    }
    // MARK: - Show / Hide ============================================================================ -
    
    public func show(from sourceView: UIView, values: [String], maxValues: Int = 5, selected: Int, frame: CGRect, hideBackground: Bool = true, completion: @escaping (Int?)->()) {
        self.values = values
        self.maxValues = maxValues
        self.selected = selected
        self.buttonSize = frame.size
        self.completion = completion
        self.frame = sourceView.frame
        backgroundView.frame = sourceView.frame
        let valuesVisible = min(maxValues, values.count)
        contentView.frame = CGRect(x: frame.minX - (CGFloat(Int(valuesVisible / 2)) * buttonSize.width), y: frame.minY, width: buttonSize.width * CGFloat(valuesVisible), height: buttonSize.height)
        focusWidthConstraint.constant = buttonSize.width
        setNeedsLayout()
        layoutIfNeeded()
        layoutSubviews()
        sourceView.addSubview(self)
        sourceView.bringSubviewToFront(self)
        backgroundView.isHidden = !hideBackground
        contentView.isHidden = false
        valuesCollectionView.reloadData()
        valuesCollectionView.scrollToItem(at: IndexPath(item: selected + 2, section: 0), at: .centeredHorizontally, animated: false)
    }
    
    public func hide() {
        removeFromSuperview()
    }
    
  // MARK: - View Setup ======================================================================== -
    
    private func loadScrollPickerPopupView() {
        
        let layout = CustomCollectionViewLayout(alphaFactor: 1.0, scaleFactor: 1.0, direction: .horizontal)
        layout.delegate = self
        valuesCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)

        // Background
        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let cancelSelector = #selector(ScrollPickerPopupView.cancelPressed(_:))
        let tapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
        backgroundView.addGestureRecognizer(tapGesture)
        backgroundView.isUserInteractionEnabled = true
        
        // Content
        backgroundView.addSubview(contentView)
        contentView.backgroundColor = UIColor(Palette.alternate.background)
        contentView.addShadow()
        let nullGesture = UITapGestureRecognizer(target: self, action: nil)
        contentView.addGestureRecognizer(nullGesture)
        contentView.isUserInteractionEnabled = true
                        
        loadCollection(collectionView: valuesCollectionView)
        
        let focusWindow = UILabel()
        focusWindow.layer.borderColor = Palette.alternate.contrastText.cgColor
        focusWindow.layer.borderWidth = 5
        contentView.addSubview(focusWindow, anchored: .centerX, .top, .bottom)
        focusWidthConstraint = Constraint.setWidth(control: focusWindow, width: 100)
    }
    
    func loadCollection(collectionView: UICollectionView) {
        contentView.addSubview(collectionView, anchored: .all)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        ScrollPickerPopupCollectionCell.register(collectionView)
    }
}

// MARK: - Cell classes ================================================================ -


fileprivate class ScrollPickerPopupCollectionCell: UICollectionViewCell {
    private var label = UILabel()
    private var tapAction: ((Int)->())?
    private static let scrollPickerPopupCellIdentifier = "Value Collection Cell"

    override init(frame: CGRect) {
        super.init(frame: frame)
                        
        self.layer.borderColor = UIColor(Palette.gridLine).cgColor

        addSubview(label, anchored: .all)
        label.textAlignment = .center
        label.minimumScaleFactor = 0.3
        label.backgroundColor = UIColor(Palette.alternate.background)
        label.textColor = UIColor(Palette.alternate.text)
        label.font = pickerTitleFont
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ScrollPickerPopupCollectionCell.tapped(_:)))
        label.addGestureRecognizer(tapGesture)
        label.isUserInteractionEnabled = true
        tapGesture.isEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ collectionView: UICollectionView) {
        collectionView.register(ScrollPickerPopupCollectionCell.self, forCellWithReuseIdentifier: scrollPickerPopupCellIdentifier)
    }

    public class func dequeue(_ collectionView: UICollectionView, for indexPath: IndexPath) -> ScrollPickerPopupCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: scrollPickerPopupCellIdentifier, for: indexPath) as! ScrollPickerPopupCollectionCell
        cell.prepareForReuse()
        return cell
    }
    
    override func prepareForReuse() {
        self.layer.borderWidth = 0

    }
    
    func set(text: String, tag: Int, selected: Bool, tapAction: ((Int)->())?) {
        self.tag = tag
        label.text = text
        self.tapAction = tapAction
        self.layer.borderWidth = (tapAction == nil ? 0 : 2)
    }
    
    @objc func tapped(_ sender: UILabel) {
        tapAction?(self.tag)
    }
}
