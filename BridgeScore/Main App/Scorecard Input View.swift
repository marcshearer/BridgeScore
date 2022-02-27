//
//  Scorecard Input View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 11/02/2022.
//

import UIKit
import SwiftUI
import Combine

struct ScorecardColumn: Codable, Equatable {
    var type: ColumnType
    var heading: String
    var size: ColumnSize
    var width: CGFloat?
    
    static func == (lhs: ScorecardColumn, rhs: ScorecardColumn) -> Bool {
        return lhs.type == rhs.type && lhs.heading == rhs.heading && lhs.size == rhs.size && lhs.width == rhs.width
    }
}

enum RowType: Int {
    case table = 1
    case board = 2
    case boardTitle = 3
    
    var tagOffset: Int {
        return self.rawValue * tagMultiplier
    }
}

struct ScorecardInputView: View {
    @Environment(\.undoManager) private var undoManager
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @ObservedObject var scorecard: ScorecardViewModel
    @State var undoPressed: Bool = false
    @State var redoPressed: Bool = false
    @State var canUndo: Bool = false
    @State var canRedo: Bool = false
    @State var linkToDetails: Bool = false
    @State var refresh = false
    
    var body: some View {
        StandardView {
            VStack(spacing: 0) {
                
                // Just to trigger view refresh
                if refresh { EmptyView() }
    
                // Banner
                Banner(title: $scorecard.desc, back: true, backAction: backAction, leftTitle: true, optionMode: .buttons, options: [
                        BannerOption(image: AnyView(Image(systemName: "arrow.uturn.backward")), likeBack: true, isEnabled: $canUndo, action: { undoDrawing() }),
                        BannerOption(image: AnyView(Image(systemName: "arrow.uturn.forward")), likeBack: true, isEnabled: $canRedo, action: { redoDrawing() }),
                        BannerOption(image: AnyView(Image(systemName: "note.text")), likeBack: true, action: { linkToDetails = true })])
                GeometryReader { geometry in
                    ScorecardInputUIViewWrapper(scorecard: scorecard, frame: geometry.frame(in: .local), undoPressed: $undoPressed, redoPressed: $redoPressed, canUndo: $canUndo, canRedo: $canRedo, refresh: $refresh)
                    .ignoresSafeArea(edges: .all)
                }
            }
            .onSwipe { (direction) in
                if direction == .right {
                    if backAction() {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onChange(of: undoPressed) { newValue in undoPressed = false }
            .onChange(of: redoPressed) { newValue in redoPressed = false }
            .onChange(of: refresh) { newValue in refresh = false }
        }
        .sheet(isPresented: $linkToDetails, onDismiss: {
            refresh = true
        }) {
            ScorecardDetailView(scorecard: scorecard, title: "Details")
        }
    }
    
    func backAction() -> Bool {
        Scorecard.current.interimSave()
        return true
    }
    
    func undoDrawing() {
        self.undoPressed = true
        self.canUndo = false
    }
    
    func redoDrawing() {
        self.redoPressed = true
        self.canRedo = false
    }
}

protocol ScorecardInputUIViewDelegate {
    func undo(isAvailable: Bool)
    func redo(isAvailable: Bool)
}

struct ScorecardInputUIViewWrapper: UIViewRepresentable {
    @ObservedObject var  scorecard: ScorecardViewModel
    @State var frame: CGRect
    @Binding var undoPressed: Bool
    @Binding var redoPressed: Bool
    @Binding var canUndo: Bool
    @Binding var canRedo: Bool
    @Binding var refresh: Bool

    func makeUIView(context: Context) -> ScorecardInputUIView {
        
        let view = ScorecardInputUIView(frame: frame, scorecard: scorecard)
        view.delegate = context.coordinator
        
        return view
    }

    func updateUIView(_ uiView: ScorecardInputUIView, context: Context) {
        
        if undoPressed {
            uiView.undo()
        }
        
        if redoPressed {
            uiView.redo()
        }
        
        if refresh {
            uiView.refresh()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator($undoPressed, $redoPressed, $canUndo, $canRedo, $refresh)
    }
    
    class Coordinator: NSObject, ScorecardInputUIViewDelegate {
        
        @Binding var undoPressed: Bool
        @Binding var redoPressed: Bool
        @Binding var canUndo: Bool
        @Binding var canRedo: Bool
        @Binding var refresh: Bool
        
        init(_ undoPressed: Binding<Bool>, _ redoPressed: Binding<Bool>, _ canUndo: Binding<Bool>, _ canRedo: Binding<Bool>, _ refresh: Binding<Bool>) {
            _undoPressed = undoPressed
            _redoPressed = redoPressed
            _refresh = refresh
            _canUndo = canUndo
            _canRedo = canRedo
        }
  
        func undo(isAvailable: Bool) {
            Utility.executeAfter(delay: 0.1) {
                self.canUndo = isAvailable
            }
        }
        
        func redo(isAvailable: Bool) {
            Utility.executeAfter(delay: 0.1) {
                self.canRedo = isAvailable
            }
        }
    }
}

protocol ScorecardDelegate {
    func scorecardChanged(type: RowType, itemNumber: Int, column: ScorecardColumn?)
    func scorecardContractEntry(board: BoardViewModel, table: TableViewModel)
    func scorecardScrollPickerPopup(values: [ScrollPickerEntry], maxValues: Int, selected: Int, frame: CGRect, in container: UIView, topPadding: CGFloat, bottomPadding: CGFloat, completion: @escaping (Int)->())
    func scorecardGetDeclarers(tableNumber: Int) -> [Seat]
    func scorecardUpdateDeclarers(tableNumber: Int, to: [Seat]?)
    func scorecardEndEditing(_ force: Bool)
}

extension ScorecardDelegate {
    func scorecardChanged(type: RowType, itemNumber: Int) {
        scorecardChanged(type: type, itemNumber: itemNumber, column: nil)
    }
    func scorecardScrollPickerPopup(values: [String], maxValues: Int, selected: Int, frame: CGRect, in container: UIView, topPadding: CGFloat, bottomPadding: CGFloat, completion: @escaping (Int)->()) {
        scorecardScrollPickerPopup(values: values.map{ScrollPickerEntry(title: $0, caption: nil)}, maxValues: maxValues, selected: selected, frame: frame, in: container, topPadding: topPadding, bottomPadding: bottomPadding, completion: completion)
    }
}

fileprivate let titleRowHeight: CGFloat = 40
fileprivate let boardRowHeight: CGFloat = 90
fileprivate let tableRowHeight: CGFloat = 80

class ScorecardInputUIView : UIView, ScorecardDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
        
    private var scorecard: ScorecardViewModel
    private var titleView: UIView!
    private var mainTableView = UITableView(frame: CGRect(), style: .plain)
    private var contractEntryView: ContractEntryView
    private var scrollPickerPopupView: ScrollPickerPopupView
    public var delegate: ScorecardInputUIViewDelegate?
    private var subscription: AnyCancellable?
    private var lastKeyboardScrollOffset: CGFloat = 0
    private var isKeyboardOffset = false
    private var bottomConstraint: NSLayoutConstraint!
    private var forceReload = true
    
    var boardColumns = [
        ScorecardColumn(type: .board, heading: "Board", size: .fixed(70)),
        ScorecardColumn(type: .contract, heading: "Contract", size: .fixed(95)),
        ScorecardColumn(type: .declarer, heading: "By", size: .fixed(70)),
        ScorecardColumn(type: .made, heading: "Made", size: .fixed(60)),
        ScorecardColumn(type: .score, heading: "Score", size: .fixed(80)),
        ScorecardColumn(type: .responsible, heading: "Resp", size: .fixed(65)),
        ScorecardColumn(type: .comment, heading: "Comment", size: .flexible)
    ]
    
    var tableColumns = [
        ScorecardColumn(type: .table, heading: "", size: .fixed(165)),
        ScorecardColumn(type: .sitting, heading: "Sitting", size: .fixed(130)),
        ScorecardColumn(type: .tableScore, heading: "Score", size: .fixed(145)),
        ScorecardColumn(type: .versus, heading: "Versus", size: .flexible)
    ]
    
    init(frame: CGRect, scorecard: ScorecardViewModel) {
        self.scorecard = scorecard
        self.contractEntryView = ContractEntryView(frame: CGRect())
        self.scrollPickerPopupView = ScrollPickerPopupView(frame: CGRect())

        super.init(frame: frame)
                    
        // Add subviews
        titleView = ScorecardInputTableTitleView(self, frame: CGRect(origin: .zero, size: CGSize(width: frame.width, height: titleRowHeight)), tag: RowType.boardTitle.tagOffset)
        self.addSubview(titleView, anchored: .leading, .trailing, .top)
        Constraint.setHeight(control: titleView, height: titleRowHeight)
        
        self.addSubview(self.mainTableView, anchored: .leading, .trailing)
        Constraint.anchor(view: self, control: titleView, to: mainTableView, toAttribute: .top, attributes: .bottom)
        bottomConstraint = Constraint.anchor(view: self, control: mainTableView, attributes: .bottom).first!
                                
        // Setup main table view
        self.mainTableView.delegate = self
        self.mainTableView.dataSource = self
        self.mainTableView.tag = RowType.board.rawValue
        self.mainTableView.sectionHeaderTopPadding = 0
        self.mainTableView.bounces = false
        ScorecardInputTableSectionHeaderView.register(mainTableView)
        ScorecardInputBoardTableCell.register(mainTableView)
        
        subscription = Publishers.keyboardHeight.sink { (keyboardHeight) in
            self.keyboardMoved(keyboardHeight)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let oldBoardColumns = boardColumns
        let oldTableColumns = tableColumns
        setupSizes(columns: &boardColumns)
        setupSizes(columns: &tableColumns)
        if boardColumns != oldBoardColumns || tableColumns != oldTableColumns || forceReload {
            mainTableView.reloadData()
            forceReload = false
        }
    }

    public func undo() {
        undoManager?.undo()
    }
    
    public func redo() {
        undoManager?.redo()
    }
    
    public func refresh() {
        forceReload = true
        setNeedsLayout()
    }
    
    // MARK: - Scorecard delegates
    
    internal func scorecardChanged(type: RowType, itemNumber: Int, column: ScorecardColumn?) {
        delegate?.undo(isAvailable: undoManager?.canUndo ?? false)
        delegate?.redo(isAvailable: undoManager?.canRedo ?? false)
        
        switch type {
        case .table:
            if let column = column {
                let section = itemNumber - 1
                switch column.type {
                case .sitting:
                        // Sitting changed - update declarer
                    let boards = scorecard.boardsTable
                    for index in 1...boards {
                        let row = index - 1
                        self.updateBoardCell(section: section, row: row, columnType: .declarer)
                    }
                default:
                    break
                }
            }
            Scorecard.current.interimSave(entity: .table, itemNumber: itemNumber)
            
        case .board:
            if let column = column {
                let section = (itemNumber - 1) / scorecard.boardsTable
                let row = (itemNumber - 1) % scorecard.boardsTable
                switch column.type {
                case .contract:
                        // Contract changed - update made picker
                    self.updateBoardCell(section: section, row: row, columnType: .made)
                case .score:
                        // Score changed - update table score
                    self.updateScore(section: section)
                default:
                    break
                }
            }
            Scorecard.current.interimSave(entity: .board, itemNumber: itemNumber)
            
        default:
            break
        }
    }
    
    private func updateBoardCell(section: Int, row: Int, columnType: ColumnType) {
        if let row = self.mainTableView.cellForRow(at: IndexPath(row: row, section: section)) as? ScorecardInputBoardTableCell {
            if let columnNumber = self.boardColumns.firstIndex(where: {$0.type == columnType}) {
                row.collectionView.reloadItems(at: [IndexPath(item: columnNumber, section: 0)])
            }
        }
    }
    
    private func updateScore(section: Int){
        if Scorecard.updateTableScore(scorecard: scorecard, tableNumber: section + 1) {
            updateTableCell(section: section, columnType: .tableScore)
            Scorecard.current.interimSave(entity: .table, itemNumber: section + 1)
        }
        if Scorecard.updateTotalScore(scorecard: scorecard) {
            if let score = Scorecard.current.scorecard?.score {
                scorecard.score = score
            }
        }
    }
    
    private func updateTableCell(section: Int, columnType: ColumnType) {
        if let headerView = mainTableView.headerView(forSection: section) as? ScorecardInputTableSectionHeaderView {
            if let columnNumber = tableColumns.firstIndex(where: {$0.type == columnType}) {
                headerView.collectionView.reloadItems(at: [IndexPath(item: columnNumber, section: 0)])
            }
        }
    }
    
    func scorecardContractEntry(board: BoardViewModel, table: TableViewModel) {
        let section = (board.board - 1) / self.scorecard.boardsTable
        let row = (board.board - 1) % self.scorecard.boardsTable
        let showDeclarer = (table.sitting != .unknown)
        contractEntryView.show(from: self, contract: board.contract, declarer: (showDeclarer ? board.declarer : nil)) { (contract, declarer) in

            if let tableCell = self.mainTableView.cellForRow(at: IndexPath(row: row, section: section)) as? ScorecardInputBoardTableCell {
                if contract != board.contract {
                    // Update contract
                    if let item = self.boardColumns.firstIndex(where: {$0.type == .contract}) {
                        if let cell = tableCell.collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? ScorecardInputBoardCollectionCell {
                            cell.contractPicker.set(contract)
                            cell.contractPickerDidChange(to: contract)
                        }
                    }
                }
                if showDeclarer && declarer != board.declarer {
                    // Update declarer
                    if let item = self.boardColumns.firstIndex(where: {$0.type == .declarer}) {
                        if let cell = tableCell.collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? ScorecardInputBoardCollectionCell {
                            if let index = Seat.allCases.firstIndex(where: {$0 == declarer}) {
                                cell.seatPicker.set(index)
                                cell.scrollPickerDidChange(to: index)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func scorecardScrollPickerPopup(values: [ScrollPickerEntry], maxValues: Int, selected: Int, frame: CGRect, in container: UIView, topPadding: CGFloat, bottomPadding: CGFloat, completion: @escaping (Int)->()) {
        scrollPickerPopupView.show(from: self, values: values, maxValues: maxValues, selected: selected, frame: container.convert(frame, to: self), topPadding: topPadding, bottomPadding: bottomPadding) { (selected) in
            if let selected = selected {
                completion(selected)
            }
        }
    }
    
    func scorecardGetDeclarers(tableNumber: Int) -> [Seat] {
        var declarers: [Seat] = []
        let boards = scorecard.boardsTable
        for index in 1...boards {
            let boardNumber = ((tableNumber - 1) * boards) + index
            declarers.append(Scorecard.current.boards[boardNumber]?.declarer ?? .unknown)
        }
        return declarers
    }
    
    func scorecardUpdateDeclarers(tableNumber: Int, to declarers: [Seat]?) {
        let boards = scorecard.boardsTable
        for index in 1...boards {
            let boardNumber = ((tableNumber - 1) * boards) + index
            if let board = Scorecard.current.boards[boardNumber] {
                board.declarer = declarers?[index - 1] ?? .unknown
            }
        }
    }
    
    func scorecardEndEditing(_ force: Bool) {
        self.endEditing(force)
    }
    
   // MARK: - TableView Delegates ===================================================================== -
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return scorecard.tables
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scorecard.boardsTable
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableRowHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = ScorecardInputTableSectionHeaderView.dequeue(self, tableView: tableView, tag: RowType.table.tagOffset + section + 1)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return boardRowHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ScorecardInputBoardTableCell.dequeue(self, tableView: tableView, for: indexPath, tag: RowType.board.tagOffset + (indexPath.section * scorecard.boardsTable) + indexPath.row + 1)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var columns = 0
        if let type = RowType(rawValue: collectionView.tag / tagMultiplier) {
            switch type {
            case .board, .boardTitle:
                columns = boardColumns.count
            case .table:
                columns = tableColumns.count
            }
        }
        return columns
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var column: ScorecardColumn?
        var height: CGFloat = 0
        if let type = RowType(rawValue: collectionView.tag / tagMultiplier) {
            switch type {
            case .board:
                height = boardRowHeight
                column = boardColumns[indexPath.item]
            case .table:
                height = tableRowHeight
                column = tableColumns[indexPath.item]
            case .boardTitle:
                height = titleRowHeight
                column = boardColumns[indexPath.item]
            }
        } else {
            fatalError()
        }
        return CGSize(width: column?.width ?? 0, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let type = RowType(rawValue: collectionView.tag / tagMultiplier) {
            switch type {
            case .board:
                let cell = ScorecardInputBoardCollectionCell.dequeue(collectionView, for: indexPath)
                let boardNumber = collectionView.tag % tagMultiplier
                if let board = Scorecard.current.boards[boardNumber] {
                    let tableNumber = ((boardNumber - 1) / scorecard.boardsTable) + 1
                    if let table = Scorecard.current.tables[tableNumber] {
                        let column = boardColumns[indexPath.item]
                        cell.set(from: self, scorecard: scorecard, table: table, board: board, boardNumber: boardNumber, column: column)
                    }
                }
                return cell
            case .boardTitle:
                let cell = ScorecardInputBoardCollectionCell.dequeue(collectionView, for: indexPath)
                let column = boardColumns[indexPath.item]
                cell.setTitle(column: column)
                return cell
            case .table:
                let cell = ScorecardInputTableCollectionCell.dequeue(collectionView, for: indexPath)
                let tableNumber = collectionView.tag % tagMultiplier
                if let table = Scorecard.current.tables[tableNumber] {
                    let column = tableColumns[indexPath.item]
                    cell.set(from: self, scorecard: scorecard, table: table, tableNumber: tableNumber, column: column)
                }
                return cell
            }
        } else {
            fatalError()
        }
    }
    
    // MARK: - Utility Routines ======================================================================== -
    
    func keyboardMoved(_ keyboardHeight: CGFloat) {
        if keyboardHeight != 0 || isKeyboardOffset {
            let focusedTextInputBottom = (UIResponder.currentFirstResponder?.globalFrame?.maxY ?? 0)
            let adjustOffset = max(0, focusedTextInputBottom - keyboardHeight) + safeAreaInsets.bottom
            // UIView.animate(withDuration: 0.1) { [self] in
                let current = self.mainTableView.contentOffset
                if isKeyboardOffset && keyboardHeight == 0 {
                    self.bottomConstraint.constant = 0
                    self.mainTableView.setContentOffset(CGPoint(x: 0, y: self.lastKeyboardScrollOffset), animated: false)
                    self.lastKeyboardScrollOffset = 0
                    self.isKeyboardOffset = false
                } else if adjustOffset != 0 && !isKeyboardOffset {
                    let newOffset = current.y + adjustOffset
                    let maxOffset = self.mainTableView.contentSize.height - mainTableView.frame.height
                    let scrollOffset = min(newOffset, maxOffset)
                    let bottomOffset = newOffset - scrollOffset
                    self.lastKeyboardScrollOffset = self.mainTableView.contentOffset.y
                    self.bottomConstraint.constant = -bottomOffset
                    self.mainTableView.setContentOffset(current.offsetBy(dy: adjustOffset), animated: false)
                    self.isKeyboardOffset = true
                }
            // }
        }
    }
    
    func setupSizes(columns: inout [ScorecardColumn]) {
        var fixedWidth: CGFloat = 0
        var flexible: Int = 0
        for column in columns {
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
    }
}

// MARK: - Table View Title Header ============================================================ -

fileprivate class ScorecardInputTableTitleView: UIView {
    fileprivate var collectionView: UICollectionView!
    private var layout: UICollectionViewFlowLayout!
    
    init<D: UICollectionViewDataSource & UICollectionViewDelegate>
    (_ dataSourceDelegate: D, frame: CGRect, tag: Int) {
        super.init(frame: frame)
        self.layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        self.addSubview(collectionView, anchored: .all)
        self.bringSubviewToFront(self.collectionView)
        ScorecardInputBoardCollectionCell.register(collectionView)
        TableViewCellWithCollectionView.setCollectionViewDataSourceDelegate(dataSourceDelegate, collectionView: collectionView, tag: tag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Table View Section Header ============================================================ -

fileprivate class ScorecardInputTableSectionHeaderView: TableViewSectionHeaderWithCollectionView {
    private static var identifier = "Table Section Header"
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        ScorecardInputTableCollectionCell.register(self.collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ tableView: UITableView, forTitle: Bool = false) {
        tableView.register(ScorecardInputTableSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: identifier)
    }
    
    public class func dequeue<D: UICollectionViewDataSource & UICollectionViewDelegate>(_ dataSourceDelegate : D, tableView: UITableView, tag: Int) -> ScorecardInputTableSectionHeaderView {
        return TableViewSectionHeaderWithCollectionView.dequeue(dataSourceDelegate, tableView: tableView, withIdentifier: ScorecardInputTableSectionHeaderView.identifier, tag: tag) as! ScorecardInputTableSectionHeaderView
    }
}

// MARK: - Board Table View Cell ================================================================ -

fileprivate class ScorecardInputBoardTableCell: TableViewCellWithCollectionView {
    private static let cellIdentifier = "Board TableCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        ScorecardInputBoardCollectionCell.register(self.collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ tableView: UITableView, forTitle: Bool = false) {
        tableView.register(ScorecardInputBoardTableCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    public class func dequeue<D: UICollectionViewDataSource & UICollectionViewDelegate>(_ dataSourceDelegate : D, tableView: UITableView, for indexPath: IndexPath, tag: Int) -> ScorecardInputBoardTableCell {
        var cell: ScorecardInputBoardTableCell
        cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ScorecardInputBoardTableCell
        cell.setCollectionViewDataSourceDelegate(dataSourceDelegate, tag: tag)
        return cell
    }
}

// MARK: - Board Collection View Cell ================================================================ -

fileprivate class ScorecardInputBoardCollectionCell: UICollectionViewCell, ScrollPickerDelegate, EnumPickerDelegate, ContractPickerDelegate, UITextViewDelegate, UITextFieldDelegate {
    private var label = UILabel()
    private var textField = UITextField()
    private var textView = UITextView()
    private var textClear = UIImageView()
    private var textClearWidth: NSLayoutConstraint!
    private var textClearPadding: [NSLayoutConstraint]!
    private var participantPicker: EnumPicker<Participant>!
    fileprivate var seatPicker: ScrollPicker!
    private var madePicker: ScrollPicker!
    fileprivate var contractPicker: ContractPicker
    private var table: TableViewModel!
    private var board: BoardViewModel!
    fileprivate var boardNumber: Int!
    private var column: ScorecardColumn!
    private var scorecardDelegate: ScorecardDelegate?
    private static let identifier = "Board CollectionCell"
    
    override init(frame: CGRect) {
        participantPicker = EnumPicker(frame: frame)
        seatPicker = ScrollPicker(frame: frame)
        contractPicker = ContractPicker(frame: frame)
        madePicker = ScrollPicker(frame: frame)
        super.init(frame: frame)
        
        self.layer.borderColor = UIColor(Palette.gridLine).cgColor
        self.layer.borderWidth = 2.0
        self.backgroundColor = UIColor(Palette.gridTable.background)
                
        let endEditingGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputBoardCollectionCell.endEditingTapped))
        self.addGestureRecognizer(endEditingGesture)
        
        addSubview(label, anchored: .all)
        label.textAlignment = .center
        label.minimumScaleFactor = 0.3
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor(Palette.gridBoard.text)
         
        addSubview(textField, constant: 8, anchored: .leading, .top, .bottom)
        textField.textAlignment = .center
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.font = cellFont
        textField.delegate = self
        textField.addTarget(self, action: #selector(ScorecardInputBoardCollectionCell.textFieldChanged), for: .editingChanged)
        textField.backgroundColor = UIColor.clear
        textField.borderStyle = .none
        textField.textColor = UIColor(Palette.gridBoard.text)
        textField.adjustsFontSizeToFitWidth = true
        textField.returnKeyType = .done
               
        addSubview(textView, constant: 8, anchored: .leading, .top, .bottom)
        textView.textAlignment = .left
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.font = cellFont
        textView.delegate = self
        textView.backgroundColor = UIColor.clear
        textView.textColor = UIColor(Palette.gridBoard.text)
        
        addSubview(textClear, constant: 8, anchored: .trailing, .top, .bottom)
        textClearWidth = Constraint.setWidth(control: textClear, width: 0)
        textClearPadding = Constraint.anchor(view: self, control: textField, to: textClear, constant: 8, toAttribute: .leading, attributes: .trailing)
        textClearPadding.append(contentsOf: Constraint.anchor(view: self, control: textView, to: textClear, constant: 8, toAttribute: .leading, attributes: .trailing))
        textClear.image = UIImage(systemName: "x.circle.fill")?.asTemplate
        textClear.tintColor = UIColor(Palette.clearText)
        textClear.contentMode = .scaleAspectFit
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputBoardCollectionCell.textViewClearPressed))
        textClear.addGestureRecognizer(tapGesture)
        textClear.isUserInteractionEnabled = true
        
        addSubview(seatPicker, top: 28, bottom: 12)
        Constraint.setWidth(control: seatPicker, width: 60)
        Constraint.anchor(view: self, control: seatPicker, attributes: .centerX)
        seatPicker.delegate = self
        let declarerTapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputBoardCollectionCell.declarerTapped))
        seatPicker.addGestureRecognizer(declarerTapGesture)

        addSubview(contractPicker, leading: 8, trailing: 8, top: 28, bottom: 12)
        contractPicker.delegate = self
        let contractTapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputBoardCollectionCell.contractTapped))
        contractPicker.addGestureRecognizer(contractTapGesture)
        
        addSubview(madePicker, top: 28, bottom: 12)
        Constraint.setWidth(control: madePicker, width: 60)
        Constraint.anchor(view: self, control: madePicker, attributes: .centerX)
        madePicker.delegate = self
        let madeTapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputBoardCollectionCell.madeTapped))
        madePicker.addGestureRecognizer(madeTapGesture)
        
        addSubview(participantPicker, top: 28, bottom: 12)
        Constraint.setWidth(control: participantPicker, width: 60)
        Constraint.anchor(view: self, control: participantPicker, attributes: .centerX)
        participantPicker.delegate = self
        let responsibleTapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputBoardCollectionCell.responsibleTapped))
        participantPicker.addGestureRecognizer(responsibleTapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ collectionView: UICollectionView) {
        collectionView.register(ScorecardInputBoardCollectionCell.self, forCellWithReuseIdentifier: identifier)
    }

    public class func dequeue(_ collectionView: UICollectionView, for indexPath: IndexPath) -> ScorecardInputBoardCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ScorecardInputBoardCollectionCell
        cell.prepareForReuse()
        return cell
    }
    
    override func prepareForReuse() {
        board = nil
        boardNumber = nil
        column = nil
        textField.isHidden = true
        seatPicker.isHidden = true
        participantPicker.isHidden = true
        seatPicker.isHidden = true
        contractPicker.isHidden = true
        madePicker.isHidden = true
        textField.isHidden = true
        textView.isHidden = true
        textClear.isHidden = true
        textClearWidth.constant = 0
        textClearPadding.forEach { (constraint) in constraint.constant = 0 }
        textField.text = ""
        textView.text = ""
        label.backgroundColor = UIColor(Palette.gridBoard.background)
        label.text = ""
        label.textAlignment = .center
        textField.textAlignment = .center
        textField.clearsOnBeginEditing = false
        textField.clearButtonMode = .never
    }
    
    func setTitle(column: ScorecardColumn) {
        self.board = nil
        self.column = column
        label.font = titleFont
        label.text = column.heading
    }
    
    func set(from scorecardDelegate: ScorecardDelegate, scorecard: ScorecardViewModel, table: TableViewModel, board: BoardViewModel, boardNumber: Int, column: ScorecardColumn) {
        self.scorecardDelegate = scorecardDelegate
        self.board = board
        self.table = table
        self.boardNumber = boardNumber
        self.column = column
        
        var color = Palette.gridBoard
        switch column.type {
        case .board:
            label.font = boardFont
            label.text = "\(scorecard.resetNumbers ? ((board.board - 1) % scorecard.boardsTable) + 1 : board.board)"
        case .contract:
            contractPicker.isHidden = false
            contractPicker.set(board.contract, color: Palette.gridBoard, font: pickerTitleFont, force: true)
        case .declarer:
            seatPicker.isHidden = false
            let isEnabled = (table.sitting != .unknown)
            color = (isEnabled ? Palette.gridBoard : Palette.gridBoardDisabled)
            let selected = board.declarer.rawValue
            seatPicker.set(selected, list: declarerList, isEnabled: isEnabled, color: color, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
        case .made:
            madePicker.isHidden = false
            let (list, min, max) = madeList
            if board.made < min {
                board.made = min
            } else if board.made > max {
                board.made = max
            }
            let isEnabled = board.contract.suit.valid
            color = (isEnabled ? Palette.gridBoard : Palette.gridBoardDisabled)
            madePicker.set(board.made - min, list: list, isEnabled: isEnabled, color: color, titleFont: pickerTitleFont)
        case .score:
            textField.isHidden = false
            textField.keyboardType = .numberPad
            textField.clearsOnBeginEditing = true
            textField.text = board.score == nil ? "" : "\(board.score!)"
        case .comment:
            textField.isHidden = false
            textField.text = board.comment
            textField.textAlignment = .left
            textClear.isHidden = board.comment == ""
            textClearWidth.constant = 34
            textClearPadding.forEach { (constraint) in constraint.constant = 8 }
        case .responsible:
            participantPicker.isHidden = false
            participantPicker.set(board.responsible, color: Palette.gridBoard, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)

        default:
            label.text = ""
        }
        label.backgroundColor = UIColor(color.background)
    }
    
    private var madeList: (list: [String], min: Int, max: Int) {
        var list: [String] = []
        var min = 0
        var max = 0
        if board.contract.suit != .blank {
            let tricks = board.contract.level.rawValue
            min = -(6 + tricks)
            max = 7 - tricks
            for i in (-6-tricks)...(7-tricks) {
                var value = ""
                switch true {
                case i < 0:
                    value = "\(i)"
                case i == 0:
                    value = "="
                case i > 0:
                    value = "+\(i)"
                default:
                    break
                }
                list.append(value)
            }
        }
        if list.count == 0 {
            list.append("")
        }
        return (list, min, max)
    }
    
    private var declarerList: [ScrollPickerEntry] {
        return Seat.allCases.map{ScrollPickerEntry(title: $0.short, caption: { (seat) in
            switch seat {
                case .unknown:
                    return seat.string
                case table.sitting:
                    return "Self"
                case table.sitting.partner:
                    return "Partner"
                default:
                    return "Opponent"
                }
        }($0))}
    }
    
    // MARK: - Control change handlers ===================================================================== -
        
    @objc private func textFieldChanged(_ textField: UITextField) {
        print("text \(textField.text!)")
        let text = textField.text ?? ""
        if let board = board {
            var undoText: String?
            switch self.column.type {
            case .score:
                undoText = board.score == nil ? "" : "\(board.score!)"
            case .comment:
                undoText = board.comment
            default:
                break
            }
            if let undoText = undoText {
                if text != undoText {
                    undoManager?.registerUndo(withTarget: textField) { (textField) in
                        textField.text = undoText
                        self.textFieldChanged(textField)
                    }
                    switch column.type {
                    case .score:
                        board.score = numericValue(text)
                    case .comment:
                        board.comment = text
                        textClear.isHidden = (text == "")
                    default:
                        break
                    }
                    scorecardDelegate?.scorecardChanged(type: .board, itemNumber: boardNumber, column: column)
                }
            }
        }
    }
    
    internal func textFieldDidEndEditing(_ textField: UITextField) {
        let text = textField.text ?? ""
        switch column.type {
        case .score:
            let score = numericValue(text)
            let newText = (score == nil ? "" : "\(score!)")
            if newText != textField.text {
                textField.text = newText
                textFieldChanged(textField)
            }

        default:
            break
        }
    }
    
    private func numericValue(_ text: String) -> Float? {
        let numericText = text.uppercased()
                              .replacingOccurrences(of: "O", with: "0")
                              .replacingOccurrences(of: "I", with: "1")
                              .replacingOccurrences(of: "L", with: "1")
                              .replacingOccurrences(of: "Z", with: "2")
                              .replacingOccurrences(of: "S", with: "5")
                              .replacingOccurrences(of: "_", with: "-")
        return Float(numericText)
    }
    
    internal func textFieldDidBeginEditing(_ textField: UITextField) {
        // Record automatic clear on entry in undo
        var undoText = ""
        if let board = board {
            switch column.type {
            case .score:
                undoText = board.score == nil ? "" : "\(board.score!)"
            default:
                break
            }
            if undoText != "" {
                textFieldChanged(textField)
            }
        }
    }
    
    internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    internal func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""
        if let board = board {
            var undoText: String?
            switch self.column.type {
            case .comment:
                undoText = board.comment
            default:
                break
            }
            if let undoText = undoText {
                if text != undoText {
                    undoManager?.registerUndo(withTarget: textView) { (textView) in
                        textView.text = undoText
                        self.textViewDidChange(textView)
                    }
                    switch column.type {
                    case .comment:
                        board.comment = text
                        textClear.isHidden = (text == "")
                    default:
                        break
                    }
                    scorecardDelegate?.scorecardChanged(type: .board, itemNumber: boardNumber, column: column)
                }
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "3nt" {
            let mutableText = NSMutableString(string: textView.text)
            textView.text = mutableText.replacingCharacters(in: range, with: "3NT")
            textViewDidChange(textView)
            return false
        }
        return true
    }
    
    @objc internal func textViewClearPressed(_ textViewClear: UIView) {
        if let board = board {
            var text: String?
            switch self.column.type {
            case .comment:
                text = board.comment
            default:
                break
            }
            if text != "" {
                textView.text = ""
                textView.resignFirstResponder()
                textField.text = ""
                textField.resignFirstResponder()
                textFieldChanged(textField)
            }
        }
    }
    
    internal func enumPickerDidChange(to value: Any) {
        if let board = board {
            var undoValue: Any?
            switch self.column.type {
            case .responsible:
                if value as? Participant != board.responsible {
                    undoValue = board.responsible
                }
            default:
                break
            }
            if let undoValue = undoValue {
                switch self.column.type {
                case .responsible:
                    undoManager?.registerUndo(withTarget: participantPicker) { (participantPicker) in
                        self.participantPicker.set(undoValue as! Participant)
                        self.enumPickerDidChange(to: undoValue)
                    }
                default:
                    break
                }
                switch column.type {
                case .responsible:
                    board.responsible = value as! Participant
                default:
                    break
                }
                scorecardDelegate?.scorecardChanged(type: .board, itemNumber: boardNumber, column: column)
            }
        }
    }
    
    internal func contractPickerDidChange(to value: Contract) {
        if let board = board {
            let undoValue = board.contract
            if value != undoValue {
                let undoMade = board.made
                undoManager?.registerUndo(withTarget: contractPicker) { (contractPicker) in
                    contractPicker.set(undoValue)
                    board.made = undoMade
                    self.contractPickerDidChange(to: undoValue)
                }
                board.contract = value
                scorecardDelegate?.scorecardChanged(type: .board, itemNumber: boardNumber, column: column)
            }
        }
    }
    
    @objc internal func contractTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: .board, itemNumber: boardNumber)
        scorecardDelegate?.scorecardContractEntry(board: board, table: table)
    }
    
    @objc internal func declarerTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: .board, itemNumber: boardNumber)
        if table.sitting != .unknown {
            let width: CGFloat = 70
            let space = (frame.width - width) / 2
            scorecardDelegate?.scorecardScrollPickerPopup(values: declarerList, maxValues: 9, selected: board.declarer.rawValue, frame: CGRect(x: self.frame.minX + space, y: self.frame.minY, width: width, height: self.frame.height), in: self.superview!, topPadding: 20, bottomPadding: 4) { (selected) in
                self.seatPicker.set(selected)
                self.scrollPickerDidChange(to: selected)
            }
        }
    }
    
    @objc internal func madeTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: .board, itemNumber: boardNumber)
        let (madeList, _, _) = madeList
        let width: CGFloat = 70
        let space = (frame.width - width) / 2
        scorecardDelegate?.scorecardScrollPickerPopup(values: madeList, maxValues: 9, selected: board.made + (6 + board.contract.level.rawValue), frame: CGRect(x: self.frame.minX + space, y: self.frame.minY, width: width, height: self.frame.height), in: self.superview!, topPadding: 0, bottomPadding: 0) { (selected) in
            self.madePicker.set(selected)
            self.scrollPickerDidChange(to: selected)
        }
    }
    
    @objc internal func responsibleTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: .board, itemNumber: boardNumber)
        let width: CGFloat = 70
        let space = (frame.width - width) / 2
        scorecardDelegate?.scorecardScrollPickerPopup(values: Participant.allCases.map{ScrollPickerEntry(title: $0.short, caption: $0.full)}, maxValues: 7, selected: board.responsible.rawValue, frame: CGRect(x: self.frame.minX + space, y: self.frame.minY, width: width, height: self.frame.height), in: self.superview!, topPadding: 28, bottomPadding: 12) { (selected) in
            if let participant = Participant(rawValue: selected) {
                self.participantPicker.set(participant)
                self.enumPickerDidChange(to: participant)
            }
        }
    }
    
    internal func scrollPickerDidChange(to value: Int) {
        if let board = board {
            var picker: ScrollPicker!
            var undoValue: Int?
            switch column.type {
            case .declarer:
                undoValue = Seat.allCases.firstIndex(where: {$0 == board.declarer})
                picker = seatPicker
            case .made:
                undoValue = board.made + (6 + board.contract.level.rawValue)
                picker = madePicker
            default:
                break
            }
            if let undoValue = undoValue {
                if undoValue != value {
                    undoManager?.registerUndo(withTarget: picker) { (picker) in
                        picker.set(undoValue)
                        self.scrollPickerDidChange(to: undoValue)
                    }
                    switch column.type {
                    case .declarer:
                        board.declarer = Seat.allCases[value]
                    case .made:
                        board.made =  value - (6 + board.contract.level.rawValue)
                    default:
                        break
                    }
                    scorecardDelegate?.scorecardChanged(type: .board, itemNumber: boardNumber, column: column)
                }
            }
        }
    }
    
    @objc internal func endEditingTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: .board, itemNumber: boardNumber)
    }
}

