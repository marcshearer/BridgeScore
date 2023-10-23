//
//  Scorecard Input View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 11/02/2022.
//

import UIKit
import SwiftUI
import Combine

public class ScorecardColumn: Codable, Equatable {
    var type: ColumnType
    var heading: String
    var size: ColumnSize
    var phoneSize: ColumnSize
    var omit: Bool
    var width: CGFloat?
    
    init(type: ColumnType, heading: String, size: ColumnSize, phoneSize: ColumnSize? = nil, omit: Bool = false, width: CGFloat? = nil) {
        self.type = type
        self.heading = heading
        self.size = size
        self.phoneSize = phoneSize ?? size
        self.omit = omit
        self.width = width
    }
    
    public static func == (lhs: ScorecardColumn, rhs: ScorecardColumn) -> Bool {
        return lhs.type == rhs.type && lhs.heading == rhs.heading && lhs.size == rhs.size && lhs.phoneSize == rhs.phoneSize && lhs.omit == rhs.omit && lhs.width == rhs.width
    }
    
    var copy: ScorecardColumn {
        ScorecardColumn(type: type, heading: heading, size: size, phoneSize: phoneSize, omit: omit, width: width)
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

// Scorecard view types
enum ColumnType: Int, Codable {
    case table = 0
    case sitting = 1
    case tableScore = 2
    case versus = 3
    case board = 4
    case contract = 5
    case declarer = 6
    case made = 7
    case points = 8
    case score = 9
    case comment = 10
    case responsible = 11
    case vulnerable = 12
    case dealer = 13
    case teamTable = 14
    case analysis1 = 15
    case analysis2 = 16
    case commentAvailable = 17
    case combined = 18
}

// Controls that need tap gesture
enum TapControl {
    case label
    case textFieldClear
    case textViewClear
    case responsible
    case declarer
    case seat
    case made
}

enum ColumnSize: Codable, Equatable {
    case fixed([CGFloat])
    case flexible
}

enum ViewType {
    case normal
    case detail
    case analysis
    
    var description: String {
        switch self {
        case .normal:
            "Simple view"
        case .detail:
            "Detailed view"
        case .analysis:
            "Analysis view"
        }
    }
    
    var otherType: ViewType {
        switch self {
        case .normal:
            Scorecard.current.isImported ? .analysis : .detail
        default:
            .normal
        }
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
    @State private var viewType: ViewType
    @State private var hideRejected = true
    @State private var importBboScorecard = false
    @State private var importBwScorecard = false
    @State private var importPbnScorecard = false
    @State private var showRankings = false
    @State private var disableBanner = false
    @State private var handViewer = false
    @State private var handBoard: BoardViewModel? = nil
    @State private var handTraveller: TravellerViewModel? = nil
    @State private var handSitting = Seat.unknown
    @State private var handView: UIView!
    @State private var analysisViewer = false
    
    init(scorecard: ScorecardViewModel, importScorecard: ImportSource = .none) {
        _scorecard = ObservedObject(initialValue: scorecard)
        _importScorecard = State(initialValue: importScorecard)
        _viewType = State(initialValue: Scorecard.current.isImported ? .analysis : .normal)
    }
    
    var body: some View {
        StandardView("Input", slideInId: id) {
            VStack(spacing: 0) {
                    // Just to trigger view refresh
                if refreshTableTotals { EmptyView() }
                
                    // Banner
                Banner(title: $scorecard.desc, back: true, backAction: backAction, leftTitle: true, optionMode: .both, menuImage: AnyView(Image(systemName: "gearshape")), menuTitle: nil, menuId: id, options: bannerOptions(isNotImported: $isNotImported), disabled: $disableBanner)
                    .disabled(disableBanner)
                GeometryReader { geometry in
                    ScorecardInputUIViewWrapper(scorecard: scorecard, frame: geometry.frame(in: .local), refreshTableTotals: $refreshTableTotals, viewType: $viewType, hideRejected: $hideRejected, inputDetail: $inputDetail, tableRefresh: $tableRefresh, showRankings: $showRankings, disableBanner: $disableBanner, handViewer: $handViewer, handBoard: $handBoard, handTraveller: $handTraveller, handSitting: $handSitting, handView: $handView, analysisViewer: $analysisViewer)
                        .ignoresSafeArea(edges: .all)
                }
            }.undoManager(canUndo: $canUndo, canRedo: $canRedo)
        }
        .onChange(of: tableRefresh, initial: false) { tableRefresh = false}
        .onChange(of: showRankings, initial: false) { showRankings = false}
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
                if Scorecard.current.isImported {
                    viewType = .analysis
                }
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
                if Scorecard.current.isImported {
                    viewType = .analysis
                }
                saveScorecard()
            }
        }
        .sheet(isPresented: $importPbnScorecard, onDismiss: {
            UndoManager.clearActions()
            if scorecard.importSource != .none {
                isNotImported = false
                tableRefresh = true
            }
        }) {
            ImportPBNScorecard(scorecard: scorecard) {
                if Scorecard.current.isImported {
                    viewType = .analysis
                }
                saveScorecard()
            }
        }
        .sheet(isPresented: $handViewer, onDismiss: {
            UndoManager.clearActions()
            disableBanner = false
        }) {
            if let handBoard = handBoard {
                if let handTraveller = handTraveller {
                    HandViewerForm(board: handBoard, traveller: handTraveller, sitting: handSitting, from: handView)
                }
            }
        }
        .fullScreenCover(isPresented: $analysisViewer, onDismiss: {
            UndoManager.clearActions()
            disableBanner = false
            tableRefresh = true
        }) {
            if let handBoard = handBoard {
                if let handTraveller = handTraveller {
                    ZStack{
                        Color.black.opacity(0.4)
                        AnalysisViewer(board: handBoard, traveller: handTraveller, sitting: handSitting, from: handView)
                            .frame(width: UIScreen.main.bounds.width - 60, height: UIScreen.main.bounds.size.height - 40 )
                            .cornerRadius(8)
                        Spacer()
                    }
                    .background(BackgroundBlurView(opacity: 0.3))
                    .edgesIgnoringSafeArea(.all)
                    .presentationDetents([.height(800)])
                }
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
            case .pbn:
                importPbnScorecard = true
            default:
                break
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
            BannerOption(image: AnyView(Image(systemName: "note.text")), text: "Scorecard details", likeBack: true, menu: true, action: { UndoManager.clearActions() ; inputDetail = true })]
        bannerOptions += [
            BannerOption(image: AnyView(Image(systemName: "\(viewType == .detail ? "minus" : "plus").magnifyingglass")), text: viewType.otherType.description, likeBack: true, menu: true, action: { viewType = viewType.otherType })]
        if viewType == .analysis {
            bannerOptions += [
                BannerOption(image: AnyView(Image(systemName: hideRejected ? "plus" : "minus")), text: hideRejected ? "Show rejected" : "Hide rejected", likeBack: true, menu: true, action: { hideRejected.toggle() })]
        }
        if isNotImported.wrappedValue || scorecard.resetNumbers {
            bannerOptions += [
                BannerOption(image: AnyView(Image(systemName: "square.and.arrow.down")), text: "Import PBN file", likeBack: true, menu: true, action: { UndoManager.clearActions() ; importPbnScorecard = true}),
                BannerOption(image: AnyView(Image(systemName: "square.and.arrow.down")), text: "Import BBO files", likeBack: true, menu: true, action: { UndoManager.clearActions() ; importBboScorecard = true})]
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
}

struct BackgroundBlurView: UIViewRepresentable {
    @State var opacity: CGFloat = 0.2
    
    func makeUIView(context: Context) -> UIView {
        let view = UIVisualEffectView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .black.withAlphaComponent(opacity)
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct ScorecardInputUIViewWrapper: UIViewRepresentable {
    @ObservedObject var  scorecard: ScorecardViewModel
    @State var frame: CGRect
    @Binding var refreshTableTotals: Bool
    @Binding var viewType: ViewType
    @Binding var hideRejected: Bool
    @Binding var inputDetail: Bool
    @Binding var tableRefresh: Bool
    @Binding var showRankings: Bool
    @Binding var disableBanner: Bool
    @Binding var handViewer: Bool
    @Binding var handBoard: BoardViewModel?
    @Binding var handTraveller: TravellerViewModel?
    @Binding var handSitting: Seat
    @Binding var handView: UIView?
    @Binding var analysisViewer: Bool

    func makeUIView(context: Context) -> ScorecardInputUIView {
        
        let inputView = ScorecardInputUIView(frame: frame, scorecard: scorecard, inputDetail: inputDetail, disableBanner: $disableBanner, handViewer: $handViewer, handBoard: $handBoard, handTraveller: $handTraveller, handSitting: $handSitting, handView: $handView, analysisViewer: $analysisViewer)
        UndoManager.clearActions()
       
        return inputView
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
        
        uiView.change(viewType: viewType)
        
        if uiView.hideRejected != hideRejected {
            uiView.hideRejected = hideRejected
            uiView.tableRefresh()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
    }
}

protocol ScorecardDelegate {
    func scorecardChanged(type: RowType, itemNumber: Int, column: ColumnType?, refresh: Bool)
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
    func setAnalysisCommentBoardNumber(boardNumber: Int)
    var viewType: ViewType {get}
    var hideRejected: Bool {get}
    var analysisCommentBoardNumber: Int? {get}
    var autoComplete: AutoComplete {get}
    var keyboardHeight: CGFloat {get}
    var inputControlInset: CGFloat {get}
}

extension ScorecardDelegate {
    func scorecardChanged(type: RowType, itemNumber: Int) {
        scorecardChanged(type: type, itemNumber: itemNumber, column: nil, refresh: false)
    }
    func scorecardChanged(type: RowType, itemNumber: Int, column: ColumnType?) {
        scorecardChanged(type: type, itemNumber: itemNumber, column: column, refresh: false)
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
    internal var viewType = ViewType.normal
    internal var hideRejected = true
    public var inputDetail: Bool
    private var disableBanner: Binding<Bool>
    public var handViewer: Binding<Bool>
    public var handBoard: Binding<BoardViewModel?>
    public var handTravelller: Binding<TravellerViewModel?>
    public var handSitting: Binding<Seat>
    public var handView: Binding<UIView?>
    public var analysisViewer: Binding<Bool>
    private var ignoreKeyboard = false
    private var titleHeightConstraint: NSLayoutConstraint!
    private var orientation: UIDeviceOrientation?
    internal var analysisCommentBoardNumber: Int?
    internal var inputControlInset: CGFloat = 0
    
    var boardColumns: [ScorecardColumn] = []
    var boardAnalysisCommentColumns: [ScorecardColumn] = []
    var tableColumns: [ScorecardColumn] = []
    
    init(frame: CGRect, scorecard: ScorecardViewModel, inputDetail: Bool, disableBanner: Binding<Bool>, handViewer: Binding<Bool>, handBoard: Binding<BoardViewModel?>, handTraveller: Binding<TravellerViewModel?>, handSitting: Binding<Seat>, handView: Binding<UIView?>, analysisViewer: Binding<Bool>) {
        self.scorecard = scorecard
        self.inputDetail = inputDetail
        self.disableBanner = disableBanner
        self.handViewer = handViewer
        self.handBoard = handBoard
        self.handTravelller = handTraveller
        self.handSitting = handSitting
        self.handView = handView
        self.analysisViewer = analysisViewer
        self.contractEntryView = ScorecardContractEntryView(frame: CGRect())
        self.scrollPickerPopupView = ScrollPickerPopupView(frame: CGRect())
        self.declarerPickerPopupView = DeclarerPickerPopupView(frame: CGRect())

        super.init(frame: frame)
    
        // Set up view
        change(viewType: viewType, force: true)
                    
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let oldBoardColumns = boardColumns.copy
        let oldBoardAnalysisCommentColumns = boardAnalysisCommentColumns.copy
        let oldTableColumns = tableColumns.copy
        setupSizes(columns: &boardColumns)
        setupSizes(columns: &boardAnalysisCommentColumns)
        setupSizes(columns: &tableColumns)
        titleHeightConstraint.constant = titleRowHeight
        if boardColumns != oldBoardColumns || boardAnalysisCommentColumns != oldBoardAnalysisCommentColumns || tableColumns != oldTableColumns || orientation != UIDevice.current.orientation || forceReload {
            tableRefresh()
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
        titleView.collectionView.reloadData()
        mainTableView.reloadData()
    }
    
    public func change(viewType: ViewType, force: Bool = false) {
        let teams = scorecard.type.players == 4
        let phone = MyApp.format == .phone
        
        if viewType != self.viewType || force {
            if viewType == .analysis {
                boardColumns = [
                    ScorecardColumn(type: .board, heading: "Board", size: .fixed([70]), phoneSize: .fixed([40])),
                    ScorecardColumn(type: .teamTable, heading: "Team", size: .fixed([60]), omit: !teams || phone),
                    ScorecardColumn(type: .combined, heading: "Contract", size: .fixed([140]), phoneSize: .fixed([90])),
                    ScorecardColumn(type: .points, heading: "Points", size: .fixed([100]), omit: phone),
                    ScorecardColumn(type: .score, heading: "Score", size: .fixed([100]), phoneSize: .fixed([70])),
                    ScorecardColumn(type: .responsible, heading: "Resp", size: .fixed([70]), omit: phone)]
                boardAnalysisCommentColumns = boardColumns
                
                boardColumns += [
                    ScorecardColumn(type: .analysis1, heading: "Bidding", size: .flexible),
                    ScorecardColumn(type: .analysis2, heading: "Play", size: .flexible),
                    ScorecardColumn(type: .commentAvailable, heading: "X", size: .fixed([40]), phoneSize: .fixed([30]))]
                
                boardAnalysisCommentColumns += [
                    ScorecardColumn(type: .comment, heading: "Comment", size: .flexible),
                    ScorecardColumn(type: .commentAvailable, heading: "", size: .fixed([40]), phoneSize: .fixed([30]))]
                
                tableColumns = [
                    ScorecardColumn(type: .table, heading: "", size: .fixed([70, teams ? 60 : 0]), phoneSize: .fixed([40])),
                    ScorecardColumn(type: .sitting, heading: "Sitting", size: .fixed([140]), phoneSize: .fixed([90])),
                    ScorecardColumn(type: .tableScore, heading: "", size: .fixed([100, 100]), phoneSize: .fixed([70])),
                    ScorecardColumn(type: .versus, heading: "Versus", size: .flexible)]
            } else if viewType == .detail {
                boardColumns = [
                    ScorecardColumn(type: .board, heading: "Board", size: .fixed([70]), phoneSize: .fixed([40])),
                    ScorecardColumn(type: .vulnerable, heading: "Vul", size: .fixed([20])),
                    ScorecardColumn(type: .dealer, heading: "Dealer", size: .fixed([50]), phoneSize: .fixed([40])),
                    ScorecardColumn(type: .contract, heading: "Contract", size: .fixed([95]), phoneSize: .fixed([60])),
                    ScorecardColumn(type: .declarer, heading: "By", size: .fixed([70]), phoneSize: .fixed([50])),
                    ScorecardColumn(type: .made, heading: "Made", size: .fixed([60]), phoneSize: .fixed([50])),
                    ScorecardColumn(type: .points, heading: "Points", size: .fixed([80]), omit: phone),
                    ScorecardColumn(type: .score, heading: "Score", size: .fixed([90]), phoneSize: .fixed([60])),
                    ScorecardColumn(type: .comment, heading: "Comment", size: .flexible)
                ]
                
                tableColumns = [
                    ScorecardColumn(type: .table, heading: "", size: .fixed([70, 30, 50]), phoneSize: .fixed([40, 20, 40])),
                    ScorecardColumn(type: .sitting, heading: "Sitting", size: .fixed([95, 70]), phoneSize: .fixed([60, 50])),
                    ScorecardColumn(type: .tableScore, heading: "", size: .fixed([60, 80, 90]), phoneSize: .fixed([50, 60])),
                    ScorecardColumn(type: .versus, heading: "Versus", size: .flexible)
                ]
            } else {
                boardColumns = [
                    ScorecardColumn(type: .board, heading: "Board", size: .fixed([70]), phoneSize: .fixed([40])),
                    ScorecardColumn(type: .contract, heading: "Contract", size: .fixed([95]), phoneSize: .fixed([60])),
                    ScorecardColumn(type: .declarer, heading: "By", size: .fixed([70]), phoneSize: .fixed([50])),
                    ScorecardColumn(type: .made, heading: "Made", size: .fixed([60]), phoneSize: .fixed([50])),
                    ScorecardColumn(type: .score, heading: "Score", size: .fixed([90]), phoneSize: .fixed([60])),
                    ScorecardColumn(type: .responsible, heading: "Resp", size: .fixed([65]), omit: phone),
                    ScorecardColumn(type: .comment, heading: "Comment", size: .flexible)
                ]
                
                tableColumns = [
                    ScorecardColumn(type: .table, heading: "", size: .fixed([70, 95]), phoneSize: .fixed([40, 60])),
                    ScorecardColumn(type: .sitting, heading: "Sitting", size: .fixed([70, 60]), phoneSize: .fixed([50, 50])),
                    ScorecardColumn(type: .tableScore, heading: "", size: .fixed([90, 65]), phoneSize: .fixed([60])),
                    ScorecardColumn(type: .versus, heading: "Versus", size: .flexible)
                ]
            }
            boardColumns = boardColumns.filter({!$0.omit})
            boardAnalysisCommentColumns = boardAnalysisCommentColumns.filter({!$0.omit})
            tableColumns = tableColumns.filter({!$0.omit})
            self.viewType = viewType
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
    
    internal func scorecardChanged(type: RowType, itemNumber: Int, column: ColumnType?, refresh: Bool) {
        switch type {
        case .board:
            if let column = column {
                let section = (itemNumber - 1) / scorecard.boardsTable
                let row = (itemNumber - 1) % scorecard.boardsTable
                switch column {
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
                case .comment:
                    if refresh {
                        // Comment has become blank / non-blank - update comment available
                        self.updateBoardCell(section: section, row: row, columnType: .commentAvailable)
                        self.updateBoardTitleCell(columnType: .commentAvailable)
                    }
                default:
                    break
                }
            }
            Scorecard.current.interimSave(entity: .board, itemNumber: itemNumber)

        case .table:
            if let column = column {
                let section = itemNumber - 1
                switch column {
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
            let boardColumns = getBoardColumns(boardNumber: itemNumber)
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
        if let rowCell = self.mainTableView.cellForRow(at: IndexPath(row: row, section: section)) as? ScorecardInputBoardTableCell {
            let boardNumber = (section * scorecard.boardsTable) + (row + 1)
            if let columnNumber = getBoardColumns(boardNumber: boardNumber).firstIndex(where: {$0.type == columnType}) {
                rowCell.collectionView.reloadItems(at: [IndexPath(item: columnNumber, section: 0)])
            }
        }
    }
    
    private func updateBoardTitleCell(columnType: ColumnType) {
        if let rowCell = self.titleView {
            if let columnNumber = getBoardColumns(boardNumber: -1).firstIndex(where: {$0.type == columnType}) {
                rowCell.collectionView.reloadItems(at: [IndexPath(item: columnNumber, section: 0)])
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
        contractEntryView.show(from: superview!.superview!, contract: board.contract, sitting: table.sitting, declarer: board.declarer) { (contract, declarer, sitting) in
            if let sitting = sitting {
                if sitting != table.sitting {
                    if let tableCell = self.mainTableView.headerView(forSection: section) as? ScorecardInputTableSectionHeaderView {
                        // Update sitting
                        if let item = self.tableColumns.firstIndex(where: {$0.type == .sitting}) {
                            if let cell = tableCell.collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? ScorecardInputCollectionCell {
                                cell.seatPicker.set(sitting)
                                cell.enumPickerDidChange(to: sitting)
                            }
                        }
                    }
                }
            }
            if let contract = contract {
                if contract != board.contract || declarer != board.declarer {
                    if let tableCell = self.mainTableView.cellForRow(at: IndexPath(row: row, section: section)) as? ScorecardInputBoardTableCell {
                            // Update contract and/or declarer
                        if let item = self.getBoardColumns(boardNumber: board.board).firstIndex(where: {$0.type == .contract}) {
                            if let cell = tableCell.collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? ScorecardInputCollectionCell {
                                cell.label.attributedText = contract.attributedString
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
            showTraverllerView.show(from: self, boardNumber: board.board, sitting: sitting) {
                self.disableBanner.wrappedValue = false
            }
        }
    }
    
    func scorecardShowHand(scorecard: ScorecardViewModel, board: BoardViewModel, sitting: Seat) {
        if !Scorecard.current.travellerList.isEmpty {
            if let (board, traveller, _) = Scorecard.getBoardTraveller(boardNumber: board.board) {
                disableBanner.wrappedValue = true
                handBoard.wrappedValue = board
                handTravelller.wrappedValue = traveller
                handSitting.wrappedValue = sitting
                handView.wrappedValue = self
                if viewType == .analysis {
                    handViewer.wrappedValue = false
                    analysisViewer.wrappedValue = true
                } else {
                    handViewer.wrappedValue = true
                    analysisViewer.wrappedValue = false
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
                if let item = self.getBoardColumns(boardNumber: boardNumber).firstIndex(where: {$0.type == .score}) {
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
    
    func setAnalysisCommentBoardNumber(boardNumber: Int) {
        // -1 is used to show all comments
        
        let oldBoardNumber = self.analysisCommentBoardNumber
        self.analysisCommentBoardNumber = (boardNumber == oldBoardNumber || oldBoardNumber == -1 ? nil : boardNumber)
        if let oldBoardNumber = oldBoardNumber {
            // Close up previously selected row
            if oldBoardNumber == -1 {
                tableRefresh()
            } else {
                let oldSection = (oldBoardNumber - 1) / scorecard.boardsTable
                let oldRow = (oldBoardNumber - 1) % scorecard.boardsTable
                mainTableView.reloadRows(at: [IndexPath(row: oldRow, section: oldSection)], with: .automatic)
            }
        }
        if let newBoardNumber = self.analysisCommentBoardNumber {
            // Open up new selected row(s)
            if newBoardNumber == -1 {
                tableRefresh()
            } else {
                let section = (newBoardNumber - 1) / scorecard.boardsTable
                let row = (newBoardNumber - 1) % scorecard.boardsTable
                mainTableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .automatic)
            }
        }
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
                let boardNumber = collectionView.tag % tagMultiplier
                columns = getBoardColumns(boardNumber: boardNumber).count
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
                let boardNumber = collectionView.tag % tagMultiplier
                height = boardRowHeight
                column = getBoardColumns(boardNumber: boardNumber)[indexPath.item]
            case .table:
                height = tableRowHeight
                column = tableColumns[indexPath.item]
            case .boardTitle:
                let boardNumber = collectionView.tag % tagMultiplier
                height = titleRowHeight
                column = getBoardColumns(boardNumber: boardNumber)[indexPath.item]
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
                let cell = ScorecardInputCollectionCell.dequeue(collectionView, from: self, for: indexPath)
                let boardNumber = collectionView.tag % tagMultiplier
                if let board = Scorecard.current.boards[boardNumber] {
                    let tableNumber = ((boardNumber - 1) / scorecard.boardsTable) + 1
                    if let table = Scorecard.current.tables[tableNumber] {
                        let column = getBoardColumns(boardNumber: boardNumber)[indexPath.item]
                        cell.set(scorecard: scorecard, table: table, board: board, itemNumber: boardNumber, rowType: .board, column: column)
                    }
                }
                return cell
            case .boardTitle:
                let cell = ScorecardInputCollectionCell.dequeue(collectionView, from: self, for: indexPath)
                let boardNumber = collectionView.tag % tagMultiplier
                var column: ScorecardColumn
                column = getBoardColumns(boardNumber: boardNumber)[indexPath.item]
                cell.setTitle(scorecard: scorecard, column: column)
                return cell
            case .table:
                let cell = ScorecardInputCollectionCell.dequeue(collectionView, from: self, for: indexPath)
                let tableNumber = collectionView.tag % tagMultiplier
                if let table = Scorecard.current.tables[tableNumber] {
                    let column = tableColumns[indexPath.item]
                    cell.set(scorecard: scorecard, table: table, itemNumber: tableNumber, rowType: .table, column: column)
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
            if inputControlInset == 0 {
                getInputControlInset()
            }
            self.keyboardHeight = keyboardHeight
            if !inputDetail && (keyboardHeight != 0 || isKeyboardOffset) {
                let focusedTextInputBottom = (UIResponder.currentFirstResponder?.globalFrame?.maxY ?? 0)
                let adjustOffset = max(0, focusedTextInputBottom - keyboardHeight + safeAreaInsets.bottom + inputControlInset)
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
                    self.layoutIfNeeded()
                    self.mainTableView.setContentOffset(current.offsetBy(dy: adjustOffset), animated: false)
                    self.isKeyboardOffset = true
                }
            }
        }
    }
    
    func getInputControlInset() {
        // Get any cell and find it's control inset (they're all the same)
        let cell = titleView.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as!
        ScorecardInputCollectionCell
        inputControlInset = cell.inputControlInset
    }
    
    func setupSizes(columns: inout [ScorecardColumn]) {
        let phone = MyApp.format == .phone
        
        if columns.count > 0 {
            var fixedWidth: CGFloat = 0
            var flexible: Int = 0
            for column in columns {
                if !column.omit {
                    switch (phone ? column.phoneSize : column.size) {
                    case .fixed(let width):
                        fixedWidth += width.reduce(0,+)
                    case .flexible:
                        flexible += 1
                    }
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
            for column in columns {
                if !column.omit {
                    switch (phone ? column.phoneSize : column.size) {
                    case .fixed(let width):
                        column.width = width.map{ceil($0 * factor)}.reduce(0,+)
                    case .flexible:
                        column.width = flexibleSize
                    }
                    remainingWidth -= column.width!
                }
            }
            columns.last!.width! += remainingWidth
        }
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
    
    private func getBoardColumns(boardNumber: Int) -> [ScorecardColumn] {
        var columns: [ScorecardColumn]
        if viewType == .analysis && (analysisCommentBoardNumber == boardNumber || analysisCommentBoardNumber == -1) {
            columns = boardAnalysisCommentColumns
        } else {
            columns = boardColumns
        }
        return columns
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
    fileprivate var labelSeparator = UIView()
    fileprivate var labelHorizontalPadding: [NSLayoutConstraint]!
    fileprivate var labelTopPadding: [NSLayoutConstraint]!
    fileprivate var bottomLabel = UILabel()
    fileprivate var bottomLabelTapGesture: UITapGestureRecognizer!
    fileprivate var topAnalysis = AnalysisSummaryView()
    fileprivate var bottomAnalysis = AnalysisSummaryView()
    fileprivate var analysisSeparator = UIView()
    fileprivate var caption = UILabel()
    fileprivate var textField = UITextField()
    fileprivate var textView = UITextView()
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
    private var labelSeparatorHeight: NSLayoutConstraint!
    private var bottomLabelHeight: NSLayoutConstraint!
    private var bottomAnalysisHeight: NSLayoutConstraint!
    private var analysisSeparatorHeight: NSLayoutConstraint!
    private var currentTapControl: TapControl?
    private var tapGesture = UITapGestureRecognizer()
    public let inputControlInset: CGFloat = 8

    public var gridLineViews: [UIView] = []
    
    private var scorecard: ScorecardViewModel!
    
    override init(frame: CGRect) {
        
        responsiblePicker = EnumPicker(frame: frame)
        declarerPicker = ScrollPicker(frame: frame)
        seatPicker = EnumPicker(frame: frame)
        madePicker = ScrollPicker(frame: frame)
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(Palette.gridTable.background)
                        
        addSubview(label)
        labelHorizontalPadding = Constraint.anchor(view: self, control: label, constant: 2, attributes: .leading, .trailing)
        label.textAlignment = .center
        label.minimumScaleFactor = 0.3
        label.adjustsFontSizeToFitWidth = true
        
        addSubview(labelSeparator, constant: 0, anchored: .leading, .trailing)
        labelSeparator.backgroundColor = UIColor(Palette.gridLine)
        Constraint.anchor(view: self, control: labelSeparator, to: label, constant: 0, toAttribute: .bottom, attributes: .top)
        labelSeparatorHeight = Constraint.setHeight(control: labelSeparator, height: 0)
        
        addSubview(bottomLabel, constant: 2, anchored: .leading, .bottom, .trailing)
        bottomLabel.textAlignment = .center
        bottomLabel.minimumScaleFactor = 0.3
        bottomLabel.adjustsFontSizeToFitWidth = true
        Constraint.anchor(view: self, control: bottomLabel, to: labelSeparator, constant: 0, toAttribute: .bottom, attributes: .top)
        bottomLabelHeight = Constraint.setHeight(control: bottomLabel, height: 0)
        bottomLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputCollectionCell.labelTapped(_:)))
        bottomLabel.addGestureRecognizer(bottomLabelTapGesture, identifier: "Bottom label")
        
        addSubview(topAnalysis, constant: 0, anchored: .leading, .top, .trailing)
        
        addSubview(analysisSeparator, constant: 0, anchored: .leading, .trailing)
        analysisSeparator.backgroundColor = UIColor(Palette.gridLine)
        Constraint.anchor(view: self, control: analysisSeparator, to: topAnalysis, constant: 0, toAttribute: .bottom, attributes: .top)
        analysisSeparatorHeight = Constraint.setHeight(control: analysisSeparator, height: 1)
        
        addSubview(bottomAnalysis, constant: 0, anchored: .leading, .bottom, .trailing)
        Constraint.anchor(view: self, control: bottomAnalysis, to: analysisSeparator, constant: 0, toAttribute: .bottom, attributes: .top)
        bottomAnalysisHeight = Constraint.setHeight(control: bottomAnalysis, height: 0)
        
        addSubview(textField, constant: inputControlInset, anchored: .leading, .top, .bottom)
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
               
        addSubview(textView, constant: inputControlInset, anchored: .leading, .top, .bottom)
        textView.textAlignment = .left
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.font = cellFont
        textView.delegate = self
        textView.backgroundColor = UIColor.clear
        textView.textContainerInset = .zero
        
        addSubview(textClear, constant: inputControlInset, anchored: .trailing, .top, .bottom)
        textClearWidth = Constraint.setWidth(control: textClear, width: 0)
        textClearPadding = Constraint.anchor(view: self, control: textField, to: textClear, constant: inputControlInset, toAttribute: .leading, attributes: .trailing)
        textClearPadding.append(contentsOf: Constraint.anchor(view: self, control: textView, to: textClear, constant: 8, toAttribute: .leading, attributes: .trailing))
        textClear.image = UIImage(systemName: "x.circle.fill")?.asTemplate
        textClear.tintColor = UIColor(Palette.clearText)
        textClear.contentMode = .scaleAspectFit
        textClear.isUserInteractionEnabled = true
        
        addSubview(declarerPicker, top: 16, bottom: 0)
        Constraint.setWidth(control: declarerPicker, width: 60)
        Constraint.anchor(view: self, control: declarerPicker, attributes: .centerX)
        declarerPicker.delegate = self
        
        addSubview(seatPicker, top: 20, bottom: 4)
        Constraint.setWidth(control: seatPicker, width: 60)
        Constraint.anchor(view: self, control: seatPicker, attributes: .centerX)
        seatPicker.delegate = self
        
        addSubview(madePicker, top: 16, bottom: 0)
        Constraint.setWidth(control: madePicker, width: 60)
        Constraint.anchor(view: self, control: madePicker, attributes: .centerX)
        madePicker.delegate = self
        
        addSubview(responsiblePicker, top: 16, bottom: 0)
        Constraint.setWidth(control: responsiblePicker, width: 60)
        Constraint.anchor(view: self, control: responsiblePicker, attributes: .centerX)
        responsiblePicker.delegate = self
        
        addSubview(caption, anchored: .leading, .trailing, .top)
        caption.textAlignment = .center
        caption.font = titleCaptionFont
        caption.minimumScaleFactor = 0.3
        caption.backgroundColor = UIColor.clear
        caption.textColor = UIColor(Palette.gridBoard.text)
        captionHeight = Constraint.setHeight(control: caption, height: 0)
        labelTopPadding = Constraint.anchor(view: self, control: label, to: caption, constant: 0, toAttribute: .bottom, attributes: .top)
        
        Constraint.addGridLineReturned(self, views: &gridLineViews, sides: [.leading, .trailing, .top, .bottom])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ collectionView: UICollectionView) {
        collectionView.register(ScorecardInputCollectionCell.self, forCellWithReuseIdentifier: identifier)
    }

    public class func dequeue(_ collectionView: UICollectionView, from scorecardDelegate: ScorecardDelegate, for indexPath: IndexPath) -> ScorecardInputCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ScorecardInputCollectionCell
        cell.scorecardDelegate = scorecardDelegate
        cell.prepareForReuse()
        return cell
    }
    
    override func prepareForReuse() {
        board = nil
        itemNumber = nil
        column = nil
        caption.isHidden = true
        captionHeight.constant = 0
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
        textClearPadding.forEach { (constraint) in constraint.setIndent(in: self, constant: 0) }
        textField.text = ""
        textView.text = ""
        textView.font = cellFont
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor(Palette.background.text)
        label.text = ""
        label.font = cellFont
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.numberOfLines = 1
        labelHorizontalPadding.forEach { constraint in constraint.setIndent(in: self, constant: 2)}
        labelTopPadding.forEach { constraint in constraint.setIndent(in: self, constant: 2)}
        bottomLabel.backgroundColor = UIColor.clear
        bottomLabel.textColor = UIColor(Palette.background.text)
        bottomLabel.text = ""
        bottomLabel.font = cellFont
        bottomLabel.textAlignment = .center
        bottomLabel.isUserInteractionEnabled = false
        bottomLabel.numberOfLines = 1
        bottomLabel.lineBreakMode = .byWordWrapping
        bottomLabelHeight.constant = 0
        bottomLabelHeight.isActive = true
        bottomLabel.isHidden = true
        bottomLabelTapGesture.isEnabled = false
        labelSeparator.isHidden = true
        labelSeparator.backgroundColor = UIColor(Palette.gridLine)
        labelSeparatorHeight.constant = 0
        topAnalysis.prepareForReuse()
        topAnalysis.isHidden = true
        bottomAnalysis.prepareForReuse()
        bottomAnalysisHeight.constant = 0
        bottomAnalysis.isHidden = true
    }
    
    func setTitle(scorecard: ScorecardViewModel, column: ScorecardColumn) {
        self.board = nil
        self.column = column
        self.rowType = .boardTitle
        self.itemNumber = 0
        label.tag = column.type.rawValue
        label.backgroundColor = UIColor(Palette.gridTitle.background)
        label.textColor = UIColor(Palette.gridTitle.text)
        label.font = titleFont.bold
        switch column.type {
        case .score:
            label.text = scorecard.type.boardScoreType.string
        case .analysis1:
            if scorecard.type.players == 4 {
                if let players = Scorecard.myRanking?.playerNames(separator: " & ", firstOnly: true, .player, .partner) {
                    label.text = players
                } else {
                    label.text = "Our Table"
                }
            } else {
                label.text = column.heading
            }
        case .analysis2:
            if scorecard.type.players == 4 {
                if let players = Scorecard.myRanking?.playerNames(separator: " & ", firstOnly: true, .lhOpponent, .rhOpponent) {
                    label.text = players
                } else {
                    label.text = "Other Table"
                }
            } else {
                label.text = column.heading
            }
        case .commentAvailable:
            label.attributedText = Scorecard.commentAvailableText(exists: Scorecard.current.boards.map({$0.value.comment != ""}).contains(true))
            label.isUserInteractionEnabled = true
            let color = scorecardDelegate?.analysisCommentBoardNumber == -1 ? Palette.enabledButton : Palette.background
            label.backgroundColor = UIColor(color.background)
            label.textColor = UIColor(color.text)
            set(tap: .label)
        default:
            label.text = column.heading
        }
    }
    
    func set(scorecard: ScorecardViewModel, table: TableViewModel, board: BoardViewModel! = nil, itemNumber: Int, rowType: RowType, column: ScorecardColumn) {
        self.scorecard = scorecard
        self.board = board
        self.table = table
        self.itemNumber = itemNumber
        self.rowType = rowType
        self.column = column
        
        var isEnabled = false
        switch column.type {
        case .board, .table, .vulnerable, .dealer, .points, .teamTable, .analysis1, .analysis2, .commentAvailable:
            isEnabled = false
        case .declarer:
            isEnabled = (table.sitting != .unknown && !Scorecard.current.isImported)
        case .made:
            isEnabled = board.contract.suit.valid && !Scorecard.current.isImported
        case .score, .versus, .sitting, .contract:
            isEnabled = !Scorecard.current.isImported
        case .responsible, .comment:
            isEnabled = true
        default:
            break
        }
        
        var color: PaletteColor
        if rowType == .board {
            if Scorecard.current.isImported && board?.score == nil {
                color = Palette.gridBoardSitout
            } else if isEnabled {
                color = Palette.gridBoard
            } else {
                color = Palette.gridBoardDisabled
            }
        } else {
            if isEnabled {
                color = Palette.gridTable
            } else {
                color = Palette.gridTableDisabled
            }
        }
        
        self.backgroundColor = UIColor(color.background)
        label.backgroundColor = UIColor(color.background)
        bottomLabel.backgroundColor = UIColor(color.background)
        topAnalysis.backgroundColor = UIColor(color.background)
        bottomAnalysis.backgroundColor = UIColor(color.background)
        label.textColor = UIColor(color.text)
        textField.textColor = UIColor(color.text)
        textView.textColor = UIColor(color.text)

        label.tag = column.type.rawValue
        bottomLabel.tag = column.type.rawValue
        
        switch column.type {
        case .board:
            label.font = boardFont
            label.text = "\(board.boardNumber)"
            label.isUserInteractionEnabled = !isEnabled
            set(tap: .label)
        case .vulnerable:
            label.isHidden = false
            label.font = titleFont.bold
            label.text = board.vulnerability.string
            label.isUserInteractionEnabled = !isEnabled
            set(tap: .label)
        case .dealer:
            seatPicker.isHidden = false
            seatPicker.set(board.dealer, isEnabled: false, color: color, titleFont: pickerTitleFont)
            seatPicker.isUserInteractionEnabled = !isEnabled
            set(tap: .label)
        case .combined:
            analysisSplitCombined()
        case .contract:
            label.isHidden = false
            label.attributedText = board.contract.attributedString
            label.isUserInteractionEnabled = true
            set(tap: .label)
        case .declarer:
            declarerPicker.isHidden = false
            let selected = (table.sitting == .unknown ? 0 : declarerList.firstIndex(where: { $0.seat == board.declarer}) ?? 0)
            declarerPicker.set(selected, list: declarerList.map{$0.entry}, isEnabled: isEnabled, color: color, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
            label.isUserInteractionEnabled = !isEnabled
            set(tap: isEnabled ? .declarer : .label)
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
            let makingValue = (Values.trickOffset + board.contract.level.rawValue)
            madePicker.set(board.made == nil ? nil : board.made! - minValue, list: list, defaultEntry: ScrollPickerEntry(caption: "Unknown"), defaultValue: min(list.count - 1, makingValue), isEnabled: isEnabled, color: color, titleFont: pickerTitleFont)
            label.isUserInteractionEnabled = !isEnabled
            set(tap: isEnabled ? .made : .label)
        case .score:
            if Scorecard.current.isImported {
                label.isHidden = false
                if let score = board?.score {
                    label.text = "\(scorecard.type.boardScoreType.prefix(score: score))\(score.toString(places: min(1, scorecard.type.boardPlaces)))\(scorecard.type.boardScoreType.shortSuffix)"
                }
            } else {
                label.isHidden = true
                textField.isHidden = false
                textField.keyboardType = .numbersAndPunctuation
                textField.clearsOnBeginEditing = true
                textField.text = board.score == nil ? "" : "\(board.score!.toString(places: scorecard.type.boardPlaces))"
                textField.isEnabled = isEnabled
            }
            label.isUserInteractionEnabled = !isEnabled
            set(tap: .label)
        case .points:
            analysisSplitPoints(isEnabled: isEnabled)
        case .comment:
            textView.text = board.comment
            textView.textAlignment = .left
            textView.autocapitalizationType = .sentences
            textClear.isHidden = board.comment == ""
            textClearWidth.constant = 34
            textClearPadding.forEach { (constraint) in constraint.setIndent(in: self, constant: 8) }
            textView.textContainer.maximumNumberOfLines = 2
            textView.textContainer.lineBreakMode = .byTruncatingTail
            textView.adjustsFontForContentSizeCategory = true
            textView.font = cellFont
            if scorecardDelegate?.viewType == .analysis {
                textView.font = smallCellFont
                label.textAlignment = .left
                labelHorizontalPadding.forEach { (constraint) in constraint.setIndent(in: self, constant: 14) }
                labelTopPadding.forEach { (constraint) in constraint.setIndent(in: self, constant: 8) }
                label.sizeToFit()
                bottomLabelHeight.isActive = false
                label.textColor = UIColor(Palette.background.faintText)
                label.font = smallCellFont
                label.text = "Enter comment"
            }
            enableCommentControls()
        case .responsible:
            responsiblePicker.isHidden = (Scorecard.current.isImported && board.score == nil)
            responsiblePicker.set(board.responsible, color: Palette.gridBoard, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
            set(tap: .responsible)
        case .analysis1:
            setAnalysis(phase: .bidding, analysisView: topAnalysis, board: board, sitting: table.sitting, otherTable: false)
            if scorecard.type.players == 4 {
                setAnalysis(phase: .play, analysisView: bottomAnalysis, analysisViewHeight: bottomAnalysisHeight, board: board, sitting: table.sitting, otherTable: false)
            }
        case .analysis2:
            if scorecard.type.players == 4 {
                setAnalysis(phase: .bidding, analysisView: topAnalysis, board: board, sitting: table.sitting.equivalent, otherTable: true)
                setAnalysis(phase: .play, analysisView: bottomAnalysis, analysisViewHeight: bottomAnalysisHeight, board: board, sitting: table.sitting.equivalent, otherTable: true)
            } else {
                setAnalysis(phase: .play, analysisView: topAnalysis, board: board, sitting: table.sitting, otherTable: false)
            }
        case .teamTable:
            label.isHidden = false
            label.font = titleFont
            label.text = "Us"
            label.isUserInteractionEnabled = true
            set(tap: .label)
            if scorecard.type.players == 4 {
                bottomLabel.isHidden = false
                bottomLabel.font = titleFont
                bottomLabel.text = "Other"
                bottomLabel.isUserInteractionEnabled = true
                bottomLabelTapGesture.isEnabled = true
                labelSeparator.isHidden = false
                labelSeparatorHeight.constant = 1
                bottomLabelHeight.constant = (boardRowHeight - 1 - 2) / 2
            }
        case .commentAvailable:
            label.isHidden = (Scorecard.current.isImported && board?.score == nil)
            let color = (scorecardDelegate?.analysisCommentBoardNumber == board.board ? Palette.enabledButton : Palette.background)
            label.backgroundColor = UIColor(color.background)
            label.textColor = UIColor(color.contrastText)
            label.attributedText = Scorecard.commentAvailableText(exists: board.comment != "")
            label.isUserInteractionEnabled = true
            set(tap: .label)
        case .table:
            label.font = boardTitleFont.bold
            label.text = (Scorecard.current.isImported ? "" : "Table \(table.table)")
            label.isUserInteractionEnabled = true
            set(tap: .label)
        case .sitting:
            seatPicker.isHidden = false
            seatPicker.set(table.sitting, isEnabled: isEnabled, color: color, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
            label.isUserInteractionEnabled = !isEnabled
            set(tap: isEnabled ? .seat : nil)
        case .tableScore:
            if scorecard.manualTotals {
                textField.isHidden = false
                textField.keyboardType = .numbersAndPunctuation
                textField.clearsOnBeginEditing = true
                textField.text = table.score == nil ? "" : "\(table.score!.toString(places: scorecard.type.tablePlaces))"
                set(tap: .textFieldClear)
            } else {
                label.text = table.score == nil ? "" : "\(scorecard.type.tableScoreType.prefix(score: table.score!))\(table.score!.toString(places: min(1, scorecard.type.tablePlaces)))\(scorecard.type.tableScoreType.suffix)"
                label.isUserInteractionEnabled = true
                set(tap: .label)
            }
        case .versus:
            if Scorecard.current.isImported {
                label.isHidden = false
                label.text = importedVersus
                label.isUserInteractionEnabled = true
                label.numberOfLines = 2
                label.font = (scorecard.type.players == 1 ? smallCellFont : cellFont)
                label.isUserInteractionEnabled = true
                set(tap: .label)
            } else {
                textField.isHidden = false
                textField.text = table.versus
                textField.textAlignment = (isEnabled ? .left : .center)
                textField.autocapitalizationType = .words
                textField.isEnabled = isEnabled
                textField.font = (scorecard.type.players == 1 ? smallCellFont : cellFont)
                textClear.isHidden = (!isEnabled || table.versus == "")
                textClearWidth.constant = 34
                textClearPadding.forEach { (constraint) in constraint.setIndent(in: self, constant: 8) }
                set(tap: .textFieldClear)
            }
        }
        
        if rowType == .table && column.heading != "" {
            caption.isHidden = false
            captionHeight.constant = 24
            caption.text = (column.type == .tableScore ? scorecard.type.boardScoreType.string : column.heading)
        }
    }
    
    private func analysisSplitCombined() {
        label.isHidden = false
        label.attributedText = board.contract.attributedCompact + " " + board.declarer.short + " " + (board.made == nil ? "" : Scorecard.madeString(made: board.made!))
        label.isUserInteractionEnabled = true
        set(tap: .label)
        if scorecard.type.players == 4 {
            label.font = smallCellFont
            labelSeparator.isHidden = false
            labelSeparatorHeight.constant = 1
            bottomLabel.isHidden = false
            bottomLabel.font = titleFont
            bottomLabelHeight.constant = (boardRowHeight - 1 - 2) / 2
            if let (_, otherTraveller, _) = Scorecard.getBoardTraveller(boardNumber: board.board, equivalentSeat: true) {
                bottomLabel.attributedText = otherTraveller.contract.attributedCompact + " " + otherTraveller.declarer.short + " " + Scorecard.madeString(made: otherTraveller.made)
            }
            bottomLabel.isUserInteractionEnabled =  true
            bottomLabelTapGesture.isEnabled = true
        }
    }
    
    private func enableCommentControls() {
        let imported = Scorecard.current.isImported
        let sitout = imported && board.score == nil
        let editing = textView.isFirstResponder
        let analysisMode = scorecardDelegate?.viewType == .analysis
        let blank = (board.comment == "")

        let useLabel = sitout || (analysisMode && blank && !editing)
        
        textView.isHidden = useLabel
        label.isHidden = !useLabel
        bottomLabel.isHidden = !useLabel
        label.isUserInteractionEnabled = useLabel
        bottomLabel.isUserInteractionEnabled = useLabel
        bottomLabelTapGesture.isEnabled = useLabel
        set(tap: useLabel ? .label : .textViewClear)
    }
    
    private func analysisSplitPoints(isEnabled: Bool) {
        if board.declarer == .unknown {
            label.text = ""
        } else {
            let points = board.points(seat: table.sitting)
            label.text = (points == nil ? "" : "\(points! > 0 ? "+" : "")\(points!)")
        }
        label.isUserInteractionEnabled = true
        set(tap: .label)
        if (scorecardDelegate?.viewType ?? .normal) == .analysis && scorecard.type.players == 4 {
            label.font = smallCellFont
            labelSeparator.isHidden = false
            labelSeparatorHeight.constant = 1
            bottomLabel.isHidden = false
            bottomLabel.font = titleFont
            bottomLabelHeight.constant = (boardRowHeight - 1 - 2) / 2
            if let (_, otherTraveller, _) = Scorecard.getBoardTraveller(boardNumber: board.board, equivalentSeat: true) {
                let points = otherTraveller.points(sitting: table.sitting.equivalent)
                bottomLabel.text = "\(points > 0 ? "+" : "")\(points)"
            }
            bottomLabel.isUserInteractionEnabled = true
            bottomLabelTapGesture.isEnabled = true
        }
    }
    
    
    private func setAnalysis(phase: AnalysisPhase, analysisView: AnalysisSummaryView, analysisViewHeight: NSLayoutConstraint? = nil, board: BoardViewModel, sitting: Seat, otherTable: Bool) {
        analysisView.isHidden = false
        if analysisView == bottomAnalysis {
            analysisSeparator.isHidden = false
            analysisViewHeight?.constant = (boardRowHeight - 1 - 2) / 2
            bottomLabel.isUserInteractionEnabled = true
            bottomLabelTapGesture.isEnabled = true
        } else {
            label.isUserInteractionEnabled = true
            set(tap: .label)
        }
        if let (_, traveller, _) = Scorecard.getBoardTraveller(boardNumber: board.board, equivalentSeat: otherTable) {
            let analysis = Scorecard.current.analysis(board: board, traveller: traveller, sitting: sitting)
            let summary = analysis.summary(phase: phase, otherTable: otherTable, verbose: true)
            analysisView.set(board: board, summary: summary, viewTapped: showHand)
        } else {
            analysisView.prepareForReuse()
        }
    }
    
    func set(tap newTapControl: TapControl?) {
        if newTapControl != currentTapControl {
            if let currentTapControl = currentTapControl {
                execute(on: currentTapControl) { (control, _) in
                    control.removeGestureRecognizer(tapGesture)
                    tapGesture.removeTarget(self, action: nil)
                    tapGesture.isEnabled = false
                }
            }
            if let newTapControl = newTapControl {
                execute(on: newTapControl) { (control, selector) in
                    control.addGestureRecognizer(tapGesture, identifier: "General control")
                    tapGesture.addTarget(self, action: selector)
                    tapGesture.isEnabled = true
                }
            }
            currentTapControl = newTapControl
        }
        
        func execute(on tapControl: TapControl, action: (UIView, Selector)->()) {
            var control: UIView
            var selector: Selector
            switch tapControl {
            case .label:
                control = label
                selector = #selector(ScorecardInputCollectionCell.labelTapped(_:))
            case .textViewClear:
                control = textClear
                selector = #selector(ScorecardInputCollectionCell.textViewClearPressed)
            case .textFieldClear:
                control = textClear
                selector = #selector(ScorecardInputCollectionCell.textFieldClearPressed)
            case .responsible:
                control = responsiblePicker
                selector = #selector(ScorecardInputCollectionCell.responsibleTapped)
            case .declarer:
                control = declarerPicker
                selector = #selector(ScorecardInputCollectionCell.declarerTapped)
            case .seat:
                control = seatPicker
                selector = #selector(ScorecardInputCollectionCell.seatPickerTapped)
            case .made:
                control = madePicker
                selector = #selector(ScorecardInputCollectionCell.madeTapped)
            }
            action(control, selector)
        }
    }
    
    private var importedVersus: String {
        var versus = ""
        let players = table.players
        let sitting = table.sitting
        var separator = ""
        if sitting == .unknown {
            versus = "Sitout"
        } else {
            for seat in [sitting.partner, sitting.leftOpponent, sitting.rightOpponent] {
                if scorecard.type.players == 1 || seat != sitting.partner {
                    let bboName = players[seat] ?? "Unknown"
                    let realName = MasterData.shared.realName(bboName: bboName) ?? bboName
                    versus += separator + realName
                    separator = (seat == sitting.partner ? " v " : " & ")
                }
            }
        }
        return (versus == "" ? table.versus : versus)
    }
    
    private var madeList: (list: [ScrollPickerEntry], minValue: Int, maxValue: Int) {
        var list: [ScrollPickerEntry] = []
        var minValue = 0
        var maxValue = 0
        if board.contract.suit != .blank {
            let tricks = board.contract.level.rawValue
            minValue = -(Values.trickOffset + tricks)
            maxValue = 7 - tricks
            for made in 0...13 {
                let plusMinus = made - 6 - tricks
                let value = Scorecard.madeString(made: plusMinus)
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
                scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber, column: columnType)
            }
        }
    }
    internal func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if column.type == .versus || column.type == .comment {
            if range.location + range.length == NSString(utf8String: textField.text!)!.length {
                let result = (textField.text! as NSString).replacingCharacters(in: range, with: string)
                textAutoComplete(text: result, textField: textField)
            }
        }
        return true
    }
    
    internal func replace(with text: String, textField: UITextField? = nil, textView: UITextView? = nil, at range: NSRange) {
        if let textField = textField {
            textField.text = (textField.text! as NSString).replacingCharacters(in: range, with: text)
            textFieldChanged(textField)
        }
        if let textView = textView {
            textView.text = (textView.text! as NSString).replacingCharacters(in: range, with: text)
            textViewDidChange(textView)
        }
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
    
    @objc internal func textFieldClearPressed(_ textFieldClear: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber)
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
            textField.text = ""
            textField.resignFirstResponder()
            textFieldChanged(textField)
        }
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
                    let wasBlank = board.comment == ""
                    let isBlank = text == ""
                    board.comment = text
                    enableCommentControls()
                    if wasBlank != isBlank {
                        scorecardDelegate?.scorecardChanged(type: .board, itemNumber: itemNumber, column: .comment, refresh: true)
                    }
                case .versus:
                    table.versus = text
                default:
                    break
                }
                textClear.isHidden = (text == "")
                scorecardDelegate?.scorecardChanged(type: .board, itemNumber: itemNumber, column: columnType)
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        } else {
            if column.type == .versus || column.type == .comment {
                if range.location + range.length == NSString(utf8String: textView.text!)!.length {
                    let result = (textView.text! as NSString).replacingCharacters(in: range, with: text)
                    textAutoComplete(text: result, textView: textView)
                }
            }
            return true
        }
    }
    
    internal func textViewDidBeginEditing(_ textView: UITextView) {
        switch column.type {
        case .comment:
            textView.textContainer.maximumNumberOfLines = 0
        default:
            break
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        switch self.column.type {
        case .comment:
            textView.textContainer.maximumNumberOfLines = 2
            board.comment = textView.text
            enableCommentControls()
        case .versus:
            table.versus = textView.text
        default:
            break
        }
    }
    
    @objc internal func textViewClearPressed(_ textViewClear: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber)
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
            switch self.column.type {
            case .comment:
                enableCommentControls()
            default:
                break
            }
            textView.resignFirstResponder()
            textViewDidChange(textView)
        }
    }
    
    private func textAutoComplete(text: String, textView: UITextView? = nil, textField: UITextField? = nil) {
        if let autoComplete = scorecardDelegate?.autoComplete {
            if let last = autoComplete.last(text: text, columnType: column.type) {
                autoComplete.delegate = self
                let listSize = autoComplete.set(text: last, textField: textField, textView: textView, at: NSRange(location: NSString(utf8String: text)!.length - NSString(utf8String: last)!.length, length: last.length), columnType: column.type)
                if listSize == 0 {
                    autoComplete.isHidden = true
                } else {
                    autoComplete.isHidden = false
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
            scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber, column: columnType)
        }
    }
    
    internal func contractDidChange(to value: Contract, made: Int? = nil, declarer: Seat? = nil) {
        if let board = board {
            let undoValue = board.contract
            let made = (value.level == .blank || value.level == .passout ? nil : (made ?? board.made))
            let declarer = declarer ?? board.declarer
            let undoMade = board.made
            let undoDeclarer = board.declarer
            let rowType = rowType!
            let columnType = column.type
            let itemNumber = itemNumber!
            if value != undoValue || made != undoMade || declarer != undoDeclarer {
                UndoManager.registerUndo(withTarget: label) { (label) in
                    if let cell = self.scorecardDelegate?.scorecardCell(rowType: rowType, itemNumber: itemNumber, columnType: columnType) {
                        cell.label.attributedText = NSAttributedString(undoValue.colorString)
                        cell.board.made = made
                        cell.board.declarer = declarer
                        cell.contractDidChange(to: undoValue, made: undoMade, declarer: undoDeclarer)
                    }
                }
                board.contract = value
                board.made = made
                board.declarer = declarer
                scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber, column: columnType)
            }
        }
    }

    @objc internal func labelTapped(_ sender: UITapGestureRecognizer) {
        scorecardDelegate?.scorecardEndEditing(true)
        if let rowType = rowType, let itemNumber = itemNumber, let column = ColumnType(rawValue: sender.view?.tag ?? -1) {
            scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber)
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
                if Scorecard.current.isImported && board?.score != nil {
                    scoreTapped(self)
                }
            case .commentAvailable:
                if rowType == .boardTitle || Scorecard.current.isImported && board?.score != nil {
                    scorecardDelegate?.setAnalysisCommentBoardNumber(boardNumber: board?.board ?? -1)
                }
            case .comment:
                if Scorecard.current.isImported && board?.score != nil {
                    label.isHidden = true
                    label.isUserInteractionEnabled = false
                    textView.isHidden = false
                    set(tap: .textViewClear)
                    textView.becomeFirstResponder()
                }
            default:
                if Scorecard.current.isImported && board?.score != nil {
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
        let makingValue = (Values.trickOffset + board.contract.level.rawValue)
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
        let selected = Responsible.validCases.firstIndex(of: board.responsible)
        scorecardDelegate?.scorecardScrollPickerPopup(values: Responsible.validCases.map{ScrollPickerEntry(title: $0.short, caption: $0.full)}, maxValues: 13, selected: selected, defaultValue: nil, frame: CGRect(x: self.frame.minX + space, y: self.frame.minY, width: width, height: self.frame.height), in: self.superview!, topPadding: 16, bottomPadding: 0) { (selected) in
            let responsible = Responsible.validCases[selected!]
            self.responsiblePicker.set(responsible)
            self.enumPickerDidChange(to: responsible)
        }
    }
    
    private func showHand() {
        if MyApp.format != .phone {
            scorecardDelegate?.scorecardShowHand(scorecard: scorecard, board: board, sitting: table.sitting)
        }
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
            undoValue = board.made == nil ? nil : board.made! + (Values.trickOffset + board.contract.level.rawValue)
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
                    board.made =  (value == nil ? nil : value! - (Values.trickOffset + board.contract.level.rawValue))
                default:
                    break
                }
                scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber, column: columnType)
            }
        }
    }
    
}

protocol AutoCompleteDelegate {
    func replace(with: String, textField: UITextField?, textView: UITextView?, at range: NSRange)
}

extension AutoCompleteDelegate {
    func replace(with: String, textField: UITextField?, at range: NSRange) {
        replace(with: with, textField: textField, textView: nil, at: range)
    }
    
    func replace(with: String, textView: UITextView?, at range: NSRange) {
        replace(with: with, textField: nil, textView: textView, at: range)
    }

}

class AutoComplete: UIView, UITableViewDataSource, UITableViewDelegate {
    var tableView = UITableView()
    var text: String = ""
    var nameList: [(replace: String, with: String, description: String)] = []
    var textField: UITextField?
    var textView: UITextView?
    var columnType: ColumnType!
    var range: NSRange!
    var delegate: AutoCompleteDelegate?
    
    init() {
        super.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 100, height: 100)))
        self.isHidden = true
        addSubview(tableView, leading: 2, trailing: 2, top: 2, bottom: 2)
        AutoCompleteCell.register(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
       
    public func set(text: String, textField: UITextField? = nil, textView: UITextView? = nil, at range: NSRange, columnType: ColumnType) -> Int {
        self.text = text
        self.textField = textField
        self.textView = textView
        self.columnType = columnType
        self.range = range
        if self.text == "" {
            nameList = []
        } else {
            switch columnType {
            case .versus:
                nameList = MasterData.shared.bboNames.filter({$0.bboName.lowercased().starts(with: self.text.lowercased())}).map{($0.bboName, $0.name, $0.name)}
            case .comment:
                nameList = Suit.validCases.filter({$0.short.uppercased().starts(with: self.text.uppercased())}).filter({$0.string != self.text}).map{($0.string, $0.string, "")}
            default:
                nameList = []
            }
        }
        self.isHidden = nameList.isEmpty
        self.tableView.reloadData()
        return nameList.count
    }
    
    public func last(text: String, columnType: ColumnType) -> String? {
        switch columnType {
        case .versus:
            text.components(separatedBy: " ").last
        case .comment:
            text.length == 0 ? "" : trailingAlphaCharacters(text: text)
        default:
            nil
        }
    }
    
    func trailingAlphaCharacters(text: String) -> String? {
        var result = ""
        for index in (0..<text.length).reversed() {
            let char = text.mid(index, 1)
            if char.rangeOfCharacter(from: CharacterSet.letters) != nil {
                result = char + result
            } else {
                break
            }
        }
        return result
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = AutoCompleteCell.dequeue(tableView: tableView, for: indexPath)
        cell.set(text: nameList[indexPath.row].replace, description: nameList[indexPath.row].description)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var with = nameList[indexPath.row].with
        switch columnType {
        case .versus:
            with += (range.location == 0 ? " & " : "")
        default:
            break
        }
        delegate?.replace(with: with, textField: textField, textView: textView, at: range)
    }
}

class AutoCompleteCell: UITableViewCell {
    private var label = UILabel()
    private var desc = UILabel()
    static public var cellIdentifier = "Auto Complete Cell"
    private var descWidth: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(label, leading: 8, top: 0, bottom: 0)
        addSubview(desc, trailing: 8, top: 0, bottom: 0)
        Constraint.anchor(view: self, control: label, to: desc, constant: 8, toAttribute: .leading, attributes: .trailing)
        descWidth = Constraint.setWidth(control: desc, width: 0)
        
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
    
    public func set(text: String, description: String = "") {
        label.text = text
        desc.text = description
        label.font = cellFont
        label.textColor = UIColor(Palette.autoComplete.text)
        desc.textColor = UIColor(Palette.autoComplete.contrastText)
        desc.font = cellFont
        descWidth.constant = (description == "" ? 0 : self.frame.width / 2)
    }
}

extension Array where Element == ScorecardColumn {
    
    public var copy: [ScorecardColumn] {
        var result: [ScorecardColumn] = []
        self.forEach { element in
            result.append(element.copy)
        }
        return result
    }
    
}
