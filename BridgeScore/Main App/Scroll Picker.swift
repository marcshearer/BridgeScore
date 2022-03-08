//
//  Scroll Picker.swift
//  BridgeScore
//
//  Created by Marc Shearer on 17/02/2022.
//

import UIKit
import SwiftUI

protocol ScrollPickerDelegate {
    func scrollPickerDidChange(_ scrollPicker: ScrollPicker?, to: Int?)
}

struct ScrollPickerEntry: Equatable {
    var title: String
    var caption: String?
    
    init(title: String = "", caption: String? = nil) {
        self.title = title
        self.caption = caption
    }
    
    public static func ==(lhs: ScrollPickerEntry, rhs: ScrollPickerEntry) -> Bool {
        return (lhs.title == rhs.title && lhs.caption == rhs.caption)
    }
}

class ScrollPicker : UIView, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, CustomCollectionViewLayoutDelegate {
     
    private var collectionView: UICollectionView!
    private var collectionViewLayout: UICollectionViewLayout!
    private var color: PaletteColor?
    private var clearBackground = true
    private var list: [ScrollPickerEntry]
    private var defaultEntry: ScrollPickerEntry?
    private var defaultValue: Int?
    private var titleFont: UIFont
    private var captionFont: UIFont
    private(set) var selected: Int?
    public var delegate: ScrollPickerDelegate?
    
    convenience init(frame: CGRect, list: [String], defaultEntry: String? = nil, color: PaletteColor? = nil, titleFont: UIFont? = nil, captionFont: UIFont? = nil) {
        self.init(frame: frame, list: list.map{ScrollPickerEntry(title: $0)}, defaultEntry: defaultEntry == nil ? nil : ScrollPickerEntry(title: defaultEntry!), color: color, titleFont: titleFont, captionFont: captionFont)
    }
    
    init(frame: CGRect, list: [ScrollPickerEntry] = [], defaultEntry: ScrollPickerEntry? = nil, color: PaletteColor? = nil, titleFont: UIFont? = nil, captionFont: UIFont? = nil) {
        self.list = list
        self.defaultEntry = defaultEntry
        self.color = color
        self.titleFont = titleFont ?? pickerTitleFont
        self.captionFont = captionFont ?? pickerCaptionFont
        super.init(frame: frame)
        let layout = CustomCollectionViewLayout(direction: .horizontal)
        layout.delegate = self
        collectionView = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.decelerationRate = .fast
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.alwaysBounceVertical = false
        collectionView.backgroundColor = UIColor.clear
        ScrollPickerCell.register(collectionView)
        self.addSubview(collectionView, anchored: .all)
    }
    
    public func set(_ selected: Int?, list: [String], defaultEntry: String? = nil, defaultValue: Int? = nil, isEnabled: Bool = true, color: PaletteColor? = nil, titleFont: UIFont?, captionFont: UIFont? = nil, clearBackground: Bool = true) {
        set(selected, list: list.map{ScrollPickerEntry(title: $0)}, defaultEntry: defaultEntry == nil ? nil : ScrollPickerEntry(title: defaultEntry!), defaultValue: defaultValue, isEnabled: isEnabled, color: color, titleFont: titleFont, captionFont: captionFont, clearBackground: clearBackground)
    }
    
