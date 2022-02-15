//
//  Scorecard Input View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 11/02/2022.
//

import UIKit
import SwiftUI

struct ScorecardInputView: View {
    @Environment(\.undoManager) private var undoManager

    @ObservedObject var scorecard: ScorecardViewModel
    @State var refresh = false
    
    var body: some View {
        StandardView {
            VStack(spacing: 0) {
                
                // Just to trigger view refresh
                if refresh { EmptyView() }
    
                // Banner
                let options = [
                    BannerOption(image: AnyView(Image(systemName: "arrow.uturn.backward")), likeBack: true, action: { undoDrawing() }),
                    BannerOption(image: AnyView(Image(systemName: "trash.fill")), likeBack: true, action: { clearDrawing() })]
                Banner(title: $scorecard.desc, back: true, backAction: backAction, leftTitle: true, optionMode: .buttons, options: options)

                GeometryReader { geometry in
                    ScorecardInputUIViewWrapper(scorecard: scorecard, frame: geometry.frame(in: .local))
                    .ignoresSafeArea(edges: .all)
                }
            }
        }
    }
    
    func backAction() -> Bool {
        return true
    }
    
    func clearDrawing() {
        MessageBox.shared.show("This will clear the contents of the drawing.\nAre you sure you want to do this?", cancelText: "Cancel", okText: "Clear", okAction: {
        })
    }
    
    func undoDrawing() {
        undoManager?.undo()
    }
}

struct ScorecardInputUIViewWrapper: UIViewRepresentable {
    @ObservedObject var  scorecard: ScorecardViewModel
    @State var frame: CGRect
    
    func makeUIView(context: Context) -> ScorecardInputUIView {
        
        let view = ScorecardInputUIView(frame: frame, scorecard: scorecard)
        view.delegate = context.coordinator
        
        return view
    }

    func updateUIView(_ uiView: ScorecardInputUIView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ScorecardInputUIViewDelegate {
    }
}

protocol ScorecardInputUIViewDelegate {
}

class ScorecardInputUIView : UIView, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
        
    var scorecard: ScorecardViewModel
    var scrollView = UIScrollView()
    var headingTableView = UITableView()
    var mainTableView = UITableView()
    var delegate: ScorecardInputUIViewDelegate?
    
    var columns = [
        ScorecardColumn(type: .board, heading: "Board", size: .fixed(70)),
        ScorecardColumn(type: .contract, heading: "Contract", size: .fixed(90)),
        ScorecardColumn(type: .declarer, heading: "By", size: .fixed(60)),
        ScorecardColumn(type: .made, heading: "Made", size: .fixed(70)),
        ScorecardColumn(type: .score, heading: "Score", size: .fixed(70)),
        ScorecardColumn(type: .comment, heading: "Comment", size: .flexible),
        ScorecardColumn(type: .responsible, heading: "Resp", size: .fixed(60))
    ]
    var rows: [ScorecardRow] = []
    let headingHeight: CGFloat = 40
    let rowHeight: CGFloat = 90
    var totalHeight: CGFloat
    private var canvasWidth: CGFloat?
    
    init(frame: CGRect, scorecard: ScorecardViewModel) {
        self.scorecard = scorecard
        self.totalHeight = (scorecard.tableTotal ? 80 : 2)
        
        super.init(frame: frame)
                    
        // Add subviews
        self.addSubview(self.headingTableView, anchored: .leading, .trailing, .top)
        self.addSubview(self.scrollView, anchored: .leading, .trailing, .bottom)
        self.scrollView.addSubview(self.mainTableView)
        
        // Set constraints on subviews
        Constraint.setHeight(control: self.headingTableView, height: headingHeight)
                
        Constraint.anchor(view: self, control: self.scrollView, to: self.headingTableView, toAttribute: .bottom, attributes: .top)
                
        // Setup heading table view
        self.headingTableView.delegate = self
        self.headingTableView.dataSource = self
        self.headingTableView.tag = RowType.heading.rawValue
        ScorecardInputUIViewTableViewCell.register(headingTableView)
        self.headingTableView.isScrollEnabled = false
        
        // Setup scroll view
        self.scrollView.contentSize = self.scrollView.frame.size
        self.scrollView.bounces = false
        
        // Setup main table view
        self.mainTableView.delegate = self
        self.mainTableView.dataSource = self
        self.mainTableView.tag = RowType.body.rawValue
        ScorecardInputUIViewTableViewCell.register(mainTableView)
        
        // Handle rotations
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [weak self] (notification) in
            self?.transformInput()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        setupRows()
        setupSizes()
        headingTableView.reloadData()
        mainTableView.reloadData()
    }

    
    func transformInput() {

    }
    
