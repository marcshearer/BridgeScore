//
//  Analysis Viewer.swift
//  BridgeScore
//
//  Created by Marc Shearer on 08/09/2023.
//

import SwiftUI
import UIKit

struct AnalysisViewer: View {
    @State var board: BoardViewModel
    @State var traveller: TravellerViewModel
    @State var sitting: Seat
    @State var from: UIView
    
    init(board: BoardViewModel, traveller: TravellerViewModel,sitting: Seat, from: UIView) {
        self.board = board
        self.traveller = traveller
        self.sitting = sitting
        self.from = from
    }
    
    var body: some View {
        
        StandardView("AnalysisView") {
            VStack {
                HStack {
                    Rectangle().frame(width: 300, height: 300).background(.yellow)
                    HandViewer(board: board, traveller: traveller, sitting: sitting, from: from)
                }
            }
        }
    }
}
