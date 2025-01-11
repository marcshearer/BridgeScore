//
//  Scorecard Canvas View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 29/01/2022.
//

import UIKit
import SwiftUI
import PencilKit
import Vision

enum CanvasRowType: Int {
    case heading = 0
    case body = 1
    case total = 2
}

enum CanvasColumnType: Codable {
    case board
    case contract
    case declarer
    case made
    case score
    case comment
    case responsible
    
    var string: String {
        return "\(self)"
    }
}

struct CanvasRow {
    var row: Int
    var type: CanvasRowType
    var table: Int?
    var board: BoardViewModel?
}

struct CanvasColumn: Codable {
    var type: CanvasColumnType
    var heading: String
    var size: ColumnSize
    var width: CGFloat?
}

struct ScorecardCanvasView: View {

    @ObservedObject var scorecard: ScorecardViewModel
    @State var refresh = false
    @State var toolPickerVisible: Bool = true
    @State var canvasView = PKCanvasView()
    @State var decodePressed: Bool = false
    
    var body: some View {
        StandardView("Canvas") {
            VStack(spacing: 0) {
                
                // Just to trigger view refresh
                if refresh { EmptyView() }
    
                // Banner
                let options = [
                    BannerOption(image: AnyView(Image(systemName: "arrow.uturn.backward")), likeBack: true, action: { undoDrawing() }),
                    BannerOption(image: AnyView(Image(systemName: "trash.fill")), likeBack: true, action: { clearDrawing() }),
                    BannerOption(image: AnyView(Image(systemName: "paintpalette")), likeBack: true, action: { toolPickerVisible.toggle() })]
                Banner(title: $scorecard.desc, back: true, backAction: backAction, leftTitle: true, optionMode: .buttons, options: options)

                GeometryReader { geometry in
                    ScorecardCanvasUIViewWrapper(scorecard: scorecard, frame: geometry.frame(in: .local), toolPickerVisible: $toolPickerVisible, decodePressed: $decodePressed, canvasView: $canvasView)
                    .ignoresSafeArea(edges: .all)
                }
            }
        }
    }
    
    func backAction() -> Bool {
        scorecard.drawing = canvasView.drawing
        scorecard.drawingWidth = canvasView.frame.width
        return true
    }
    
    func clearDrawing() {
        MessageBox.shared.show("This will clear the contents of the drawing.\nAre you sure you want to do this?", cancelText: "Cancel", okText: "Clear", okAction: {
            canvasView.drawing = PKDrawing()
        })
    }
    
    func undoDrawing() {
        MyApp.undoManager.undo()
    }
    
    func decodeDrawing() {
        decodePressed = true
    }
}

struct ScorecardCanvasUIViewWrapper: UIViewRepresentable {
    @ObservedObject var  scorecard: ScorecardViewModel
    @State var frame: CGRect
    @Binding var toolPickerVisible: Bool
    @Binding var decodePressed: Bool
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> ScorecardCanvasUIView {
        
        let view = ScorecardCanvasUIView(frame: frame, scorecard: scorecard, canvasView: canvasView)
        view.delegate = context.coordinator
        
        return view
    }

    func updateUIView(_ uiView: ScorecardCanvasUIView, context: Context) {
        uiView.setToolPicker(visible: toolPickerVisible)
        if decodePressed {
            uiView.decode()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator($decodePressed)
    }
    
    class Coordinator: NSObject, ScorecardCanvasUIViewDelegate {
        @Binding var decodePressed: Bool
        
        init(_ decodePressed: Binding<Bool>) {
            _decodePressed = decodePressed
        }
        
        func clearDecodePressed() {
            decodePressed = false
        }
    }
    
}

protocol ScorecardCanvasUIViewDelegate {
    func clearDecodePressed()
}

class ScorecardCanvasUIView : UIView, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PKToolPickerObserver, PKCanvasViewDelegate {
        
    var scorecard: ScorecardViewModel
    var scrollView = UIScrollView()
    var headingTableView = UITableView()
    var mainTableView = UITableView()
    var canvasView: PKCanvasView
    var toolPicker = PKToolPicker()
    var delegate: ScorecardCanvasUIViewDelegate?
    
