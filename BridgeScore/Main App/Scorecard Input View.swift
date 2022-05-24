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
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.verticalSizeClass) var sizeClass
    
    private let id = scorecardInputViewId
    @ObservedObject var scorecard: ScorecardViewModel
    @State var importScorecard: ImportSource = .none
    @State private var canUndo: Bool = false
    @State private var canRedo: Bool = false
    @State private var isNotImported: Bool = true
    @State private var inputDetail: Bool = false
    @State private var refreshTableTotals = false
    @State private var deleted = false
    @State private var tableRefresh = false
    @State private var detailView = false
    @State private var importBboScorecard = false
    @State private var importBwScorecard = false
    @State private var showRankings = false
    @State private var disableBanner = false
    
    var body: some View {
        StandardView("Input", slideInId: id) {
            VStack(spacing: 0) {
                
                // Just to trigger view refresh
                if refreshTableTotals { EmptyView() }
    
                // Banner
                Banner(title: $scorecard.desc, back: true, backAction: backAction, leftTitle: true, optionMode: .both, menuImage: AnyView(Image(systemName: "gearshape")), menuTitle: nil, menuId: id, options: bannerOptions(isNotImported: $isNotImported), disabled: $disableBanner)
                    .disabled(disableBanner)
                GeometryReader { geometry in
                    ScorecardInputUIViewWrapper(scorecard: scorecard, frame: geometry.frame(in: .local), refreshTableTotals: $refreshTableTotals, detailView: $detailView, inputDetail: $inputDetail, tableRefresh: $tableRefresh, showRankings: $showRankings, disableBanner: $disableBanner)
                    .ignoresSafeArea(edges: .all)
                }
            }
            .undoManager(canUndo: $canUndo, canRedo: $canRedo)
        }
        .onChange(of: tableRefresh) { (value) in tableRefresh = false}
        .onChange(of: showRankings) { (value) in showRankings = false}
        .sheet(isPresented: $inputDetail, onDismiss: {
            UndoManager.clearActions()
            if deleted {
                presentationMode.wrappedValue.dismiss()
            } else {
                refreshTableTotals = true
            }
        }) {
            ScorecardDetailView(scorecard: scorecard, deleted: $deleted, tableRefresh: $tableRefresh, title: "Details")
        }
        .sheet(isPresented: $importBboScorecard, onDismiss: {
            UndoManager.clearActions()
            if scorecard.importSource != .none {
                isNotImported = false
                tableRefresh = true
            }
        }) {
            ImportBBOScorecard(scorecard: scorecard) {
                saveScorecard()
            }
        }
        .sheet(isPresented: $importBwScorecard, onDismiss: {
            UndoManager.clearActions()
            if scorecard.importSource != .none {
                isNotImported = false
                tableRefresh = true
            }
        }) {
            ImportBridgeWebsScorecard(scorecard: scorecard) {
                saveScorecard()
            }
        }
        .onAppear {
            Scorecard.updateScores(scorecard: scorecard)
            isNotImported = !Scorecard.current.isImported
            switch importScorecard {
            case .bbo:
                importBboScorecard = true
            case .bridgeWebs:
                importBwScorecard = true
            default: break
            }
        }
    }
    
    func bannerOptions(isNotImported: Binding<Bool>) -> [BannerOption] {
        var bannerOptions: [BannerOption] = []
        if scorecard.score != nil && !scorecard.manualTotals {
            bannerOptions += [
                BannerOption(text: scorecard.scoreString, color: Palette.bannerShadow, isEnabled: Binding.constant(false), action: {}) ]
        }
        bannerOptions += UndoManager.undoBannerOptions(canUndo: $canUndo, canRedo: $canRedo)
        if !isNotImported.wrappedValue && !Scorecard.current.rankingList.isEmpty {
            bannerOptions += [
                BannerOption(image: AnyView(Image(systemName: "list.number")), likeBack: true, isHidden: isNotImported, action: { disableBanner = true ; showRankings = true })]
        }
        bannerOptions += [
                BannerOption(image: AnyView(Image(systemName: "note.text")), text: "Scorecard details", likeBack: true, menu: true, action: { UndoManager.clearActions() ; inputDetail = true }),
                BannerOption(image: AnyView(Image(systemName: "\(detailView ? "minus" : "plus").magnifyingglass")), text: (detailView ? "Simple view" : "Alternative view"), likeBack: true, menu: true, action: { toggleView() })]
        if isNotImported.wrappedValue || scorecard.resetNumbers {
            bannerOptions += [
                BannerOption(image: AnyView(Image(systemName: "square.and.arrow.down")), text: "Import from BBO", likeBack: true, menu: true, action: { UndoManager.clearActions() ; importBboScorecard = true})]
            if scorecard.location?.bridgeWebsId != "" {
                bannerOptions += [
                    BannerOption(image: AnyView(Image(systemName: "square.and.arrow.down")), text: "Import from BridgeWebs", likeBack: true, menu: true, action: { UndoManager.clearActions() ; importBwScorecard = true})]
            }
        }
        if !isNotImported.wrappedValue {
            bannerOptions += [
                BannerOption(image: AnyView(Image(systemName: "lock.open.fill")), text: "Remove import details", likeBack: true, menu: true, action: {
                    UndoManager.clearActions()
                    MessageBox.shared.show("This will remove imported rankings and travellers and unlock the scorecard for editing. Are you sure you want to do this?", cancelText: "Cancel", okText: "Remove", okDestructive: true, okAction: {
                        MessageBox.shared.show("Clearing import...", okText: nil)
                        Utility.executeAfter(delay: 0.1) {
                            if let context = CoreData.context {
                                context.performAndWait {
                                    Scorecard.current.clearImport()
                                }
                                isNotImported.wrappedValue = true
                                tableRefresh = true
                                MessageBox.shared.hide()
                            }
                        }
                    })
                })]
        }
        return bannerOptions
    }
    
    func backAction() -> Bool {
        saveScorecard()
        return true
    }
    
    func saveScorecard() {
        Scorecard.current.addNew()
        Scorecard.current.saveAll(scorecard: scorecard)
        if let master = MasterData.shared.scorecard(id: scorecard.scorecardId) {
            master.copy(from: scorecard)
            master.save()
            scorecard.copy(from: master)
        } else {
            let master = ScorecardViewModel()
            master.copy(from: scorecard)
            master.insert()
            scorecard.copy(from: master)
        }
    }
    
    func toggleView() {
        detailView.toggle()
    }
}

struct ScorecardInputUIViewWrapper: UIViewRepresentable {
    @ObservedObject var  scorecard: ScorecardViewModel
    @State var frame: CGRect
    @Binding var refreshTableTotals: Bool
    @Binding var detailView: Bool
    @Binding var inputDetail: Bool
    @Binding var tableRefresh: Bool
    @Binding var showRankings: Bool
    @Binding var disableBanner: Bool

    func makeUIView(context: Context) -> ScorecardInputUIView {
        
        let view = ScorecardInputUIView(frame: frame, scorecard: scorecard, inputDetail: inputDetail, disableBanner: $disableBanner)
        UndoManager.clearActions()
       
        return view
    }

