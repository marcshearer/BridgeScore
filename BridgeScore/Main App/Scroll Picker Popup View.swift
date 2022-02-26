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
    private var values: [ScrollPickerEntry]!
    private var maxValues = 5
    private var buttonSize: CGSize!
    private var completion: ((Int?)->())?
    private var focusWidthConstraint: NSLayoutConstraint!
    private var topPadding: CGFloat = 0
    private var bottomPadding: CGFloat = 0
    private var extra: Int { Int(maxValues / 2) }

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
    // MARK: - Show / Hide ============================================================================ -
    
    public func show(from sourceView: UIView, values: [ScrollPickerEntry], maxValues: Int = 5, selected: Int, frame: CGRect, hideBackground: Bool = true, topPadding: CGFloat = 0, bottomPadding: CGFloat = 0, completion: @escaping (Int?)->()) {
        self.values = values
        self.maxValues = maxValues
        self.selected = selected
        self.buttonSize = frame.size
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.completion = completion
        self.frame = sourceView.frame
        backgroundView.frame = sourceView.frame
        let valuesVisible = maxValues
        contentView.frame = CGRect(x: frame.minX - (CGFloat(Int(valuesVisible / 2)) * buttonSize.width), y: frame.minY - 5, width: buttonSize.width * CGFloat(valuesVisible), height: buttonSize.height + 10)
        focusWidthConstraint.constant = buttonSize.width + 10
        setNeedsLayout()
        layoutIfNeeded()
        layoutSubviews()
        sourceView.addSubview(self)
        sourceView.bringSubviewToFront(self)
        backgroundView.isHidden = !hideBackground
        valuesCollectionView.reloadData()
        valuesCollectionView.scrollToItem(at: IndexPath(item: selected + Int(maxValues / 2), section: 0), at: .centeredHorizontally, animated: false)
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

        // Background
        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let cancelSelector = #selector(ScrollPickerPopupView.cancelPressed(_:))
        let tapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
        backgroundView.addGestureRecognizer(tapGesture)
        backgroundView.isUserInteractionEnabled = true
        
        // Content
        backgroundView.addSubview(contentView)
        contentView.backgroundColor = UIColor.clear
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
        contentView.isHidden = true
    }
    
    func loadCollection(collectionView: UICollectionView) {
        contentView.addSubview(collectionView, leading: 0, trailing: 0, top: 5, bottom: 5)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        ScrollPickerCell.register(collectionView)
    }
}