    func transformInput(to newWidth: CGFloat) {
        if newWidth != 0 {
        }
    }
           
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch RowType(rawValue: tableView.tag) {
        case .heading:
            return 1
        default:
            return rows.count - 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch RowType(rawValue: tableView.tag) {
        case .heading:
            return headingHeight
        default:
            let row = rows[indexPath.row + 1]
            return row.type == .total ? totalHeight : rowHeight
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ScorecardInputUIViewTableViewCell.dequeue(self, tableView: tableView, for: indexPath, tag: (RowType(rawValue: tableView.tag) == .heading ? 0 : indexPath.row + 1))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return columns.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let column = columns[indexPath.item]
        let row = rows[collectionView.tag]
        let height = row.type == . total ? totalHeight : row.type == .heading ? headingHeight : rowHeight
        return CGSize(width: column.width ?? 0, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = ScorecardInputUIViewCollectionViewCell.dequeue(collectionView, for: indexPath)
        let column = columns[indexPath.item]
        let row = rows[collectionView.tag]
        cell.set(row: row, column: column)
        return cell
    }
    
    func setupSizes() {
        var fixedWidth: CGFloat = 0
        var flexible: Int = 0
        for column in self.columns {
            switch column.size {
            case .fixed(let width):
                fixedWidth += width
            case .flexible:
                flexible += 1
            }
        }
        
        var factor: CGFloat = 1.0
        if UIScreen.main.bounds.height < UIScreen.main.bounds.width {
            factor = UIScreen.main.bounds.width / UIScreen.main.bounds.height
        }
        
        let availableSize = UIScreen.main.bounds.width
        let fixedSize = fixedWidth * factor
        let flexibleSize = (availableSize - fixedSize) / CGFloat(flexible)
        
        var remainingWidth = availableSize
        for index in 0..<columns.count - 1 {
            switch columns[index].size {
            case .fixed(let width):
                columns[index].width = width * factor
            case .flexible:
                columns[index].width = flexibleSize
            }
            remainingWidth -= columns[index].width!
        }
        columns[columns.count - 1].width = remainingWidth
        
        let totalRowHeight = (CGFloat(scorecard.boards) * rowHeight) + (CGFloat(scorecard.tables) * totalHeight) + headingHeight
        
        self.scrollView.contentSize = CGSize(width: availableSize, height: totalRowHeight - headingHeight)
        self.mainTableView.frame = CGRect(x: 0, y: 0, width: availableSize, height: totalRowHeight - headingHeight)
        self.mainTableView.isScrollEnabled = false
    }
    
    func setupRows(){
        rows = []
        
        rows.append(ScorecardRow(row: 0, type: .heading))
        
        for table in 1...scorecard.tables {
            
            // Add body rows
            for tableBoard in 1...scorecard.boardsTable {
                let boardNumber = ((table - 1) * scorecard.boardsTable) + tableBoard
                let board = BoardViewModel(scorecard: scorecard, match: table, board: boardNumber)
                rows.append(ScorecardRow(row: rows.count, type: .body, table: table, board: board))
            }
            
            // Add total rows
            rows.append(ScorecardRow(row: rows.count, type: .total, table: table))
        }
    }
}

// MARK: - Cell classes ================================================================ -

class ScorecardInputUIViewTableViewCell: UITableViewCell {
    fileprivate var collectionView: UICollectionView!
    private var layout: UICollectionViewFlowLayout!
    private static let identifier = "ScorecardUIViewTableViewCell"
           
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: layout)
        ScorecardInputUIViewCollectionViewCell.register(self.collectionView)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(collectionView, anchored: .all)
        self.contentView.bringSubviewToFront(self.collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ tableView: UITableView) {
        tableView.register(ScorecardInputUIViewTableViewCell.self, forCellReuseIdentifier: identifier)
    }
    
    public class func dequeue<D: UICollectionViewDataSource & UICollectionViewDelegate>(_ dataSourceDelegate : D, tableView: UITableView, for indexPath: IndexPath, tag: Int) -> ScorecardInputUIViewTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ScorecardInputUIViewTableViewCell
        cell.setCollectionViewDataSourceDelegate(dataSourceDelegate, tag: tag)
        return cell
    }
    
