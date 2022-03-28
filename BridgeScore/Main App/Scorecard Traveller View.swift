//
//  Scorecard Traveller View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 27/03/2022.
//

import UIKit
import CoreMedia

enum TravellerColumnType: Int, Codable {
    case players = 0
    case contract = 1
    case declarer = 2
    case lead = 3
    case made = 4
    case points = 5
    case score = 6
    case section = 7
    case number = 8
    
    var string: String {
        return "\(self)"
    }
}

struct TravellerColumn: Codable, Equatable {
    var type: TravellerColumnType
    var heading: String?
    var size: ColumnSize
    var width: CGFloat?
    
    static func == (lhs: TravellerColumn, rhs: TravellerColumn) -> Bool {
        return lhs.type == rhs.type && lhs.heading == rhs.heading && lhs.size == rhs.size && lhs.width == rhs.width
    }
}

enum TravellerRowType: Int {
    case traveller = 1
    case title = 2
    
    var rowHeight: CGFloat {
        switch self {
        case .traveller:
            return 70
        case .title:
            return 70
        }
    }
    
    var tagOffset: Int {
        return self.rawValue * tagMultiplier
    }
}

class ScorecardTravellerView: UIView, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
       
    private var backgroundView = UIView()
    private var contentView = UIView()
    private var containerView = UIView()
    private var instructionLabel = UILabel()
    private var closeButton = UILabel()
    private var titleView: ScorecardTravellerTitleView!
    private var valuesTableView: UITableView!
    private var bottomSpacing: NSLayoutConstraint!
    private var buttonSpacing: CGFloat = 25
    private var buttonHeight: CGFloat = 50
    private var buttonWidth: CGFloat = 160
    private var paddingSize: CGFloat = 20
    private var travellerColumns: [TravellerColumn] = []
    private var values: [TravellerViewModel] = []
    private var boardNumber: Int = 0
    private var sitting: Seat = .unknown
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        loadScorecardTravellerView()
        setupColumns()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupSizes(columns: &travellerColumns)
        contentView.roundCorners(cornerRadius: 20)
        closeButton.roundCorners(cornerRadius: 10)
        valuesTableView.reloadData()
        titleView.collectionView.reloadData()
        layoutIfNeeded()
        if valuesTableView.frame.height > valuesTableView.contentSize.height {
            bottomSpacing.constant = buttonSpacing + (valuesTableView.frame.height - valuesTableView.contentSize.height)
        }
    }
    
    // MARK: - Replace BBO names ========================================================================= -
    
    func replaceNames(values: [String]) {
        let editValues = MasterData.shared.getBboNames(values: values)
        let bboNameReplaceView = BBONameReplaceView(frame: CGRect())
        bboNameReplaceView.show(from: self, values: editValues) {
            self.valuesTableView.reloadData()
        }
    }

    // MARK: - CollectionView Delegates ================================================================ -
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TravellerRowType.traveller.rowHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        return ScorecardTravellerTableCell.dequeue(self, tableView: tableView, for: indexPath, tag: TravellerRowType.traveller.tagOffset + indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    // MARK: - CollectionView Overrides ================================================================ -
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return travellerColumns.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let column = travellerColumns[indexPath.item]
        var height: CGFloat = 0
        if let type = TravellerRowType(rawValue: collectionView.tag / tagMultiplier) {
            height = type.rowHeight
        }
        return CGSize(width: column.width ?? 0, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let type = TravellerRowType(rawValue: collectionView.tag / tagMultiplier) {
            switch type {
            case .traveller:
                let cell = ScorecardTravellerCollectionCell.dequeue(collectionView, for: indexPath)
                let row = collectionView.tag % tagMultiplier
                let column = travellerColumns[indexPath.item]
                cell.set(scorecard: Scorecard.current.scorecard!, traveller: values[row], sitting: sitting, rowType: .traveller, column: column) { (players) in
                    self.replaceNames(values: players)
                }
                return cell
            case .title:
                let cell = ScorecardTravellerCollectionCell.dequeue(collectionView, for: indexPath)
                let column = travellerColumns[indexPath.item]
                cell.setTitle(column: column, sitting: sitting)
                return cell
            }
        } else {
            fatalError()
        }
    }
    
    
    // MARK: - Tap handlers ============================================================================ -
    
    @objc private func cancelPressed(_ sender: Any) {
        self.endEditing(true)
        hide()
    }
    
    func cancelTap(_: Int) {
        cancelPressed(self)
    }
    
    // MARK: - Show / Hide ============================================================================ -
    
    public func show(from sourceView: UIView, boardNumber: Int, sitting: Seat) {
        self.frame = sourceView.frame
        self.boardNumber = boardNumber
        self.sitting = sitting
        setupValues()
        backgroundView.frame = sourceView.frame
        sourceView.addSubview(self)
        sourceView.bringSubviewToFront(self)
        contentView.frame = CGRect(x: sourceView.frame.midX - 500, y: sourceView.frame.midY - 350, width: 1000, height: 700)
        self.bringSubviewToFront(contentView)
        contentView.isHidden = false
        setNeedsLayout()
        layoutIfNeeded()
        layoutSubviews()
    }
    
    public func hide() {
        // self.contentView.isHidden = true
        removeFromSuperview()
    }
    
  // MARK: - View Setup ======================================================================== -
    
    private func setupColumns() {
        travellerColumns = [
            TravellerColumn(type: .players, heading: "Players", size: .flexible),
            TravellerColumn(type: .contract, heading: "Contract", size: .fixed([70])),
            TravellerColumn(type: .declarer, heading: "By", size: .fixed([60])),
            TravellerColumn(type: .lead, heading: "Lead", size: .fixed([50])),
            TravellerColumn(type: .made, heading: "Made", size: .fixed([50])),
            TravellerColumn(type: .points, heading: "Points", size: .fixed([60])),
            TravellerColumn(type: .score, heading: "Score", size: .fixed([60]))]
        
        setNeedsLayout()
    }
    
    private func setupValues() {
        if let travellers = Scorecard.current.travellers[boardNumber] {
        for (_, sectionTravellers) in travellers {
                for (_, traveller) in sectionTravellers {
                    values.append(traveller)
                }
            }
        }
        values.sort(by: {sort($0, $1)})
    }
    
    func sort(_ first: TravellerViewModel, _ second: TravellerViewModel) -> Bool {
        let sign: Float = sitting.northSouth ? 1 : -1
        if  (sign * first.nsScore) > (sign * second.nsScore) {
            return true
        } else if first.nsScore == second.nsScore && first.contract.level.rawValue > second.contract.level.rawValue {
            return true
        } else if first.nsScore == second.nsScore && first.isSelf {
            return true
        } else {
            return false
        }
    }
    
    func setupSizes(columns: inout [TravellerColumn]) {
        if !columns.isEmpty {
            var fixedWidth: CGFloat = 0
            var flexible: Int = 0
            for column in columns {
                switch column.size {
                case .fixed(let width):
                    fixedWidth += width.reduce(0,+)
                case .flexible:
                    flexible += 1
                }
            }
            
            var factor: CGFloat = 1.0
            if UIScreen.main.bounds.height < UIScreen.main.bounds.width {
                factor = UIScreen.main.bounds.width / UIScreen.main.bounds.height
            }
            
            let availableSize = valuesTableView.frame.width
            let fixedSize = fixedWidth * factor
            let flexibleSize = max(20, (availableSize - fixedSize) / CGFloat(flexible))
            
            var remainingWidth = availableSize
            for index in 0..<columns.count - 1 {
                switch columns[index].size {
                case .fixed(let width):
                    columns[index].width = width.map{ceil($0 * factor)}.reduce(0,+)
                case .flexible:
                    columns[index].width = flexibleSize
                }
                remainingWidth -= columns[index].width!
            }
            columns[columns.count - 1].width = max(20, remainingWidth)
        }
    }
    
    private func loadScorecardTravellerView() {
        
        valuesTableView = UITableView()

        // Background
        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let cancelSelector = #selector(ScorecardTravellerView.cancelPressed(_:))
        let backgroundTapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
        backgroundView.addGestureRecognizer(backgroundTapGesture)
        backgroundView.isUserInteractionEnabled = true
        
        // Content view
        addSubview(contentView)
        contentView.backgroundColor = UIColor(Palette.background.background)
        contentView.addShadow()

        // TableView and Title Container view
        contentView.addSubview(containerView, constant: paddingSize, anchored: .leading, .trailing, .top)

        // Add subviews
        titleView = ScorecardTravellerTitleView(self, frame: CGRect(origin: .zero, size: CGSize(width: frame.width, height: TravellerRowType.title.rowHeight)), tag: TravellerRowType.title.tagOffset)
        containerView.addSubview(titleView, anchored: .leading, .trailing, .top)
        Constraint.setHeight(control: titleView, height: TravellerRowType.title.rowHeight)
        
        // Table view
        loadTable(tableView: valuesTableView)
        Constraint.anchor(view: contentView, control: valuesTableView, to: titleView, toAttribute: .bottom, attributes: .top)
        
        // Close button
        contentView.addSubview(closeButton, anchored: .centerX)
        Constraint.setHeight(control: closeButton, height: buttonHeight)
        Constraint.setWidth(control: closeButton, width: buttonWidth)
        Constraint.anchor(view: contentView, control: closeButton, constant: buttonSpacing, attributes: .bottom)
        bottomSpacing = Constraint.anchor(view: contentView, control: closeButton, to: containerView, constant: buttonSpacing, toAttribute: .bottom, attributes: .top).first!
        closeButton.backgroundColor = UIColor(Palette.highlightButton.background)
        closeButton.textColor = UIColor(Palette.highlightButton.text)
        closeButton.textAlignment = .center
        closeButton.text = "Close"
        closeButton.font = replaceTitleFont
        let tapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
        closeButton.addGestureRecognizer(tapGesture)
        closeButton.isUserInteractionEnabled = true

        Constraint.addGridLine(containerView, size: 2, sides: .leading, .trailing, .top, .bottom)

        contentView.isHidden = true
    }
    
    func loadTable(tableView: UITableView) {
        containerView.addSubview(tableView, anchored: .leading, .trailing, .bottom)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor(Palette.background.background)
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 0
        tableView.bounces = false
         
        ScorecardTravellerSectionHeaderView.register(tableView)
        ScorecardTravellerTableCell.register(tableView)

    }
}