// MARK: - Table Collection View Cell ================================================================ -

fileprivate class ScorecardInputTableCollectionCell: UICollectionViewCell, EnumPickerDelegate, UITextViewDelegate, UITextFieldDelegate {
    fileprivate var caption = UILabel()
    fileprivate var label = UILabel()
    fileprivate var textField = UITextField()
    fileprivate var textView = UITextView()
    fileprivate var textClear = UIImageView()
    fileprivate var textClearWidth: NSLayoutConstraint!
    fileprivate var textClearPadding: [NSLayoutConstraint]!
    fileprivate var seatPicker: EnumPicker<Seat>!
    fileprivate var table: TableViewModel!
    fileprivate var tableNumber: Int!
    fileprivate var column: ScorecardColumn!
    private var scorecardDelegate: ScorecardDelegate?
    private static let identifier = "Table CollectionCell"
    private var captionHeight: NSLayoutConstraint!

    override init(frame: CGRect) {
        seatPicker = EnumPicker(frame: frame, color: Palette.gridTable)
        super.init(frame: frame)
        
        self.layer.borderColor = UIColor(Palette.gridLine).cgColor
        self.layer.borderWidth = 2.0
        self.backgroundColor = UIColor(Palette.gridTable.background)
        
        let endEditingGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputBoardCollectionCell.endEditingTapped))
        self.addGestureRecognizer(endEditingGesture)
        
        addSubview(label, constant: 8, anchored: .all)
        label.textAlignment = .center
        label.font = cellFont
        label.adjustsFontSizeToFitWidth = true
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor(Palette.gridTable.text)

        addSubview(textField, constant: 8, anchored: .leading, .top, .bottom)
        textField.textAlignment = .center
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.font = cellFont
        textField.delegate = self
        textField.addTarget(self, action: #selector(ScorecardInputTableCollectionCell.textFieldChanged), for: .editingChanged)
        textField.backgroundColor = UIColor.clear
        textField.borderStyle = .none
        textField.textColor = UIColor(Palette.gridTable.text)
        textField.adjustsFontSizeToFitWidth = true
        textField.returnKeyType = .done

        addSubview(textView, constant: 8, anchored: .leading, .bottom)
        Constraint.anchor(view: self, control: textView, constant: 20, attributes: .top)
        textView.textAlignment = .left
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.font = cellFont
        textView.delegate = self
        textView.backgroundColor = UIColor.clear
        textView.textColor = UIColor(Palette.gridTable.text)
        
        addSubview(textClear, constant: 8, anchored: .trailing, .top, .bottom)
        textClearWidth = Constraint.setWidth(control: textClear, width: 0)
        textClearPadding = Constraint.anchor(view: self, control: textField, to: textClear, constant: 8, toAttribute: .leading, attributes: .trailing)
        textClearPadding.append(contentsOf: Constraint.anchor(view: self, control: textView, to: textClear, constant: 8, toAttribute: .leading, attributes: .trailing))
        textClear.image = UIImage(systemName: "x.circle.fill")?.asTemplate
        textClear.contentMode = .scaleAspectFit
        textClear.tintColor = UIColor(Palette.clearText)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputBoardCollectionCell.textViewClearPressed))
        textClear.addGestureRecognizer(tapGesture)
        textClear.isUserInteractionEnabled = true
        
        addSubview(seatPicker, top: 20, bottom: 4)
        Constraint.setWidth(control: seatPicker, width: 60)
        Constraint.anchor(view: self, control: seatPicker, attributes: .centerX)
        seatPicker.delegate = self
        let seatGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputTableCollectionCell.sittingTapped))
        seatPicker.addGestureRecognizer(seatGesture)

        addSubview(caption, anchored: .leading, .trailing, .top)
        caption.textAlignment = .center
        caption.font = titleCaptionFont
        caption.minimumScaleFactor = 0.3
        caption.backgroundColor = UIColor.clear
        caption.textColor = UIColor(Palette.gridBoard.text)
        captionHeight = Constraint.setHeight(control: caption, height: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ collectionView: UICollectionView) {
        collectionView.register(ScorecardInputTableCollectionCell.self, forCellWithReuseIdentifier: identifier)
    }

    public class func dequeue(_ collectionView: UICollectionView, for indexPath: IndexPath) -> ScorecardInputTableCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ScorecardInputTableCollectionCell
        cell.prepareForReuse()
        return cell
    }
    
    override func prepareForReuse() {
        caption.isHidden = true
        textField.isHidden = true
        seatPicker.isHidden = true
        textField.text = ""
        textField.clearsOnBeginEditing = false
        textView.isHidden = true
        textClear.isHidden = true
        textClearWidth.constant = 0
        textClearPadding.forEach { (constraint) in constraint.constant = 0 }
        label.text = ""
        label.font = cellFont
        label.backgroundColor = UIColor(Palette.gridTable.background)
        label.textAlignment = .center
        textField.textAlignment = .center
        captionHeight.constant = 0
    }
    
    func set(from scorecardDelegate: ScorecardDelegate, scorecard: ScorecardViewModel, table: TableViewModel, tableNumber: Int, column: ScorecardColumn) {        self.scorecardDelegate = scorecardDelegate
        self.table = table
        self.tableNumber = tableNumber
        self.column = column
        
        let color = Palette.gridTable // Change to var if want to change color
        switch column.type {
        case .table:
            label.font = boardTitleFont
            label.text = "Round \(table.table)"
        case .sitting:
            seatPicker.isHidden = false
            seatPicker.set(table.sitting, color: Palette.gridTable, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
        case .tableScore:
            if scorecard.type.tableAggregate == .manual {
                textField.isHidden = false
                textField.clearsOnBeginEditing = true
                textField.text = table.score == nil ? "" : "\(table.score!)"
            } else {
                label.text = table.score == nil ? "" : "\(table.score!)"
            }
        case .versus:
            textField.isHidden = false
            textField.text = table.versus
            textField.textAlignment = .left
            textClear.isHidden = table.versus == ""
            textClearWidth.constant = 34
            textClearPadding.forEach { (constraint) in constraint.constant = 8 }
        default:
            label.text = ""
        }
        if column.heading != "" {
            caption.isHidden = false
            captionHeight.constant = 24
            caption.text = column.heading
        }
        label.backgroundColor = UIColor(color.background)
    }
    
    // MARK: - Control change handlers ===================================================================== -
    
    @objc private func textFieldChanged(_ textField: UITextField) {
        let text = textField.text ?? ""
        if let table = table {
            var undoText: String?
            switch self.column.type {
            case .tableScore:
                undoText = table.score == nil ? "" : "\(table.score!)"
            case .versus:
                undoText = table.versus
            default:
                break
            }
            if let undoText = undoText {
                if undoText != text {
                    undoManager?.registerUndo(withTarget: textField) { (textField) in
                        textField.text = undoText
                        self.textFieldChanged(textField)
                    }
                    switch column.type {
                    case .tableScore:
                        table.score = Float(text) ?? 0
                    case .versus:
                        table.versus = text
                        textClear.isHidden = table.versus == ""
                    default:
                        break
                    }
                    scorecardDelegate?.scorecardChanged(type: .table, itemNumber: tableNumber, column: column)
                }
            }
        }
    }
    
    internal func textFieldDidEndEditing(_ textField: UITextField) {
        let text = textField.text ?? ""
        switch column.type {
        case .tableScore:
            let score = Float(text)
            let newText = (score == nil ? "" : "\(score!)")
            if newText != textField.text {
                textField.text = newText
                textFieldChanged(textField)
            }
        default:
            break
        }
    }
    
    internal func textFieldDidBeginEditing(_ textField: UITextField) {
        // Record automatic clear on entry in undo
        var undoText = ""
        if let table = table {
            switch column.type {
            case .tableScore:
                undoText = table.score == nil ? "" : "\(table.score!)"
            default:
                break
            }
            if undoText != "" {
                textFieldChanged(textField)
            }
        }
    }
    
    internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    internal func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""
        if let table = table {
            var undoText: String?
            switch self.column.type {
            case .versus:
                undoText = table.versus
            default:
                break
            }
            if let undoText = undoText {
                if undoText != text {
                    undoManager?.registerUndo(withTarget: textView) { (textView) in
                        textView.text = undoText
                        self.textViewDidChange(textView)
                    }
                    switch column.type {
                    case .versus:
                        table.versus = text
                        textClear.isHidden = (text == "")
                    default:
                        break
                    }
                    scorecardDelegate?.scorecardChanged(type: .board, itemNumber: tableNumber, column: column)
                }
            }
        }
    }
    
    @objc internal func textViewClearPressed(_ textViewClear: UIView) {
        if let table = table {
            var text: String?
            switch self.column.type {
            case .versus:
                text = table.versus
            default:
                break
            }
            if text != "" {
                textView.text = ""
                textView.resignFirstResponder()
                textField.text = ""
                textField.resignFirstResponder()
                textFieldChanged(textField)
            }
        }
    }
    
    internal func enumPickerDidChange(to value: Any) {
        if let table = table, let value = value as? Seat {
            var undoValue: Seat?
            var undoDeclarers: [Seat]?
            switch self.column.type {
            case .sitting:
                undoValue = table.sitting
                undoDeclarers = (undoValue == .unknown ? nil : scorecardDelegate?.scorecardGetDeclarers(tableNumber: tableNumber))
            default:
                break
            }
            if let undoValue = undoValue {
                if undoValue != value {
                    undoManager?.registerUndo(withTarget: seatPicker) { (seatPicker) in
                        switch self.column.type {
                        case .sitting:
                            self.scorecardDelegate?.scorecardUpdateDeclarers(tableNumber: self.tableNumber, to: undoDeclarers)
                            self.seatPicker.set(undoValue)
                        default:
                            break
                        }
                        self.enumPickerDidChange(to: undoValue)
                    }
                    switch column.type {
                    case .sitting:
                        table.sitting = value
                        if value == .unknown {
                            self.scorecardDelegate?.scorecardUpdateDeclarers(tableNumber: tableNumber, to: nil)
                        }
                    default:
                        break
                    }
                    scorecardDelegate?.scorecardChanged(type: .table, itemNumber: tableNumber, column: column)
                }
            }
        }
    }
    
    @objc internal func sittingTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: .table, itemNumber: tableNumber)
        let width: CGFloat = 70
        let space = (frame.width - width) / 2
        scorecardDelegate?.scorecardScrollPickerPopup(values: Seat.allCases.map{ScrollPickerEntry(title: $0.short, caption: $0.string)}, maxValues: 9, selected: table.sitting.rawValue, frame: CGRect(x: self.frame.minX + space, y: self.frame.minY, width: width, height: self.frame.height), in: self.superview!, topPadding: 20, bottomPadding: 4) { (selected) in
            if let seat = Seat(rawValue: selected) {
                self.seatPicker.set(seat)
                self.enumPickerDidChange(to: seat)
            }
        }
    }
    
    @objc internal func endEditingTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: .table, itemNumber: tableNumber)
    }
}
