//
//  Scorecard Ranking View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 25/03/2022.
//

import UIKit
import CoreMedia

enum RankingColumnType: Int, Codable {
    case table = 0
    case section = 1
    case number = 2
    case players = 3
    case ranking = 4
    case score = 5
    case points = 6
    case nsXImps = 7
    case ewXImps = 8
    case rounds = 9
    case way = 10
    
    var string: String {
        return "\(self)"
    }
}

struct RankingColumn: Codable, Equatable {
    var type: RankingColumnType
    var heading: String?
    var size: ColumnSize
    var width: CGFloat?
    
    static func == (lhs: RankingColumn, rhs: RankingColumn) -> Bool {
        return lhs.type == rhs.type && lhs.heading == rhs.heading && lhs.size == rhs.size && lhs.width == rhs.width
    }
}

enum RankingRowType: Int, CaseIterable {
    case heading = 1
    case ranking = 2
    case title = 3
    case rounds = 4
    
    func rowHeight(scorecard: ScorecardViewModel) -> CGFloat {
        switch self {
        case .heading:
            return 50
        case .ranking, .rounds:
            return (scorecard.type.players == 4 ? 80 : 50)
        case .title:
            return 40
        }
    }
    
    var tagOffset: Int {
        return RankingRowType.offset(self.rawValue)
    }
    
    private static func offset(_ rawValue: Int) -> Int {
        return rawValue * tagMultiplier
    }
}

