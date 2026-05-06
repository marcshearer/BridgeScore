//
//  Key Detector.swift
//  BridgeScore
//
//  Created by Marc Shearer on 03/05/2026.
//

import SwiftUI

struct KeyDetectorView: View {
    var processKey: (KeyEquivalent?,String?)->()
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
                if keyPress.characters == "\u{7f}" {
                    processKey(KeyEquivalent.deleteForward, nil)
                } else {
                    processKey(keyPress.key, nil)
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
