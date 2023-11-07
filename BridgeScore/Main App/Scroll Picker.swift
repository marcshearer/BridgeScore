//
//  Scroll Picker.swift
//  BridgeScore
//
//  Created by Marc Shearer on 17/02/2022.
//

import UIKit
import SwiftUI

protocol ScrollPickerDelegate {
    func scrollPickerDidChange(_ scrollPicker: ScrollPicker?, to: Int?, allowPopup: Bool)
}

extension ScrollPickerDelegate {
    func scrollPickerDidChange(_ scrollPicker: ScrollPicker?, to: Int?) {
        scrollPickerDidChange(scrollPicker, to: to, allowPopup: false)
    }
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
    private var accumulatedView: ScrollPickerView!
#if targetEnvironment(macCatalyst)
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var panStart: CGFloat = 0
#endif
    private var color: PaletteColor?
    private var clearBackground = true
    public var list: [ScrollPickerEntry]
    private var defaultEntry: ScrollPickerEntry?
    private var defaultValue: Int?
    private var titleFont: UIFont
    private var captionFont: UIFont
    private(set) var selected: Int?
    private var selectedOnEntry: Int?
    public var delegate: ScrollPickerDelegate?
    private var accumulatedCharacters: String = ""
    
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
        accumulatedView = ScrollPickerView()
        self.addSubview(accumulatedView, anchored: .all)
        
