//
//  Scorecard View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 25/01/2022.
//

import SwiftUI

enum RowType {
    case heading
    case body
    case total
}

enum ColumnType {
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

struct ScorecardColumn {
    var type: ColumnType
    var heading: String
    var size: GridItem.Size
}

struct ScorecardCell: Identifiable {
    let id = UUID()
    var row: Int
    var rowType: RowType
    var column: ScorecardColumn
    var text: String
    var font: Font
    var color: PaletteColor
    
    init(row: Int = 0, rowType: RowType = .body, column: ScorecardColumn, text: String = "", font: Font = cellFont, color: PaletteColor = Palette.gridBody) {
        self.row = row
        self.rowType = rowType
        self.column = column
        self.text = text
        self.font = font
        self.color = color
    }
}

struct ScorecardView: View {
    @Binding var scorecard: ScorecardViewModel
    @State var refresh = false
    @State var minValue = 1
    @State var linkToScorecard = false
    
    let columns = [
        ScorecardColumn(type: .board, heading: "Board", size: .fixed(70)),
        ScorecardColumn(type: .contract, heading: "Contract", size: .fixed(90)),
        ScorecardColumn(type: .declarer, heading: "By", size: .fixed(60)),
        ScorecardColumn(type: .result, heading: "Result", size: .fixed(70)),
        ScorecardColumn(type: .score, heading: "Score", size: .fixed(70)),
        ScorecardColumn(type: .comment, heading: "Comment", size: .flexible()),
        ScorecardColumn(type: .responsible, heading: "Resp", size: .fixed(60)),
    ]
    
    var body: some View {
        StandardView {
            
            let heading = heading()
            let cells = cells()
            
            VStack(spacing: 0) {
                
                // Just to trigger view refresh
                if refresh { EmptyView() }
    
                // Banner
                Banner(title: $scorecard.desc, back: true, optionMode: .none)
                
                // Heading
                LazyVGrid(columns: columns.map{GridItem($0.size, spacing: 0)}, alignment: .center, spacing: 0) {
                    ForEach(heading) { cell in
                        ScorecardViewCell(scorecard: $scorecard, cell: cell, height: 30)
                    }
                }
                
                // Body and totals
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns.map{GridItem($0.size, spacing: 0)}, alignment: .center, spacing: 0) {
                        ForEach(cells) { cell in
                            ScorecardViewCell(scorecard: $scorecard, cell: cell, height: (cell.rowType == .total && !scorecard.tableTotal ? 2 : 80))
                        }
                    }
                }
            }
        }
    }
    
    func heading() -> [ScorecardCell] {
        var heading: [ScorecardCell] = []
        
        // Add titles
        for column in columns {
            heading.append(ScorecardCell(rowType: .heading, column: column, text: column.heading, font: titleFont, color: Palette.gridHeader))
        }
        return heading
    }
    
    func cells() -> [ScorecardCell] {
        var cells: [ScorecardCell] = []
        
        let tables = scorecard.boards / scorecard.boardsTable
        
        for table in 1...tables {
            
            // Add body rows
            for tableBoard in 1...scorecard.boardsTable {
                let board = ((table - 1) * scorecard.boardsTable) + tableBoard
                
                for column in columns {
                    switch column.type {
                    case .board:
                        cells.append(ScorecardCell(row: board, column: column, text: String(board), font: .largeTitle))
                    default:
                        cells.append(ScorecardCell(row: board, column: column))
                    }
                }
            }
            
            // Add total cells
            for column in columns {
                cells.append(ScorecardCell(row: table, rowType: .total, column: column, color: Palette.gridTotal))
            }
        }
        
        return cells
    }
                                 
    func boardsTableLabel(boardsTable: Int) -> String {
        return "\(boardsTable) \(plural("board", boardsTable)) per table"
    }
    
    func boardsLabel(boards: Int) -> String {
        let tables = boards / max(1, scorecard.boardsTable)
        return "\(tables) \(plural("table", tables)) - \(boards) \(plural("board", boards)) in total"
    }
    
    func plural(_ text: String, _ value: Int) -> String {
        return (value <= 1 ? text : text + "s")
    }

}


struct ScorecardViewCell: View {
    @Binding var scorecard: ScorecardViewModel
    @State var cell: ScorecardCell
    @State var height: CGFloat
        
    var body: some View {
        
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if cell.rowType != .heading && cell.column.type != .board {
                    CanvasView()
                } else {
                    Spacer()
                    Text(cell.text)
                        .font(cell.font)
                        .foregroundColor(cell.color.text)
                        .minimumScaleFactor(0.4)
                    Spacer()
                }
            }
            .frame(height: height)
            .border(Palette.gridLine)
        }
        .background(cell.color.background)
    }
}