// MARK: - Table View Title Header ============================================================ -

fileprivate class ScorecardTravellerTitleView: UIView {
    fileprivate var collectionView: UICollectionView!
    private var layout: UICollectionViewFlowLayout!
    
    init<D: UICollectionViewDataSource & UICollectionViewDelegate>
    (_ dataSourceDelegate: D, frame: CGRect, tag: Int) {
        super.init(frame: frame)
        self.layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        self.addSubview(collectionView, anchored: .all)
        self.bringSubviewToFront(self.collectionView)
        ScorecardTravellerCollectionCell.register(collectionView)
        TableViewCellWithCollectionView.setCollectionViewDataSourceDelegate(dataSourceDelegate, collectionView: collectionView, tag: tag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
// MARK: - Table View Section Header ============================================================ -

fileprivate class ScorecardTravellerSectionHeaderView: TableViewSectionHeaderWithCollectionView {
    private static var identifier = "Traveller Section Header"
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        ScorecardTravellerCollectionCell.register(self.collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ tableView: UITableView, forTitle: Bool = false) {
        tableView.register(ScorecardTravellerSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: identifier)
    }
    
    public class func dequeue<D: UICollectionViewDataSource & UICollectionViewDelegate>(_ dataSourceDelegate : D, tableView: UITableView, tag: Int) -> ScorecardTravellerSectionHeaderView {
        return TableViewSectionHeaderWithCollectionView.dequeue(dataSourceDelegate, tableView: tableView, withIdentifier: ScorecardTravellerSectionHeaderView.identifier, tag: tag) as! ScorecardTravellerSectionHeaderView
    }
}


// MARK: - Board Table View Cell ================================================================ -

class ScorecardTravellerTableCell: TableViewCellWithCollectionView, UITextFieldDelegate {
    private static let cellIdentifier = "Traveller Table Cell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        ScorecardTravellerCollectionCell.register(self.collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ tableView: UITableView, forTitle: Bool = false) {
        tableView.register(ScorecardTravellerTableCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    public class func dequeue<D: UICollectionViewDataSource & UICollectionViewDelegate>(_ dataSourceDelegate : D, tableView: UITableView, for indexPath: IndexPath, tag: Int) -> ScorecardTravellerTableCell {
        var cell: ScorecardTravellerTableCell
        cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ScorecardTravellerTableCell
        cell.setCollectionViewDataSourceDelegate(dataSourceDelegate, tag: tag)
        return cell
    }
}

class ScorecardTravellerCollectionCell: UICollectionViewCell {
    private var label = UILabel()
    private static let identifier = "Traveller Collection Cell"
    
    private var rowType: TravellerRowType!
    private var column: TravellerColumn!
    private var scorecard: ScorecardViewModel!
    private var traveller: TravellerViewModel!
    private var sitting: Seat!
    private var tapAction: (([String]) ->())?

    override init(frame: CGRect) {
        super.init(frame: frame)
        scorecard = Scorecard.current.scorecard
        
        self.backgroundColor = UIColor(Palette.background.background)
        
        addSubview(label, leading: 8, trailing: 8, top: 0, bottom: 0)
        label.textAlignment = .center
        label.minimumScaleFactor = 0.3
        label.adjustsFontSizeToFitWidth = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardTravellerCollectionCell.tapped(_:)))
        label.addGestureRecognizer(tapGesture)
        label.isUserInteractionEnabled = true
        
        Constraint.addGridLine(self, size: 1, sides: .leading, .trailing, .top, .bottom)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ collectionView: UICollectionView) {
        collectionView.register(ScorecardTravellerCollectionCell.self, forCellWithReuseIdentifier: identifier)
    }

    public class func dequeue(_ collectionView: UICollectionView, for indexPath: IndexPath) -> ScorecardTravellerCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ScorecardTravellerCollectionCell
        cell.prepareForReuse()
        return cell
    }
    
    override func prepareForReuse() {
        traveller = nil
        column = nil
        rowType = nil
        
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor(Palette.background.text)
        label.text = ""
        label.font = smallCellFont
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 1
    }
    
    func setTitle(column: TravellerColumn, sitting: Seat) {
        self.column = column
        label.backgroundColor = UIColor(Palette.gridTitle.background)
        label.textColor = UIColor(Palette.gridTitle.text)
        label.font = smallCellFont.bold
        switch column.type {
        case .score:
            label.text = (sitting.northSouth ? "NS" : "EW") + "\n" + scorecard.type.boardScoreType.string
            label.numberOfLines = 2
        case .points:
            label.text = (sitting.northSouth ? "NS" : "EW")
        case .players:
            label.numberOfLines = 2
            label.text = (sitting.northSouth ? "North & South\nEast & West" : "East & West\nNorth & South")
        default:
            label.text = column.heading
        }
    }
 
    func set(scorecard: ScorecardViewModel, traveller: TravellerViewModel, sitting: Seat, rowType: TravellerRowType, column: TravellerColumn, tapAction: (([String])->())? = nil) {
        self.scorecard = scorecard
        self.traveller = traveller
        self.tapAction = tapAction
        self.rowType = rowType
        self.column = column
        
        label.tag = column.type.rawValue
        
        let color = (traveller.isSelf ? Palette.alternate : Palette.background)
        backgroundColor = UIColor(color.background)
        label.textColor = UIColor(color.text)
        
        switch column.type {
        case .players:
            var names: [Seat:NSAttributedString] = [:]
            for seat in Seat.validCases {
                let bboName = traveller.ranking(seat: seat)?.players[seat]
                let name = MasterData.shared.realName(bboName: bboName) ?? "Unknown"
                let color = (bboName == name ? UIColor(Palette.background.themeText) : nil)
                names[seat] = NSAttributedString(name, pickerColor: color)
            }
            let nsNames = names[.north]! + " & " + names[.south]!
            let ewNames = names[.east]! + " & " + names[.west]!
            label.attributedText = (sitting.northSouth ? (nsNames + "\n" + ewNames) : (ewNames + "\n" + nsNames))
            label.textAlignment = .left
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 2
            label.isUserInteractionEnabled = true
        case .contract:
            label.text = traveller.contract.string
        case .declarer:
            label.text = traveller.declarer.short
        case .lead:
            label.text = traveller.lead
        case .made:
            label.text = (traveller.made == 0 ? "=" : (
                          traveller.made > 0 ? "+\(traveller.made)" : (
                          "\(traveller.made)")))
        case .points:
            let sign = sitting.northSouth ? 1 : -1
            label.text = "\(sign * Scorecard.points(contract: traveller.contract, vulnerability: Vulnerability(board: traveller.board), declarer: traveller.declarer, made: traveller.made, seat: .north))"
        case .score:
            let score = (sitting.northSouth ? traveller.nsScore : scorecard.type.invertScore(score: traveller.nsScore))
            label.text = score.toString(places: scorecard.type.matchPlaces)
        case .section:
            label.text = "\(traveller.section)"
        default:
            break
        }
    }
    
    @objc private func tapped(_ sender: Any) {
        var players: [String] = []
        Seat.validCases.forEach{ (seat) in
            let player = traveller.ranking(seat: seat)?.players[seat] ?? ""
            if player != "" && !players.contains(where: {$0 == player}) {
                players.append(player)
            }
        }
        tapAction?(players)
    }
}