    private func setCollectionViewDataSourceDelegate
    <D: UICollectionViewDataSource & UICollectionViewDelegate>
    (_ dataSourceDelegate: D, tag: Int) {
        
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.tag = tag
        collectionView.reloadData()
    }
}

class ScorecardInputUIViewCollectionViewCell: UICollectionViewCell, ScrollPickerDelegate {
    fileprivate var label: UILabel!
    fileprivate var textField: UITextField
    fileprivate var positionPicker: EnumPicker<Position>!
    fileprivate var row: ScorecardRow!
    fileprivate var column: ScorecardColumn!
    private static let identifier = "ScorecardInputUIViewCollectionViewCell"
    
    override init(frame: CGRect) {
        label = UILabel()
        textField = UITextField()
        positionPicker = EnumPicker()
        super.init(frame: frame)
                
        addSubview(label, anchored: .all)
        label.layer.borderColor = UIColor(Palette.gridLine).cgColor
        label.layer.borderWidth = 2.0
        label.textAlignment = .center
        label.minimumScaleFactor = 0.3
        
        addSubview(textField, anchored: .all)
        textField.layer.borderColor = UIColor(Palette.gridLine).cgColor
        textField.layer.borderWidth = 2.0
        textField.textAlignment = .center
        textField.font = cellFont
        textField.addTarget(self, action: #selector(ScorecardInputUIViewCollectionViewCell.textFieldChanged), for: .editingChanged)
        
        addSubview(positionPicker, anchored: .all)
        positionPicker.layer.borderColor = UIColor(Palette.gridLine).cgColor
        positionPicker.layer.borderWidth = 2.0
        positionPicker.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ collectionView: UICollectionView) {
        collectionView.register(ScorecardInputUIViewCollectionViewCell.self, forCellWithReuseIdentifier: identifier)
    }
    
    public class func dequeue(_ collectionView: UICollectionView, for indexPath: IndexPath) -> ScorecardInputUIViewCollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ScorecardInputUIViewCollectionViewCell
        cell.prepareForReuse()
        return cell
    }
    
    func set(row: ScorecardRow, column: ScorecardColumn) {
        var color: PaletteColor
        self.row = row
        self.column = column
        
        switch row.type {
        case .heading:
            label.isHidden = false
            label.text = column.heading
            label.font = titleFont
            color = Palette.gridHeader
        case .body:
            setBody()
            color = Palette.gridBody
        case .total:
            label.isHidden = false
            label.font = cellFont
            color = Palette.gridTotal
        }
        label.backgroundColor = UIColor(color.background)
        label.textColor = UIColor(color.text)
    }
    
    override func prepareForReuse() {
        textField.isHidden = true
        label.isHidden = true
        positionPicker.isHidden = true
        textField.text = ""
        label.text = ""
        label.textAlignment = .center
        textField.textAlignment = .center
    }
    
