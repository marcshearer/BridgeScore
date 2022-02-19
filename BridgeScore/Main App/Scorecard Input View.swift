//
//  Scorecard Input View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 11/02/2022.
//

import UIKit
import SwiftUI

struct ScorecardColumn: Codable {
    var type: ColumnType
    var heading: String
    var size: ColumnSize
    var width: CGFloat?
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

    @ObservedObject var scorecard: ScorecardViewModel
    @State var undoPressed: Bool = false
    @State var redoPressed: Bool = false
    @State var canUndo: Bool = false
    @State var canRedo: Bool = false
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
                        BannerOption(image: AnyView(Image(systemName: "trash.fill")), likeBack: true, action: { clearScorecard() })])

                GeometryReader { geometry in
                    ScorecardInputUIViewWrapper(scorecard: scorecard, frame: geometry.frame(in: .local), undoPressed: $undoPressed, redoPressed: $redoPressed, canUndo: $canUndo, canRedo: $canRedo)
                    .ignoresSafeArea(edges: .all)
                }
            }
            .onChange(of: undoPressed) { newValue in undoPressed = false }
            .onChange(of: redoPressed) { newValue in redoPressed = false }
        }
    }
    
    func backAction() -> Bool {
        return true
    }
    
    func clearScorecard() {
        MessageBox.shared.show("This will clear the contents of the drawing.\nAre you sure you want to do this?", cancelText: "Cancel", okText: "Clear", okAction: {
        })
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
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator($undoPressed, $redoPressed, $canUndo, $canRedo)
    }
    
    class Coordinator: NSObject, ScorecardInputUIViewDelegate {
        
        @Binding var undoPressed: Bool
        @Binding var redoPressed: Bool
        @Binding var canUndo: Bool
        @Binding var canRedo: Bool
        
        init(_ undoPressed: Binding<Bool>, _ redoPressed: Binding<Bool>, _ canUndo: Binding<Bool>, _ canRedo: Binding<Bool>) {
            _undoPressed = undoPressed
            _redoPressed = redoPressed
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

protocol ScorecardChangeDelegate {
    func scorecardChanged(type: RowType, itemNumber: Int, column: ScorecardColumn)
}

class ScorecardInputUIView : UIView, ScorecardChangeDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
        
    var scorecard: ScorecardViewModel
    var mainTableView = UITableView()
    var delegate: ScorecardInputUIViewDelegate?
    
    var boardColumns = [
        ScorecardColumn(type: .board, heading: "Board", size: .fixed(70)),
        ScorecardColumn(type: .contract, heading: "Contract", size: .fixed(90)),
        ScorecardColumn(type: .declarer, heading: "By", size: .fixed(60)),
        ScorecardColumn(type: .made, heading: "Made", size: .fixed(70)),
        ScorecardColumn(type: .score, heading: "Score", size: .fixed(70)),
        ScorecardColumn(type: .comment, heading: "Comment", size: .flexible),
        ScorecardColumn(type: .responsible, heading: "Resp", size: .fixed(60))
    ]
    
    var tableColumns = [
        ScorecardColumn(type: .table, heading: "", size: .fixed(160)),
        ScorecardColumn(type: .sitting, heading: "Sitting", size: .fixed(130)),
        ScorecardColumn(type: .versus, heading: "Versus", size: .flexible),
        ScorecardColumn(type: .tableScore, heading: "Score", size: .fixed(60)),
    ]

    let titleRowHeight: CGFloat = 40
    let boardRowHeight: CGFloat = 90
    var tableRowHeight: CGFloat
    private var canvasWidth: CGFloat?
    
    init(frame: CGRect, scorecard: ScorecardViewModel) {
        self.scorecard = scorecard
        self.tableRowHeight = (scorecard.tableTotal ? 80 : 2)
        
        super.init(frame: frame)
                    
        // Add subviews
        self.addSubview(self.mainTableView, anchored: .all)
                                
        // Setup main table view
        self.mainTableView.delegate = self
        self.mainTableView.dataSource = self
        self.mainTableView.tag = RowType.board.rawValue
        self.mainTableView.sectionHeaderTopPadding = 0
        self.mainTableView.bounces = false
        ScorecardInputTableTableCell.register(mainTableView)
        ScorecardInputBoardTableCell.register(mainTableView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        setupSizes(columns: &boardColumns)
        setupSizes(columns: &tableColumns)
        mainTableView.reloadData()
    }

    public func undo() {
        undoManager?.undo()
    }
    
    public func redo() {
        undoManager?.redo()
    }
    
    internal func scorecardChanged(type: RowType, itemNumber: Int, column: ScorecardColumn) {
        delegate?.undo(isAvailable: undoManager?.canUndo ?? false)
        delegate?.redo(isAvailable: undoManager?.canRedo ?? false)
        if type == .board {
            let indexRow = (itemNumber - 1) % scorecard.boardsTable
            let indexSection = (itemNumber - 1) / scorecard.boardsTable
            switch column.type {
            case .contract:
                    // Contract changed - update made picker
                if let row = mainTableView.cellForRow(at: IndexPath(row: indexRow, section: indexSection)) as? ScorecardInputBoardTableCell {
                    if let columnNumber = boardColumns.firstIndex(where: {$0.type == .made}) {
                        row.collectionView.reloadItems(at: [IndexPath(item: columnNumber, section: 0)])
                    }
                }
            default:
                break
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return scorecard.tables
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scorecard.boardsTable
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableRowHeight + titleRowHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        let headerCell = ScorecardInputTableTableCell.dequeue(self, tableView: tableView, tag: RowType.table.tagOffset + section + 1)
        let boardTitleCell = ScorecardInputBoardTableCell.dequeue(self, tableView: tableView, tag: RowType.boardTitle.tagOffset + section + 1)
        view.addSubview(headerCell, anchored: .leading, .trailing, .top)
        view.addSubview(boardTitleCell, anchored: .leading, .trailing, .bottom)
        Constraint.setHeight(control: boardTitleCell, height: titleRowHeight)
        Constraint.anchor(view: view, control: headerCell, to: boardTitleCell, toAttribute: .top, attributes: .bottom)
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
                    let column = boardColumns[indexPath.item]
                    cell.set(from: self, board: board, boardNumber: boardNumber, column: column)
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
                    cell.set(from: self, table: table, tableNumber: tableNumber, column: column)
                }
                return cell
            }
        } else {
            fatalError()
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

// MARK: - Cell classes ================================================================ -

fileprivate class ScorecardInputBaseTableCell: UITableViewCell {
    fileprivate var collectionView: UICollectionView!
    private var layout: UICollectionViewFlowLayout!
           
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        self.contentView.addSubview(collectionView, anchored: .all)
        self.contentView.bringSubviewToFront(self.collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setCollectionViewDataSourceDelegate
    <D: UICollectionViewDataSource & UICollectionViewDelegate>
    (_ dataSourceDelegate: D, tag: Int) {
        
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.tag = tag
        collectionView.reloadData()
    }
}

fileprivate class ScorecardInputBoardTableCell: ScorecardInputBaseTableCell {
    private static let identifier = "Board TableCell"
    private static let titleIdentifier = "Board Title TableCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        ScorecardInputBoardCollectionCell.register(self.collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ tableView: UITableView) {
        tableView.register(ScorecardInputBoardTableCell.self, forCellReuseIdentifier: identifier)
        tableView.register(ScorecardInputBoardTableCell.self, forCellReuseIdentifier: titleIdentifier)
    }
    
    public class func dequeue<D: UICollectionViewDataSource & UICollectionViewDelegate>(_ dataSourceDelegate : D, tableView: UITableView, for indexPath: IndexPath? = nil, tag: Int) -> ScorecardInputBoardTableCell {
        var cell: ScorecardInputBoardTableCell
        if let indexPath = indexPath {
            cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ScorecardInputBoardTableCell
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: titleIdentifier) as! ScorecardInputBoardTableCell
        }
        cell.setCollectionViewDataSourceDelegate(dataSourceDelegate, tag: tag)
        return cell
    }
}

fileprivate class ScorecardInputTableTableCell: ScorecardInputBaseTableCell {
    private static let identifier = "Table TableCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        ScorecardInputTableCollectionCell.register(self.collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func register(_ tableView: UITableView) {
        tableView.register(ScorecardInputTableTableCell.self, forCellReuseIdentifier: identifier)
    }
    
    public class func dequeue<D: UICollectionViewDataSource & UICollectionViewDelegate>(_ dataSourceDelegate : D, tableView: UITableView, tag: Int) -> ScorecardInputTableTableCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as! ScorecardInputTableTableCell
        cell.setCollectionViewDataSourceDelegate(dataSourceDelegate, tag: tag)
        return cell
    }
}

fileprivate class ScorecardInputBoardCollectionCell: UICollectionViewCell, ScrollPickerDelegate, EnumPickerDelegate, ContractPickerDelegate, UITextViewDelegate {
    private var label = UILabel()
    private var textField = UITextField()
    private var textView = UITextView()
    private var textViewClear = UIImageView()
    private var participantPicker: EnumPicker<Participant>!
    private var madePicker: ScrollPicker!
    private var contractPicker: ContractPicker
    private var board: BoardViewModel!
    private var boardNumber: Int!
    private var column: ScorecardColumn!
    private var changeDelegate: ScorecardChangeDelegate?
    private static let identifier = "Board CollectionCell"

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
    
    override init(frame: CGRect) {
        participantPicker = EnumPicker(frame: frame)
        contractPicker = ContractPicker(frame: frame)
        madePicker = ScrollPicker(frame: frame)
        super.init(frame: frame)
                
        addSubview(label, anchored: .all)
        label.layer.borderColor = UIColor(Palette.gridLine).cgColor
        label.layer.borderWidth = 2.0
        label.textAlignment = .center
        label.minimumScaleFactor = 0.3
        label.backgroundColor = UIColor(Palette.gridBoard.background)
        label.textColor = UIColor(Palette.gridBoard.text)
         
        addSubview(textField, constant: 4, anchored: .all)
        textField.textAlignment = .center
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.font = cellFont
        textField.addTarget(self, action: #selector(ScorecardInputBoardCollectionCell.textFieldChanged), for: .editingChanged)
        textField.addTarget(self, action: #selector(ScorecardInputBoardCollectionCell.textFieldEndEdit), for: .editingDidEnd)
        textField.addTarget(self, action: #selector(ScorecardInputBoardCollectionCell.textFieldBeginEdit), for: .editingDidBegin)
        textField.backgroundColor = UIColor(Palette.gridBoard.background)
        textField.borderStyle = .none
        textField.textColor = UIColor(Palette.gridBoard.text)
        textField.adjustsFontSizeToFitWidth = true
               
        addSubview(textView, constant: 4, anchored: .leading, .top, .bottom)
        textView.textAlignment = .left
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.font = cellFont
        textView.delegate = self
        textView.backgroundColor = UIColor(Palette.gridBoard.background)
        textView.textColor = UIColor(Palette.gridBoard.text)
        
        addSubview(textViewClear, constant: 4, anchored: .trailing, .top, .bottom)
        Constraint.setWidth(control: textViewClear, width: 32)
        Constraint.anchor(view: self, control: textView, to: textViewClear, constant: 8, toAttribute: .leading, attributes: .trailing)
        textViewClear.image = UIImage(systemName: "x.circle.fill")?.asTemplate
        textViewClear.tintColor = UIColor(Palette.clearText)
        textViewClear.contentMode = .scaleAspectFit
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputBoardCollectionCell.textViewClearPressed))
        textViewClear.addGestureRecognizer(tapGesture)
        textViewClear.isUserInteractionEnabled = true
        
        addSubview(participantPicker, constant: 4, anchored: .all)
        participantPicker.delegate = self
        
        addSubview(contractPicker, constant: 4, anchored: .all)
        contractPicker.delegate = self
        
        addSubview(madePicker, constant: 4, anchored: .all)
        madePicker.delegate = self
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
        textField.isHidden = true
        participantPicker.isHidden = true
        contractPicker.isHidden = true
        madePicker.isHidden = true
        textField.isHidden = true
        textView.isHidden = true
        textViewClear.isHidden = true
        textField.text = ""
        textView.text = ""
        label.text = ""
        label.textAlignment = .center
        textField.textAlignment = .center
        textField.clearsOnBeginEditing = false
        textField.clearButtonMode = .never
    }
    
    func setTitle(column: ScorecardColumn) {
        self.board = nil
        self.column = column
        label.isHidden = false
        label.font = titleFont
        label.text = column.heading
    }
    
    func set(from changeDelegate: ScorecardChangeDelegate, board: BoardViewModel, boardNumber: Int, column: ScorecardColumn) {
        self.changeDelegate = changeDelegate
        self.board = board
        self.boardNumber = boardNumber
        self.column = column
        
        switch column.type {
        case .board:
            label.isHidden = false
            label.font = boardFont
            label.text = "\(board.board)"
        case .contract:
            contractPicker.isHidden = false
            contractPicker.set(board.contract, color: Palette.gridBoard, font: pickerTitleFont, force: true)
        case .declarer:
            participantPicker.isHidden = false
            participantPicker.set(board.declarer, color: Palette.gridBoard, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
        case .made:
            madePicker.isHidden = false
            let (list, min, max) = madeList
            if board.made < min {
                board.made = min
            } else if board.made > max {
                board.made = max
            }
            madePicker.set(board.made - min, list: list, color: Palette.gridBoard, titleFont: pickerTitleFont)
        case .score:
            textField.isHidden = false
            textField.clearsOnBeginEditing = true
            textField.text = board.score == 0 ? "" : "\(board.score)"
        case .comment:
            textView.isHidden = false
            textViewClear.isHidden = board.comment == ""
            textView.text = board.comment
        case .responsible:
            participantPicker.isHidden = false
            participantPicker.set(board.declarer, color: Palette.gridBoard, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
        default:
            label.isHidden = false
            label.text = ""
        }
    }
        
    @objc private func textFieldChanged(_ textField: UITextField) {
        let text = textField.text ?? ""
        if let board = board {
            var undoText: String?
            switch self.column.type {
            case .score:
                undoText = board.score == 0 ? "" : "\(board.score)"
            case .comment:
                undoText = board.comment
            default:
                break
            }
            undoManager?.registerUndo(withTarget: textField) { (textField) in
                textField.text = undoText
                self.textFieldChanged(textField)
            }
            switch column.type {
            case .score:
                board.score = Float(text) ?? 0
            case .comment:
                board.comment = text
            default:
                break
            }
            changeDelegate?.scorecardChanged(type: .board, itemNumber: boardNumber, column: column)
        }
    }
    
    @objc private func textFieldEndEdit(_ textField: UITextField) {
        let text = textField.text ?? ""
        if let board = board {
            switch column.type {
            case .score:
                board.score = Float(text) ?? 0
                textField.text = board.score == 0 ? "" : "\(board.score)"
            default:
                break
            }
        }
    }
    
    @objc private func textFieldBeginEdit(_ textField: UITextField) {
        // Record automatic clear on entry in undo
        var undoText = ""
        if let board = board {
            switch column.type {
            case .comment:
                undoText = board.comment
            case .score:
                undoText = board.score == 0 ? "" : "\(board.score)"
            default:
                break
            }
            if undoText != "" {
                textFieldChanged(textField)
            }
        }
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
            undoManager?.registerUndo(withTarget: textView) { (textView) in
                textView.text = undoText
                self.textViewDidChange(textView)
            }
            switch column.type {
            case .comment:
                board.comment = text
                textViewClear.isHidden = (text == "")
            default:
                break
            }
            changeDelegate?.scorecardChanged(type: .board, itemNumber: boardNumber, column: column)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        print(text)
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
                textViewDidChange(textView)
            }
        }
    }
    
    internal func enumPickerDidChange(to value: Any) {
        if let board = board {
            var undoValue: Participant?
            switch self.column.type {
            case .declarer:
                undoValue =  board.declarer
            case .responsible:
                undoValue = board.responsible
            default:
                break
            }
            if let undoValue = undoValue {
                undoManager?.registerUndo(withTarget: participantPicker) { (participantPicker) in
                    participantPicker.set(undoValue)
                    self.enumPickerDidChange(to: undoValue)
                }
            }
            switch column.type {
            case .declarer:
                board.declarer = value as! Participant
            case .responsible:
                board.responsible = value as! Participant
            default:
                break
            }
            changeDelegate?.scorecardChanged(type: .board, itemNumber: boardNumber, column: column)
        }
    }
    
    internal func contractPickerDidChange(to value: Contract) {
        if let board = board {
            let undoValue = board.contract
            let undoMade = board.made
            undoManager?.registerUndo(withTarget: contractPicker) { (contractPicker) in
                contractPicker.set(undoValue)
                board.made = undoMade
                self.contractPickerDidChange(to: undoValue)
            }
            board.contract = value
            changeDelegate?.scorecardChanged(type: .board, itemNumber: boardNumber, column: column)
        }
    }
    
    internal func scrollPickerDidChange(to value: Int) {
        if let board = board {
            var undoValue: Int?
            switch column.type {
            case .made:
                undoValue = board.made + (6 + board.contract.level.rawValue)
            default:
                break
            }
            if let undoValue = undoValue {
                switch column.type {
                case .made:
                    undoManager?.registerUndo(withTarget: madePicker) { (madePicker) in
                        madePicker.set(undoValue)
                        self.scrollPickerDidChange(to: undoValue)
                    }
                default:
                    break
                }
            }
            switch column.type {
            case .made:
                board.made =  value - (6 + board.contract.level.rawValue)
            default:
                break
            }
            changeDelegate?.scorecardChanged(type: .board, itemNumber: boardNumber, column: column)
        }
    }
}


fileprivate class ScorecardInputTableCollectionCell: UICollectionViewCell, EnumPickerDelegate, UITextViewDelegate {
    fileprivate var caption = UILabel()
    fileprivate var label = UILabel()
    fileprivate var textField = UITextField()
    fileprivate var textView = UITextView()
    fileprivate var textViewClear = UIImageView()
    fileprivate var seatPicker: EnumPicker<Seat>!
    fileprivate var table: TableViewModel!
    fileprivate var tableNumber: Int!
    fileprivate var column: ScorecardColumn!
    private var changeDelegate: ScorecardChangeDelegate?
    private static let identifier = "Table CollectionCell"
    private var captionHeight: NSLayoutConstraint!

    override init(frame: CGRect) {
        seatPicker = EnumPicker(frame: frame, color: Palette.gridTable)
        super.init(frame: frame)
                
        addSubview(label, anchored: .all)
        label.layer.borderColor = UIColor(Palette.gridLine).cgColor
        label.layer.borderWidth = 2.0
        label.textAlignment = .center
        label.minimumScaleFactor = 0.3
        label.backgroundColor = UIColor(Palette.gridTable.background)
        label.textColor = UIColor(Palette.gridTable.text)

        addSubview(textField, constant: 4, anchored: .all)
        textField.textAlignment = .center
        textField.autocapitalizationType = .words
        textField.autocapitalizationType = UITextAutocapitalizationType.none
        textField.autocorrectionType = .no
        textField.font = cellFont
        textField.addTarget(self, action: #selector(ScorecardInputTableCollectionCell.textFieldChanged), for: .editingChanged)
        textField.addTarget(self, action: #selector(ScorecardInputTableCollectionCell.textFieldEndEdit), for: .editingDidEnd)
        textField.addTarget(self, action: #selector(ScorecardInputTableCollectionCell.textFieldBeginEdit), for: .editingDidBegin)
        textField.backgroundColor = UIColor(Palette.gridTable.background)
        textField.textColor = UIColor(Palette.gridTable.text)

        addSubview(textView, constant: 4, anchored: .leading, .bottom)
        Constraint.anchor(view: self, control: textView, constant: 20, attributes: .top)
        textView.textAlignment = .left
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.font = cellFont
        textView.delegate = self
        textView.backgroundColor = UIColor(Palette.gridTable.background)
        textView.textColor = UIColor(Palette.gridTable.text)
        
        addSubview(textViewClear, constant: 4, anchored: .trailing, .top, .bottom)
        Constraint.setWidth(control: textViewClear, width: 34)
        Constraint.anchor(view: self, control: textView, to: textViewClear, constant: 8, toAttribute: .leading, attributes: .trailing)
        textViewClear.image = UIImage(systemName: "x.circle.fill")?.asTemplate
        textViewClear.contentMode = .scaleAspectFit
        textViewClear.tintColor = UIColor(Palette.clearText)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ScorecardInputBoardCollectionCell.textViewClearPressed))
        textViewClear.addGestureRecognizer(tapGesture)
        textViewClear.isUserInteractionEnabled = true
        
        addSubview(seatPicker, constant: 4, anchored: .all)
        seatPicker.delegate = self
        
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
        textViewClear.isHidden = true
        label.text = ""
        label.textAlignment = .center
        textField.textAlignment = .center
        captionHeight.constant = 0
    }
    
    func set(from changeDelegate: ScorecardChangeDelegate, table: TableViewModel, tableNumber: Int, column: ScorecardColumn) {
        self.changeDelegate = changeDelegate
        self.table = table
        self.tableNumber = tableNumber
        self.column = column
        
        switch column.type {
        case .table:
            label.font = boardFont
            label.text = "Round \(table.table)"
        case .sitting:
            seatPicker.isHidden = false
            seatPicker.set(table.sitting, color: Palette.gridTable, titleFont: pickerTitleFont, captionFont: pickerCaptionFont)
        case .tableScore:
            textField.isHidden = false
            textField.clearsOnBeginEditing = true
            textField.text = table.score == 0 ? "" : "\(table.score)"
        case .versus:
            textField.isHidden = false
            textField.text = table.versus
            textField.clearButtonMode = .always
        default:
            label.text = ""
        }
        if column.heading != "" {
            caption.isHidden = false
            captionHeight.constant = 24
            caption.text = column.heading
        }
    }
    
    @objc private func textFieldChanged(_ textField: UITextField) {
        let text = textField.text ?? ""
        if let table = table {
            var undoText: String?
            switch self.column.type {
            case .tableScore:
                undoText = table.score == 0 ? "" : "\(table.score)"
            case .versus:
                undoText = table.versus
            default:
                break
            }
            undoManager?.registerUndo(withTarget: textField) { (textField) in
                textField.text = undoText
                self.textFieldChanged(textField)
            }
            switch column.type {
            case .tableScore:
                table.score = Float(text) ?? 0
            case .versus:
                table.versus = text
            default:
                break
            }
            changeDelegate?.scorecardChanged(type: .table, itemNumber: tableNumber, column: column)
        }
    }
    
    @objc private func textFieldEndEdit(_ textField: UITextField) {
        let text = textField.text ?? ""
        if let table = table {
            switch column.type {
            case .tableScore:
                table.score = Float(text) ?? 0
                textField.text = table.score == 0 ? "" : "\(table.score)"
            default:
                break
            }
        }
    }
    
    @objc private func textFieldBeginEdit(_ textField: UITextField) {
        // Record automatic clear on entry in undo
        var undoText = ""
        if let table = table {
            switch column.type {
            case .versus:
                undoText = table.versus
            case .tableScore:
                undoText = table.score == 0 ? "" : "\(table.score)"
            default:
                break
            }
            if undoText != "" {
                textFieldChanged(textField)
            }
        }
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
            undoManager?.registerUndo(withTarget: textView) { (textView) in
                textView.text = undoText
                self.textViewDidChange(textView)
            }
            switch column.type {
            case .versus:
                table.versus = text
                textViewClear.isHidden = (text == "")
            default:
                break
            }
            changeDelegate?.scorecardChanged(type: .board, itemNumber: tableNumber, column: column)
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
                textViewDidChange(textView)
            }
        }
    }
    
    internal func enumPickerDidChange(to value: Any) {
        if let table = table {
            var undoValue: Any?
            switch self.column.type {
            case .sitting:
                undoValue = table.sitting
            default:
                break
            }
            if let undoValue = undoValue {
                undoManager?.registerUndo(withTarget: seatPicker) { (value) in
                    self.seatPicker.set(undoValue as! Seat)
                    self.enumPickerDidChange(to: undoValue)
                }
            }
            switch column.type {
            case .sitting:
                table.sitting = value as! Seat
            default:
                break
            }
            changeDelegate?.scorecardChanged(type: .table, itemNumber: tableNumber, column: column)
        }
    }
}