    func updateUIView(_ uiView: ScorecardInputUIView, context: Context) {
        
        uiView.inputDetail = inputDetail
        
        if refreshTableTotals {
            uiView.refreshTableTotals()
            refreshTableTotals = false
        }
        
        if tableRefresh {
            uiView.tableRefresh()
        }
        
        if showRankings {
            uiView.showRankings()
        }
        
        uiView.switchView(detailView: detailView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
    }
}

protocol ScorecardDelegate {
    func scorecardChanged(type: RowType, itemNumber: Int, column: ScorecardColumn?)
    func scorecardCell(rowType: RowType, itemNumber: Int, columnType: ColumnType) -> ScorecardInputCollectionCell?
    func scorecardContractEntry(board: BoardViewModel, table: TableViewModel)
    func scorecardBBONamesReplace(values: [String])
    func scorecardShowTraveller(scorecard: ScorecardViewModel, board: BoardViewModel, sitting: Seat)
    func scorecardShowHand(scorecard: ScorecardViewModel, board: BoardViewModel, sitting: Seat)
    func scorecardScrollPickerPopup(values: [ScrollPickerEntry], maxValues: Int, selected: Int?, defaultValue: Int?, frame: CGRect, in container: UIView, topPadding: CGFloat, bottomPadding: CGFloat, completion: @escaping (Int?)->())
    func scorecardDeclarerPickerPopup(values: [(Seat, ScrollPickerEntry)], selected: Seat?, frame: CGRect, in container: UIView, topPadding: CGFloat, bottomPadding: CGFloat, completion: @escaping (Seat?)->())
    func scorecardGetDeclarers(tableNumber: Int) -> [Seat]
    func scorecardUpdateDeclarers(tableNumber: Int, to: [Seat]?)
    func scorecardSelectScore(boardNumber: Int)
    func scorecardEndEditing(_ force: Bool)
    var autoComplete: AutoComplete {get}
    var keyboardHeight: CGFloat {get}
}

extension ScorecardDelegate {
    func scorecardChanged(type: RowType, itemNumber: Int) {
        scorecardChanged(type: type, itemNumber: itemNumber, column: nil)
    }
    func scorecardScrollPickerPopup(values: [String], maxValues: Int, selected: Int?, defaultValue: Int?, frame: CGRect, in container: UIView, topPadding: CGFloat, bottomPadding: CGFloat, completion: @escaping (Int?)->()) {
        scorecardScrollPickerPopup(values: values.map{ScrollPickerEntry(title: $0, caption: nil)}, maxValues: maxValues, selected: selected, defaultValue: defaultValue, frame: frame, in: container, topPadding: topPadding, bottomPadding: bottomPadding, completion: completion)
    }
}

fileprivate var titleRowHeight: CGFloat { MyApp.format == .phone ? (isLandscape ? 30 : 40) : 40 }
fileprivate var boardRowHeight: CGFloat { MyApp.format == .phone ? (isLandscape ? 50 : 70) : 90 }
fileprivate var tableRowHeight: CGFloat { MyApp.format == .phone ? (isLandscape ? 60 : 60) : 80 }

class ScorecardInputUIView : UIView, ScorecardDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    private var scorecard: ScorecardViewModel
    private var titleView: ScorecardInputTableTitleView!
    private var mainTableView = UITableView(frame: CGRect(), style: .plain)
    private var contractEntryView: ScorecardContractEntryView
    private var scrollPickerPopupView: ScrollPickerPopupView
    private var declarerPickerPopupView: DeclarerPickerPopupView
    private var subscription: AnyCancellable?
    private var lastKeyboardScrollOffset: CGFloat = 0
    internal var keyboardHeight: CGFloat = 0
    private var isKeyboardOffset = false
    private var bottomConstraint: NSLayoutConstraint!
    private var forceReload = true
    private var detailView = true
    public var inputDetail: Bool
    private var disableBanner: Binding<Bool>
    private var ignoreKeyboard = false
    private var titleHeightConstraint: NSLayoutConstraint!
    private var orientation: UIDeviceOrientation?
    
    var boardColumns: [ScorecardColumn] = []
    var tableColumns: [ScorecardColumn] = []
    