class ScorecardRankingView: UIView, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
       
    private var backgroundView = UIView()
    private var contentView = UIView()
    private var containerView = UIView()
    private var instructionLabel = UILabel()
    private var closeButton = UILabel()
    private var titleView: ScorecardRankingTitleView!
    private var valuesTableView: UITableView!
    private var bottomSpacing: NSLayoutConstraint!
    private var buttonSpacing: CGFloat = 25
    private var buttonHeight: CGFloat = 50
    private var buttonWidth: CGFloat = 160
    private var paddingSize: CGFloat = 20
    private var rankingColumns: [RankingColumn] = []
    private var headingColumns: [RankingColumn] = []
    private var rankings: [[RankingViewModel]] = []
    private var multiTables = false
    private var multiSections = false
    private var multiWays = false
    private var totalRankings: Int = 0
    private var sourceView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        loadScorecardRankingView()
        setupValues()
        
        // Handle rotations
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [weak self] (notification) in
            self?.layoutSubviews()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setFrames()
        layoutIfNeeded()
        setupColumns()
        setupSizes(columns: &rankingColumns)
        setupSizes(columns: &headingColumns)
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
        if Scorecard.current.scorecard?.importSource == .bbo {
            let editValues = MasterData.shared.getBboNames(values: values)
            let bboNameReplaceView = BBONameReplaceView(frame: CGRect())
            bboNameReplaceView.show(from: self, values: editValues) {
                self.valuesTableView.reloadData()
            }
        }
    }

    // MARK: - CollectionView Delegates ================================================================ -
    
    func numberOfSections(in tableView: UITableView) -> Int {
        rankings.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rankings[section].count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if multiTables || multiSections || multiWays {
            return RankingRowType.heading.rowHeight(scorecard: Scorecard.current.scorecard!)
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if multiTables || multiSections || multiWays {
            let view = ScorecardRankingSectionHeaderView.dequeue(self, tableView: tableView, tag: RankingRowType.heading.tagOffset + section)
            return view
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return RankingRowType.ranking.rowHeight(scorecard: Scorecard.current.scorecard!)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return ScorecardRankingTableCell.dequeue(self, tableView: tableView, for: indexPath, tag: RankingRowType.ranking.tagOffset + (indexPath.section * totalRankings) + indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    // MARK: - CollectionView Overrides ================================================================ -
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var columns = 0
        if let type = RankingRowType(rawValue: collectionView.tag / tagMultiplier) {
            switch type {
            case .ranking, .title:
                columns = rankingColumns.count
            case .heading:
                columns = headingColumns.count
            case .rounds:
                columns = Scorecard.current.scorecard?.tables ?? 0
            }
        }
        return columns
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var width: CGFloat = 0
        var height: CGFloat = 0
        if let type = RankingRowType(rawValue: collectionView.tag / tagMultiplier) {
            switch type {
            case .ranking, .title:
                width = rankingColumns[indexPath.item].width ?? 0
            case .heading:
                width = headingColumns[indexPath.item].width ?? 0
            case .rounds:
                if let roundsColumn = rankingColumns.first(where: {$0.type == .rounds}) {
                    width = (roundsColumn.width ?? 0) / CGFloat(min(8, Scorecard.current.scorecard?.tables ?? 1))
                }
            }
            height = type.rowHeight(scorecard: Scorecard.current.scorecard!)
        } else {
            fatalError()
        }
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let type = RankingRowType(rawValue: collectionView.tag / tagMultiplier) {
            switch type {
            case .ranking:
                let cell = ScorecardRankingCollectionCell.dequeue(collectionView, for: indexPath)
                let index = collectionView.tag % tagMultiplier
                let grouping = index / totalRankings
                let item = index % totalRankings
                let ranking = rankings[grouping][item]
                let column = rankingColumns[indexPath.item]
                cell.set(from: self, scorecard: Scorecard.current.scorecard!, ranking: ranking, roundsTag: RankingRowType.rounds.tagOffset + (collectionView.tag % tagMultiplier), rowType: .ranking, column: column) { (players) in
                    self.replaceNames(values: players)
                }
                return cell
            case .title:
                let cell = ScorecardRankingCollectionCell.dequeue(collectionView, for: indexPath)
                let column = rankingColumns[indexPath.item]
                cell.setTitle(column: column)
                return cell
            case .heading:
                let cell = ScorecardRankingCollectionCell.dequeue(collectionView, for: indexPath)
                let grouping = collectionView.tag % tagMultiplier
                let ranking = rankings[grouping][0]
                let column = headingColumns[indexPath.item]
                cell.set(from: self, scorecard: Scorecard.current.scorecard!, ranking: ranking, rowType: .heading, column: column)
                return cell
            case .rounds:
                let cell = ScorecardRankingRoundCollectionCell.dequeue(collectionView, for: indexPath)
                let index = collectionView.tag % tagMultiplier
                let grouping = index / totalRankings
                let item = index % totalRankings
                let ranking = rankings[grouping][item]
                cell.set(ranking: ranking, tableNumber: indexPath.row + 1, places: Scorecard.current.scorecard?.type.tablePlaces ?? 2)
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
    
    public func show(from sourceView: UIView) {
        self.sourceView = sourceView
        self.frame = sourceView.frame
        sourceView.addSubview(self)
        sourceView.bringSubviewToFront(self)
        self.bringSubviewToFront(contentView)
        setFrames()
        setNeedsLayout()
        layoutIfNeeded()
        layoutSubviews()
        contentView.isHidden = false
    }
    
    private func setFrames() {
        if backgroundView.frame != sourceView.frame {
            backgroundView.frame = sourceView.frame
            let width = sourceView.frame.width * 0.90
            let padding = bannerHeight + safeAreaInsets.top + safeAreaInsets.bottom
            let height = (sourceView.frame.height - padding) * 0.95
            contentView.frame = CGRect(x: sourceView.frame.midX - (width / 2), y: ((bannerHeight + safeAreaInsets.top) / 2) + sourceView.frame.midY - (height / 2), width: width, height: height)
        }
    }
    
    public func hide() {
        // self.contentView.isHidden = true
        removeFromSuperview()
    }
    
  // MARK: - View Setup ======================================================================== -
    
    private func setupColumns() {
        let sectionRankings = Scorecard.current.rankingList
        rankingColumns = [
            RankingColumn(type: .ranking, heading: "Rank", size: .fixed([50])),
            RankingColumn(type: .players, heading: "Names", size: .flexible)]
           
        if (Scorecard.current.scorecard?.entry ?? 0) > 2 && isLandscape {
            rankingColumns += [
                RankingColumn(type: .rounds, heading: "Rounds", size: .fixed([CGFloat(min(8, Scorecard.current.scorecard?.tables ?? 1) * 25) + 8]))]
        }
        
        rankingColumns += [
            RankingColumn(type: .score, heading: "Score", size: .fixed([60]))]
        
        if sectionRankings.first(where: {$0.points != 0}) != nil {
            rankingColumns += [
                RankingColumn(type: .points, heading: "Points", size: .fixed([60]))
            ]
        }
        
        if sectionRankings.first(where: {$0.xImps[.ns] ?? 0 != 0}) != nil && (Scorecard.current.scorecard?.entry ?? 0) > 2 {
            rankingColumns += [
                RankingColumn(type: .nsXImps, heading: "NS XImps", size: .fixed([60])),
                RankingColumn(type: .ewXImps, heading: "EW XImps", size: .fixed([60]))
            ]
        }
        
        headingColumns = []
        if multiTables {
            headingColumns.append(RankingColumn(type: .table, heading: nil, size: .fixed([200])))
        }
        if multiSections {
            headingColumns.append(RankingColumn(type: .section, heading: nil, size: .fixed([200])))
        }
        if multiWays {
            headingColumns.append(RankingColumn(type: .way, heading: nil, size: .fixed([200])))
        }
    }
    
    private func setupValues() {
        rankings = []
        totalRankings = 0
        
        Scorecard.current.scanRankings() { (ranking, newGrouping, _) in
            if newGrouping {
                rankings.append([])
            }
            rankings[rankings.count - 1].append(ranking)
            totalRankings += 1
        }
        multiTables = Set(rankings.map{$0.first!.table}).count > 1
        multiSections = Set(rankings.map{$0.first!.section}).count > 1
        multiWays = Set(rankings.map{$0.first!.way}).count > 1
    }
    
    func sort(_ first: RankingViewModel, _ second: RankingViewModel) -> Bool {
        if first.ranking < second.ranking {
            return true
        } else if first.ranking == second.ranking && first.number < second.number {
            return true
        } else {
            return false
        }
    }
    
    func setupSizes(columns: inout [RankingColumn]) {
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
            if isLandscape {
                factor = sourceView.frame.width / sourceView.frame.height
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
    
    private func loadScorecardRankingView() {
        
        valuesTableView = UITableView()

        // Background
        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let cancelSelector = #selector(ScorecardRankingView.cancelPressed(_:))
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
        titleView = ScorecardRankingTitleView(self, frame: CGRect(origin: .zero, size: CGSize(width: frame.width, height: RankingRowType.title.rowHeight(scorecard: Scorecard.current.scorecard!))), tag: RankingRowType.title.tagOffset)
        containerView.addSubview(titleView, anchored: .leading, .trailing, .top)
        Constraint.setHeight(control: titleView, height: RankingRowType.title.rowHeight(scorecard: Scorecard.current.scorecard!))
        
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
        closeButton.font = replaceTitleFont.bold
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
         
        ScorecardRankingSectionHeaderView.register(tableView)
        ScorecardRankingTableCell.register(tableView)

    }
}

// MARK: - Table View Title Header ============================================================ -

fileprivate class ScorecardRankingTitleView: UIView {
    fileprivate var collectionView: UICollectionView!
    private var layout: UICollectionViewFlowLayout!
    
    init<D: UICollectionViewDataSource & UICollectionViewDelegate>
    (_ dataSourceDelegate: D, frame: CGRect, tag: Int) {
        super.init(frame: frame)
        self.layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        self.addSubview(collectionView, anchored: .all)
        self.bringSubviewToFront(self.collectionView)
        ScorecardRankingCollectionCell.register(collectionView)
        TableViewCellWithCollectionView.setCollectionViewDataSourceDelegate(dataSourceDelegate, collectionView: collectionView, tag: tag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
// MARK: - Table View Section Header ============================================================ -

fileprivate class ScorecardRankingSectionHeaderView: TableViewSectionHeaderWithCollectionView {
    private static var identifier = "Ranking Section Header"
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        ScorecardRankingCollectionCell.register(self.collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ tableView: UITableView, forTitle: Bool = false) {
        tableView.register(ScorecardRankingSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: identifier)
    }
    
    public class func dequeue<D: UICollectionViewDataSource & UICollectionViewDelegate>(_ dataSourceDelegate : D, tableView: UITableView, tag: Int) -> ScorecardRankingSectionHeaderView {
        return TableViewSectionHeaderWithCollectionView.dequeue(dataSourceDelegate, tableView: tableView, withIdentifier: ScorecardRankingSectionHeaderView.identifier, tag: tag) as! ScorecardRankingSectionHeaderView
    }
}


// MARK: - Board Table View Cell ================================================================ -

class ScorecardRankingTableCell: TableViewCellWithCollectionView, UITextFieldDelegate {
    private static let cellIdentifier = "Ranking Table Cell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        ScorecardRankingCollectionCell.register(self.collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ tableView: UITableView, forTitle: Bool = false) {
        tableView.register(ScorecardRankingTableCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    public class func dequeue<D: UICollectionViewDataSource & UICollectionViewDelegate>(_ dataSourceDelegate : D, tableView: UITableView, for indexPath: IndexPath, tag: Int) -> ScorecardRankingTableCell {
        var cell: ScorecardRankingTableCell
        cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ScorecardRankingTableCell
        cell.setCollectionViewDataSourceDelegate(dataSourceDelegate, tag: tag)
        return cell
    }
}

class ScorecardRankingCollectionCell: UICollectionViewCell {
    private var label = UILabel()
    private static let identifier = "Ranking Collection Cell"
    
    private var rowType: RankingRowType!
    private var column: RankingColumn!
    private var scorecard: ScorecardViewModel!
    private var ranking: RankingViewModel!
    private var tapAction: (([String]) ->())?
    private var roundCollectionView: UICollectionView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(Palette.background.background)
        
        addSubview(label, leading: 8, trailing: 8, top: 0, bottom: 0)
        label.textAlignment = .center
        label.minimumScaleFactor = 0.3
        label.adjustsFontSizeToFitWidth = true
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        roundCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        roundCollectionView.showsHorizontalScrollIndicator = false
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        addSubview(roundCollectionView, anchored: .all)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardRankingCollectionCell.tapped(_:)))
        label.addGestureRecognizer(tapGesture)
        label.isUserInteractionEnabled = true
        
        Constraint.addGridLine(self, size: 1, sides: .leading, .trailing, .top, .bottom)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ collectionView: UICollectionView) {
        collectionView.register(ScorecardRankingCollectionCell.self, forCellWithReuseIdentifier: identifier)
    }

    public class func dequeue(_ collectionView: UICollectionView, for indexPath: IndexPath) -> ScorecardRankingCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ScorecardRankingCollectionCell
        cell.prepareForReuse()
        return cell
    }
    
    override func prepareForReuse() {
        ranking = nil
        column = nil
        rowType = nil
        
        self.backgroundColor = UIColor(Palette.background.background)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor(Palette.background.text)
        label.text = ""
        label.font = smallCellFont
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 1
        label.isHidden = false
        
        ScorecardRankingRoundCollectionCell.register(roundCollectionView)
        roundCollectionView.isHidden = true
    }
    
    func setTitle(column: RankingColumn) {
        self.column = column
        label.backgroundColor = UIColor(Palette.gridTitle.background)
        label.textColor = UIColor(Palette.gridTitle.text)
        label.font = titleFont.bold
        switch column.type {
        case .number:
            switch Scorecard.current.scorecard!.type.players {
            case 2:
                label.text = "Pair"
            case 4:
                label.text = "Team"
            default:
                label.text = "Number"
            }
        default:
            label.text = column.heading
        }
    }
 
    func set(from sourceView: UICollectionViewDataSource & UICollectionViewDelegate, scorecard: ScorecardViewModel, ranking: RankingViewModel, roundsTag: Int = 0, rowType: RankingRowType, column: RankingColumn, tapAction: (([String])->())? = nil) {
        self.scorecard = scorecard
        self.ranking = ranking
        self.tapAction = tapAction
        self.rowType = rowType
        self.column = column
        
        label.tag = column.type.rawValue
        
        let color = (ranking.isSelf && rowType == .ranking ? Palette.alternate : Palette.background)
        backgroundColor = UIColor(color.background)
        label.textColor = UIColor(color.text)
        label.font = smallCellFont
        
        switch column.type {
        case .ranking:
            label.text = "\(ranking.ranking)\(ranking.tie ? " =" : "")"
        case .number:
            label.text = "\(ranking.number)"
        case .players:
            var text = NSAttributedString(string: "")
            for (index, player) in getPlayers().enumerated() {
                if index > 0 {
                    if index % 2 == 0 {
                        text = text + "\n"
                    } else {
                        text = text + " & "
                    }
                }
                let name = (MasterData.shared.realName(bboName: player) ?? player)
                if name == player {
                    text = text + NSAttributedString(name, pickerColor: UIColor(Palette.background.themeText))
                } else {
                    text = text + name
                }
            }
            label.attributedText = text
            label.textAlignment = .left
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = max(10, (Scorecard.current.scorecard?.type.players ?? 2) / 2)
            label.isUserInteractionEnabled = true
        case .rounds:
            label.isHidden = true
            roundCollectionView.isHidden = false
            roundCollectionView.tag = roundsTag
            roundCollectionView.delegate = sourceView
            roundCollectionView.dataSource = sourceView
            roundCollectionView.isUserInteractionEnabled = true
            roundCollectionView.backgroundColor = UIColor(color.background)
            roundCollectionView.reloadData()
        case .score:
            label.text = ranking.score.toString(places: scorecard.type.matchPlaces, exact: true)
            label.textAlignment = .right
        case .nsXImps:
            let nsXImps = ranking.xImps[.ns]
            label.text = nsXImps == 0 ? "" : nsXImps?.toString(places: 2, exact: true) ?? ""
            label.textAlignment = .right
        case .ewXImps:
            let ewXImps = ranking.xImps[.ew]
            label.text = ewXImps == 0 ? "" : ewXImps?.toString(places: 2, exact: true) ?? ""
            label.textAlignment = .right
        case .points:
            label.text = (ranking.points == 0 ? "" : ranking.points.toString(places: 2, exact: true))
            label.textAlignment = .right
        case .table:
            label.text = "     Round \(ranking.table)"
            label.textAlignment = .left
        case .section:
            label.text = "     Section \(ranking.section)"
            label.textAlignment = .left
        case .way:
            label.text = "     \(ranking.way.string)"
            label.textAlignment = .left
        }
    }
    
    private func getPlayers() -> [String] {
        var players: [String] = []
        for seat in Seat.validCases {
            if let player = ranking.players[seat] {
                if players.first(where: {$0 == player}) == nil {
                    players.append(player)
                }
            }
        }
        return players
    }
    
    @objc private func tapped(_ sender: Any) {
        tapAction?(getPlayers())
    }
}

class ScorecardRankingRoundCollectionCell: UICollectionViewCell {
    private var label = UILabel()
    private static let identifier = "Ranking Round Collection Cell"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        addSubview(label, leading: 4, trailing: 4, top: 0, bottom: 0)
        label.textAlignment = .center
        label.font = smallCellFont
        label.minimumScaleFactor = 0.3
        label.adjustsFontSizeToFitWidth = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ collectionView: UICollectionView) {
        collectionView.register(ScorecardRankingRoundCollectionCell.self, forCellWithReuseIdentifier: identifier)
    }

    public class func dequeue(_ collectionView: UICollectionView, for indexPath: IndexPath) -> ScorecardRankingRoundCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ScorecardRankingRoundCollectionCell
        cell.prepareForReuse()
        return cell
    }
    
    override func prepareForReuse() {
        label.text = ""
        label.textAlignment = .center
    }
    
     
    func set(ranking: RankingViewModel, tableNumber: Int, places: Int) {
        if let table = Scorecard.current.tables[tableNumber] {
            var seats: [Seat]
            let players = Scorecard.current.scorecard?.type.players ?? 0
            if players == 1 { seats = Seat.validCases }
            else if players == 2 { seats = [.north, .east] }
            else { seats = [.north] }
            let tableScore = table.score(ranking: ranking, seats: seats)
            label.text = tableScore.toString(places: 0)
            label.textAlignment = .right
        }
    }
}
