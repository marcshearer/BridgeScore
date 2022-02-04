//
//  ScorecardView.swift
//  BridgeScore
//
//  Created by Marc Shearer on 29/01/2022.
//

import UIKit
import SwiftUI
import PencilKit

enum RowType: Int {
    case heading = 0
    case body = 1
    case total = 2
}

enum ColumnType: Codable {
    case board
    case contract
    case declarer
    case result
    case score
    case comment
    case responsible
    
    var string: String {
        return "\(self)"
    }
}

enum ColumnSize: Codable {
    case fixed(CGFloat)
    case flexible
}

struct ScorecardRow {
    var type: RowType
    var table: Int?
    var board: Int?
}

struct ScorecardColumn: Codable {
    var type: ColumnType
    var heading: String
    var size: ColumnSize
    var width: CGFloat?
}

struct ScorecardView: View {
    @Environment(\.undoManager) private var undoManager

    @Binding var scorecard: ScorecardViewModel
    @State var refresh = false
    @State var linkToScorecard = false
    @State var toolPickerVisible: Bool = true
    @State var canvasView = PKCanvasView()
    
    var body: some View {
        StandardView {
            VStack(spacing: 0) {
                
                // Just to trigger view refresh
                if refresh { EmptyView() }
    
                // Banner
                let options = [
                    BannerOption(image: AnyView(Image(systemName: "arrow.uturn.backward")), likeBack: true, action: { undoDrawing() }),
                    BannerOption(image: AnyView(Image(systemName: "trash.fill")), likeBack: true, action: { clearDrawing() }),
                    BannerOption(image: AnyView(Image(systemName: "paintpalette")), likeBack: true, action: { toolPickerVisible.toggle() })]
                Banner(title: $scorecard.desc, back: true, backAction: backAction, optionMode: .buttons, options: options)
                
                GeometryReader { geometry in
                    ScorecardUIViewWrapper(frame: geometry.frame(in: .local), scorecard: $scorecard, toolPickerVisible: $toolPickerVisible, canvasView: $canvasView)
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
        undoManager?.undo()
    }
}

struct ScorecardUIViewWrapper: UIViewRepresentable {
    @State var frame: CGRect
    @Binding var scorecard: ScorecardViewModel
    @Binding var toolPickerVisible: Bool
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> ScorecardUIView {
        
        ScorecardUIView(frame: frame, scorecard: scorecard, canvasView: canvasView)
        
    }

    func updateUIView(_ uiView: ScorecardUIView, context: Context) {
        uiView.setToolPicker(visible: toolPickerVisible)
   }
}

class ScorecardUIView : UIView, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PKToolPickerObserver, PKCanvasViewDelegate {
        
    var scorecard: ScorecardViewModel
    var scrollView = UIScrollView()
    var headingTableView = UITableView()
    var mainTableView = UITableView()
    var canvasView: PKCanvasView
    var toolPicker = PKToolPicker()
    
    var columns = [
        ScorecardColumn(type: .board, heading: "Board", size: .fixed(70)),
        ScorecardColumn(type: .contract, heading: "Contract", size: .fixed(90)),
        ScorecardColumn(type: .declarer, heading: "By", size: .fixed(60)),
        ScorecardColumn(type: .result, heading: "Result", size: .fixed(70)),
        ScorecardColumn(type: .score, heading: "Score", size: .fixed(70)),
        ScorecardColumn(type: .comment, heading: "Comment", size: .flexible),
        ScorecardColumn(type: .responsible, heading: "Resp", size: .fixed(60))
    ]
    var rows: [ScorecardRow] = []
    let headingHeight: CGFloat = 40
    let rowHeight: CGFloat = 90
    var totalHeight: CGFloat
    private var canvasWidth: CGFloat?
    
    init(frame: CGRect, scorecard: ScorecardViewModel, canvasView: PKCanvasView) {
        self.scorecard = scorecard
        self.canvasView = canvasView
        self.totalHeight = (scorecard.tableTotal ? 80 : 2)
        
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
        self.headingTableView.tag = RowType.heading.rawValue
        self.headingTableView.register(ScorecardUIViewTableViewCell.self, forCellReuseIdentifier: "ScorecardUIViewTableViewCell")
        self.headingTableView.isScrollEnabled = false
        
        // Setup scroll view
        self.scrollView.contentSize = self.scrollView.frame.size
        self.scrollView.bounces = false
        
        // Setup main table view
        self.mainTableView.delegate = self
        self.mainTableView.dataSource = self
        self.mainTableView.tag = RowType.body.rawValue
        self.mainTableView.register(ScorecardUIViewTableViewCell.self, forCellReuseIdentifier: "ScorecardUIViewTableViewCell")
        
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScorecardUIViewTableViewCell", for: indexPath) as! ScorecardUIViewTableViewCell
        cell.setCollectionViewDataSourceDelegate(self, forRow: (RowType(rawValue: tableView.tag) == .heading ? 0 : indexPath.row + 1))
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScorecardUIViewCollectionViewCell", for: indexPath) as! ScorecardUIViewCollectionViewCell
        let column = columns[indexPath.item]
        let row = rows[collectionView.tag]
        cell.set(row: row, column: column)
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
        self.canvasView.frame = self.mainTableView.frame
        self.mainTableView.isScrollEnabled = false
    }
    
    func setupRows(){
        rows = []
        
        rows.append(ScorecardRow(type: .heading))
        
        for table in 1...scorecard.tables {
            
            // Add body rows
            for tableBoard in 1...scorecard.boardsTable {
                let board = ((table - 1) * scorecard.boardsTable) + tableBoard
                rows.append(ScorecardRow(type: .body, table: table, board: board))
            }
            
            // Add total rows
            rows.append(ScorecardRow(type: .total, table: table))
        }
    }
}

// MARK: - Cell classes ================================================================ -

class ScorecardUIViewTableViewCell: UITableViewCell {
    fileprivate var collectionView: UICollectionView!
    private var layout: UICollectionViewFlowLayout!
           
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: layout)
        self.collectionView.register(ScorecardUIViewCollectionViewCell.self, forCellWithReuseIdentifier: "ScorecardUIViewCollectionViewCell")
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

class ScorecardUIViewCollectionViewCell: UICollectionViewCell {
    fileprivate var label: UILabel
    
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
    
    func set(row: ScorecardRow, column: ScorecardColumn) {
        var color: PaletteColor
        switch row.type {
        case .heading:
            self.label.text = column.heading
            self.label.font = titleFont
            color = Palette.gridHeader
        case .body:
            if column.type == .board {
                self.label.font = boardFont
                self.label.text = "\(row.board!)"
            } else {
                self.label.font = cellFont
            }
            color = Palette.gridBody
        case .total:
            self.label.font = cellFont
            color = Palette.gridTotal
        }
        self.label.backgroundColor = UIColor(color.background)
        self.label.textColor = UIColor(color.text)
    }
    
    override func prepareForReuse() {
        self.label.text = ""
    }
}