    init(frame: CGRect, scorecard: ScorecardViewModel, inputDetail: Bool, disableBanner: Binding<Bool>) {
        self.scorecard = scorecard
        self.inputDetail = inputDetail
        self.disableBanner = disableBanner
        self.contractEntryView = ScorecardContractEntryView(frame: CGRect())
        self.scrollPickerPopupView = ScrollPickerPopupView(frame: CGRect())
        self.declarerPickerPopupView = DeclarerPickerPopupView(frame: CGRect())

        super.init(frame: frame)
        
        // Set up view
        switchView(detailView: true, force: true)
                    
        // Add subviews
        titleView = ScorecardInputTableTitleView(self, frame: CGRect(), tag: RowType.boardTitle.tagOffset)
        self.addSubview(titleView, anchored: .safeLeading, .safeTrailing, .top)
        titleHeightConstraint = Constraint.setHeight(control: titleView, height: titleRowHeight)
        
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
        
        // Setup auto-complete view
        self.addSubview(autoComplete)
        
        subscription = Publishers.keyboardHeight.sink { (keyboardHeight) in
            self.keyboardMoved(keyboardHeight)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        endEditing(true)
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let oldBoardColumns = boardColumns
        let oldTableColumns = tableColumns
        setupSizes(columns: &boardColumns)
        setupSizes(columns: &tableColumns)
        titleHeightConstraint.constant = titleRowHeight
        if boardColumns != oldBoardColumns || tableColumns != oldTableColumns || orientation != UIDevice.current.orientation || forceReload {
            mainTableView.reloadData()
            titleView.collectionView.reloadData()
            orientation = UIDevice.current.orientation
            forceReload = false
        }
    }

    public func refreshTableTotals() {
        for table in 1...scorecard.tables {
            updateTableCell(section: table - 1, columnType: .tableScore)
        }
    }
    
    public func tableRefresh() {
        mainTableView.reloadData()
    }
    
    public func switchView(detailView: Bool, force: Bool = false) {
        if self.detailView != detailView || force {
            if detailView {
                boardColumns = [
                    ScorecardColumn(type: .board, heading: "Board", size: .fixed([70])),
                    ScorecardColumn(type: .vulnerable, heading: "Vul", size: .fixed([30])),
                    ScorecardColumn(type: .dealer, heading: "Dealer", size: .fixed([50])),
                    ScorecardColumn(type: .contract, heading: "Contract", size: .fixed([95])),
                    ScorecardColumn(type: .declarer, heading: "By", size: .fixed([70])),
                    ScorecardColumn(type: .made, heading: "Made", size: .fixed([60])),
                    ScorecardColumn(type: .points, heading: "Points", size: .fixed([80])),
                    ScorecardColumn(type: .score, heading: "Score", size: .fixed([80])),
                    ScorecardColumn(type: .comment, heading: "Comment", size: .flexible)
                ]
                
                tableColumns = [
                    ScorecardColumn(type: .table, heading: "", size: .fixed([70, 30, 50])),
                    ScorecardColumn(type: .sitting, heading: "Sitting", size: .fixed([95, 70])),
                    ScorecardColumn(type: .tableScore, heading: "", size: .fixed([60, 80, 80])),
                    ScorecardColumn(type: .versus, heading: "Versus", size: .flexible)
                ]
            } else if MyApp.format == .phone {
                boardColumns = [
                    ScorecardColumn(type: .board, heading: "Board", size: .fixed([40])),
                    ScorecardColumn(type: .contract, heading: "Contract", size: .fixed([60])),
                    ScorecardColumn(type: .declarer, heading: "By", size: .fixed([50])),
                    ScorecardColumn(type: .made, heading: "Made", size: .fixed([50])),
                    ScorecardColumn(type: .score, heading: "Score", size: .fixed([60])),
                    ScorecardColumn(type: .comment, heading: "Comment", size: .flexible)
                ]
                
                tableColumns = [
                    ScorecardColumn(type: .table, heading: "", size: .fixed([40, 60])),
                    ScorecardColumn(type: .sitting, heading: "Sitting", size: .fixed([50, 50])),
                    ScorecardColumn(type: .tableScore, heading: "", size: .fixed([60])),
                    ScorecardColumn(type: .versus, heading: "", size: .flexible)
                ]
            } else {
                boardColumns = [
                    ScorecardColumn(type: .board, heading: "Board", size: .fixed([70])),
                    ScorecardColumn(type: .contract, heading: "Contract", size: .fixed([95])),
                    ScorecardColumn(type: .declarer, heading: "By", size: .fixed([70])),
                    ScorecardColumn(type: .made, heading: "Made", size: .fixed([60])),
                    ScorecardColumn(type: .score, heading: "Score", size: .fixed([80])),
                    ScorecardColumn(type: .responsible, heading: "Resp", size: .fixed([65])),
                    ScorecardColumn(type: .comment, heading: "Comment", size: .flexible)
                ]
                
                tableColumns = [
                    ScorecardColumn(type: .table, heading: "", size: .fixed([70, 95])),
                    ScorecardColumn(type: .sitting, heading: "Sitting", size: .fixed([70, 60])),
                    ScorecardColumn(type: .tableScore, heading: "", size: .fixed([80, 65])),
                    ScorecardColumn(type: .versus, heading: "Versus", size: .flexible)
                ]
            }
            self.detailView = detailView
            forceReload = true
            self.setNeedsLayout()
        }
    }
    
    public func showRankings() {
        let rankings = ScorecardRankingView(frame: CGRect())
        rankings.show(from: superview!.superview!) {
            self.disableBanner.wrappedValue = false
        }
    }
    
    // MARK: - Scorecard delegates
    
    internal var autoComplete = AutoComplete()
    
    internal func scorecardChanged(type: RowType, itemNumber: Int, column: ScorecardColumn?) {
        switch type {
        case .board:
            if let column = column {
                let section = (itemNumber - 1) / scorecard.boardsTable
                let row = (itemNumber - 1) % scorecard.boardsTable
                switch column.type {
                case .contract:
                        // Contract changed - update made and points
                    self.updateBoardCell(section: section, row: row, columnType: .declarer)
                    self.updateBoardCell(section: section, row: row, columnType: .made)
                    self.updateBoardCell(section: section, row: row, columnType: .points)
                case .made, .declarer:
                    self.updateBoardCell(section: section, row: row, columnType: .points)
                case .score:
                        // Score changed - update table score
                    self.updateScore(section: section)
                default:
                    break
                }
            }
            Scorecard.current.interimSave(entity: .board, itemNumber: itemNumber)

        case .table:
            if let column = column {
                let section = itemNumber - 1
                switch column.type {
                case .sitting:
                        // Sitting changed - update declarer and points etc
                    let boards = scorecard.boardsTable
                    for index in 1...boards {
                        let row = index - 1
                        self.updateBoardCell(section: section, row: row, columnType: .declarer)
                        self.updateBoardCell(section: section, row: row, columnType: .points)
                        self.updateBoardCell(section: section, row: row, columnType: .dealer)
                    }
                default:
                    break
                }
            }
            Scorecard.current.interimSave(entity: .table, itemNumber: itemNumber)
            
        default:
            break
        }
    }
    
    internal func scorecardCell(rowType: RowType, itemNumber: Int, columnType: ColumnType) -> ScorecardInputCollectionCell? {
        // Note this MUST be called from all undo registry closures as cell might have been re-used
        // by the time the undo triggers. Undo code must not reference self
        var cell: ScorecardInputCollectionCell?
        switch rowType {
        case .board:
            if let columnNumber = boardColumns.firstIndex(where: {$0.type == columnType}) {
                let section = (itemNumber - 1) / scorecard.boardsTable
                let row = (itemNumber - 1) % scorecard.boardsTable
                if let tableRow = mainTableView.cellForRow(at: IndexPath(row: row, section: section)) as? ScorecardInputBoardTableCell {
                    cell = tableRow.collectionView.cellForItem(at: IndexPath(item: columnNumber, section: 0)) as?
                    ScorecardInputCollectionCell
                }
            }
            
        case .table:
            if let columnNumber = tableColumns.firstIndex(where: {$0.type == columnType}) {
                let section = (itemNumber - 1)
                if let tableRow = mainTableView.headerView(forSection: section) as? ScorecardInputTableSectionHeaderView {
                    cell = tableRow.collectionView.cellForItem(at: IndexPath(item: columnNumber, section: 0)) as?
                    ScorecardInputCollectionCell
                }
            }
            
        default:
            break
        }
        return cell
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
        contractEntryView = ScorecardContractEntryView(frame: CGRect())
        let section = (board.board - 1) / self.scorecard.boardsTable
        let row = (board.board - 1) % self.scorecard.boardsTable
        disableBanner.wrappedValue = true
        contractEntryView.show(from: superview!.superview!, contract: board.contract, sitting: table.sitting, declarer: board.declarer) { (contract, declarer) in
            if let contract = contract {
                if let tableCell = self.mainTableView.cellForRow(at: IndexPath(row: row, section: section)) as? ScorecardInputBoardTableCell {
                    if contract != board.contract || declarer != board.declarer {
                        // Update contract and/or declarer
                        if let item = self.boardColumns.firstIndex(where: {$0.type == .contract}) {
                            if let cell = tableCell.collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? ScorecardInputCollectionCell {
                                cell.label.text = contract.string
                                cell.contractDidChange(to: contract, declarer: declarer)
                            }
                        }
                    }
                }
            }
            self.disableBanner.wrappedValue = false
        }
    }
    
    func scorecardBBONamesReplace(values: [String]) {
        if scorecard.importSource == .bbo {
            let editValues = MasterData.shared.getBboNames(values: values)
            ignoreKeyboard = true
            let bboNameReplaceView = BBONameReplaceView(frame: CGRect())
            disableBanner.wrappedValue = true
            bboNameReplaceView.show(from: self.superview!.superview!, values: editValues) {
                self.disableBanner.wrappedValue = false
                self.ignoreKeyboard = false
                self.tableRefresh()
            }
        }
    }
    
    func scorecardShowTraveller(scorecard: ScorecardViewModel, board: BoardViewModel, sitting: Seat) {
        if !Scorecard.current.travellerList.isEmpty {
            let showTraverllerView = ScorecardTravellerView(frame: CGRect())
            disableBanner.wrappedValue = true
            showTraverllerView.show(from: superview!.superview!, boardNumber: board.board, sitting: sitting) {
                self.disableBanner.wrappedValue = false
            }
        }
    }
    
    func scorecardShowHand(scorecard: ScorecardViewModel, board: BoardViewModel, sitting: Seat) {
        if !Scorecard.current.travellerList.isEmpty {
            if let scorer = MasterData.shared.scorer {
                let rankings = Scorecard.current.rankings(table: board.tableNumber, player: (bboName:scorer.bboName, name: scorer.name))
                if let myRanking = rankings.first {
                    if let traveller = Scorecard.current.traveller(board: board.board, seat: sitting, rankingNumber: myRanking.number, section: myRanking.section) {
                        disableBanner.wrappedValue = true
                        Scorecard.showHand(from: self, traveller: traveller) {
                            self.disableBanner.wrappedValue = false
                        }
                    }
                }
            }
        }
    }
    
    func scorecardScrollPickerPopup(values: [ScrollPickerEntry], maxValues: Int, selected: Int?, defaultValue: Int?, frame: CGRect, in container: UIView, topPadding: CGFloat, bottomPadding: CGFloat, completion: @escaping (Int?)->()) {
        scrollPickerPopupView.show(from: self, values: values, maxValues: maxValues, selected: selected, defaultValue: defaultValue, frame: container.convert(frame, to: self), topPadding: topPadding, bottomPadding: bottomPadding) { (selected) in
            completion(selected)
        }
    }
    
    func scorecardDeclarerPickerPopup(values: [(Seat, ScrollPickerEntry)], selected: Seat?, frame: CGRect, in container: UIView, topPadding: CGFloat, bottomPadding: CGFloat, completion: @escaping (Seat?)->()) {
        var frame = container.convert(frame, to: self)
        let freeSpace = self.mainTableView.frame.maxY - frame.maxY
        let offset = mainTableView.contentOffset
        if freeSpace < frame.height {
            // Need to scroll down a row
            let adjustY = frame.height - freeSpace
            mainTableView.contentOffset = offset.offsetBy(dy: adjustY)
            frame = frame.offsetBy(dy: -adjustY)
        }
        declarerPickerPopupView.show(from: self, values: values, selected: selected, frame: frame, topPadding: topPadding, bottomPadding: bottomPadding) { (selected) in
            self.mainTableView.contentOffset = offset
            completion(selected)
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
    
    func scorecardSelectScore(boardNumber: Int) {
        if boardNumber <= scorecard.boards {
            let section = (boardNumber - 1) / self.scorecard.boardsTable
            let row = (boardNumber - 1) % self.scorecard.boardsTable
            if let tableCell = self.mainTableView.cellForRow(at: IndexPath(row: row, section: section)) as? ScorecardInputBoardTableCell {
                // Update contract and/or declarer
                if let item = self.boardColumns.firstIndex(where: {$0.type == .score}) {
                    if let cell = tableCell.collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? ScorecardInputCollectionCell {
                        cell.textField.becomeFirstResponder()
                    }
                }
            }
        }
    }
    
    func scorecardEndEditing(_ force: Bool) {
        self.endEditing(force)
    }
    
    var scorecardMainTableView: UITableView {
        self.mainTableView
    }
    
    var scorecardBoardColumns: [ScorecardColumn] {
        boardColumns
    }
    
    var scorecardTableColumns: [ScorecardColumn] {
        tableColumns
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        autoComplete.isHidden = true
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
                let cell = ScorecardInputCollectionCell.dequeue(collectionView, for: indexPath)
                let boardNumber = collectionView.tag % tagMultiplier
                if let board = Scorecard.current.boards[boardNumber] {
                    let tableNumber = ((boardNumber - 1) / scorecard.boardsTable) + 1
                    if let table = Scorecard.current.tables[tableNumber] {
                        let column = boardColumns[indexPath.item]
                        cell.set(from: self, scorecard: scorecard, table: table, board: board, itemNumber: boardNumber, rowType: .board, column: column)
                    }
                }
                return cell
            case .boardTitle:
                let cell = ScorecardInputCollectionCell.dequeue(collectionView, for: indexPath)
                let column = boardColumns[indexPath.item]
                cell.setTitle(column: column, scorecard: scorecard)
                return cell
            case .table:
                let cell = ScorecardInputCollectionCell.dequeue(collectionView, for: indexPath)
                let tableNumber = collectionView.tag % tagMultiplier
                if let table = Scorecard.current.tables[tableNumber] {
                    let column = tableColumns[indexPath.item]
                    cell.set(from: self, scorecard: scorecard, table: table, itemNumber: tableNumber, rowType: .table, column: column)
                }
                return cell
            }
        } else {
            fatalError()
        }
    }
    
    // MARK: - Utility Routines ======================================================================== -
    
    func keyboardMoved(_ keyboardHeight: CGFloat) {
        if !ignoreKeyboard {
            self.keyboardHeight = keyboardHeight
            if !inputDetail && (keyboardHeight != 0 || isKeyboardOffset) {
                let focusedTextInputBottom = (UIResponder.currentFirstResponder?.globalFrame?.maxY ?? 0)
                let adjustOffset = max(0, focusedTextInputBottom - keyboardHeight) + safeAreaInsets.bottom
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
            }
        }
    }
    
    func setupSizes(columns: inout [ScorecardColumn]) {
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
            factor = min(1.3, mainTableView.frame.width / mainTableView.frame.height)
        }
        
        let availableSize = frame.width - safeAreaInsets.left - safeAreaInsets.right
        let fixedSize = fixedWidth * factor
        let flexibleSize = (availableSize - fixedSize) / CGFloat(flexible)
        
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
        columns[columns.count - 1].width = remainingWidth
    }
    