    var columns = [
        CanvasColumn(type: .board, heading: "Board", size: .fixed([70])),
        CanvasColumn(type: .contract, heading: "Contract", size: .fixed([90])),
        CanvasColumn(type: .declarer, heading: "By", size: .fixed([60])),
        CanvasColumn(type: .made, heading: "Made", size: .fixed([70])),
        CanvasColumn(type: .score, heading: "Score", size: .fixed([70])),
        CanvasColumn(type: .comment, heading: "Comment", size: .flexible),
        CanvasColumn(type: .responsible, heading: "Resp", size: .fixed([60]))
    ]
    var rows: [CanvasRow] = []
    let headingHeight: CGFloat = 40
    let rowHeight: CGFloat = 90
    var totalHeight: CGFloat = 80
    private var canvasWidth: CGFloat?
    
    init(frame: CGRect, scorecard: ScorecardViewModel, canvasView: PKCanvasView) {
        self.scorecard = scorecard
        self.canvasView = canvasView
        
        super.init(frame: frame)
        
        // Check if drawing in progress - if so restore and rotate if necessary
        self.canvasView.drawing = scorecard.drawing
        let width = scorecard.drawingWidth
        if width > 0 {
            canvasWidth = CGFloat(width)
        }
        
        // Add subviews
        self.addSubview(self.headingTableView)
        self.addSubview(self.scrollView)
        self.scrollView.addSubview(self.mainTableView)
        self.mainTableView.addSubview(self.canvasView)
        
        // Set constraints on subviews
        Constraint.anchor(view: self, control: self.headingTableView, attributes: .leading, .trailing, .top)
        Constraint.setHeight(control: self.headingTableView, height: headingHeight)
                
        Constraint.anchor(view: self, control: self.scrollView, attributes: .leading, .trailing, .bottom)
        Constraint.anchor(view: self, control: self.scrollView, to: self.headingTableView, toAttribute: .bottom, attributes: .top)
                
        // Setup heading table view
        self.headingTableView.delegate = self
        self.headingTableView.dataSource = self
        self.headingTableView.tag = CanvasRowType.heading.rawValue
        self.headingTableView.register(ScorecardCanvasUIViewTableViewCell.self, forCellReuseIdentifier: "ScorecardUIViewTableViewCell")
        self.headingTableView.isScrollEnabled = false
        
        // Setup scroll view
        self.scrollView.contentSize = self.scrollView.frame.size
        self.scrollView.bounces = false
        
        // Setup main table view
        self.mainTableView.delegate = self
        self.mainTableView.dataSource = self
        self.mainTableView.tag = CanvasRowType.body.rawValue
        self.mainTableView.register(ScorecardCanvasUIViewTableViewCell.self, forCellReuseIdentifier: "ScorecardUIViewTableViewCell")
        
        // Setup pencil canvas
        canvasView.tool = PKInkingTool(.pen, color: .blue, width: 4)
        canvasView.backgroundColor = .clear
        canvasView.delegate = self
        toolPicker.addObserver(self)
        toolPicker.selectedTool = canvasView.tool
        
        // Handle rotations
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [weak self] (notification) in
            self?.transformCanvas()
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
        if canvasWidth != canvasView.frame.width {
            self.transformCanvas(to: canvasView.frame.width)
        }
    }