    private func setBody() {
        switch column.type {
        case .board:
            label.isHidden = false
            label.font = boardFont
            label.text = "\(row.board?.board ?? 0)"
        case .contract:
            textField.isHidden = false
            textField.text = row.board?.contract ?? ""
        case .declarer:
            positionPicker.isHidden = false
            positionPicker.set(row.board?.declarer ?? .scorer, color: Palette.gridBody, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
        case .made:
            textField.isHidden = false
            textField.text = "\(row.board?.made ?? 0)"
        case .score:
            textField.isHidden = false
            textField.text = "\(row.board?.score ?? 0)"
        case .comment:
            textField.isHidden = false
            textField.textAlignment = .left
            textField.text = row.board?.comment ?? ""
        case .responsible:
            positionPicker.isHidden = false
            positionPicker.set(row.board?.declarer ?? .scorer, color: Palette.gridBody, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
        }
    }
    
    @objc private func textFieldChanged(_ textField: UITextField) {
        if let board = row.board, let text = textField.text {
            switch column.type {
            case .score:
                board.score = Float(text) ?? 0
            case .comment:
                board.comment = text
            default:
                break
            }
        }
    }
    
    internal func scrollPickerDidChange(to value: Any) {
        if let board = row.board {
            switch column.type {
            case .declarer:
                board.declarer = value as! Position
            case .responsible:
                board.responsible = value as! Position
            default:
                break
            }
        }
    }
}

protocol EnumPickerType : CaseIterable {
    var string: String {get}
}

protocol ScrollPickerDelegate {
    func scrollPickerDidChange(to: Any)
}

class EnumPicker<EnumType> : UIView, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, CustomCollectionViewLayoutDelegate where EnumType : EnumPickerType {
     
    private var collectionView: UICollectionView!
    private var collectionViewLayout: UICollectionViewLayout!
    private var color: PaletteColor?
    private var list = EnumType.allCases.map{$0}
    private var titleFont = pickerTitleFont
    private var captionFont = pickerCaptionFont
    private(set) var selected: EnumType!
    public var delegate: ScrollPickerDelegate?
    
    init(color: PaletteColor? = nil) {
        super.init(frame: CGRect())
        self.color = color
        let layout = CustomCollectionViewLayout(direction: .vertical)
        layout.delegate = self
        collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.decelerationRate = .fast
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        EnumPickerCell.register(collectionView)
        self.addSubview(collectionView, anchored: .all)
    }
    
    public func set(_ selected: EnumType, color: PaletteColor? = nil, titleFont: UIFont?, captionFont: UIFont? = nil) {
        self.selected = selected
        if let color = color {
            self.color = color
        }
        if let titleFont = titleFont {
            self.titleFont = titleFont
        }
        if let captionFont = captionFont {
            self.captionFont = captionFont
        }

        let itemAtCenter = self.list.firstIndex(where: {$0.string == selected.string})!
        self.collectionView.selectItem(at: IndexPath(item: itemAtCenter, section: 0), animated: true, scrollPosition: .centeredVertically)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        EnumType.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return frame.size
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = EnumPickerCell.dequeue(collectionView, for: indexPath)
        let title = list[indexPath.item].string
        cell.set(titleText: title.left(1).capitalized, captionText: title.capitalized, color: color, titleFont: titleFont, captionFont: captionFont)
        return cell
    }
    
    internal func changed(_ collectionView: UICollectionView?, itemAtCenter: Int, forceScroll: Bool, animation: ViewAnimation) {
        Utility.mainThread {
            self.selected = self.list[itemAtCenter]
            self.delegate?.scrollPickerDidChange(to: self.selected!)
            collectionView?.reloadData()
        }
    }
}

class EnumPickerCell: UICollectionViewCell {
    private var title: UILabel!
    private var caption: UILabel!
    private static let identifier = "EnumPickerCell"
    private var captionHeightConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        title = UILabel(frame: frame)
        title.font = cellFont
        title.textAlignment = .center
        title.minimumScaleFactor = 0.3
        self.addSubview(title, anchored: .all)
        caption = UILabel(frame: frame)
        caption.font = cellFont
        caption.textAlignment = .center
        caption.minimumScaleFactor = 0.3
        self.addSubview(caption, anchored: .leading, .trailing)
        captionHeightConstraint = Constraint.setHeight(control: caption, height: 0)
        Constraint.anchor(view: self, control: caption, constant: frame.height / 10, attributes: .bottom)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ collectionView: UICollectionView) {
        collectionView.register(EnumPickerCell.self, forCellWithReuseIdentifier: identifier)
    }
    
    public class func dequeue(_ collectionView: UICollectionView, for indexPath: IndexPath) -> EnumPickerCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! EnumPickerCell
        return cell
    }
    
    public func set(titleText: String, captionText: String? = nil, color: PaletteColor? = nil, titleFont: UIFont?, captionFont: UIFont? = nil) {
        title.text = titleText
        if let titleFont = titleFont {
            title.font = titleFont
        }
        title.backgroundColor = UIColor(color?.background ?? Color.clear)
        title.textColor = UIColor(color?.text ?? Palette.background.text)
        if let captionText = captionText {
            caption.text = captionText
            captionHeightConstraint.constant = self.frame.height / 4
            if let captionFont = captionFont {
                caption.font = captionFont
            }
        }
    }
}
 