    public static func numericValue(_ text: String) -> Float? {
        let numericText = text.uppercased()
                              .replacingOccurrences(of: "O", with: "0")
                              .replacingOccurrences(of: "I", with: "1")
                              .replacingOccurrences(of: "L", with: "1")
                              .replacingOccurrences(of: "Z", with: "2")
                              .replacingOccurrences(of: "S", with: "5")
                              .replacingOccurrences(of: "_", with: "-")
        return Float(numericText)
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
        ScorecardInputCollectionCell.register(collectionView)
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
        ScorecardInputCollectionCell.register(self.collectionView)
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

class ScorecardInputBoardTableCell: TableViewCellWithCollectionView {
    
    private static let cellIdentifier = "Board Table Cell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        ScorecardInputCollectionCell.register(self.collectionView)
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

class ScorecardInputCollectionCell: UICollectionViewCell, ScrollPickerDelegate, EnumPickerDelegate, UITextViewDelegate, UITextFieldDelegate, AutoCompleteDelegate {
    fileprivate var label = UILabel()
    fileprivate var caption = UILabel()
    fileprivate var textField = UITextField()
    private var textView = UITextView()
    private var textClear = UIImageView()
    private var textClearWidth: NSLayoutConstraint!
    private var textClearPadding: [NSLayoutConstraint]!
    private var responsiblePicker: EnumPicker<Responsible>!
    fileprivate var declarerPicker: ScrollPicker!
    fileprivate var seatPicker: EnumPicker<Seat>!
    private var madePicker: ScrollPicker!
    private var table: TableViewModel!
    private var board: BoardViewModel!
    fileprivate var itemNumber: Int!
    fileprivate var rowType: RowType!
    private var column: ScorecardColumn!
    private var scorecardDelegate: ScorecardDelegate?
    private static let identifier = "Grid Collection Cell"
    private var captionHeight: NSLayoutConstraint!
    
    private var scorecard: ScorecardViewModel!
    
    override init(frame: CGRect) {
        responsiblePicker = EnumPicker(frame: frame)
        declarerPicker = ScrollPicker(frame: frame)
        seatPicker = EnumPicker(frame: frame)
        madePicker = ScrollPicker(frame: frame)
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(Palette.gridTable.background)
                
        let endEditingGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputCollectionCell.endEditingTapped))
        self.addGestureRecognizer(endEditingGesture)
        
        addSubview(label, constant: 2, anchored: .leading, .trailing, .bottom)
        label.textAlignment = .center
        label.minimumScaleFactor = 0.3
        label.adjustsFontSizeToFitWidth = true
        let labelTapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputCollectionCell.labelTapped(_:)))
        label.addGestureRecognizer(labelTapGesture)
         