    public func decode() {
        var queue: [ScorecardCanvasUIViewCollectionViewCell] = []

        func decodeCell(_ index: Int) {
            let cell = queue[index]
            let frame = cell.view.convert(cell.frame, to: canvasView)
            Utility.executeAfter(delay: 0.01) { [self] in
                let currentY = scrollView.contentOffset.y
                var scrollY = currentY
                if frame.minY < currentY {
                    scrollY = frame.minY
                } else if frame.maxY > currentY + scrollView.frame.height {
                    scrollY = frame.maxY - scrollView.frame.height
                }
                UIView.animate(withDuration: 0.01) {
                    self.scrollView.setContentOffset(CGPoint(x: self.mainTableView.frame.minX, y: scrollY), animated: false)
                } completion: { (result) in
                    let image = self.self.canvasView.drawing.image(from: frame, scale: 1)
                    self.decodeImage(image: image, completion: { text in
                        if let text = text {
                            cell.label.text = "  " + text
                        }
                        if index < queue.count - 1 {
                            decodeCell(index + 1)
                        } else {
                            Utility.executeAfter(delay: 0.1) {
                                self.delegate?.clearDecodePressed()
                            }
                        }
                    })
                }
            }
        }
        
        for row in 0..<mainTableView.numberOfRows(inSection: 0) {
            if let tableView = mainTableView.cellForRow(at: IndexPath(row: row, section: 0)) as? ScorecardCanvasUIViewTableViewCell {
                for columnNumber in 0..<tableView.collectionView.numberOfItems(inSection: 0) {
                    if let cell = tableView.collectionView.cellForItem(at: IndexPath(item: columnNumber, section: 0)) as? ScorecardCanvasUIViewCollectionViewCell {
                        queue.append(cell)
                    }
                }
            }
        }
        decodeCell(0)
    }
    
