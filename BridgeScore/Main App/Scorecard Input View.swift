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
    var minX: CGFloat?
    var width: CGFloat?
    
    init(type: ColumnType, heading: String, size: ColumnSize, phoneSize: ColumnSize? = nil, omit: Bool = false, minX: CGFloat? = nil, width: CGFloat? = nil) {
        self.type = type
        self.heading = heading
        self.size = size
        self.phoneSize = phoneSize ?? size
        self.omit = omit
        self.minX = minX
        self.width = width
    }
    
    public var maxX: CGFloat? {
        if let minX = minX, let width = width {
            minX + width
        } else {
            nil
        }
    }
    
    public static func == (lhs: ScorecardColumn, rhs: ScorecardColumn) -> Bool {
        return lhs.type == rhs.type && lhs.heading == rhs.heading && lhs.size == rhs.size && lhs.phoneSize == rhs.phoneSize && lhs.omit == rhs.omit && lhs.width == rhs.width
    }
    
    var copy: ScorecardColumn {
        ScorecardColumn(type: type, heading: heading, size: size, phoneSize: phoneSize, omit: omit, minX: minX, width: width)
    }
}

enum RowType: Int {
    case table = 1
    case board = 2
    case boardTitle = 3
    
    var tagOffset: Int {
        return self.rawValue * tagMultiplier
    }
    
    var other: RowType {
        switch self {
        case .table:
            .board
        case .board:
            .table
        default:
            self
        }
    }
    
