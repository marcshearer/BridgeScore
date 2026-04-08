//
//  Key Interceptor.swift
//  BridgeScore
//
//  Created by Marc Shearer on 07/04/2026.
//

import SwiftUI
import UIKit

struct KeyInterceptor: UIViewRepresentable {
    @Binding var ignoreKeys: Bool
    var onKey: (UIKey) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = KeyView()
        view.onKey = onKey
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if !ignoreKeys && context.coordinator.wasFocused {
            Utility.executeAfter(delay: 0.1) {
                if !uiView.isFirstResponder {
                    uiView.becomeFirstResponder()
                }
                context.coordinator.wasFocused = false
            }
        } else {
            context.coordinator.wasFocused = true
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var wasFocused = false
    }

    class KeyView: UIView {
        var onKey: ((UIKey) -> Void)?
        var ignoreKeys: (() -> Bool)?

        override var canBecomeFirstResponder: Bool { true }

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            if let focused = ignoreKeys?(), focused {
                super.pressesBegan(presses, with: event)
                return
            }

            if let key = presses.first?.key {
                onKey?(key)
            }
        }
    }
}