    func decodeImage(image: UIImage, completion: @escaping (String?)->()) {
        var text: String? = nil
        let request = VNRecognizeTextRequest { (request, error) in
            if error == nil {
                if let observations = request.results as? [VNRecognizedTextObservation] {
                    for observation in observations {
                        for candidate in observation.topCandidates(1) {
                            text = (text ?? "") + " \(candidate.string)"
                        }
                    }
                    completion(text?.ltrim())
                }
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.customWords = ["C", "D", "H", "S", "N", "O"]
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        try? handler.perform([request])
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        scorecard.backupCurrentDrawing(drawing: canvasView.drawing, width: self.canvasWidth)
    }
    
    func transformCanvas() {
        transformCanvas(to: canvasView.frame.width)
    }
    
    func transformCanvas(to newWidth: CGFloat) {
        if newWidth != 0 {
            if let canvasWidth = canvasWidth {
                if canvasWidth != newWidth {
                    let factor = newWidth / canvasWidth
                    canvasView.drawing.transform(using: CGAffineTransform(scaleX: factor, y: 1))
                }
            }
            canvasWidth = newWidth
        }
    }
    
    func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
        canvasView.tool = toolPicker.selectedTool
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch CanvasRowType(rawValue: tableView.tag) {
        case .heading:
            return 1
        default:
            return rows.count - 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch CanvasRowType(rawValue: tableView.tag) {
        case .heading:
            return headingHeight
        default:
            let row = rows[indexPath.row + 1]
            return row.type == .total ? totalHeight : rowHeight
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScorecardUIViewTableViewCell", for: indexPath) as! ScorecardCanvasUIViewTableViewCell
        cell.setCollectionViewDataSourceDelegate(self, forRow: (CanvasRowType(rawValue: tableView.tag) == .heading ? 0 : indexPath.row + 1))
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScorecardUIViewCollectionViewCell", for: indexPath) as! ScorecardCanvasUIViewCollectionViewCell
        let column = columns[indexPath.item]
        let row = rows[collectionView.tag]
        cell.set(view: collectionView, scorecard: scorecard, row: row, column: column)
        return cell
    }
    
    func setToolPicker(visible: Bool) {
        self.toolPicker.setVisible(visible, forFirstResponder: self.canvasView)
        self.canvasView.becomeFirstResponder()
    }
    
    func setupSizes() {
        var fixedWidth: CGFloat = 0
        var flexible: Int = 0
        for column in self.columns {
            switch column.size {
            case .fixed(let width):
                fixedWidth += width.reduce(0,+)
            case .flexible:
                flexible += 1
            }
        }
        
        var factor: CGFloat = 1.0
        if isLandscape {
            factor = UIScreen.main.bounds.width / UIScreen.main.bounds.height
        }
        
        let availableSize = UIScreen.main.bounds.width
        let fixedSize = fixedWidth * factor
        let flexibleSize = (availableSize - fixedSize) / CGFloat(flexible)
        
        var remainingWidth = availableSize
        for index in 0..<columns.count - 1 {
            switch columns[index].size {
            case .fixed(let width):
                columns[index].width = width.reduce(0,+) * factor
            case .flexible:
                columns[index].width = flexibleSize
            }
            remainingWidth -= columns[index].width!
        }
        columns[columns.count - 1].width = remainingWidth
        
        let totalRowHeight = (CGFloat(scorecard.boards) * rowHeight) + (CGFloat(scorecard.tables) * totalHeight) + headingHeight
        
        self.scrollView.contentSize = CGSize(width: availableSize, height: totalRowHeight - headingHeight)
        self.mainTableView.frame = CGRect(x: 0, y: 0, width: availableSize, height: totalRowHeight - headingHeight)
        self.canvasView.frame = self.mainTableView.frame
        self.mainTableView.isScrollEnabled = false
    }
    
    func setupRows(){
        rows = []
        
        rows.append(CanvasRow(row: 0, type: .heading))
        
        for table in 1...scorecard.tables {
            
            // Add body rows
            for tableBoard in 1...scorecard.boardsTable {
                let boardIndex = ((table - 1) * scorecard.boardsTable) + tableBoard
                let board = BoardViewModel(scorecard: scorecard, boardIndex: boardIndex)
                rows.append(CanvasRow(row: rows.count, type: .body, table: table, board: board))
            }
            
            // Add total rows
            rows.append(CanvasRow(row: rows.count, type: .total, table: table))
        }
    }
}

// MARK: - Cell classes ================================================================ -

class ScorecardCanvasUIViewTableViewCell: UITableViewCell {
    fileprivate var collectionView: UICollectionView!
    private var layout: UICollectionViewFlowLayout!
           
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: layout)
        self.collectionView.register(ScorecardCanvasUIViewCollectionViewCell.self, forCellWithReuseIdentifier: "ScorecardUIViewCollectionViewCell")
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(collectionView)
        Constraint.anchor(view: self.contentView, control: self.collectionView, attributes: .leading, .trailing, .top, .bottom)
        self.contentView.bringSubviewToFront(self.collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCollectionViewDataSourceDelegate
    <D: UICollectionViewDataSource & UICollectionViewDelegate>
    (_ dataSourceDelegate: D, forRow row: Int) {
        
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.tag = row
        collectionView.reloadData()
    }
}

class ScorecardCanvasUIViewCollectionViewCell: UICollectionViewCell {
    fileprivate var label: UILabel
    fileprivate var row: CanvasRow!
    fileprivate var column: CanvasColumn!
    fileprivate var view: UICollectionView!
    
    override init(frame: CGRect) {
        self.label = UILabel()
        super.init(frame: frame)
        self.addSubview(self.label)
        Constraint.anchor(view: self, control: self.label, attributes: .leading, .trailing, .top, .bottom)
        self.label.layer.borderColor = UIColor(Palette.gridLine).cgColor
        self.label.layer.borderWidth = 2.0
        self.label.textAlignment = .center
        self.label.minimumScaleFactor = 0.3
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(view: UICollectionView, scorecard: ScorecardViewModel, row: CanvasRow, column: CanvasColumn) {
        var color: PaletteColor
        self.view = view
        self.row = row
        self.column = column
        
        switch row.type {
        case .heading:
            self.label.text = column.heading
            self.label.font = titleFont.bold
            color = Palette.gridTitle
        case .body:
            if column.type == .board {
                self.label.font = boardFont
                let boardIndex = row.board?.board ?? 0
                self.label.text = "\(scorecard.resetNumbers ? ((boardIndex - 1) % scorecard.boardsTable) + 1 : boardIndex)"
            } else {
                self.label.font = cellFont
            }
            if column.type == .comment {
                self.label.textAlignment = .left
            }
            color = Palette.gridBoard
        case .total:
            self.label.font = cellFont
            color = Palette.gridTable
        }
        self.label.backgroundColor = UIColor(color.background)
        self.label.textColor = UIColor(color.text)
    }
    
    override func prepareForReuse() {
        self.label.text = ""
        self.label.textAlignment = .center
    }
}