    var entity: ScorecardEntity? {
        switch self {
        case .table:
            ScorecardEntity.table
        case .board:
            ScorecardEntity.board
        default:
            nil
        }
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
    case noTap
    case label
    case responsible
    case declarer
    case seat
    case made
    case contract
    case textInput
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
    @State private var uiView: UIView!
    @State private var analysisViewer = false
    @State private var dismissView = false
    
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
                    ScorecardInputUIViewWrapper(scorecard: scorecard, frame: geometry.frame(in: .local), refreshTableTotals: $refreshTableTotals, viewType: $viewType, hideRejected: $hideRejected, inputDetail: $inputDetail, tableRefresh: $tableRefresh, showRankings: $showRankings, disableBanner: $disableBanner, handViewer: $handViewer, handBoard: $handBoard, handTraveller: $handTraveller, handSitting: $handSitting, uiView: $uiView, analysisViewer: $analysisViewer)
                        .ignoresSafeArea(edges: .all)
                }
            }.undoManager(canUndo: $canUndo, canRedo: $canRedo)
        }
        .onChange(of: uiView) {
            // Seem to need this to trigger refresh
        }
        .onChange(of: tableRefresh, initial: false) { tableRefresh = false}
        .onChange(of: showRankings, initial: false) { showRankings = false}
        .onChange(of: refreshTableTotals, initial: false) { refreshTableTotals = false}
        .fullScreenCover(isPresented: $inputDetail, onDismiss: {
            UndoManager.clearActions()
            if deleted {
                presentationMode.wrappedValue.dismiss()
            } else {
                refreshTableTotals = true
            }
        }) {
            ZStack {
                let title = "Details" + (Scorecard.current.isImported ? " - Imported from \(Scorecard.current.scorecard!.importSource.from)" : "")
                let backgroundView = UIView(frame: uiView.superview!.superview!.frame)
                let width = min(704, backgroundView.frame.width) // Allow for safe area
                let height = min(784, (backgroundView.frame.height))
                let frame = CGRect(x: (backgroundView.frame.width - width) / 2,
                                   y: ((backgroundView.frame.height - height) / 2),
                                   width: width,
                                   height: height)
                
                Color.black.opacity(0.4)
                ScorecardDetailView(scorecard: scorecard, deleted: $deleted, tableRefresh: $tableRefresh, title: title, frame: frame, initialYOffset: backgroundView.frame.height + 100, dismissView: $dismissView)
                    .cornerRadius(8)
                Spacer()
            }
            .background(BackgroundBlurView(opacity: 0.0))
            .edgesIgnoringSafeArea(.all)
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
                    HandViewerForm(board: handBoard, traveller: handTraveller, sitting: handSitting, from: uiView)
                }
            }
        }
        .fullScreenCover(isPresented: $analysisViewer, onDismiss: {
            UndoManager.clearActions()
            disableBanner = false
            tableRefresh = true
        }, content: {
            if let handBoard = handBoard {
                if let handTraveller = handTraveller {
                    ZStack{
                        Color.black.opacity(0.4)
                        let backgroundView = UIView(frame: uiView.superview!.superview!.frame)
                        let width = min(1134, backgroundView.frame.width) // Allow for safe area
                        let height = min(794, (backgroundView.frame.height))
                        let frame = CGRect(x: (backgroundView.frame.width - width) / 2,
                                           y: ((backgroundView.frame.height - height) / 2),
                                           width: width,
                                           height: height)
                        AnalysisViewer(board: handBoard, traveller: handTraveller, sitting: handSitting, frame: frame, initialYOffset: backgroundView.frame.height + 100, dismissView: $dismissView, from: uiView)
                            .cornerRadius(8)
                        Spacer()
                    }
                    .background(BackgroundBlurView(opacity: 0.0))
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        dismissView = true
                    }
                }
            }
        })
        .transaction { transaction in
            transaction.disablesAnimations = true
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
        if isNotImported.wrappedValue || (scorecard.resetNumbers && scorecard.importNext <= scorecard.tables) {
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
                    MessageBox.shared.show("This will remove imported rankings and travellers and any analysis and unlock the scorecard for editing. Are you sure you want to do this?", cancelText: "Cancel", okText: "Remove", okDestructive: true, okAction: {
                        MessageBox.shared.show("Clearing import...", okText: nil)
                        Utility.executeAfter(delay: 0.1) {
                            if let context = CoreData.context {
                                context.performAndWait {
                                    Scorecard.current.clearImport()
                                }
                                isNotImported.wrappedValue = true
                                viewType = (viewType == .analysis ? .normal : viewType)
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

struct ScorecardInputUIViewWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = ScorecardInputUIViewController
    
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
    @Binding var uiView: UIView?
    @Binding var analysisViewer: Bool
    
    func makeUIViewController(context: Context) -> ScorecardInputUIViewController {
        
        let inputViewController = ScorecardInputUIViewController(frame: frame, scorecard: scorecard, inputDetail: inputDetail, disableBanner: $disableBanner, handViewer: $handViewer, handBoard: $handBoard, handTraveller: $handTraveller, handSitting: $handSitting, analysisViewer: $analysisViewer)
        UndoManager.clearActions()
        inputViewController.delegate = context.coordinator
        
        return inputViewController
    }
    
    func updateUIViewController(_ uiViewController: ScorecardInputUIViewController, context: Context) {
        
        uiViewController.inputDetail = inputDetail
        
        if let inputView = uiViewController.view as? ScorecardInputUIView {
            if refreshTableTotals {
                inputView.refreshTableTotals()
            }
            
            if tableRefresh {
                inputView.tableRefresh()
            }
            
            if showRankings {
                inputView.showRankings()
            }
            
            inputView.change(viewType: viewType)
            
            if inputView.scorecardHideRejected != hideRejected {
                inputView.scorecardHideRejected = hideRejected
                inputView.tableRefresh()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ScorecardInputViewControllerDelegate {
        var parent: ScorecardInputUIViewWrapper
        
        init(_ parent: ScorecardInputUIViewWrapper) {
            self.parent = parent
        }
        
        func updateView(view: UIView?) {
            self.parent.uiView = view
        }
    }
}

protocol ScorecardDelegate {
    func scorecardChanged(type: RowType, itemNumber: Int, column: ColumnType?, refresh: Bool)
    func scorecardCell(rowType: RowType, itemNumber: Int, columnType: ColumnType) -> ScorecardInputCollectionCell?
    func scorecardContractEntry(board: BoardViewModel, table: TableViewModel, contract:Contract?)
    func scorecardBBONamesReplace(values: [String])
    func scorecardShowTraveller(scorecard: ScorecardViewModel, board: BoardViewModel, sitting: Seat)
    func scorecardShowHand(scorecard: ScorecardViewModel, board: BoardViewModel, sitting: Seat)
    func scorecardScrollPickerPopup(values: [ScrollPickerEntry], maxValues: Int, selected: Int?, defaultValue: Int?, frame: CGRect, in container: UIView, topPadding: CGFloat, bottomPadding: CGFloat, completion: @escaping (Int?, KeyAction?)->())
    func scorecardDeclarerPickerPopup(values: [(Seat, ScrollPickerEntry)], selected: Seat?, frame: CGRect, in container: UIView, topPadding: CGFloat, bottomPadding: CGFloat, completion: @escaping (Seat?, KeyAction?)->())
    func scorecardGetDeclarers(tableNumber: Int) -> [Seat]
    func scorecardUpdateDeclarers(tableNumber: Int, to: [Seat]?)
    func scorecardSelectNext(rowType: RowType, itemNumber: Int, columnType: ColumnType?, action: KeyAction)
    func scorecardEndEditing(_ force: Bool)
    func scorecardSetCommentBoardNumber(boardNumber: Int)
    var scorecardViewType: ViewType {get}
    var scorecardHideRejected: Bool {get}
    var scorecardCommentBoardNumber: Int? {get}
    var scorecardAutoComplete: [ColumnType:AutoComplete] {get}
    var scorecardKeyboardHeight: CGFloat {get}
    var scorecardInputControlInset: CGFloat {get}
    var scorecardFocusCell: ScorecardInputCollectionCell? {get set}
    var scorecardMainTableView: UITableView {get}
}

extension ScorecardDelegate {
    func scorecardChanged(type: RowType, itemNumber: Int) {
        scorecardChanged(type: type, itemNumber: itemNumber, column: nil, refresh: false)
    }
    func scorecardChanged(type: RowType, itemNumber: Int, column: ColumnType?) {
        scorecardChanged(type: type, itemNumber: itemNumber, column: column, refresh: false)
    }
    func scorecardScrollPickerPopup(values: [String], maxValues: Int, selected: Int?, defaultValue: Int?, frame: CGRect, in container: UIView, topPadding: CGFloat, bottomPadding: CGFloat, completion: @escaping (Int?, KeyAction?)->()) {
        scorecardScrollPickerPopup(values: values.map{ScrollPickerEntry(title: $0, caption: nil)}, maxValues: maxValues, selected: selected, defaultValue: defaultValue, frame: frame, in: container, topPadding: topPadding, bottomPadding: bottomPadding, completion: completion)
    }
}

fileprivate var titleRowHeight: CGFloat { MyApp.format == .phone ? (isLandscape ? 30 : 40) : 40 }
fileprivate var boardRowHeight: CGFloat { MyApp.format == .phone ? (isLandscape ? 50 : 70) : 90 }
fileprivate var tableRowHeight: CGFloat { MyApp.format == .phone ? (isLandscape ? 60 : 60) : 80 }

protocol ScorecardInputViewControllerDelegate {
    func updateView(view: UIView?)
}

class ScorecardInputUIViewController: UIViewController {
    private var scorecard: ScorecardViewModel!
    private var titleView: ScorecardInputTableTitleView!
    public var inputDetail = false
    private var disableBanner: Binding<Bool>
    public var handViewer: Binding<Bool>
    public var handBoard: Binding<BoardViewModel?>
    public var handTraveller: Binding<TravellerViewModel?>
    public var handSitting: Binding<Seat>
    public var analysisViewer: Binding<Bool>
    private var frame: CGRect!
    public var delegate: ScorecardInputViewControllerDelegate?
    
    init(frame: CGRect, scorecard: ScorecardViewModel, inputDetail: Bool, disableBanner: Binding<Bool>, handViewer: Binding<Bool>, handBoard: Binding<BoardViewModel?>, handTraveller: Binding<TravellerViewModel?>, handSitting: Binding<Seat>, analysisViewer: Binding<Bool>) {
        self.frame = frame
        self.scorecard = scorecard
        self.inputDetail = inputDetail
        self.disableBanner = disableBanner
        self.handViewer = handViewer
        self.handBoard = handBoard
        self.handTraveller = handTraveller
        self.handSitting = handSitting
        self.analysisViewer = analysisViewer
        super.init(nibName: nil, bundle: nil)
    }
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        return false
    }
    
    override func loadView() {
        view = ScorecardInputUIView(viewController: self, frame: frame, scorecard: scorecard, inputDetail: inputDetail, disableBanner: disableBanner, handViewer: handViewer, handBoard: handBoard, handTraveller: handTraveller, handSitting: handSitting, analysisViewer: analysisViewer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.updateView(view: view)
    }
    
    let x = UIViewController()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class ScorecardInputUIView : UIView, ScorecardDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    private var scorecard: ScorecardViewModel
    private var titleView: ScorecardInputTableTitleView!
    private var mainTableView = UITableView(frame: CGRect(), style: .plain)
    private var contractEntryView: ScorecardContractEntryView
    private var scrollPickerPopupView: ScrollPickerPopupView
    private var declarerPickerPopupView: DeclarerPickerPopupView
    private var subscription: AnyCancellable?
    private var lastKeyboardScrollOffset: CGFloat = 0
    internal var scorecardKeyboardHeight: CGFloat = 0
    private var isKeyboardOffset = false
    private var bottomConstraint: NSLayoutConstraint!
    private var forceReload = true
    internal var scorecardViewType = ViewType.normal
    internal var scorecardHideRejected = true
    public var inputDetail: Bool
    private var disableBanner: Binding<Bool>
    public var handViewer: Binding<Bool>
    public var handBoard: Binding<BoardViewModel?>
    public var handTraveller: Binding<TravellerViewModel?>
    public var handSitting: Binding<Seat>
    public var analysisViewer: Binding<Bool>
    private var ignoreKeyboard = false
    private var titleHeightConstraint: NSLayoutConstraint!
    private var orientation: UIDeviceOrientation?
    internal var scorecardCommentBoardNumber: Int?
    internal var scorecardInputControlInset: CGFloat = 0
    private var viewController: UIViewController!
    private var maskBackgroundView: UIView!
    internal var focusRowType: RowType?
    internal var focusTable: Int?
    internal var focusBoard: Int?
    internal var focusColumnType: ColumnType?
    
    var boardColumns: [ScorecardColumn] = []
    var boardAnalysisCommentColumns: [ScorecardColumn] = []
    var tableColumns: [ScorecardColumn] = []
    
    init(viewController: UIViewController, frame: CGRect, scorecard: ScorecardViewModel, inputDetail: Bool, disableBanner: Binding<Bool>, handViewer: Binding<Bool>, handBoard: Binding<BoardViewModel?>, handTraveller: Binding<TravellerViewModel?>, handSitting: Binding<Seat>, analysisViewer: Binding<Bool>) {
        self.viewController = viewController
        self.scorecard = scorecard
        self.inputDetail = inputDetail
        self.disableBanner = disableBanner
        self.handViewer = handViewer
        self.handBoard = handBoard
        self.handTraveller = handTraveller
        self.handSitting = handSitting
        self.analysisViewer = analysisViewer
        self.contractEntryView = ScorecardContractEntryView(frame: CGRect())
        self.scrollPickerPopupView = ScrollPickerPopupView(frame: CGRect())
        self.declarerPickerPopupView = DeclarerPickerPopupView(frame: CGRect())
        
        super.init(frame: frame)
    
        // Set up view
        change(viewType: scorecardViewType, force: true)
                    
        // Add subviews
        titleView = ScorecardInputTableTitleView(self, frame: CGRect(), tag: RowType.boardTitle.tagOffset)
        self.addSubview(titleView, anchored: .safeLeading, .safeTrailing, .top)
        titleHeightConstraint = Constraint.setHeight(control: titleView, height: titleRowHeight)
        
        self.addSubview(self.mainTableView, anchored: .leading, .trailing)
        mainTableView.allowsFocus = false
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
        
        // Setup auto-complete views
        for columnType in [ColumnType.versus, .comment] {
            let autoComplete = AutoComplete()
            switch columnType {
            case .versus:
                let nameList = MasterData.shared.bboNames.map{($0.bboName, $0.name, $0.name)}
                autoComplete.set(list: nameList, consider: .lastWord, adjustReplace: versusAdjustReplace, mustStart: false, searchDescription: true)
            case .comment:
                var list:[(String, String, String)] = []
                for rank in CardRank.allCases {
                    list.append(contentsOf: Suit.realSuits.map({(rank.short + $0.short.uppercased(), rank.short + $0.string, "\(rank.string) \(rank.rawValue > 7 ? "of" : "") \($0.words)")}))
                }
                list.append(contentsOf: Suit.realSuits.map({($0.short.uppercased(), $0.string, $0.words)}))
                list.append(contentsOf: Suit.realSuits.map({("1" + $0.short.uppercased(), "1" + $0.string, "1 " + $0.singular)}))
                autoComplete.set(list: list, consider: .trailingAlphaNumeric)
            default:
                break
            }
            scorecardAutoComplete[columnType] = autoComplete
            self.addSubview(autoComplete)
        }
                
        subscription = Publishers.keyboardHeight.sink { (keyboardHeight) in
            self.keyboardMoved(keyboardHeight)
        }
    }
    
    func versusAdjustReplace(text: String, start: Bool, end: Bool) -> String {
        start && end ? text + " & " : text
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
        
        if viewType != self.scorecardViewType || force {
            if viewType == .analysis {
                boardColumns = [
                    ScorecardColumn(type: .board, heading: "Board", size: .fixed([70]), phoneSize: .fixed([40])),
                    ScorecardColumn(type: .teamTable, heading: "Team", size: .fixed([60]), omit: !teams || phone),
                    ScorecardColumn(type: .combined, heading: "Contract", size: .fixed([(teams ? 100 : 120)]), phoneSize: .fixed([90])),
                    ScorecardColumn(type: .points, heading: "Points", size: .fixed([(teams ? 70 : 90)]), omit: phone),
                    ScorecardColumn(type: .score, heading: "Score", size: .fixed([(teams ? 70 : 90)]), phoneSize: .fixed([70])),
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
                    ScorecardColumn(type: .sitting, heading: "Sitting", size: .fixed([(teams ? 100 : 120)]), phoneSize: .fixed([90])),
                    ScorecardColumn(type: .tableScore, heading: "", size: .fixed([(teams ? 70 : 90), (teams ? 70 : 90)]), phoneSize: .fixed([70])),
                    ScorecardColumn(type: .versus, heading: "Versus", size: .flexible)]
            } else if viewType == .detail {
                boardColumns = [
                    ScorecardColumn(type: .board, heading: "Board", size: .fixed([70]), phoneSize: .fixed([40])),
                    ScorecardColumn(type: .vulnerable, heading: "Vul", size: .fixed([30])),
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
            self.scorecardViewType = viewType
            forceReload = true
            self.setNeedsLayout()
        }
    }
    
    internal var scorecardFocusCell: ScorecardInputCollectionCell? {
        get {
            if let rowType = focusRowType, let table = focusTable, let columnType = focusColumnType, let column = getColumnNumber(rowType: rowType, itemNumber: (rowType == .board ? (focusBoard ?? 0) : table), type: columnType) {
                cell(rowType: rowType, section: table - 1, row: (focusBoard == nil ? nil : focusBoard! - 1), column: column)
            } else {
                nil
            }
        }
        set(cell) {
            if let cell = cell {
                focusRowType = cell.rowType
                focusTable = cell.table.table
                focusBoard = cell.board?.board
                focusColumnType = cell.column.type
            } else {
                focusRowType = nil
                focusTable = nil
                focusBoard = nil
                focusColumnType = nil
            }
        }
    }
    
    public func showRankings() {
        let rankings = ScorecardRankingView(frame: CGRect())
        rankings.show(from: superview!.superview!, frame: self.superview!.superview!.frame) {
            self.disableBanner.wrappedValue = false
        }
    }
    
    public func showMaskBackground() {
        if maskBackgroundView == nil {
            maskBackgroundView = UIView(frame: superview!.superview!.frame)
            maskBackgroundView?.backgroundColor = UIColor(Palette.maskBackground)
            superview!.superview!.addSubview(maskBackgroundView, anchored: .all)
        }
        maskBackgroundView.isHidden = false
    }
    
    public func hidMaskBackground() {
        maskBackgroundView.isHidden = true
    }
    
    // MARK: - Scorecard delegates
    
    internal var scorecardAutoComplete: [ColumnType:AutoComplete] = [:]
    
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
    
    func scorecardContractEntry(board: BoardViewModel, table: TableViewModel, contract: Contract?) {
        contractEntryView = ScorecardContractEntryView(frame: CGRect())
        let section = (board.board - 1) / self.scorecard.boardsTable
        disableBanner.wrappedValue = true
        contractEntryView.show(from: superview!.superview!, contract: contract ?? board.contract, sitting: table.sitting, declarer: board.declarer) { [self] (contract, declarer, sitting, keyAction) in
            if let sitting = sitting {
                if sitting != table.sitting {
                    if let tableCell = mainTableView.headerView(forSection: section) as? ScorecardInputTableSectionHeaderView {
                        // Update sitting
                        if let item = tableColumns.firstIndex(where: {$0.type == .sitting}) {
                            if let cell = tableCell.collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? ScorecardInputCollectionCell {
                                cell.seatPicker.set(sitting)
                                cell.enumPickerDidChange(to: sitting)
                            }
                        }
                    }
                }
            }
            
            if let columnNumber = getColumnNumber(rowType: .board, itemNumber: board.board, type: .contract) {
                if let cell = cell(rowType: .board, section: table.table - 1, row: board.board - 1, column: columnNumber) {
                    if let contract = contract {
                        if contract != board.contract || declarer != board.declarer {
                            cell.contractPicker.set(contract: contract)
                            cell.contractDidChange(to: contract, declarer: declarer)
                        }
                    }
                    if let keyAction = keyAction {
                        if !cell.keyPressed(keyAction: keyAction) {
                            cell.getFocus()
                        }
                    } else {
                        cell.getFocus()
                    }
                }
            }
            disableBanner.wrappedValue = false
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
            showTraverllerView.show(from: self, frame: self.superview!.superview!.frame, boardNumber: board.board, sitting: sitting) {
                self.disableBanner.wrappedValue = false
            }
        }
    }
    
    func scorecardShowHand(scorecard: ScorecardViewModel, board: BoardViewModel, sitting: Seat) {
        if !Scorecard.current.travellerList.isEmpty {
            if let (board, traveller, _) = Scorecard.getBoardTraveller(boardNumber: board.board) {
                disableBanner.wrappedValue = true
                handBoard.wrappedValue = board
                handTraveller.wrappedValue = traveller
                handSitting.wrappedValue = sitting
                if scorecardViewType == .analysis {
                    handViewer.wrappedValue = false
                    analysisViewer.wrappedValue = true
                } else {
                    handViewer.wrappedValue = true
                    analysisViewer.wrappedValue = false
                }
            }
        }
    }
    
    func scorecardScrollPickerPopup(values: [ScrollPickerEntry], maxValues: Int, selected: Int?, defaultValue: Int?, frame: CGRect, in container: UIView, topPadding: CGFloat, bottomPadding: CGFloat, completion: @escaping (Int?, KeyAction?)->()) {
        scrollPickerPopupView.show(from: self, values: values, maxValues: maxValues, selected: selected, defaultValue: defaultValue, frame: container.convert(frame, to: self), topPadding: topPadding, bottomPadding: bottomPadding) { (selected, keyAction) in
            completion(selected, keyAction)
        }
    }
    
    func scorecardDeclarerPickerPopup(values: [(Seat, ScrollPickerEntry)], selected: Seat?, frame: CGRect, in container: UIView, topPadding: CGFloat, bottomPadding: CGFloat, completion: @escaping (Seat?, KeyAction?)->()) {
        var frame = container.convert(frame, to: self)
        let freeSpace = self.mainTableView.frame.maxY - frame.maxY
        let offset = mainTableView.contentOffset
        if freeSpace < frame.height {
            // Need to scroll down a row
            let adjustY = frame.height - freeSpace
            mainTableView.contentOffset = offset.offsetBy(dy: adjustY)
            frame = frame.offsetBy(dy: -adjustY)
        }
        declarerPickerPopupView.show(from: self, values: values, selected: selected, frame: frame, topPadding: topPadding, bottomPadding: bottomPadding) { [self] (selected, keyAction) in
            mainTableView.contentOffset = offset
            completion(selected, keyAction)
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
    
    internal func scorecardSelectNext(rowType: RowType, itemNumber: Int, columnType: ColumnType?, action: KeyAction) {
        
        scorecardSelect(rowType: rowType, itemNumber: itemNumber, columnType: columnType, originalColumnType: columnType, action: action, originalAction: action)
    }
    
    @discardableResult private func scorecardSelect(rowType: RowType, itemNumber: Int, columnType: ColumnType?, originalColumnType: ColumnType?, action: KeyAction, originalAction: KeyAction, initialOffset: Int? = nil, scrolling: Bool = true) -> Bool? {
        
        let newItemNumber = itemNumber
        var newColumnNumber: Int?
        var columnNumber: Int?
        
        let section = (rowType == .table ? itemNumber - 1 : (itemNumber - 1) / scorecard.boardsTable)
        let row = (rowType == .table ? nil : (itemNumber - 1) % scorecard.boardsTable)
            
        if scrolling {
            // Make sure this row is in view
            // Scroll row into view if necessary
            let tableIndexPath = IndexPath(row: row ?? 0, section: section)
            let frame = mainTableView.rectForRow(at: tableIndexPath)
            let atPosition = moveTo(cellFrame: frame)
            if let atPosition = atPosition {
                Utility.animate(parent: self, duration: 0.1, completion: { [self] in
                    scorecardSelect(rowType: rowType, itemNumber: itemNumber, columnType: columnType, originalColumnType: originalColumnType, action: action, originalAction: originalAction, initialOffset: initialOffset, scrolling: false)
                }, animations: { [self] in
                    mainTableView.scrollToRow(at: (mainTableView.contentOffset.y < 0 ? IndexPath(row: 0, section: 0) : tableIndexPath), at: atPosition, animated: false)
                })
                return nil
            }
        }
            
        if let columnType = columnType {
            // Column might not exist in this row type
            columnNumber = getColumnNumber(rowType: rowType, itemNumber: itemNumber, type: columnType, findNearest: true)
        }
        if columnNumber == nil {
            // Didn't exist in row or positioning off the ends of row
            columnNumber = (action == .previous ? getColumns(rowType: rowType, itemNumber: itemNumber).count - 1 : 0)
        }
        if let collectionView = rowCollectionView(rowType: rowType, section: section, row: row) {
            if let columnNumber = columnNumber {
                let adjustedColumnNumber = columnNumber + (initialOffset ?? 0)
                switch action {
                case .up:
                    if let (newRowType, newItemNumber) = previousRow(rowType: rowType, itemNumber: itemNumber) {
                        return scorecardSelect(rowType: newRowType, itemNumber: newItemNumber, columnType: columnType, originalColumnType: originalColumnType, action: .next, originalAction: originalAction, initialOffset: -1)
                    }
                case .down:
                    if let (newRowType, newItemNumber) = nextRow(rowType: rowType, itemNumber: itemNumber) {
                        return scorecardSelect(rowType: newRowType, itemNumber: newItemNumber, columnType: columnType, originalColumnType: originalColumnType, action: .next, originalAction: originalAction, initialOffset: -1)
                    }
                case .previous, .backspace:
                    newColumnNumber = nextRowCell(collectionView: collectionView, columnNumber: adjustedColumnNumber, increment: -1)
                    if newColumnNumber == nil && action != originalAction {
                        // Trying to find column in row - try going the other way
                        newColumnNumber = nextRowCell(collectionView: collectionView, columnNumber: columnNumber - 1, increment: +1)
                        if newColumnNumber == nil {
                            // No editable columns in row - carry on in original direction
                            return scorecardSelect(rowType: rowType, itemNumber: itemNumber, columnType: originalColumnType, originalColumnType: originalColumnType, action: originalAction, originalAction: originalAction)
                        }
                    }
                    if newColumnNumber == nil {
                        if let (newRowType, newItemNumber) = previousRow(rowType: rowType, itemNumber: itemNumber) {
                            return scorecardSelect(rowType: newRowType, itemNumber: newItemNumber, columnType: nil, originalColumnType: originalColumnType, action: action, originalAction: originalAction, initialOffset: +1)
                        }
                    }
                case .next:
                    newColumnNumber = nextRowCell(collectionView: collectionView, columnNumber: adjustedColumnNumber, increment: +1)
                    if newColumnNumber == nil && action != originalAction {
                        // Trying to find column in row - try going the other way
                        newColumnNumber = nextRowCell(collectionView: collectionView, columnNumber: columnNumber + 1, increment: -1)
                        if newColumnNumber == nil {
                            // No editable columns in row - carry on in original direction
                            return scorecardSelect(rowType: rowType, itemNumber: itemNumber, columnType: originalColumnType, originalColumnType: originalColumnType, action: originalAction, originalAction: originalAction)
                        }
                    }
                    if newColumnNumber == nil {
                        if let (newRowType, newItemNumber ) = nextRow(rowType: rowType, itemNumber: itemNumber) {
                            return scorecardSelect(rowType: newRowType, itemNumber: newItemNumber, columnType: nil, originalColumnType: originalColumnType, action: action, originalAction: originalAction, initialOffset: -1)
                        }
                    }
                default:
                    break
                }
            }
        }
        if let columnNumber = columnNumber, let newColumnNumber = newColumnNumber {
            if newItemNumber != itemNumber || newColumnNumber != columnNumber || initialOffset != nil {
                let newSection = rowType == .table ? newItemNumber - 1 : (newItemNumber - 1) / scorecard.boardsTable
                let newRow = rowType == .table ? nil : (newItemNumber - 1) % scorecard.boardsTable
                if let cell = self.cell(rowType: rowType, section: newSection, row: newRow, column: newColumnNumber) {
                        // Get focus for cell when scrolling finished
                    cell.getFocus()
                }
            }
        }
        return true
    }
                                             
    func moveTo(cellFrame: CGRect) -> UITableView.ScrollPosition? {
        let mainHeight = mainTableView.frame.height
        let offset = mainTableView.contentOffset.y
        let minY = cellFrame.minY
        let maxY = cellFrame.maxY
        var result: UITableView.ScrollPosition?
        
        if offset != 0 && (offset + tableRowHeight > minY || offset < 0) {
            result = .top
        } else if offset + mainHeight < maxY {
            result = .bottom
        }
        
        return result
    }
    
    func previousRow(rowType: RowType, itemNumber: Int) -> (rowType: RowType, itemNumber: Int)? {
        if rowType == .board {
            let tableNumber = ((itemNumber - 1) / scorecard.boardsTable) + 1
            let boardNumber =  ((itemNumber - 1) % self.scorecard.boardsTable) + 1
            if boardNumber > 1 {
                // Just previous board
                return (rowType: rowType, itemNumber - 1)
            } else {
                // First board - return table
                return (rowType: .table, itemNumber: tableNumber)
            }
        } else {
            if itemNumber > 1 {
                // Return last board in previous table
                return (rowType: .board, itemNumber: (itemNumber - 1) * scorecard.boardsTable)
            } else {
                // Can't go back from first table
                return nil
            }
        }
    }
    
    func nextRow(rowType: RowType, itemNumber: Int) -> (rowType: RowType, itemNumber: Int)? {
        if rowType == .board {
            let tableNumber = ((itemNumber - 1) / scorecard.boardsTable) + 1
            let boardNumber =  ((itemNumber - 1) % self.scorecard.boardsTable) + 1
            if boardNumber < scorecard.boardsTable {
                // Just next board
                return (rowType: rowType, itemNumber: itemNumber + 1)
            } else if tableNumber < scorecard.tables {
                // Next table
                return (rowType: .table, itemNumber: tableNumber + 1)
            } else {
                // Can't go forward from last board in last table
                return nil
            }
        } else {
            // Return first board for this table
            return (rowType: .board, itemNumber: ((itemNumber - 1) * scorecard.boardsTable) + 1)
        }
    }
    
    func nextRowCell(collectionView: UICollectionView, columnNumber: Int, increment: Int) -> Int? {
        var cell: ScorecardInputCollectionCell?
        var newColumnNumber = columnNumber
        repeat {
            newColumnNumber += increment
            cell = rowCell(collectionView: collectionView, item: newColumnNumber)
            if let cell = cell {
                if cell.canGetFocus {
                    break
                }
            }
        } while cell != nil
        return cell == nil ? nil : newColumnNumber
    }
    
    func getColumns(rowType: RowType, itemNumber: Int) -> [ScorecardColumn] {
        return (rowType == .table ? tableColumns : getBoardColumns(boardNumber: itemNumber))
    }
    
    func getColumnNumber(rowType: RowType, itemNumber: Int, type: ColumnType, findNearest: Bool = false) -> Int? {
        let columns = getColumns(rowType: rowType, itemNumber: itemNumber)
        var result = columns.firstIndex(where: {$0.type == type})
        if result == nil && findNearest {
            let otherItemNumber = (rowType == .board ? ((itemNumber - 1) / scorecard.boardsTable) + 1 : ((itemNumber - 1) * scorecard.boardsTable) + 1)
            let otherColumns = getColumns(rowType: rowType.other, itemNumber: otherItemNumber)
            if let otherColumn = otherColumns.first(where: {$0.type == type}) {
                if let (index, _) = columns.enumerated().reversed().first(where: {($0.1.minX ?? 0) <= (otherColumn.minX ?? 0)}) {
                    result = index
                }
            }
        }
        return result
    }
    
    func rowCollectionView(rowType: RowType, section: Int, row: Int? = nil) -> UICollectionView? {
        if rowType == .table {
            return (mainTableView.headerView(forSection: section) as? ScorecardInputTableSectionHeaderView)?.collectionView
        } else {
            return (mainTableView.cellForRow(at: IndexPath(row: row!, section: section)) as? ScorecardInputBoardTableCell)?.collectionView
        }
    }
    
    func rowCell(collectionView: UICollectionView, item: Int) -> ScorecardInputCollectionCell? {
        return collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? ScorecardInputCollectionCell
    }
    
    func cell(rowType: RowType, section: Int, row: Int? = nil, column: Int) -> ScorecardInputCollectionCell? {
        var result: ScorecardInputCollectionCell?
        if let collectionView = rowCollectionView(rowType: rowType, section: section, row: row) {
            result = rowCell(collectionView: collectionView, item: column)
        }
        return result
    }
    
    func scorecardEndEditing(_ force: Bool) {
        self.endEditing(force)
    }
    
    var scorecardMainTableView: UITableView {
        self.mainTableView
    }
    
    func scorecardSetCommentBoardNumber(boardNumber: Int) {
        // -1 is used to show all comments
        
        let oldBoardNumber = self.scorecardCommentBoardNumber
        self.scorecardCommentBoardNumber = (boardNumber == oldBoardNumber || oldBoardNumber == -1 ? nil : boardNumber)
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
        if let newBoardNumber = self.scorecardCommentBoardNumber {
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
        view.collectionView.allowsFocus = false
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return boardRowHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ScorecardInputBoardTableCell.dequeue(self, tableView: tableView, for: indexPath, tag: RowType.board.tagOffset + (indexPath.section * scorecard.boardsTable) + indexPath.row + 1)
        cell.collectionView.allowsFocus = false
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scorecardAutoComplete.forEach{ (_, view) in view.isActive = false }
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
            if scorecardInputControlInset == 0 {
                getInputControlInset()
            }
            self.scorecardKeyboardHeight = keyboardHeight
            if !inputDetail && (keyboardHeight != 0 || isKeyboardOffset) {
                let focusedTextInputBottom = (UIResponder.currentFirstResponder?.globalFrame?.maxY ?? 0)
                let adjustOffset = max(0, focusedTextInputBottom - keyboardHeight + safeAreaInsets.bottom + scorecardInputControlInset)
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
        scorecardInputControlInset = cell.inputControlInset
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
            var minX: CGFloat = 0
            
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
                    column.minX = minX
                    minX += column.width!
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
                              .replacingOccurrences(of: "B", with: "8")
                              .replacingOccurrences(of: "_", with: "-")
        let filteredText = numericText.filter { "0123456789-.".contains($0) }
        return Float(filteredText)
    }
    
    private func getBoardColumns(boardNumber: Int) -> [ScorecardColumn] {
        var columns: [ScorecardColumn]
        if scorecardViewType == .analysis && (scorecardCommentBoardNumber == boardNumber || scorecardCommentBoardNumber == -1) {
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

class ScorecardInputCollectionCell: UICollectionViewCell, ScrollPickerDelegate, EnumPickerDelegate, AutoCompleteDelegate, ScorecardInputDelegate {
    fileprivate var indexPath: IndexPath!
    fileprivate var label = UILabel()
    fileprivate var firstResponderLabel: FirstResponderLabel!
    fileprivate var contractPicker: ContractPicker!
    fileprivate var labelSeparator = UIView()
    fileprivate var labelHorizontalPadding: [NSLayoutConstraint]!
    fileprivate var labelTopPadding: [NSLayoutConstraint]!
    fileprivate var bottomLabel = UILabel()
    fileprivate var bottomLabelTapGesture: UITapGestureRecognizer!
    fileprivate var bottomContractPicker: ContractPicker!
    fileprivate var topAnalysis = AnalysisSummaryView()
    fileprivate var bottomAnalysis = AnalysisSummaryView()
    fileprivate var analysisSeparator = UIView()
    fileprivate var caption = UILabel()
    fileprivate var textField =  ScorecardInputTextField()
    fileprivate var textView = ScorecardInputTextView()
    private var textFieldCenterYConstraint: NSLayoutConstraint!
    private var textFieldHeightConstraint: NSLayoutConstraint!
    private var textFieldTopBorderConstraint: NSLayoutConstraint!
    private var textFieldBottomBorderConstraint: NSLayoutConstraint!
    private var textClear = UIImageView()
    private var textClearWidth: NSLayoutConstraint!
    private var textClearPadding: [NSLayoutConstraint]!
    private var textClearTapGesture: UITapGestureRecognizer!
    private var responsiblePicker: EnumPicker<Responsible>!
    fileprivate var declarerPicker: ScrollPicker!
    fileprivate var seatPicker: EnumPicker<Seat>!
    private var madePicker: ScrollPicker!
    internal var table: TableViewModel!
    internal var board: BoardViewModel!
    fileprivate var itemNumber: Int!
    internal var rowType: RowType!
    fileprivate var column: ScorecardColumn!
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
    public var focusLineViews: [UIView] = []
    
    private var scorecard: ScorecardViewModel!
    
    override init(frame: CGRect) {
        
        responsiblePicker = EnumPicker(frame: frame)
        declarerPicker = ScrollPicker(frame: frame)
        seatPicker = EnumPicker(frame: frame, allCases: true)
        madePicker = ScrollPicker(frame: frame)
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(Palette.gridTable.background)
                        
        addSubview(label)
        labelHorizontalPadding = Constraint.anchor(view: self, control: label, constant: 2, attributes: .leading)
        label.textAlignment = .center
        label.minimumScaleFactor = 0.3
        label.adjustsFontSizeToFitWidth = true
        label.accessibilityIdentifier = "label"
        
        addSubview(labelSeparator, constant: 0, anchored: .leading, .trailing)
        labelSeparator.backgroundColor = UIColor(Palette.gridLine)
        Constraint.anchor(view: self, control: labelSeparator, to: label, constant: 0, toAttribute: .bottom, attributes: .top)
        labelSeparatorHeight = Constraint.setHeight(control: labelSeparator, height: 0)
        labelSeparator.accessibilityIdentifier = "labelSeparator"
        
        addSubview(bottomLabel, constant: 2, anchored: .leading, .bottom, .trailing)
        bottomLabel.textAlignment = .center
        bottomLabel.minimumScaleFactor = 0.3
        bottomLabel.adjustsFontSizeToFitWidth = true
        Constraint.anchor(view: self, control: bottomLabel, to: labelSeparator, constant: 0, toAttribute: .bottom, attributes: .top)
        bottomLabelHeight = Constraint.setHeight(control: bottomLabel, height: 0)
        bottomLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputCollectionCell.labelTapped(_:)))
        bottomLabel.addGestureRecognizer(bottomLabelTapGesture, identifier: "Bottom label")
        bottomLabel.accessibilityIdentifier = "bottomLabel"
        
        addSubview(topAnalysis, constant: 0, anchored: .leading, .top, .trailing)
        topAnalysis.accessibilityIdentifier = "topAnalysis"
        
        addSubview(analysisSeparator, constant: 0, anchored: .leading, .trailing)
        analysisSeparator.backgroundColor = UIColor(Palette.gridLine)
        Constraint.anchor(view: self, control: analysisSeparator, to: topAnalysis, constant: 0, toAttribute: .bottom, attributes: .top)
        analysisSeparatorHeight = Constraint.setHeight(control: analysisSeparator, height: 1)
        analysisSeparator.accessibilityIdentifier = "analysisSeparator"
        
        addSubview(bottomAnalysis, constant: 0, anchored: .leading, .bottom, .trailing)
        Constraint.anchor(view: self, control: bottomAnalysis, to: analysisSeparator, constant: 0, toAttribute: .bottom, attributes: .top)
        bottomAnalysisHeight = Constraint.setHeight(control: bottomAnalysis, height: 0)
        bottomAnalysis.accessibilityIdentifier = "bottomAnalysis"
        
        firstResponderLabel = FirstResponderLabel(from: self)
        addSubview(firstResponderLabel)
        firstResponderLabel.accessibilityIdentifier = "firstResponderLabel"
        
        textField = ScorecardInputTextField(delegate: self, label: firstResponderLabel)
        addSubview(textField, constant: inputControlInset, anchored: .leading)
        textFieldCenterYConstraint = Constraint.anchor(view: self, control: textField, attributes: .centerY).first!
        textFieldCenterYConstraint.isActive = false
        textFieldHeightConstraint = Constraint.setHeight(control: textField, height: tableRowHeight / 2)
        textFieldHeightConstraint.isActive = false
        textFieldTopBorderConstraint = Constraint.anchor(view: self, control: textField, attributes: .top).first!
        textFieldBottomBorderConstraint = Constraint.anchor(view: self, control: textField, attributes: .bottom).first!
        textField.textAlignment = .center
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.font = cellFont
        textField.backgroundColor = UIColor.clear
        textField.borderStyle = .none
        textField.adjustsFontSizeToFitWidth = true
        textField.returnKeyType = .done
        textField.accessibilityIdentifier = "textField"
        
        textView = ScorecardInputTextView(delegate: self, label: firstResponderLabel)
        addSubview(textView, constant: inputControlInset, anchored: .leading)
        Constraint.anchor(view: self, control: textView, to: textField, attributes: .all)
        textView.textAlignment = .left
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.font = cellFont
        textView.backgroundColor = UIColor.clear
        textView.textContainerInset = .zero
        textView.accessibilityIdentifier = "textView"
        
        Constraint.anchor(view: self, control: firstResponderLabel, to: textField, attributes: .all)
        
        addSubview(textClear, constant: inputControlInset, anchored: .top, .bottom)
        textClearWidth = Constraint.setWidth(control: textClear, width: 0)
        textClearPadding = Constraint.anchor(view: self, control: textClear, constant: 0, attributes: .trailing)
        textClearPadding.append(contentsOf : Constraint.anchor(view: self, control: textClear, to: textField, constant: 0, toAttribute: .trailing, attributes: .leading))
        textClearPadding.append(contentsOf: Constraint.anchor(view: self, control: textClear, to: textView, constant: 0, toAttribute: .trailing, attributes: .leading))
        textClearPadding.append(contentsOf: Constraint.anchor(view: self, control: textClear, to: label, constant: 0, toAttribute: .trailing, attributes: .leading))
        textClear.image = UIImage(systemName: "x.circle.fill")?.asTemplate
        textClear.tintColor = UIColor(Palette.clearText)
        textClear.contentMode = .scaleAspectFit
        textClear.isUserInteractionEnabled = true
        textClearTapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputCollectionCell.clearTapped(_:)))
        textClear.addGestureRecognizer(textClearTapGesture, identifier: "Text clear")
        textClear.accessibilityIdentifier = "textClear"
        
        contractPicker = ContractPicker(from: self)
        addSubview(contractPicker, anchored: .all)
        contractPicker.accessibilityIdentifier = "contractPicker"
        
        addSubview(declarerPicker, top: 16, bottom: 0)
        Constraint.setWidth(control: declarerPicker, width: 60)
        Constraint.anchor(view: self, control: declarerPicker, attributes: .centerX)
        declarerPicker.delegate = self
        declarerPicker.accessibilityIdentifier = "declarerPicker"
        
        addSubview(seatPicker, top: 20, bottom: 4)
        Constraint.setWidth(control: seatPicker, width: 60)
        Constraint.anchor(view: self, control: seatPicker, attributes: .centerX)
        seatPicker.delegate = self
        seatPicker.accessibilityIdentifier = "seatPicker"
        
        addSubview(madePicker, top: 16, bottom: 0)
        Constraint.setWidth(control: madePicker, width: 60)
        Constraint.anchor(view: self, control: madePicker, attributes: .centerX)
        madePicker.delegate = self
        madePicker.accessibilityIdentifier = "madePicker"
        
        addSubview(responsiblePicker, top: 16, bottom: 0)
        Constraint.setWidth(control: responsiblePicker, width: 60)
        Constraint.anchor(view: self, control: responsiblePicker, attributes: .centerX)
        responsiblePicker.delegate = self
        responsiblePicker.accessibilityIdentifier = "responsiblePicker"
        
        addSubview(caption, anchored: .leading, .trailing, .top)
        caption.textAlignment = .center
        caption.font = titleCaptionFont
        caption.minimumScaleFactor = 0.3
        caption.backgroundColor = UIColor.clear
        caption.textColor = UIColor(Palette.gridBoard.text)
        captionHeight = Constraint.setHeight(control: caption, height: 0)
        labelTopPadding = Constraint.anchor(view: self, control: label, to: caption, constant: 0, toAttribute: .bottom, attributes: .top)
        caption.accessibilityIdentifier = "caption"
        
        Constraint.addGridLineReturned(self, views: &gridLineViews, sides: [.leading, .trailing, .top, .bottom])
        gridLineViews.forEach{ line in line.accessibilityIdentifier = "gridLines"}
        Constraint.addGridLineReturned(self, size: 3, color: .black, views: &focusLineViews, sides: [.leading, .trailing, .top, .bottom])
        focusLineViews.forEach{ line in line.accessibilityIdentifier = "focusLines"}
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
        cell.indexPath = indexPath
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
        setTextInput(centered: false)
        textField.keyboardType = .default
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.isUserInteractionEnabled = false
        textField.prepareForReuse()
        textView.isHidden = true
        textView.font = cellFont
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.isUserInteractionEnabled = false
        textView.prepareForReuse()
        textClear.isHidden = true
        textClearWidth.constant = 0
        textClearPadding.forEach { (constraint) in constraint.constant = 0 }
        textClearTapGesture.isEnabled = false
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
        firstResponderLabel.text = ""
        firstResponderLabel.isHidden = false
        firstResponderLabel.backgroundColor = UIColor.clear
        firstResponderLabel.textColor = UIColor(Palette.background.text)
        firstResponderLabel.font = cellFont
        firstResponderLabel.textAlignment = .center
        firstResponderLabel.isUserInteractionEnabled = false
        firstResponderLabel.numberOfLines = 1
        firstResponderLabel.isHidden = true
        contractPicker.prepareForReuse()
        contractPicker.isHidden = true
        labelSeparator.isHidden = true
        labelSeparator.backgroundColor = UIColor(Palette.gridLine)
        labelSeparatorHeight.constant = 0
        topAnalysis.prepareForReuse()
        topAnalysis.isHidden = true
        bottomAnalysis.prepareForReuse()
        bottomAnalysisHeight.constant = 0
        bottomAnalysis.isHidden = true
        focusLineViews.forEach { line in line.isHidden = true }
    }
    
    func setTitle(scorecard: ScorecardViewModel, column: ScorecardColumn) {
        self.board = nil
        self.column = column
        self.rowType = .boardTitle
        self.itemNumber = 0
        self.isUserInteractionEnabled = false
        label.tag = column.type.rawValue
        label.backgroundColor = UIColor(Palette.gridTitle.background)
        label.textColor = UIColor(Palette.gridTitle.text)
        label.font = titleFont.bold
        switch column.type {
        case .score:
            label.text = scorecard.type.boardScoreType.string
        case .analysis1:
            if scorecard.type.players == 4 {
                if let players = Scorecard.myRanking(table: 1)?.playerNames(separator: " & ", firstOnly: true, .player, .partner) {
                    label.text = players
                } else {
                    label.text = "Our Table"
                }
            } else {
                label.text = column.heading
            }
        case .analysis2:
            if scorecard.type.players == 4 {
                if let players = Scorecard.myRanking(table: 1)?.playerNames(separator: " & ", firstOnly: true, .lhOpponent, .rhOpponent) {
                    label.text = players
                } else {
                    label.text = "Other Table"
                }
            } else {
                label.text = column.heading
            }
        case .commentAvailable:
            self.isUserInteractionEnabled = true
            label.attributedText = Scorecard.commentAvailableText(exists: Scorecard.current.boards.map({$0.value.comment != ""}).contains(true))
            label.isUserInteractionEnabled = true
            let color = scorecardDelegate?.scorecardCommentBoardNumber == -1 ? Palette.enabledButton : Palette.background
            label.backgroundColor = UIColor(color.background)
            label.textColor = UIColor(color.text)
            set(tap: .label)
        default:
            label.text = column.heading
        }
    }
    
    var isEnabled : Bool {
        if rowType == .boardTitle {
            false
        } else {
            switch column.type {
            case .board, .table, .vulnerable, .dealer, .points, .teamTable, .analysis1, .analysis2, .commentAvailable:
                false
            case .declarer:
                (table?.sitting ?? .unknown != .unknown && !Scorecard.current.isImported)
            case .made:
                board.contract.isValid && !Scorecard.current.isImported
            case .score, .versus, .sitting, .contract:
                !Scorecard.current.isImported
            case .responsible, .comment:
                true
            default:
                false
            }
        }
    }
    
    override var description : String {
        if let rowType = rowType, let itemNumber = itemNumber, let column = column {
            "\(rowType) \(itemNumber): \(column.type)"
        } else {
            "Uninitialised cell"
        }
    }
    
    func set(scorecard: ScorecardViewModel, table: TableViewModel, board: BoardViewModel! = nil, itemNumber: Int, rowType: RowType, column: ScorecardColumn) {
        self.scorecard = scorecard
        self.board = board
        self.table = table
        self.itemNumber = itemNumber
        self.rowType = rowType
        self.column = column

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
        firstResponderLabel.tag = column.type.rawValue
        
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
            contractPicker.isHidden = false
            contractPicker.set(contract: board.contract, completion: contractPickerChanged)
            contractPicker.isUserInteractionEnabled = true
            set(tap: .contract)
        case .declarer:
            declarerPicker.isHidden = false
            let selected = (table.sitting == .unknown ? 0 : declarerList.firstIndex(where: { $0.seat == board.declarer}) ?? 0)
            declarerPicker.set(selected, list: declarerList.map{$0.entry}, defaultValue: 0, isEnabled: isEnabled, color: color, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
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
                setTextInput(centered: true)
                textControl?.textAlignment = .center
                textControl?.isHidden = false
                textControl?.keyboardType = .numbersAndPunctuation
                textControl?.textValue = board.score == nil ? "" : "\(board.score!.toString(places: scorecard.type.boardPlaces))"
                textControl?.isUserInteractionEnabled = isEnabled
                textControl?.isActive = true
            }
            firstResponderLabel.isUserInteractionEnabled = true
            set(tap: .textInput)
        case .points:
            analysisSplitPoints(isEnabled: isEnabled)
        case .comment:
            setTextInputString(value: board.comment, font: scorecardDelegate?.scorecardViewType == .analysis ? smallCellFont : cellFont, centered: scorecardDelegate?.scorecardViewType != .analysis)
        case .responsible:
            responsiblePicker.isHidden = (Scorecard.current.isImported && board.score == nil)
            responsiblePicker.set(board.responsible, defaultValue: .unknown, color: Palette.gridBoard, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
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
            let color = (scorecardDelegate?.scorecardCommentBoardNumber == board.board ? Palette.enabledButton : Palette.background)
            label.backgroundColor = UIColor(color.background)
            label.textColor = UIColor(color.contrastText)
            label.attributedText = Scorecard.commentAvailableText(exists: board.comment != "")
            label.isUserInteractionEnabled = true
            set(tap: .label)
        case .table:
            label.font = boardTitleFont.bold
            label.text = (scorecard.resetNumbers ? "Stanza \(table.table)" : (Scorecard.current.isImported ? "" : "Table \(table.table)"))
            label.isUserInteractionEnabled = true
            set(tap: .label)
        case .sitting:
            seatPicker.isHidden = false
            seatPicker.set(table.sitting, defaultValue: .unknown, isEnabled: isEnabled, color: color, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
            label.isUserInteractionEnabled = !isEnabled
            set(tap: isEnabled ? .seat : nil)
        case .tableScore:
            if scorecard.manualTotals {
                setTextInput(centered: true)
                textControl?.textAlignment = .center
                textControl?.isHidden = false
                textControl?.keyboardType = .numbersAndPunctuation
                textControl?.textValue = table.score == nil ? "" : "\(table.score!.toString(places: scorecard.type.tablePlaces))"
                textControl?.isActive = true
                set(tap: .noTap)
            } else {
                label.text = table.score == nil ? "" : "\(scorecard.type.tableScoreType.prefix(score: table.score!))\(table.score!.toString(places: min(1, scorecard.type.tablePlaces)))\(scorecard.type.tableScoreType.suffix)"
                label.isUserInteractionEnabled = true
                set(tap: .label)
            }
        case .versus:
            setTextInputString(value: (Scorecard.current.isImported ? importedVersus : table.versus), offset: 16)
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
    
    private func setTextInputString(value: String, font: UIFont = cellFont, centered: Bool = true, offset: CGFloat = 0) {
        textControl?.textValue = value
        textControl?.textAlignment = .left
        textControl?.autocapitalizationType = .sentences
        textControl?.adjustsFontForContentSizeCategory = true
        textControl?.isUserInteractionEnabled = true
        textControl?.font = cellFont
        textControl?.isActive = true
        textControl?.useLabel = true
        textClear.isHidden = (value == "")
        textClearTapGesture.isEnabled = true
        textClearWidth.constant = 34
        textClearPadding.forEach { (constraint) in constraint.setIndent(in: self, constant: inputControlInset * 2) }
        firstResponderLabel.textAlignment = (centered ? .center : .left)
        set(tap: .label)
    }
    
    private func textInputStringLabelTapped() {
        if !(Scorecard.current.isImported && board?.score == nil) {
            textControl?.forceFirstResponder = true
            getFocus()
        }
    }
    
    private func setTextInput(centered: Bool, offset: CGFloat = 0) {
        // Have to deactivate before activating
        setCentered(false, offset)
        setBorder(!centered, offset)
        setCentered(centered, offset)
    }
        
    private func setCentered(_ value: Bool, _ offset: CGFloat = 0) {
        textFieldCenterYConstraint.isActive = value
        textFieldCenterYConstraint.constant = offset
        textFieldHeightConstraint.isActive = value
    }
    
    private func setBorder(_ value: Bool, _ offset: CGFloat = 0) {
        textFieldTopBorderConstraint.isActive = value
        textFieldTopBorderConstraint.constant = offset
        textFieldBottomBorderConstraint.isActive = value
    }
    
    private func analysisSplitPoints(isEnabled: Bool) {
        label.isHidden = false
        if board.declarer == .unknown {
            label.text = ""
        } else {
            let points = board.points(seat: table.sitting)
            label.text = (points == nil ? "" : "\(points! > 0 ? "+" : "")\(points!)")
        }
        label.isUserInteractionEnabled = true
        set(tap: .label)
        if (scorecardDelegate?.scorecardViewType ?? .normal) == .analysis && scorecard.type.players == 4 {
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
            analysisView.set(board: board, summary: summary, hideRejected: scorecardDelegate?.scorecardHideRejected ?? true, viewTapped: showHand)
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
                    control.isUserInteractionEnabled = true
                    tapGesture.addTarget(self, action: selector)
                    tapGesture.isEnabled = true
                }
            }
            currentTapControl = newTapControl
        }
        
        func execute(on tapControl: TapControl, action: (UIView, Selector)->()) {
            var control: UIView?
            var selector: Selector?
            switch tapControl {
            case .label:
                control = label
                selector = #selector(ScorecardInputCollectionCell.labelTapped(_:))
            case .responsible:
                control = responsiblePicker
                selector = #selector(ScorecardInputCollectionCell.responsibleTapped)
            case .declarer:
                control = declarerPicker
                selector = #selector(ScorecardInputCollectionCell.declarerTapped)
            case .seat:
                control = seatPicker
                selector = #selector(ScorecardInputCollectionCell.seatTapped)
            case .made:
                control = madePicker
                selector = #selector(ScorecardInputCollectionCell.madeTapped)
            case .contract:
                control = contractPicker
                selector = #selector(ScorecardInputCollectionCell.contractTapped)
            case .textInput:
                control = firstResponderLabel
                selector = #selector(ScorecardInputCollectionCell.labelTapped(_:))
            default:
                break
            }
            if let control = control, let selector = selector {
                action(control, selector)
            }
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
        
    internal func inputTextChanged(_ textInput: ScorecardInputTextInput) {
        let text = textInput.textValue ?? ""
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
                UndoManager.registerUndo(withTarget: self) { [self] (_) in
                    if let cell = self.scorecardDelegate?.scorecardCell(rowType: rowType, itemNumber: itemNumber, columnType: columnType) {
                        if let textControl = cell.textControl {
                            textControl.textValue = undoText
                            cell.inputTextChanged(textControl)
                        }
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
    
    func inputTextShouldChangeCharacters(_ textInput: ScorecardInputTextInput, in range: NSRange, replacementString string: String) -> Bool {
        if column.type == .versus || column.type == .comment {
            textAutoComplete(replacing: textInput.textValue!, range: range, with: string)
        }
        return true
    }
    
    internal func inputTextDidBeginEditing(_ textInput: ScorecardInputTextInput) {
        var clear = false
        switch column.type {
        case .score:
            clear = board.score != nil
        case .tableScore:
            clear = table.score != nil
        default:
            break
        }
        let position = textInput.endOfDocument
        textInput.selectedTextRange = textInput.textRange(from: position, to: position)
        if clear {
            // Record automatic clear on entry in undo
            inputTextChanged(textInput)
        }
    }
    
    internal func inputTextDidEndEditing(_ inputText: ScorecardInputTextInput) {
        let text = inputText.textValue ?? ""
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
            if newText != inputText.textValue {
                inputText.textValue = newText
                inputTextChanged(inputText)
            }
        }
        scorecardDelegate?.scorecardAutoComplete[column.type]?.isActive = false
    }
    
    func inputTextShouldReturn(_ inputText: ScorecardInputTextInput) -> Bool {
        if keyPressed(keyAction: .enter) {
            return false
        } else {
            switch column.type {
            case .score:
                if inputText.textValue != "" {
                    if board.board < scorecard.boards {
                        scorecardDelegate?.scorecardSelectNext(rowType: .board, itemNumber: board.board, columnType: .score, action: .down)
                    }
                }
                return true
            default:
                break
            }
            getFocus()
            return true
        }
    }
    
    func inputTextSpecialCharacters(_ inputText: ScorecardInputTextView, text: String) -> Bool {
        var result = false
        if text == "\n" {
            if !keyPressed(keyAction: .enter) {
                getFocus()
            }
            result = true
        } else if text == "\t" {
            keyPressed(keyAction: .next)
            result = true
        }
        return result
    }
    
    internal func replace(with text: String, textInput: ScorecardInputTextInput, positionAt: NSRange) {
        textInput.textValue = text
        inputTextChanged(textInput)
        if let location = textInput.position(from: textInput.beginningOfDocument, offset: positionAt.location) {
            textInput.selectedTextRange = textInput.textRange(from: location, to: location)
        }
        scorecardDelegate?.scorecardAutoComplete[column.type]?.isActive = false
    }
    
    // Other handlers
    
    @objc internal func clearTapped(_ textFieldClear: UIView) {
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
            textControl?.textValue = ""
            inputTextChanged(textControl!)
        }
    }
    
    private func textAutoComplete(replacing original: String, range: NSRange, with: String) {
       if let autoComplete = scorecardDelegate?.scorecardAutoComplete[column.type] {
           let text = (original as NSString).replacingCharacters(in: range, with: with)
           let range = NSRange(location: range.location + NSString(string: with).length, length: 0)
           autoComplete.delegate = self
           let listSize = autoComplete.set(text: text, textInput: textControl, at: range)
           if listSize == 0 {
               autoComplete.isActive = false
               autoComplete.delegate = nil
           } else {
               autoComplete.isActive = true
               let height = CGFloat(min(5, listSize) * 40)
               var point = self.superview!.convert(CGPoint(x: frame.minX, y: frame.maxY), to: autoComplete.superview!)
               if point.y + 200 >= UIScreen.main.bounds.height - (scorecardDelegate?.scorecardKeyboardHeight ?? 0) {
                   point = point.offsetBy(dy: -frame.height - height)
               }
               autoComplete.frame = CGRect(x: point.x, y: point.y, width: self.frame.width, height: height)
           }
       }
    }
    
    internal func enumPickerDidChange(to value: Any, allowPopup: Bool = false) {
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
        switch columnType {
        case .responsible:
            if allowPopup {
                responsibleTapped(self)
            }
        case .sitting:
            if allowPopup {
                seatTapped(self)
            }
        default:
            break
        }
    }
    
    internal func contractPickerChanged(contract: Contract?, keyAction: KeyAction?, characters: String?) {
        if let contract = contract {
            if contract != board.contract {
                contractDidChange(to: contract)
                contractPicker.set(contract: board.contract)
            }
        }
        if let keyAction = keyAction {
            if keyAction == .enter || (keyAction == .characters && characters?.trim() == "") {
                contractTapped(self)
            } else {
                keyPressed(keyAction: keyAction)
            }
        } else {
            getFocus()
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
                        cell.contractPicker.set(contract: undoValue)
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
            case .versus:
                versusTapped(self)
            case .score:
                if Scorecard.current.isImported && board?.score != nil {
                    scoreTapped(self)
                } else {
                    getFocus()
                }
            case .commentAvailable:
                if rowType == .boardTitle || Scorecard.current.isImported && board?.score != nil {
                    scorecardDelegate?.scorecardSetCommentBoardNumber(boardNumber: board?.board ?? -1)
                }
            case .comment:
                if !(Scorecard.current.isImported && board?.score == nil) {
                    textControl?.forceFirstResponder = true
                    getFocus()
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
        if !Scorecard.current.isImported {
            scorecardDelegate?.scorecardContractEntry(board: board, table: table, contract: contractPicker.contract)
        } else {
            showHand()
        }
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
        } else {
            if !Scorecard.current.isImported {
                textControl?.forceFirstResponder = true
                getFocus()
            }
        }
    }
    
    @objc internal func declarerTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber)
        if table.sitting != .unknown {
            scorecardDelegate?.scorecardDeclarerPickerPopup(values: orderedDeclarerList, selected: board.declarer, frame: self.frame, in: self.superview!, topPadding: 20, bottomPadding: 4) { [ self] (selected, keyAction) in
                if let index = declarerList.firstIndex(where: {$0.seat == selected}) {
                    declarerPicker.setValue(index)
                    scrollPickerDidChange(to: index)
                    if let keyAction = keyAction {
                        if keyAction == .escape || keyAction == .enter || !keyPressed(keyAction: keyAction) {
                            getFocus()
                        }
                    } else {
                        getFocus()
                    }
                }
            }
        }
    }

    @objc internal func seatTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber)
        let width: CGFloat = (MyApp.format == .phone ? 50 : 70)
        let space = (frame.width - width) / 2
        if !Scorecard.current.isImported {
            let selected = Seat.allCases.firstIndex(where: {$0 == table.sitting}) ?? 0
            scorecardDelegate?.scorecardScrollPickerPopup(values: Seat.allCases.map{ScrollPickerEntry(title: $0.short, caption: $0.string)}, maxValues: 9, selected: selected, defaultValue: nil, frame: CGRect(x: frame.minX + space, y: frame.minY, width: width, height: frame.height), in: superview!, topPadding: 20, bottomPadding: 4) { [self] (selected, keyAction) in
                let seat = Seat.allCases[selected!]
                seatPicker.set(seat)
                enumPickerDidChange(to: seat)
                if let keyAction = keyAction {
                    if keyAction == .escape || keyAction == .enter || !keyPressed(keyAction: keyAction) {
                        getFocus()
                    }
                } else {
                    getFocus()
                }
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
        scorecardDelegate?.scorecardScrollPickerPopup(values: madeList, maxValues: 9, selected: selected, defaultValue: makingValue, frame: CGRect(x: self.frame.minX + space, y: self.frame.minY, width: width, height: self.frame.height), in: self.superview!, topPadding: 16, bottomPadding: 0) { [self] (selected, keyAction) in
            madePicker.set(selected, reload: board.made == nil || selected == nil)
            scrollPickerDidChange(madePicker, to: selected)
            if let keyAction = keyAction {
                if keyAction == .escape || keyAction == .enter || !keyPressed(keyAction: keyAction) {
                    getFocus()
                }
            } else {
                getFocus()
            }
        }
    }
    
    @objc internal func responsibleTapped(_ sender: UIView) {
        scorecardDelegate?.scorecardEndEditing(true)
        scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber)
        let width: CGFloat = 70
        let space = (frame.width - width) / 2
        let selected = Responsible.validCases.firstIndex(of: board.responsible)
        scorecardDelegate?.scorecardScrollPickerPopup(values: Responsible.validCases.map{ScrollPickerEntry(title: $0.short, caption: $0.full)}, maxValues: 13, selected: selected, defaultValue: nil, frame: CGRect(x: self.frame.minX + space, y: self.frame.minY, width: width, height: self.frame.height), in: self.superview!, topPadding: 16, bottomPadding: 0) { [self] (selected, keyAction) in
            let responsible = Responsible.validCases[selected!]
            responsiblePicker.set(responsible)
            enumPickerDidChange(to: responsible)
            if let keyAction = keyAction {
                if keyAction == .escape || keyAction == .enter || !keyPressed(keyAction: keyAction) {
                    getFocus()
                }
            } else {
                getFocus()
            }
        }
    }
    
    private func showHand() {
        if MyApp.format != .phone {
            scorecardDelegate?.scorecardShowHand(scorecard: scorecard, board: board, sitting: table.sitting)
        }
    }
    
@nonobjc internal func scrollPickerDidChange(_ picker: ScrollPicker? = nil, to value: Int?, allowPopup: Bool = false) {
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
                        picker?.setValue(undoValue)
                        cell.scrollPickerDidChange(picker, to: undoValue)
                    }
                }
                switch columnType {
                case .declarer:
                    board.declarer = declarerList[value!].seat
                case .made:
                    board.made = ((value == nil || board.contract.level == .blank || value! < 0) ? nil : value! - (Values.trickOffset + board.contract.level.rawValue))
                default:
                    break
                }
                scorecardDelegate?.scorecardChanged(type: rowType, itemNumber: itemNumber, column: columnType)
            }
        }
        if allowPopup {
            switch columnType {
            case .declarer:
                declarerTapped(self)
            case .made:
                madeTapped(self)
            default:
                break
            }
        }
    }
    
    var canGetFocus: Bool {
        return isEnabled
    }
    
    @discardableResult func getFocus() -> Bool {
        print("Getting \(description)")
        var result = false
        if isEnabled {
            let currentFocusCell = scorecardDelegate?.scorecardFocusCell
            if currentFocusCell != self {
                currentFocusCell?.loseFocus()
                if let entity = rowType.entity {
                    Scorecard.current.interimSave(entity: entity, itemNumber: itemNumber)
                }
            }
            scorecardDelegate?.scorecardFocusCell = self
            textControl?.forceFirstResponder = true
            focusLineViews.forEach { line in line.isHidden = false }
            responderControls.forEach { control in control?.updateFocus = false }
            result = responderControl?.becomeFirstResponder() ?? false
            responderControls.forEach { control in control?.updateFocus = true }
        }
        return result
    }
    
    @discardableResult func loseFocus() -> Bool {
        print("Resigning \(description)")
        
        // Remove focus halo
        focusLineViews.forEach { line in line.isHidden = true }
        
        // Carry out any control specific pre-amble
        switch column?.type {
        case .responsible:
            responsiblePicker.loseFocus()
        case .made:
            madePicker.loseFocus()
        case .sitting:
            seatPicker.loseFocus()
        default: break
        }
        
        // Resign first responder
        responderControl?.updateFocus = false
        let result = responderControl?.resignFirstResponder() ?? false
        responderControl?.updateFocus = true
        
        // Set the focused cell to nil
        scorecardDelegate?.scorecardFocusCell = nil

        return result
    }
    
    func resignedFirstResponder(from responder: ScorecardResponder) {
        // Main action takes place when another cell gets focus and hence this cell loses focus
    }
    
    var responderControls: [ScorecardResponder?] {
        if let textControl = textControl {
            [textControl, firstResponderLabel]
        } else {
            [responderControl]
        }
    }
    
    var responderControl: ScorecardResponder? {
        switch column?.type {
        case .contract:
            contractPicker
        case .declarer:
            firstResponderLabel
        case .made:
            firstResponderLabel
        case .score:
            textResponder
        case .comment:
            textResponder
        case .responsible:
            firstResponderLabel
        case .analysis1:
            firstResponderLabel
        case .analysis2:
            firstResponderLabel
        case .commentAvailable:
            firstResponderLabel
        case .combined:
            firstResponderLabel
        case .sitting:
            firstResponderLabel
        case .tableScore:
            textResponder
        case .versus:
            textResponder
        default:
            nil
        }
    }
    
    var textInputString: Bool {
        column?.type == .comment || column?.type == .versus
    }
    
    var textResponder: ScorecardResponder? {
        if !(textControl?.showLabel ?? false) || !textInputString {
            textControl
        } else {
            firstResponderLabel
        }
    }
    
    var textControl: ScorecardInputTextInput? {
        switch column?.type {
        case .score:
            textField
        case .comment:
            textField
        case .tableScore:
            textField
        case .versus:
            textField
        default:
            nil
        }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !processPressedKeys(presses, with: event, allowCharacters: true, action: { (keyAction, _) in
            switch keyAction {
            case .next, .previous, .characters:
                true
            case .left, .right, .escape, .enter, .backspace, .delete:
                switch column.type {
                case .contract, .declarer, .made, .responsible, .sitting, .score, .comment, .tableScore, .versus:
                    true
                default:
                    false
                }
            default:
                false
            }
        }) {
            super.pressesBegan(presses, with: event)
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !processPressedKeys(presses, with: event, allowCharacters: true, action: keyPressed) {
            super.pressesEnded(presses, with: event)
        }
    }
    
    @discardableResult public func keyPressed(keyAction: KeyAction?, characters: String = "") -> Bool {
        var handled = false
        print("Key pressed \(description)")
        while true {
            if let keyAction = keyAction {
                handled = false
                switch column.type {
                case .declarer:
                    if declarerPicker.processKeys(keyAction: keyAction, characters: characters) {
                        handled = !keyAction.movementKey
                    }
                case .made:
                    if madePicker.processKeys(keyAction: keyAction, characters: characters) {
                        handled = !keyAction.movementKey
                    }
                case .responsible:
                    if responsiblePicker.processKeys(keyAction: keyAction, characters: characters) {
                        handled = !keyAction.movementKey
                    }
                case .sitting:
                    if seatPicker.processKeys(keyAction: keyAction, characters: characters) {
                        handled = !keyAction.movementKey
                    }
                case .versus, .comment:
                    if let autoComplete = scorecardDelegate?.scorecardAutoComplete[column.type] {
                        if autoComplete.isActive {
                            if keyAction.upDownKey || keyAction == .enter {
                                handled = autoComplete.keyPressed(keyAction: keyAction)
                            }
                        }
                    } 
                    if !handled {
                        if textControl?.showLabel ?? true {
                            if keyAction == .enter || keyAction == .characters || keyAction.leftRightKey || keyAction.deletionKey {
                                textControl?.forceFirstResponder = true
                                getFocus()
                                handled = true
                            }
                        } else {
                            if keyAction == .enter {
                                handled = true
                            }
                        }
                    }
                default:
                   handled = false
                }
                if !handled {
                    switch keyAction {
                    case .next, .previous, .up, .down, .backspace:
                        scorecardDelegate?.scorecardSelectNext(rowType: rowType, itemNumber: itemNumber, columnType: column.type, action: keyAction)
                        handled = true
                    case .characters, .enter:
                        switch column.type {
                        case .contract:
                            contractTapped(self)
                            handled = true
                        case .declarer:
                            declarerTapped(self)
                            handled = true
                        case .made:
                            madeTapped(self)
                            handled = true
                        case .responsible:
                            responsibleTapped(self)
                            handled = true
                        case .sitting:
                            seatTapped(self)
                            handled = true
                        default:
                            break
                        }
                    default:
                        break
                    }
                }
            }
            break
        }
        return handled
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

protocol ScorecardResponder: UIView {
    var updateFocus: Bool {get set}
}
