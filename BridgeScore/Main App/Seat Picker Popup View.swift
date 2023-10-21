//
//  Seat Picker.swift
//  BridgeScore
//
//  Created by Marc Shearer on 09/03/2022.
//

import UIKit

class DeclarerPickerPopupView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
       
    private var backgroundView = UIView()
    private var contentView = UIView()
    private var valuesCollectionView: UICollectionView!
    private var selected: Seat?
    private var values: [(seat: Seat, entry: ScrollPickerEntry)]!
    private var buttonSize: CGSize!
    private var completion: ((Seat?)->())?
    private var topPadding: CGFloat = 0
    private var bottomPadding: CGFloat = 0
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadSeatPickerPopupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        loadSeatPickerPopupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
       
    // MARK: - CollectionView Delegates ================================================================ -
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return values.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = indexPath.item
        let size = CGSize(width: (item == 0 || item == values.count - 1 ? 3 : 1) * buttonSize.width, height: buttonSize.height)
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = ScrollPickerCell.dequeue(collectionView, for: indexPath)
        let item = indexPath.item
        let entry = values[item].entry
        let selectedItem = (values[item].seat == selected)
        let space = (item == 0 || item == values.count - 1 ? buttonSize.width : 0)
        cell.set(titleText: entry.title, captionText: entry.caption, tag: item, color: (selectedItem ? Palette.banner : Palette.alternate), clearBackground: false, topPadding: topPadding, bottomPadding: bottomPadding, leadingSpace: space, trailingSpace: space, borderWidth: 2.0, tapAction: valueTapped)
        return cell
    }
            
    // MARK: - Tap handlers ============================================================================ -
    
    private func valueTapped(item: Int) {
        completion?(values[item].seat)
        hide()
    }
    
    @objc private func cancelTapped(_ sender: Any) {
        completion?(selected)
        hide()
    }
    
    @objc private func clearTapped(_ sender: Any) {
        completion?(nil)
        hide()
    }
    
    // MARK: - Show / Hide ============================================================================ -
    
    public func show(from sourceView: UIView, values: [(Seat, ScrollPickerEntry)], selected: Seat?, frame: CGRect, hideBackground: Bool = true, topPadding: CGFloat = 0, bottomPadding: CGFloat = 0, completion: @escaping (Seat?)->()) {
        self.values = values
        self.selected = selected
        self.buttonSize = frame.size
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.completion = completion
        self.frame = sourceView.frame
        backgroundView.frame = sourceView.frame
        setNeedsLayout()
        layoutIfNeeded()
        layoutSubviews()
        contentView.frame = CGRect(x: frame.minX - buttonSize.width,
                                   y: frame.minY - buttonSize.height,
                                   width: (3.01 * frame.size.width),
                                   height: (3.01 * frame.size.height))
        sourceView.addSubview(self)
        sourceView.bringSubviewToFront(self)
        backgroundView.isHidden = !hideBackground
        valuesCollectionView.reloadData()
        self.contentView.isHidden = false
    }
        
    public func hide() {
        self.contentView.isHidden = true
        removeFromSuperview()
    }
    
  // MARK: - View Setup ======================================================================== -
    
    private func loadSeatPickerPopupView() {
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        valuesCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)

        // Background
        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let cancelSelector = #selector(DeclarerPickerPopupView.cancelTapped(_:))
        let tapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
        backgroundView.addGestureRecognizer(tapGesture, identifier: "Seat picker")
        backgroundView.isUserInteractionEnabled = true
        
        // Content
        backgroundView.addSubview(contentView)
        contentView.backgroundColor = UIColor.clear
        contentView.addShadow()
                        
        loadCollection(collectionView: valuesCollectionView)
        
        contentView.isHidden = true
    }
    
    func loadCollection(collectionView: UICollectionView) {
        contentView.addSubview(collectionView, anchored: .all)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        ScrollPickerCell.register(collectionView)
    }
}