    public func set(_ selected: Int?, list: [ScrollPickerEntry]! = nil, defaultEntry: ScrollPickerEntry? = nil, defaultValue: Int? = nil, isEnabled: Bool = true, color: PaletteColor? = nil, titleFont: UIFont? = nil, captionFont: UIFont? = nil, clearBackground: Bool = true, reload: Bool = false) {
        var reload = reload
        
        if let defaultEntry = defaultEntry {
            self.defaultEntry = defaultEntry
        }
        
        if self.clearBackground != clearBackground {
            self.clearBackground = clearBackground
            reload = true
        }
        
        if let color = color {
            if color != self.color {
                self.color = color
                reload = true
            }
        }
        if let titleFont = titleFont {
            if titleFont != self.titleFont {
                self.titleFont = titleFont
                reload = true
            }
        }
        if let captionFont = captionFont {
            if captionFont != self.captionFont {
                self.captionFont = captionFont
                reload = true
            }
        }

        if let list = list {
            if list != self.list {
                self.list = list
                reload = true
            }
        }
        self.isUserInteractionEnabled = isEnabled
        self.selected = selected
        if let defaultValue = defaultValue {
            self.defaultValue = defaultValue
        }
        if reload {
            collectionView.reloadData()
        }

        Utility.executeAfter(delay: 0.1) {
            self.collectionView.scrollToItem(at: IndexPath(item: self.selected ?? self.defaultValue ?? 0, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        list.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return frame.size
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = ScrollPickerCell.dequeue(collectionView, for: indexPath)
        let item = (selected == nil && indexPath.item == (defaultValue ?? 0) && defaultEntry != nil ? defaultEntry! : list[indexPath.item])
        cell.set(titleText: item.title, captionText: item.caption ?? "", color: color, titleFont: titleFont, captionFont: captionFont, clearBackground: clearBackground)
        return cell
    }
    
    internal func changed(_ collectionView: UICollectionView?, itemAtCenter: Int, forceScroll: Bool, animation: ViewAnimation) {
        Utility.mainThread {
            self.selected = max(0, min(self.list.count - 1, itemAtCenter))
            self.delegate?.scrollPickerDidChange(self, to: self.selected!)
            collectionView?.reloadData()
        }
    }
}

class ScrollPickerCell: UICollectionViewCell {
    private var background: UIView!
    private var title: UILabel!
    private var caption: UILabel!
    private static let identifier = "ScrollPickerCell"
    private var captionHeightConstraint: NSLayoutConstraint!
    private var tapAction: ((Int)->())?
    private var tapGesture: UITapGestureRecognizer!
    private var topPaddingHeight: NSLayoutConstraint!
    private var bottomPaddingHeight: NSLayoutConstraint!
    private var centerPaddingHeight: NSLayoutConstraint!
    private var trailingSpace: NSLayoutConstraint!
    private var leadingSpace: NSLayoutConstraint!
    private var cornerRadius: CGFloat?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        background = UIView(frame: frame)
        self.addSubview(background, anchored: .top, .bottom)
        leadingSpace = Constraint.anchor(view: self, control: background, attributes: .leading).first!
        trailingSpace = Constraint.anchor(view: self, control: background, attributes: .trailing).first!

        title = UILabel(frame: frame)
        title.font = pickerTitleFont
        title.minimumScaleFactor = 0.3
        title.textAlignment = .center
        background.addSubview(title, leading: 0, trailing: 0)
        topPaddingHeight = Constraint.anchor(view: self, control: title, constant: 0, attributes: .top).first!
        
        caption = UILabel(frame: frame)
        caption.font = pickerCaptionFont
        caption.textAlignment = .center
        background.addSubview(caption, leading: 0, trailing: 0)
        bottomPaddingHeight = Constraint.anchor(view: self, control: caption, constant: 0, attributes: .bottom).first!
        centerPaddingHeight = Constraint.anchor(view: self, control: caption, to: title, constant: 0, toAttribute: .bottom, attributes: .top).first!
        captionHeightConstraint = Constraint.setHeight(control: caption, height: 0)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(ScrollPickerCell.tapped(_:)))
        background.addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ collectionView: UICollectionView) {
        collectionView.register(ScrollPickerCell.self, forCellWithReuseIdentifier: identifier)
    }
    
    public class func dequeue(_ collectionView: UICollectionView, for indexPath: IndexPath) -> ScrollPickerCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ScrollPickerCell
        return cell
    }
    
    override func layoutSubviews() {
        if let cornerRadius = cornerRadius {
            background.roundCorners(cornerRadius: cornerRadius)
        }
    }
    
    internal override func prepareForReuse() {
        self.backgroundColor = UIColor.clear
        background.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = false
        title.text = ""
        title.font = pickerTitleFont
        title.minimumScaleFactor = 0.3
        title.textAlignment = .center
        title.backgroundColor = UIColor.clear
        caption.text = ""
        caption.font = pickerCaptionFont
        caption.textAlignment = .center
        captionHeightConstraint.constant = 0
        tapAction = nil
    }
    
    public func set(titleText: String, captionText: String? = nil, tag: Int = 0, color: PaletteColor? = nil, titleFont: UIFont? = nil, captionFont: UIFont? = nil, clearBackground: Bool = true, topPadding: CGFloat = 0, bottomPadding: CGFloat = 0, leadingSpace: CGFloat = 0, trailingSpace: CGFloat = 0, borderWidth: CGFloat = 0, cornerRadius: CGFloat? = nil, tapAction: ((Int)->())? = nil) {
        
        background.backgroundColor = (clearBackground ? UIColor.clear : UIColor(color?.background ?? Color.clear))
        self.tag = tag
        self.tapAction = tapAction
        self.isUserInteractionEnabled = (tapAction != nil)
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = UIColor(Palette.gridLine).cgColor
        self.cornerRadius = cornerRadius
        
        let height = frame.height - topPadding - bottomPadding
        self.topPaddingHeight.constant = (height * 0.10) + topPadding
        self.centerPaddingHeight.constant = height * 0.075
        self.bottomPaddingHeight.constant = -((height * 0.10) + bottomPadding)
        self.leadingSpace.constant = leadingSpace
        self.trailingSpace.constant = -trailingSpace
        
        title.text = titleText
        if let titleFont = titleFont {
            title.font = titleFont
        }
        title.textColor = UIColor(color?.text ?? Palette.background.text)
        if let captionText = captionText {
            caption.text = captionText
            captionHeightConstraint.constant = height / 4
            if let captionFont = captionFont {
                caption.font = captionFont
            }
            caption.textColor = UIColor(color?.text ?? Palette.background.text)
        }
    }
    
    @objc private func tapped(_ sender: UIView) {
        tapAction?(tag)
    }
}