        addSubview(textField, constant: 8, anchored: .leading, .top, .bottom)
        textField.textAlignment = .center
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.font = cellFont
        textField.delegate = self
        textField.addTarget(self, action: #selector(ScorecardInputCollectionCell.textFieldChanged), for: .editingChanged)
        textField.backgroundColor = UIColor.clear
        textField.borderStyle = .none
        textField.adjustsFontSizeToFitWidth = true
        textField.returnKeyType = .done
               
        addSubview(textView, constant: 8, anchored: .leading, .top, .bottom)
        textView.textAlignment = .left
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.font = cellFont
        textView.delegate = self
        textView.backgroundColor = UIColor.clear
        
        addSubview(textClear, constant: 8, anchored: .trailing, .top, .bottom)
        textClearWidth = Constraint.setWidth(control: textClear, width: 0)
        textClearPadding = Constraint.anchor(view: self, control: textField, to: textClear, constant: 8, toAttribute: .leading, attributes: .trailing)
        textClearPadding.append(contentsOf: Constraint.anchor(view: self, control: textView, to: textClear, constant: 8, toAttribute: .leading, attributes: .trailing))
        textClear.image = UIImage(systemName: "x.circle.fill")?.asTemplate
        textClear.tintColor = UIColor(Palette.clearText)
        textClear.contentMode = .scaleAspectFit
        let textClearTapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputCollectionCell.textViewClearPressed))
        textClear.addGestureRecognizer(textClearTapGesture)
        textClear.isUserInteractionEnabled = true
        
        addSubview(declarerPicker, top: 16, bottom: 0)
        Constraint.setWidth(control: declarerPicker, width: 60)
        Constraint.anchor(view: self, control: declarerPicker, attributes: .centerX)
        declarerPicker.delegate = self
        let declarerTapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputCollectionCell.declarerTapped))
        declarerPicker.addGestureRecognizer(declarerTapGesture)
        
        addSubview(seatPicker, top: 20, bottom: 4)
        Constraint.setWidth(control: seatPicker, width: 60)
        Constraint.anchor(view: self, control: seatPicker, attributes: .centerX)
        seatPicker.delegate = self
        let seatGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputCollectionCell.seatPickerTapped))
        seatPicker.addGestureRecognizer(seatGesture)

        addSubview(madePicker, top: 16, bottom: 0)
        Constraint.setWidth(control: madePicker, width: 60)
        Constraint.anchor(view: self, control: madePicker, attributes: .centerX)
        madePicker.delegate = self
        let madeTapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputCollectionCell.madeTapped))
        madePicker.addGestureRecognizer(madeTapGesture)
        
        addSubview(responsiblePicker, top: 16, bottom: 0)
        Constraint.setWidth(control: responsiblePicker, width: 60)
        Constraint.anchor(view: self, control: responsiblePicker, attributes: .centerX)
        responsiblePicker.delegate = self
        let responsibleTapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputCollectionCell.responsibleTapped))
        responsiblePicker.addGestureRecognizer(responsibleTapGesture)
        
        addSubview(caption, anchored: .leading, .trailing, .top)
        caption.textAlignment = .center
        caption.font = titleCaptionFont
        caption.minimumScaleFactor = 0.3
        caption.backgroundColor = UIColor.clear
        caption.textColor = UIColor(Palette.gridBoard.text)
        captionHeight = Constraint.setHeight(control: caption, height: 0)
        Constraint.anchor(view: self, control: label, to: caption, constant: 0, toAttribute: .bottom, attributes: .top)
        
        Constraint.addGridLine(self, sides: .leading, .trailing, .top, .bottom)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ collectionView: UICollectionView) {
        collectionView.register(ScorecardInputCollectionCell.self, forCellWithReuseIdentifier: identifier)
    }

    public class func dequeue(_ collectionView: UICollectionView, for indexPath: IndexPath) -> ScorecardInputCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ScorecardInputCollectionCell
        cell.prepareForReuse()
        return cell
    }
    
    override func prepareForReuse() {
        board = nil
        itemNumber = nil
        column = nil
        caption.isHidden = true
        captionHeight.constant = 0
        textField.isHidden = true
        declarerPicker.isHidden = true
        seatPicker.isHidden = true
        responsiblePicker.isHidden = true
        madePicker.isHidden = true
        textField.isHidden = true
        textField.textAlignment = .center
        textField.clearsOnBeginEditing = false
        textField.clearButtonMode = .never
        textField.font = cellFont
        textField.keyboardType = .default
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.isEnabled = true
        textView.isHidden = true
        textClear.isHidden = true
        textClearWidth.constant = 0
        textClearPadding.forEach { (constraint) in constraint.constant = 0 }
        textField.text = ""
        textView.text = ""
        textView.font = cellFont
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor(Palette.background.text)
        label.text = ""
        label.font = cellFont
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.numberOfLines = 1
        label.lineBreakMode = .byWordWrapping
    }
    
    func setTitle(column: ScorecardColumn, scorecard: ScorecardViewModel) {
        self.board = nil
        self.column = column
        label.backgroundColor = UIColor(Palette.gridTitle.background)
        label.textColor = UIColor(Palette.gridTitle.text)
        label.font = titleFont.bold
        if column.type == .score {
            label.text = scorecard.type.boardScoreType.string
        } else {
            label.text = column.heading
        }
    }
    
    func set(from scorecardDelegate: ScorecardDelegate, scorecard: ScorecardViewModel, table: TableViewModel, board: BoardViewModel! = nil, itemNumber: Int, rowType: RowType, column: ScorecardColumn) {
        self.scorecard = scorecard
        self.scorecardDelegate = scorecardDelegate
        self.board = board
        self.table = table
        self.itemNumber = itemNumber
        self.rowType = rowType
        self.column = column
        
        var isEnabled = false
        switch column.type {
        case .board, .table, .vulnerable, .dealer, .points:
            isEnabled = false
        case .declarer:
            isEnabled = (table.sitting != .unknown && !Scorecard.current.isImported)
        case .made:
            isEnabled = board.contract.suit.valid && !Scorecard.current.isImported
        case .score, .versus, .sitting, .contract:
            isEnabled = !Scorecard.current.isImported
        default:
            break
        }
        
        let color = (rowType == .board ? (isEnabled ? Palette.gridBoard : Palette.gridBoardDisabled)
                                       : (isEnabled ? Palette.gridTable : Palette.gridTableDisabled))
        label.backgroundColor = UIColor(color.background)
        label.textColor = UIColor(color.text)
        textField.textColor = UIColor(color.text)
        textView.textColor = UIColor(color.text)

        label.tag = column.type.rawValue
        
        switch column.type {
        case .board:
            label.font = boardFont
            label.text = "\(scorecard.resetNumbers ? ((board.board - 1) % scorecard.boardsTable) + 1 : board.board)"
            label.isUserInteractionEnabled = !isEnabled
        case .vulnerable:
            label.isHidden = false
            label.font = titleFont.bold
            label.text = board.vulnerability.string
            label.isUserInteractionEnabled = !isEnabled
        case .dealer:
            seatPicker.isHidden = false
            seatPicker.set(board.dealer, isEnabled: false, color: color, titleFont: pickerTitleFont)
            seatPicker.isUserInteractionEnabled = false
            label.isUserInteractionEnabled = !isEnabled
        case .contract:
            label.isHidden = false
            label.text = board.contract.string
            label.isUserInteractionEnabled = true
        case .declarer:
            declarerPicker.isHidden = false
            let selected = declarerList.firstIndex(where: {$0.seat == board.declarer}) ?? 0
            declarerPicker.set(selected, list: declarerList.map{$0.entry}, isEnabled: isEnabled, color: color, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
            label.isUserInteractionEnabled = !isEnabled
        case .made:
            madePicker.isHidden = false
            let (list, minValue, maxValue) = madeList
            if let made = board.made {
                if made < minValue {
                    board.made = minValue
                } else if made > maxValue {
                    board.made = maxValue
                }
            }
            let makingValue = (6 + board.contract.level.rawValue)
            madePicker.set(board.made == nil ? nil : board.made! - minValue, list: list, defaultEntry: ScrollPickerEntry(caption: "Unknown"), defaultValue: min(list.count - 1, makingValue), isEnabled: isEnabled, color: color, titleFont: pickerTitleFont)
            label.isUserInteractionEnabled = !isEnabled
        case .score:
            textField.isHidden = false
            textField.keyboardType = .numbersAndPunctuation
            textField.clearsOnBeginEditing = true
            textField.text = board.score == nil ? "" : "\(board.score!.toString(places: scorecard.type.boardPlaces))"
            textField.isEnabled = isEnabled
            label.isUserInteractionEnabled = !isEnabled
        case .points:
            if board.declarer == .unknown {
                label.text = ""
            } else {
                let points = board.points(seat: table.sitting)
                label.text = (points == nil ? "" : "\(points! > 0 ? "+" : "")\(points!)")
            }
            label.isUserInteractionEnabled = !isEnabled
        case .comment:
            textField.isHidden = false
            textField.text = board.comment
            textField.textAlignment = .left
            textField.autocapitalizationType = .sentences
            textClear.isHidden = board.comment == ""
            textClearWidth.constant = 34
            textClearPadding.forEach { (constraint) in constraint.constant = 8 }
        case .responsible:
            responsiblePicker.isHidden = false
            responsiblePicker.set(board.responsible, color: Palette.gridBoard, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
        case .table:
            label.font = boardTitleFont.bold
            label.text = "Round \(table.table)"
        case .sitting:
            seatPicker.isHidden = false
            seatPicker.set(table.sitting, isEnabled: isEnabled, color: color, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
        case .tableScore:
            if scorecard.manualTotals {
                textField.isHidden = false
                textField.keyboardType = .numbersAndPunctuation
                textField.clearsOnBeginEditing = true
                textField.text = table.score == nil ? "" : "\(table.score!.toString(places: scorecard.type.tablePlaces))"
            } else {
                label.text = table.score == nil ? "" : "\(table.score!.toString(places: scorecard.type.tablePlaces))"
            }
        case .versus:
            if Scorecard.current.isImported {
                label.isHidden = false
                label.text = importedVersus
                label.isUserInteractionEnabled = true
                label.numberOfLines = 2
                label.font = (scorecard.type.players == 1 ? smallCellFont : cellFont)
            } else {
                textField.isHidden = false
                textField.text = table.versus
                textField.textAlignment = (isEnabled ? .left : .center)
                textField.autocapitalizationType = .words
                textField.isEnabled = isEnabled
                textField.font = (scorecard.type.players == 1 ? smallCellFont : cellFont)
                textClear.isHidden = (!isEnabled || table.versus == "")
                textClearWidth.constant = 34
                textClearPadding.forEach { (constraint) in constraint.constant = 8 }
            }
        }
        
        if rowType == .table && column.heading != "" {
            caption.isHidden = false
            captionHeight.constant = 24
            caption.text = column.heading
        }
    }
    
    private var importedVersus: String {
        var versus = ""
        let players = table.players
        let sitting = table.sitting
        var separator = ""
        for seat in [sitting.partner, sitting.leftOpponent, sitting.rightOpponent] {
            if scorecard.type.players == 1 || seat != sitting.partner {
                let bboName = players[seat] ?? "Unknown"
                let realName = MasterData.shared.realName(bboName: bboName) ?? bboName
                versus += separator + realName
                separator = (seat == sitting.partner ? " v " : " & ")
            }
        }
        return versus
    }
    
    private var madeList: (list: [ScrollPickerEntry], minValue: Int, maxValue: Int) {
        var list: [ScrollPickerEntry] = []
        var minValue = 0
        var maxValue = 0
        if board.contract.suit != .blank {
            let tricks = board.contract.level.rawValue
            minValue = -(6 + tricks)
            maxValue = 7 - tricks
            for made in 0...13 {
                let plusMinus = made - 6 - tricks
                var value = ""
                switch true {
                case plusMinus < 0:
                    value = "\(plusMinus)"
                case plusMinus == 0:
                    value = "="
                case plusMinus > 0:
                    value = "+\(plusMinus)"
                default:
                    break
                }
                list.append(ScrollPickerEntry(title: value, caption: "Made \(made)"))
            }
        }
        if list.count == 0 {
            list.append(ScrollPickerEntry())
        }
        return (list, minValue, maxValue)
    }
    
    public var declarerList: [(seat: Seat, entry: ScrollPickerEntry)] {
        return Scorecard.declarerList(sitting: table.sitting)
    }
    
    public var orderedDeclarerList: [(seat: Seat, entry: ScrollPickerEntry)] {
        return Scorecard.orderedDeclarerList(sitting: table.sitting)
    }
        
    // MARK: - Control change handlers ===================================================================== -
        
    @objc private func textFieldChanged(_ textField: UITextField) {
        let text = textField.text ?? ""
        var undoText: String?
        let rowType = rowType!
        let columnType = column.type
        let itemNumber = itemNumber!
        switch columnType {
        case .comment:
            undoText = board.comment
        case .versus:
            undoText = table.versus
        case .score:
            undoText = board.score == nil ? "" : "\(board.score!)"
        case .tableScore:
            undoText = table.score == nil ? "" : "\(table.score!)"
        default:
            break
        }
        if let undoText = undoText {
            if text != undoText {
                UndoManager.registerUndo(withTarget: self) { (_) in
                    if let cell = self.scorecardDelegate?.scorecardCell(rowType: rowType, itemNumber: itemNumber, columnType: columnType) {
                        cell.textField.text = undoText
                        cell.textFieldChanged(cell.textField)
                    }
                }
                switch columnType {
                case .comment:
                    board.comment = text
                    textClear.isHidden = (text == "")
                case .versus:
                    table.versus = text
                    textClear.isHidden = (text == "")
                case .score:
                    board.score = ScorecardInputUIView.numericValue(text)
                case .tableScore:
                    table.score = ScorecardInputUIView.numericValue(text)
                default:
                    break
                }
                scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber, column: column)
            }
        }
    }
    
    internal func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if column.type == .versus {
            if range.location + range.length == textField.text?.count {
                let result = (textField.text! as NSString).replacingCharacters(in: range, with: string)
                if let last = result.components(separatedBy: " ").last {
                    if let autoComplete = scorecardDelegate?.autoComplete {
                        autoComplete.delegate = self
                        let listSize = autoComplete.set(text: last, in: textField, at: NSRange(location: result.length - last.length, length: last.length))
                        let height = CGFloat(min(5, listSize) * 40)
                        var point = self.superview!.convert(CGPoint(x: frame.minX, y: frame.maxY), to: autoComplete.superview!)
                        if point.y + 200 >= UIScreen.main.bounds.height - (scorecardDelegate?.keyboardHeight ?? 0) {
                            point = point.offsetBy(dy: -frame.height - height)
                        }
                        autoComplete.frame = CGRect(x: point.x, y: point.y, width: self.frame.width, height: height)
                    }
                }
            }
        }
        return true
    }
    
    internal func replace(with text: String, in textField: UITextField, at range: NSRange) {
        textField.text = (textField.text! as NSString).replacingCharacters(in: range, with: text + (range.location == 0 ? " & " : ""))
        textFieldChanged(textField)
        scorecardDelegate?.autoComplete.delegate = nil
        scorecardDelegate?.autoComplete.isHidden = true
    }
    
    internal func textFieldDidEndEditing(_ textField: UITextField) {
        let text = textField.text ?? ""
        var places: Int?
        switch column.type {
        case .score:
            places = scorecard.type.boardPlaces
        case .tableScore:
            places = scorecard.type.tablePlaces
        default:
            break
        }
        if let places = places {
            let score = ScorecardInputUIView.numericValue(text)
            let newText = (score == nil ? "" : "\(score!.toString(places: places))")
            if newText != textField.text {
                textField.text = newText
                textFieldChanged(textField)
            }
        }
        scorecardDelegate?.autoComplete.isHidden = true
        textField.resignFirstResponder()
    }
    
    internal func textFieldDidBeginEditing(_ textField: UITextField) {
        // Record automatic clear on entry in undo
        var clear = false
        switch column.type {
        case .score:
            clear = board.score != nil
        case .tableScore:
            clear = table.score != nil
        default:
            break
        }
        if clear {
            textFieldChanged(textField)
        }
    }
    
    internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        switch column.type {
        case .score:
            scorecardDelegate?.scorecardSelectScore(boardNumber: board.board + 1)
        default:
            break
        }
        return true
    }
    
    internal func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""
        var undoText: String?
        let rowType = rowType!
        let columnType = column.type
        let itemNumber = itemNumber!
        switch columnType {
        case .comment:
            undoText = board.comment
        case .versus:
            undoText = table.versus
        default:
            break
        }
        if let undoText = undoText {
            if text != undoText {
                UndoManager.registerUndo(withTarget: self) { (_) in
                    if let cell = self.scorecardDelegate?.scorecardCell(rowType: rowType, itemNumber: itemNumber, columnType: columnType) {
                        cell.textView.text = undoText
                        cell.textViewDidChange(cell.textView)
                    }
                }
                switch column.type {
                case .comment:
                    board.comment = text
                case .versus:
                    table.versus = text
                default:
                    break
                }
                textClear.isHidden = (text == "")
                scorecardDelegate?.scorecardChanged(type: .board, itemNumber: itemNumber, column: column)
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
        var text: String?
        switch self.column.type {
        case .comment:
            text = board.comment
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
    
    internal func enumPickerDidChange(to value: Any) {
        var undoValue: Any?
        let rowType = rowType!
        let columnType = column.type
        let itemNumber = itemNumber!
        switch columnType {
        case .responsible:
            if value as? Responsible != board.responsible {
                undoValue = board.responsible
            }
        case .sitting:
            if value as? Seat != table.sitting {
                undoValue = table.sitting
            }
        default:
            break
        }
        if let undoValue = undoValue {
            UndoManager.registerUndo(withTarget: responsiblePicker) { (responsiblePicker) in
                if let cell = self.scorecardDelegate?.scorecardCell(rowType: rowType, itemNumber: itemNumber, columnType: columnType) {
                    switch columnType {
                    case .responsible:
                        cell.responsiblePicker.set(undoValue as! Responsible)
                        cell.enumPickerDidChange(to: undoValue)
                    case .sitting:
                        cell.seatPicker.set(undoValue as! Seat)
                        cell.enumPickerDidChange(to: undoValue)
                    default:
                        break
                    }
                }
            }
            switch columnType {
            case .responsible:
                board.responsible = value as! Responsible
            case .sitting:
                table.sitting = value as! Seat
            default:
                break
            }
            scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber, column: column)
        }
    }
    
    internal func contractDidChange(to value: Contract, made: Int? = nil, declarer: Seat? = nil) {
        if let board = board {
            let undoValue = board.contract
            let made = made ?? board.made
            let declarer = declarer ?? board.declarer
            let undoMade = board.made
            let undoDeclarer = board.declarer
            let rowType = rowType!
            let columnType = column.type
            let itemNumber = itemNumber!
            if value != undoValue || made != undoMade || declarer != undoDeclarer {
                UndoManager.registerUndo(withTarget: label) { (label) in
                    if let cell = self.scorecardDelegate?.scorecardCell(rowType: rowType, itemNumber: itemNumber, columnType: columnType) {
                        cell.label.text = undoValue.string
                        cell.board.made = made
                        cell.board.declarer = declarer
                        cell.contractDidChange(to: undoValue, made: undoMade, declarer: undoDeclarer)
                    }
                }
                board.contract = value
                board.made = made
                board.declarer = declarer
                scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber, column: column)
            }
        }
    }

    @objc internal func labelTapped(_ sender: UITapGestureRecognizer) {
        if let column = ColumnType(rawValue: sender.view?.tag ?? -1) {
            switch column {
            case .contract:
                if !Scorecard.current.isImported {
                    contractTapped(self)
                } else {
                    showHand()
                }
            case .versus:
                versusTapped(self)
            case .score:
                scoreTapped(self)
            default:
                if Scorecard.current.isImported {
                    showHand()
                }
            }
        }
    }
    
    @objc internal func contractTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: .board, itemNumber: itemNumber)
        scorecardDelegate?.scorecardContractEntry(board: board, table: table)
    }
    
    @objc internal func scoreTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: .board, itemNumber: itemNumber)
        scorecardDelegate?.scorecardShowTraveller(scorecard: scorecard, board: board, sitting: table.sitting)
    }
    
    @objc internal func versusTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: .board, itemNumber: itemNumber)
    
        if scorecard.importSource == .bbo {
            var values: [String] = []
            let players = table.players
            let sitting = table.sitting
            for seat in [sitting.partner, sitting.leftOpponent, sitting.rightOpponent] {
                if scorecard.type.players == 1 || seat != sitting.partner {
                    if let player = players[seat] {
                        values.append(player)
                    }
                }
            }
            
            if !values.isEmpty {
                scorecardDelegate?.scorecardBBONamesReplace(values: values)
            }
        }
    }
    
    @objc internal func declarerTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber)
        if table.sitting != .unknown {
            scorecardDelegate?.scorecardDeclarerPickerPopup(values: orderedDeclarerList, selected: board.declarer, frame: self.frame, in: self.superview!, topPadding: 20, bottomPadding: 4) { (selected) in
                if let index = self.declarerList.firstIndex(where: {$0.seat == selected}) {
                    self.declarerPicker.set(index)
                    self.scrollPickerDidChange(to: index)
                }
            }
        }
    }

    @objc internal func seatPickerTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber)
        let width: CGFloat = (MyApp.format == .phone ? 50 : 70)
        let space = (frame.width - width) / 2
        if !Scorecard.current.isImported {
            let selected = Seat.allCases.firstIndex(where: {$0 == table.sitting}) ?? 0
            scorecardDelegate?.scorecardScrollPickerPopup(values: Seat.allCases.map{ScrollPickerEntry(title: $0.short, caption: $0.string)}, maxValues: 9, selected: selected, defaultValue: nil, frame: CGRect(x: self.frame.minX + space, y: self.frame.minY, width: width, height: self.frame.height), in: self.superview!, topPadding: 20, bottomPadding: 4) { (selected) in
                let seat = Seat.allCases[selected!]
                self.seatPicker.set(seat)
                self.enumPickerDidChange(to: seat)
            }
        }
    }
    
    @objc internal func madeTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber)
        let (madeList, _, _) = madeList
        let width: CGFloat = min(frame.width, 70)
        let space = (frame.width - width) / 2
        let makingValue = (6 + board.contract.level.rawValue)
        let selected = board.made == nil ? nil : board.made! + makingValue
        scorecardDelegate?.scorecardScrollPickerPopup(values: madeList, maxValues: 9, selected: selected, defaultValue: makingValue, frame: CGRect(x: self.frame.minX + space, y: self.frame.minY, width: width, height: self.frame.height), in: self.superview!, topPadding: 16, bottomPadding: 0) { (selected) in
            self.madePicker.set(selected, reload: self.board.made == nil || selected == nil)
            self.scrollPickerDidChange(self.madePicker, to: selected)
        }
    }
    
    @objc internal func responsibleTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber)
        let width: CGFloat = 70
        let space = (frame.width - width) / 2
        let selected = board.responsible.rawValue + 3
        scorecardDelegate?.scorecardScrollPickerPopup(values: Responsible.allCases.map{ScrollPickerEntry(title: $0.short, caption: $0.full)}, maxValues: 13, selected: selected, defaultValue: nil, frame: CGRect(x: self.frame.minX + space, y: self.frame.minY, width: width, height: self.frame.height), in: self.superview!, topPadding: 16, bottomPadding: 0) { (selected) in
            if let responsible = Responsible(rawValue: selected! - 3) {
                self.responsiblePicker.set(responsible)
                self.enumPickerDidChange(to: responsible)
            }
        }
    }
    
    private func showHand() {
        scorecardDelegate?.scorecardShowHand(scorecard: scorecard, board: board, sitting: table.sitting)
    }
    
    @nonobjc internal func scrollPickerDidChange(_ picker: ScrollPicker? = nil, to value: Int?) {
        var undoValue: Int?
        var found = true
        let rowType = rowType!
        let columnType = column.type
        let itemNumber = itemNumber!
        switch columnType {
        case .declarer:
            undoValue = declarerList.firstIndex(where: {$0.seat == board.declarer})!
        case .made:
            undoValue = board.made == nil ? nil : board.made! + (6 + board.contract.level.rawValue)
        default:
            found = false
        }
        if found {
            if undoValue != value {
                UndoManager.registerUndo(withTarget: self) { (_) in
                    if let cell = self.scorecardDelegate?.scorecardCell(rowType: rowType, itemNumber: itemNumber, columnType: columnType) {
                        var picker: ScrollPicker?
                        switch columnType {
                        case .declarer:
                            picker = cell.declarerPicker
                        case .made:
                            picker = cell.madePicker
                        default:
                            break
                        }
                        picker?.set(undoValue)
                        cell.scrollPickerDidChange(picker, to: undoValue)
                    }
                }
                switch columnType {
                case .declarer:
                    board.declarer = declarerList[value!].seat
                case .made:
                    board.made =  (value == nil ? nil : value! - (6 + board.contract.level.rawValue))
                default:
                    break
                }
                scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber, column: column)
            }
        }
    }
    
    @objc internal func endEditingTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber)
    }
}

