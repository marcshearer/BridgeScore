//
//  Derived Values View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 04/05/2026.
//

import SwiftUI

struct DerivedValuesView : View {
    @Binding var logic: [DerivedElement]
    var color: ThemeBackgroundColorName
    
    @State var cursor: Int = 0
    @State var literalCursor: Int? = nil
    
    var body: some View {
        HStack {
            KeyDetectorView(processKey: processKey)
            Spacer()
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(0..<logic.count+1, id: \.self) { index in
                        if index == cursor && literalCursor == nil {
                            HStack {
                                Spacer()
                                Rectangle().frame(width: 2, height: 30)
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .frame(width: 4)
                        } else {
                            HStack {
                                Spacer().frame(width: 4)
                            }
                        }
                        if index <= logic.count - 1 {
                            let string = logic[index].string
                            if let literalCursor = literalCursor, cursor == index {
                                HStack(spacing: 0) {
                                    Text(string.prefix(literalCursor))
                                    Rectangle().frame(width: 2, height: 30)
                                        .foregroundColor(.blue)
                                    Text(string.suffix(string.count - literalCursor))
                                }
                            } else {
                                Text(string)
                            }
                        }
                    }
                    Spacer()
                }
                .focusable()
                .focusEffectDisabled()
            }
            .palette(color)
            Spacer()
        }
        .onAppear {
            cursor = logic.count
        }
    }

    func processKey(_ key: KeyEquivalent) {
        var clearLiteralCursor: Bool = true
        
        switch key {
        case "+", "*", "/", "-":
            logic.insert(.operatorSymbol(.init(rawValue: String(key.character))!), at: self.cursor)
            cursor += 1
        case "(", ")":
            logic.insert(.bracket(.init(rawValue: String(key.character))!), at: self.cursor)
            cursor += 1
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".":
            var handled = false
            if literalCursor != nil  {
                if case let .literal(value) = logic[cursor] {
                    var combined = ""
                    if literalCursor! >= 1 {
                        combined += value.prefix(literalCursor!)
                    }
                    combined += String(key.character)
                    if literalCursor! < value.count {
                        combined += value.suffix(value.count - literalCursor!)
                    }
                    if Float(combined) != nil {
                        logic[cursor] = .literal(combined)
                        literalCursor = literalCursor! + 1
                    }
                    clearLiteralCursor = false
                    handled = true
                }
            }
            if !handled {
                if cursor > 0 {
                    if case .literal(let value) = logic[cursor - 1] {
                        // Combine with preceding literal
                        let combined = value + String(key.character)
                        if let _ = Float(combined) {
                            logic[cursor-1] = .literal(combined)
                        }
                        handled = true
                    }
                }
                if !handled && cursor < logic.count - 1 {
                    // Combine with subsequent literal
                    if case .literal(let value) = logic[cursor] {
                        let combined = String(key.character) + value
                        if Float(combined) != nil {
                            logic[cursor] = .literal(combined)
                        }
                        handled = true
                    }
                }
                if !handled {
                    // Create new literal
                    let combined = String(key.character)
                    if let _ = Float(combined) {
                        logic.insert(.literal(combined), at: self.cursor)
                        cursor += 1
                    }
                }
                clearLiteralCursor = handled
            }
        case .leftArrow :
            if literalCursor != nil {
                // In a literal
                if literalCursor! <= 1 {
                    // Moving out of literal
                    if literalCursor == 0 {
                        cursor = max(0, cursor - 1)
                    }
                } else {
                    // Move left within literal
                    literalCursor = literalCursor! - 1
                    clearLiteralCursor = false
                }
            } else {
                // Moving left - check if previous element is a literal
                if cursor > 0 {
                    if case .literal(let value) = logic[cursor - 1] {
                        // Moving into a literal
                        if value.count > 1 {
                            // Move before last character
                            cursor = cursor - 1
                            literalCursor = value.count - 1
                            clearLiteralCursor = false
                        } else {
                            // Only one character - no need to step over it
                            cursor = max(0, cursor - 1)
                        }
                    } else {
                        // Not a literal
                        cursor = max(0, cursor - 1)
                    }
                }
            }
        case .rightArrow:
            if literalCursor != nil {
                // In a literal
                if case .literal(let value) = logic[cursor] {
                    if literalCursor! >= value.count - 1 {
                        // Moving out of this literal
                        cursor = min(logic.count, cursor + 1)
                    } else {
                        // Move right one character
                        literalCursor = literalCursor! + 1
                        clearLiteralCursor = false
                    }
                } else {
                    // This shouldn't happen
                }
            } else {
                // Moving right - check if current element is a literal
                if cursor <= logic.count - 1 {
                    if case .literal(let value) = logic[cursor] {
                        if value.count <= 1 {
                            // Only one character - no need to step over it
                            cursor = cursor + 1
                        } else {
                            // Move after first character
                            literalCursor = 1
                            clearLiteralCursor = false
                        }
                    } else {
                        // Not a literal
                        cursor = min(logic.count, cursor + 1)
                    }
                } else {
                    // Move to end
                    cursor = logic.count
                }
            }
        case .delete:
            // Backspace key
            if cursor > 0 {
                var handled = false
                if literalCursor != nil && literalCursor! > 0 {
                    if case .literal(let value) = logic[cursor] {
                        var value = value
                        if literalCursor == 1 {
                            value = String(value.dropFirst())
                        } else if literalCursor == value.count {
                            value = String(value.dropLast())
                        } else {
                            value = String(value.prefix(literalCursor! - 1)) + String(value.suffix(value.count - literalCursor!))
                        }
                        if Float(value) != nil {
                            logic[cursor] = .literal(String(value))
                            handled = true
                            if literalCursor! > 1 {
                                literalCursor = literalCursor! - 1
                                clearLiteralCursor = false
                            }
                        }
                    }
                }
                if !handled {
                    if case .literal(let value) = logic[cursor - 1] {
                        if value.count > 1 {
                            let value = value.dropLast()
                            if Float(value) != nil {
                                logic[cursor - 1] = .literal(String(value))
                            }
                            handled = true
                        }
                    }
                }
                if !handled {
                    logic.remove(at: cursor - 1)
                    cursor -= 1
                }
            }
        case .deleteForward:
            // Delete key
            var handled = false
            if cursor < logic.count {
                if case .literal(let value) = logic[cursor] {
                    if literalCursor != nil && literalCursor! <= value.count - 1 {
                        var value = value
                        if literalCursor == 0 {
                            value = String(value.dropFirst())
                        } else if literalCursor == value.count - 1 {
                            value = String(value.dropLast())
                        } else {
                            value = String(value.prefix(literalCursor!)) + String(value.suffix(value.count - literalCursor! - 1))
                        }
                        if Float(value) != nil {
                            logic[cursor] = .literal(String(value))
                            handled = true
                            if literalCursor! <= value.count - 1 {
                                clearLiteralCursor = false
                            } else {
                                cursor = cursor + 1
                            }
                        }
                    }
                }
            }
            if !handled && cursor < logic.count {
                if case .literal(let value) = logic[cursor] {
                    if value.count > 1 {
                        let value = value.dropFirst()
                        if let _ = Float(value) {
                            logic[cursor] = .literal(String(value))
                        }
                        handled = true
                    }
                }
                if handled == false {
                    logic.remove(at: cursor)
                }
            }
        default:
            clearLiteralCursor = false
        }
        if clearLiteralCursor {
            literalCursor = nil
        }
    }
}