        #if targetEnvironment(macCatalyst)
        // Mac catalyst pan gesture
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ScrollPicker.panned(_:)))
        collectionView.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.isEnabled = true
        #endif
    }
    
    public func set(_ selected: Int?, list: [String], defaultEntry: String? = nil, defaultValue: Int? = nil, isEnabled: Bool = true, color: PaletteColor? = nil, titleFont: UIFont? = nil, captionFont: UIFont? = nil, clearBackground: Bool = true) {
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
        self.selectedOnEntry = selected
        self.accumulatedCharacters = ""
        if let defaultValue = defaultValue {
            self.defaultValue = defaultValue
        }
        
        if reload {
            collectionView.reloadData()
            collectionView.alpha = 0
        }
        
        accumulatedView.prepareForReuse()
        accumulatedView.set(titleText: "", captionText: "", color: color, titleFont: titleFont, captionFont: captionFont, clearBackground: clearBackground)
        
        Utility.mainThread { [self] in
            setValue(selected, force: true)
        }
    }
    
    public func setValue(_ selected: Int?, force: Bool = false) {
        accumulatedCharacters = ""
        updateAccumulatedView()
        if self.selected != selected || force {
            self.selected = selected
            collectionView.scrollToItem(at: IndexPath(item: selected ?? 0, section: 0), at: .centeredHorizontally, animated: false)
            delegate?.scrollPickerDidChange(self, to: selected ?? -1)
        }
        self.collectionView.alpha = 1
    }
    
    private func updateAccumulatedView() {
        let show = accumulatedCharacters != ""
        accumulatedView.isHidden = !show
        collectionView.isHidden = show
        accumulatedView.set(titleText: accumulatedCharacters.capitalized)
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
        let item = (selected == nil && defaultEntry != nil ? defaultEntry! : list[indexPath.item])
        cell.set(titleText: item.title, captionText: item.caption ?? "", color: color, titleFont: titleFont, captionFont: captionFont, clearBackground: clearBackground)
        return cell
    }
    
    internal func changed(_ collectionView: UICollectionView?, itemAtCenter: Int, forceScroll: Bool, animation: ViewAnimation) {
        Utility.mainThread {
            self.selected = max(0, min(self.list.count - 1, itemAtCenter))
            collectionView?.reloadData()
        }
    }
    
    // MARK: - Pan Gesture handlers
    
    #if targetEnvironment(macCatalyst)
    @objc private func panned(_ sender: UIView) {
        let translation = panGestureRecognizer.translation(in: self.superview!.superview!)
        switch panGestureRecognizer.state {
        case .began:
            panStart = collectionView.contentOffset.x
        case .changed:
            collectionView.setContentOffset(CGPoint(x: max(0, min(CGFloat(list.count - 1) * frame.width, panStart - translation.x)), y: 0), animated: false)
        case .ended:
            let buttons = Int((translation.x / frame.width).rounded())
            let newSelected = max(0, min(list.count - 1, (selected ?? defaultValue ?? 0) - buttons))
            collectionView.setContentOffset(CGPoint(x: CGFloat(newSelected) * frame.width, y: 0), animated: true)
            changed(collectionView, itemAtCenter: newSelected, forceScroll: false, animation: .none)
        default:
            break
        }
    }
    #endif
    
    public func loseFocus() {
        delegate?.scrollPickerDidChange(self, to: selected, allowPopup: false)
        set(selected)
    }
    
    public func processKeys(keyAction: KeyAction, characters: String) -> Bool {
        if keyAction == .characters && characters.trim() == "" {
            // Blank pressed - just save current and popup window rather than blanking picker
            delegate?.scrollPickerDidChange(self, to: selected, allowPopup: true)
            set(selected)
            return false
        } else {
            return ScrollPicker.processKeys(keyAction: keyAction, characters: characters, accumulatedCharacters: accumulatedCharacters, selected: selected, defaultValue: defaultValue, values: list.map({ $0.title}), completion: { [self] (characters, newSelected, keyAction) in
                
                accumulatedCharacters = characters
                if accumulatedCharacters != "" && keyAction == .characters && newSelected == nil {
                    updateAccumulatedView()
                } else {
                    accumulatedCharacters = ""
                    updateAccumulatedView()
                    
                    if newSelected != selected {
                        if let newSelected = newSelected {
                            setValue(newSelected)
                        }
                    }
                    switch keyAction {
                    case .previous, .next, .up, .down, .enter:
                        delegate?.scrollPickerDidChange(self, to: selected, allowPopup: keyAction == .enter)
                        set(selected)
                    case .escape:
                        if let selectedOnEntry = selectedOnEntry {
                            setValue(selectedOnEntry)
                        }
                    case .delete, .backspace:
                        if let defaultValue = defaultValue {
                            delegate?.scrollPickerDidChange(self, to: defaultValue)
                            set(defaultValue)
                        }
                    default:
                        break
                    }
                }
            })
        }
    }
    
    static public func processKeys(keyAction: KeyAction, characters: String, accumulatedCharacters: String, selected: Int?, defaultValue: Int? = nil, values: [String], crossPattern: Bool = false, completion: (String, Int?, KeyAction?)->()) -> Bool {
        var result = true
        var accumulatedCharacters = accumulatedCharacters
        switch keyAction {
        case .previous, .next, .enter, .backspace, .delete:
            completion("", selected, keyAction)
        case .left:
            if crossPattern {
                if selected != 0 && selected != values.count - 1 {
                    completion("", max(1, (selected ?? defaultValue ?? 0) - 1), keyAction)
                } else {
                    completion("", (values.count / 2) - 1, keyAction)
                }
            } else {
                completion("", max(0,(selected ?? defaultValue ?? 0) - 1), keyAction)
            }
        case .right:
            if crossPattern {
                if selected != 0 && selected != values.count - 1 {
                    completion("", min(values.count - 2, (selected ?? defaultValue ?? 0) + 1), keyAction)
                } else {
                    completion("", (values.count / 2) + 1, keyAction)
                }
            } else {
                completion("", min(values.count - 1, (selected ?? defaultValue ?? 0) + 1), keyAction)
            }
        case .up:
            if crossPattern {
                let newSelected = (selected == values.count - 1 ? values.count / 2 : 0)
                completion("", newSelected, keyAction)
            } else {
                completion("", selected, keyAction)
            }
        case .down:
            if crossPattern {
                let newSelected = (selected == 0 ? values.count / 2 : values.count - 1)
                completion("", newSelected, keyAction)
            } else {
                completion("", selected, keyAction)
            }
        case .escape:
            completion("", nil, keyAction)
        case .characters:
            accumulatedCharacters += characters.trim()
            if characters == " " {
                if let blankIndex = values.firstIndex(where: {$0.trim() == ""}) {
                    if selected == blankIndex {
                        completion("", selected, nil)
                    } else {
                        completion("", blankIndex, .characters)
                    }
                } else {
                    completion("", selected, .characters)
                }
            } else if let index = values.firstIndex(where: {$0.lowercased() == accumulatedCharacters.lowercased()}) {
                completion("", index, .characters)
            } else if values.firstIndex(where: {$0.lowercased().starts(with: accumulatedCharacters.lowercased())}) != nil {
                completion(accumulatedCharacters, nil, .characters)
            } else if values.firstIndex(where: {$0.lowercased().starts(with: characters.lowercased())}) != nil  {
                completion(characters, nil, .characters)
            }
        default:
            result = false
        }
        return result
    }
}