protocol AutoCompleteDelegate {
    func replace(with: String, in textField: UITextField, at range: NSRange)
}

class AutoComplete: UIView, UITableViewDataSource, UITableViewDelegate {
    var tableView = UITableView()
    var text: String = ""
    var nameList: [BBONameViewModel] = []
    var textField: UITextField!
    var range: NSRange!
    var delegate: AutoCompleteDelegate?
    
    init() {
        super.init(frame: CGRect.zero)
        addSubview(tableView, leading: 2, trailing: 2, top: 2, bottom: 2)
        AutoCompleteCell.register(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
       
    public func set(text: String, in textField: UITextField, at range: NSRange) -> Int {
        self.text = text.lowercased()
        self.textField = textField
        self.range = range
        if self.text == "" {
            nameList = []
        } else {
            nameList = MasterData.shared.bboNames.filter({$0.bboName.starts(with: self.text)})
        }
        self.isHidden = nameList.isEmpty
        self.tableView.reloadData()
        return nameList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = AutoCompleteCell.dequeue(tableView: tableView, for: indexPath)
        cell.set(text: nameList[indexPath.row].bboName)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.replace(with: nameList[indexPath.row].name, in: textField, at: range)
    }
}

class AutoCompleteCell: UITableViewCell {
    private var label = UILabel()
    static public var cellIdentifier = "Auto Complete Cell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(label, leading: 8, trailing: 8, top: 0, bottom: 0)
        self.backgroundColor = UIColor(Palette.autoComplete.background)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    public class func register(_ tableView: UITableView, forTitle: Bool = false) {
        tableView.register(AutoCompleteCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    public class func dequeue(tableView: UITableView, for indexPath: IndexPath) -> AutoCompleteCell {
        return tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! AutoCompleteCell
    }
    
    public func set(text: String) {
        label.text = text
        label.font = cellFont
        label.textColor = UIColor(Palette.autoComplete.text)
    }
}
