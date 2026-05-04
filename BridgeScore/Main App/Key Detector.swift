//
//  Key Detector.swift
//  BridgeScore
//
//  Created by Marc Shearer on 03/05/2026.
//

import SwiftUI

struct KeyDetectorView: View {
    var processKey: (KeyEquivalent)->()
    @State private var hiddenInput = "X"
    @FocusState private var isFocused: Bool
    @State private var process = true
    
    var body: some View {
        TextField("", text: $hiddenInput)
            .focused($isFocused)
            .frame(width: 0, height: 0)
            .opacity(0)
            .onChange(of: hiddenInput) {
                if hiddenInput == "" {
                    // Backspace key
                    processKey(.delete)
                    process = true
                } else if let character = hiddenInput.last {
                    if process {
                        processKey(KeyEquivalent(character))
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
                if keyPress.characters == "\u{7f}" {
                    processKey(.deleteForward)
                } else {
                    processKey(keyPress.key)
                }
                if hiddenInput != "X" {
                    process = false
                    hiddenInput = "X"
                }
                return .handled
            }
            .onAppear {
                isFocused = true
            }
    }
    
}