class ScrollPickerView: UIView {
    private var background: UIView!
    private var title: UILabel!
    private var caption: UILabel!
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
    }
    
    func addTapGesture(tapAction: ((Int)->())?) {
        if tapAction != nil {
            if tapGesture == nil {
                tapGesture = UITapGestureRecognizer(target: self, action: #selector(ScrollPickerView.tapped(_:)))
                background.addGestureRecognizer(tapGesture, identifier: "ScrollPicker")
            }
        }
        self.tapAction = tapAction
        tapGesture?.isEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let cornerRadius = cornerRadius {
            background.roundCorners(cornerRadius: cornerRadius)
        }
    }
    
    internal func prepareForReuse() {
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
        tapGesture?.isEnabled = false
    }
    
    public func set(titleText: String, captionText: String? = nil, tag: Int = 0, color: PaletteColor? = nil, titleFont: UIFont? = nil, captionFont: UIFont? = nil, clearBackground: Bool = true, topPadding: CGFloat = 0, bottomPadding: CGFloat = 0, leadingSpace: CGFloat = 0, trailingSpace: CGFloat = 0, borderWidth: CGFloat = 0, cornerRadius: CGFloat? = nil, tapAction: ((Int)->())? = nil) {
        
        background.backgroundColor = (clearBackground ? UIColor.clear : UIColor(color?.background ?? Color.clear))
        self.tag = tag
        self.addTapGesture(tapAction: tapAction)
        self.isUserInteractionEnabled = (tapAction != nil)
        background.layer.borderWidth = borderWidth
        background.layer.borderColor = UIColor(Palette.gridLine).cgColor
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

class ScrollPickerCell: UICollectionViewCell {
    private static let identifier = "ScrollPickerCell"
    private var view: ScrollPickerView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        view = ScrollPickerView(frame: frame)
        self.addSubview(view, anchored: .all)
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
    
    public func set(titleText: String, captionText: String? = nil, tag: Int = 0, color: PaletteColor? = nil, titleFont: UIFont? = nil, captionFont: UIFont? = nil, clearBackground: Bool = true, topPadding: CGFloat = 0, bottomPadding: CGFloat = 0, leadingSpace: CGFloat = 0, trailingSpace: CGFloat = 0, borderWidth: CGFloat = 0, cornerRadius: CGFloat? = nil, tapAction: ((Int)->())? = nil) {
        view.set(titleText: titleText, captionText: captionText, tag: tag, color: color, titleFont: titleFont, captionFont: captionFont, clearBackground: clearBackground, topPadding: topPadding, bottomPadding: bottomPadding, leadingSpace: leadingSpace, trailingSpace: trailingSpace, borderWidth: borderWidth, cornerRadius: cornerRadius, tapAction: tapAction)
    }
    
    internal override func prepareForReuse() {
        view.prepareForReuse()
    }
}
