//
//  Key Detector.swift
//  BridgeScore
//
//  Created by Marc Shearer on 03/05/2026.
//

import SwiftUI

struct KeyDetectorView<Focus>: View where Focus : Hashable {
    var processKey: (KeyEquivalent?,String?)->()
    @FocusState.Binding var focused: Focus
    var focusValue: Focus
    var nextFocusValue: Focus? = nil
    var previousFocusValue: Focus? = nil
    @State private var hiddenInput = "X"
    @State private var process = true
    var ignoreEscape: Bool = true
    
    var body: some View {
        TextField("", text: $hiddenInput)
            .focusable()
            .focused($focused, equals: focusValue)
            .frame(width: 0, height: 0)
            .opacity(0)
            .onChange(of: hiddenInput) {
                if hiddenInput == "" {
                    // Backspace key
                    processKey(KeyEquivalent.delete, nil)
                    process = true
                } else if let character = hiddenInput.last {
                    if process {
                        processKey(nil, String(character))
                    } else {
                        process = true
                    }
                }
                if hiddenInput != "X" {
                    process = false
                    hiddenInput = "X"
                }
            }
            .onKeyPress { keyPress in
                let shift = keyPress.modifiers.contains(.shift)
                if let nextFocusValue = nextFocusValue, (keyPress.key == .return || (keyPress.key == .tab && !shift)) {
                    // Move focus forward
                    focused = nextFocusValue
                    return .handled
                } else if let previousFocusValue = previousFocusValue, (keyPress.key == .tab && shift) {
                    focused = previousFocusValue
                    return .handled
                }
                if keyPress.characters == "\u{7f}" {
                    processKey(KeyEquivalent.deleteForward, nil)
                } else {
                    processKey(keyPress.key, nil)
                }
                if hiddenInput != "X" {
                    process = false
                    hiddenInput = "X"
                }
                return (ignoreEscape && keyPress.key == .escape) ? .ignored : .handled
            }
    }
    
}
