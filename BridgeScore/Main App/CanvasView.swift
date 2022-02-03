//
//  CanvasView.swift
//  BridgeScore
//
//  Created by Marc Shearer on 27/01/2022.
//

import SwiftUI
import PencilKit

struct CanvasView {
  @State var canvasView = PKCanvasView()
}

extension CanvasView: UIViewRepresentable {
  func makeUIView(context: Context) -> PKCanvasView {
    canvasView.tool = PKInkingTool(.pen, color: .blue, width: 8)
    #if targetEnvironment(simulator)
      canvasView.drawingPolicy = .anyInput
      canvasView.backgroundColor = .clear
      canvasView.isOpaque = false
      canvasView.sizeToFit()
    #endif
    return canvasView
  }

  func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
