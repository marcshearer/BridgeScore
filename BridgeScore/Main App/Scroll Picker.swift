//
//  Scroll Picker.swift
//  BridgeScore
//
//  Created by Marc Shearer on 17/02/2022.
//

import UIKit
import SwiftUI

@objc protocol ScrollPickerDelegate {
    @objc optional func scrollPickerDidChange(to: Int)
    @objc optional func scrollPickerDidChange(_ scrollPicker: ScrollPicker, to: Int)
}

struct ScrollPickerEntry: Equatable {
    var title: String
    var caption: String?
    
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
    private var titleFont: UIFont
    private var captionFont: UIFont
    private(set) var selected: Int?
    public var delegate: ScrollPickerDelegate?
    
    convenience init(frame: CGRect, list: [String], color: PaletteColor? = nil, titleFont: UIFont? = nil, captionFont: UIFont? = nil) {
        self.init(frame: frame, list: list.map{ScrollPickerEntry(title: $0, caption: nil)}, color: color, titleFont: titleFont, captionFont: captionFont)
    }
    
    init(frame: CGRect, list: [ScrollPickerEntry] = [], color: PaletteColor? = nil, titleFont: UIFont? = nil, captionFont: UIFont? = nil) {
        self.list = list
        self.color = color
        self.titleFont = titleFont ?? pickerTitleFont
        self.captionFont = captionFont ?? pickerCaptionFont
        super.init(frame: frame)
        let layout = CustomCollectionViewLayout(direction: .vertical)
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
    
    public func set(_ selected: Int, list: [String], isEnabled: Bool = true, color: PaletteColor? = nil, titleFont: UIFont?, captionFont: UIFont? = nil, clearBackground: Bool = true) {
        set(selected, list: list.map{ScrollPickerEntry(title: $0, caption: nil)}, isEnabled: isEnabled, color: color, titleFont: titleFont, captionFont: captionFont, clearBackground: clearBackground)
    }
    
    public func set(_ selected: Int, list: [ScrollPickerEntry]! = nil, isEnabled: Bool = true, color: PaletteColor? = nil, titleFont: UIFont? = nil, captionFont: UIFont? = nil, clearBackground: Bool = true) {
        var reload = false
        
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
        if reload {
            collectionView.reloadData()
        }

        Utility.executeAfter(delay: 0.1) {
            self.collectionView.scrollToItem(at: IndexPath(item: selected, section: 0), at: .centeredVertically, animated: false)
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
        let item = list[indexPath.item]
        cell.set(titleText: item.title, captionText: item.caption ?? "", color: color, titleFont: titleFont, captionFont: captionFont, clearBackground: clearBackground)
        return cell
    }
    
    internal func changed(_ collectionView: UICollectionView?, itemAtCenter: Int, forceScroll: Bool, animation: ViewAnimation) {
        Utility.mainThread {
            self.selected = itemAtCenter
            self.delegate?.scrollPickerDidChange?(to: self.selected!)
            self.delegate?.scrollPickerDidChange?(self, to: self.selected!)
            collectionView?.reloadData()
        }
    }
}

class ScrollPickerCell: UICollectionViewCell {
    private var title: UILabel!
    private var caption: UILabel!
    private static let identifier = "ScrollPickerCell"
    private var captionHeightConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        title = UILabel(frame: frame)
        title.font = pickerTitleFont
        title.minimumScaleFactor = 0.3
        title.textAlignment = .center
        self.addSubview(title, leading: 0, trailing: 0, top: frame.height / 10)
        caption = UILabel(frame: frame)
        caption.font = pickerCaptionFont
        caption.textAlignment = .center
        self.addSubview(caption, leading: 0, trailing: 0, bottom: frame.height / 10)
        captionHeightConstraint = Constraint.setHeight(control: caption, height: 0)
        Constraint.anchor(view: self, control: caption, to: title, constant: frame.height / 10, toAttribute: .bottom, attributes: .top)
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
    
    public func set(titleText: String, captionText: String? = nil, color: PaletteColor? = nil, titleFont: UIFont?, captionFont: UIFont? = nil, clearBackground: Bool = true) {
        title.text = titleText
        if let titleFont = titleFont {
            title.font = titleFont
        }
        self.backgroundColor = (clearBackground ? UIColor.clear : UIColor(color?.background ?? Color.clear))
        title.backgroundColor = UIColor.clear
        title.textColor = UIColor(color?.text ?? Palette.background.text)
        if let captionText = captionText {
            caption.text = captionText
            captionHeightConstraint.constant = self.frame.height / 5
            if let captionFont = captionFont {
                caption.font = captionFont
            }
        }
    }
}
