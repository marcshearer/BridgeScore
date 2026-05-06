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
        VStack {
            Spacer()
            HStack {
                Spacer().frame(width: 4)
                KeyDetectorView(processKey: processKey)
                Spacer()
                ScrollViewReader { proxy in
                    ScrollView(.horizontal) {
                        HStack(spacing: 0) {
                            ForEach(0..<logic.count+1, id: \.self) { index in
                                HStack(spacing: 0) {
                                    HStack(spacing: 0) {
                                        if index == cursor && literalCursor == nil {
                                            HStack(spacing: 0) {
                                                Spacer()
                                                Rectangle().frame(width: 2, height: 30)
                                                    .foregroundColor(.black)
                                                Spacer()
                                            }
                                            .frame(width: 8)
                                        } else {
                                            HStack(spacing: 0) {
                                                Text("").frame(width: 8)
                                            }
                                        }
                                    }
                                    if index <= logic.count - 1 {
                                        let string = logic[index].string
                                        if let literalCursor = literalCursor, cursor == index, case let .literal(literal) = logic[index] {
                                            HStack(spacing: 0) {
                                                let literalCursor = literalCursor + literal.literalCursorOffset
                                                if literalCursor > 0 {
                                                    Text(string.prefix(literalCursor))
                                                }
                                                Rectangle().frame(width: 2, height: 30)
                                                    .foregroundColor(.black)
                                                if string.count > literalCursor {
                                                    Text(string.suffix(string.count - literalCursor))
                                                }
                                            }
                                            .layoutPriority(1)
                                        } else {
                                            Text(string)
                                        }
                                    }
                                }
                                .id(index)
                            }
                            Spacer()
                        }
                        Spacer().frame(width: 4)
                    }
                    .onChange(of: cursor) {
                        withAnimation {
                            proxy.scrollTo(cursor, anchor: nil)
                        }
                        
                    }
                    .frame(height: 50)
                    .contentMargins(.bottom, 10, for: .scrollContent)
                }
                Spacer().frame(width: 4)
            }
        }
        .frame(height: 60)
        .dropDestination(for: ColumnTransfer.self) { (droppedColumns, _) in
            return handleDrop(droppedColumns, cursor)
        }
        .palette(color)
        .cornerRadius(8)
        .onAppear {
            cursor = logic.count
        }
    }
    
    func handleDrop(_ droppedColumns: [ColumnTransfer], _ before: Int) {
        logic.insert(contentsOf: droppedColumns.map{.variable($0.column)}, at: cursor)
        cursor += droppedColumns.count
    }
    
    func processKey(key: KeyEquivalent? = nil, character: String? = nil) {
        var clearLiteralCursor: Bool = true
        
        if let key = key {
            switch key {
            case .leftArrow :
                if literalCursor != nil, cursor < logic.count, case let(.literal(literal)) = logic[cursor] {
                    // In a literal
                    if literalCursor! <= literal.literalCursorLow {
                        // Moving out of literal - just reset literalCursor
                        // cursor = max(0, cursor - 1)
                    } else {
                        // Move left within literal
                        literalCursor = literalCursor! - 1
                        clearLiteralCursor = false
                    }
                } else {
                    // Moving left - check if previous element is a literal
                    if cursor > 0 {
                        if case .literal(let literal) = logic[cursor - 1], literal.type != .boolean {
                            // Moving into a literal
                            if literal.characters.count > literal.literalCursorLow || (literal.isString && literal.characters.isEmpty) {
                                // Move before last character
                                cursor = cursor - 1
                                literalCursor = literal.literalCursorHigh
                                clearLiteralCursor = false
                            } else {
                                // Moving out of it
                                cursor = max(0, cursor - 1)
                            }
                        } else {
                            // Not a (non-boolean) literal
                            cursor = max(0, cursor - 1)
                        }
                    }
                }
            case .rightArrow:
                if literalCursor != nil {
                    // In a literal
                    if case .literal(let literal) = logic[cursor] {
                        if literalCursor! >= literal.literalCursorHigh {
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
                        if case .literal(let literal) = logic[cursor], literal.type != .boolean {
                            if !literal.isString && literal.characters.count <= literal.literalCursorLow {
                                // Less than min characters - step out of it
                                cursor = cursor + 1
                            } else {
                                // Move after first character
                                literalCursor = literal.literalCursorLow
                                clearLiteralCursor = false
                            }
                        } else {
                            // Not a (non-boolean) literal
                            cursor = min(logic.count, cursor + 1)
                        }
                    } else {
                        // Move to end
                        cursor = logic.count
                    }
                }
            case .delete:
                // Backspace key
                if cursor > 0 || literalCursor != nil {
                    var handled = false
                    if literalCursor != nil  {
                        if case .literal(let literal) = logic[cursor], literal.type != .boolean {
                            if literalCursor! > 0 {
                                var string = literal.characters
                                if literalCursor == 1 {
                                    string = String(string.dropFirst())
                                } else if literalCursor == string.count {
                                    string = String(string.dropLast())
                                } else {
                                    string = String(string.prefix(literalCursor! - 1)) + String(string.suffix(string.count - literalCursor!))
                                }
                                if !literal.isNumeric || Float(string) != nil {
                                    logic[cursor] = .literal(DerivedLiteral(characters: String(string), type: literal.type))
                                    handled = true
                                    if literalCursor! > literal.literalCursorLow {
                                        literalCursor = literalCursor! - 1
                                        clearLiteralCursor = false
                                    }
                                }
                            } else if literal.isString {
                                // Deleting opening quote - clear it
                                logic.remove(at: cursor)
                                handled = true
                            }
                        }
                    }
                    if !handled && cursor > 0 {
                        if case .literal(let literal) = logic[cursor - 1], literal.type != .boolean {
                            var literal = literal
                            if literal.characters.count > 1 {
                                let string = literal.characters.dropLast()
                                if !literal.isNumeric || Float(string) != nil {
                                    literal = DerivedLiteral(characters: String(string), type: literal.type)
                                    logic[cursor - 1] = .literal(literal)
                                }
                                if literal.isString && literal.characters.count > 1 {
                                    literalCursor = literal.literalCursorHigh
                                    clearLiteralCursor = false
                                    cursor -= 1
                                }
                                handled = true
                            }
                        }
                    }
                    if !handled && cursor > 0 {
                        logic.remove(at: cursor - 1)
                        cursor -= 1
                    }
                }
            case .deleteForward:
                // Delete key
                var handled = false
                if cursor < logic.count {
                    if case .literal(let literal) = logic[cursor], literal.type != .boolean {
                        if literalCursor != nil && literalCursor! <= literal.literalCursorHigh {
                            var string = literal.characters
                            if literalCursor == literal.literalCursorHigh {
                                if literal.isString {
                                    // Deleting closing quote - remove the literal
                                    logic.remove(at: cursor)
                                    handled = true
                                }
                            }
                            if !handled {
                                if literalCursor == 0 {
                                    string = String(string.dropFirst())
                                } else if literalCursor == string.count - 1 {
                                    string = String(string.dropLast())
                                } else {
                                    string = String(string.prefix(literalCursor!)) + String(string.suffix(string.count - literalCursor! - 1))
                                }
                                if !literal.isNumeric || Float(string) != nil {
                                    logic[cursor] = .literal(DerivedLiteral(characters: String(string), type: literal.type))
                                    handled = true
                                    if literalCursor! <= literal.literalCursorHigh {
                                        clearLiteralCursor = false
                                    } else {
                                        cursor = cursor + 1
                                    }
                                }
                            }
                        }
                    }
                }
                if !handled && cursor < logic.count {
                    if case .literal(let literal) = logic[cursor], literal.type != .boolean {
                        if literal.characters.count > literal.literalCursorLow {
                            let string = literal.characters.dropFirst()
                            if !literal.isNumeric || Float(string) != nil {
                                logic[cursor] = .literal(DerivedLiteral(characters: String(string), type: literal.type))
                                if literal.isString {
                                    // Move into the string
                                    literalCursor = 0
                                    clearLiteralCursor = false
                                }
                            }
                            handled = true                        }
                    }
                    if handled == false {
                        logic.remove(at: cursor)
                    }
                }
            default:
                clearLiteralCursor = false
            }
        } else if let character = character {
            var handled = false
            if literalCursor != nil, cursor < logic.count, case let .literal(literal) = logic[cursor] {
                if literal.type == .string {
                    if character == "\"" {
                        // Ending string
                        var string = ""
                        if literalCursor != 0 {
                            // Truncate it at the literal cursor
                            string = String(literal.characters.prefix(literalCursor!))
                        }
                        logic[cursor] = .literal(DerivedLiteral(characters: string, type: .string))
                    } else {
                        // Adding to an existing string
                        var combined = ""
                        if literalCursor! >= 1 {
                            combined += literal.characters.prefix(literalCursor!)
                        }
                        combined += character
                        if literalCursor! < literal.characters.count {
                            combined += literal.characters.suffix(literal.characters.count - literalCursor!)
                        }
                        logic[cursor] = .literal(DerivedLiteral(characters: combined, type: .string))
                        literalCursor! += 1
                        clearLiteralCursor = false
                        handled = true
                    }
                } else if literal.type == .numeric {
                    var combined = ""
                    if literalCursor! >= 1 {
                        combined += literal.characters.prefix(literalCursor!)
                    }
                    combined += character
                    if literalCursor! < literal.characters.count {
                        combined += literal.characters.suffix(literal.characters.count - literalCursor!)
                    }
                    if Float(combined) != nil {
                        logic[cursor] = .literal(DerivedLiteral(characters: combined, type: .numeric))
                        literalCursor = literalCursor! + 1
                    }
                    clearLiteralCursor = false
                    handled = true
                }
            }
            if !handled {
                switch character.first! {
                case "+", "*", "/", "-":
                    logic.insert(.operatorSymbol(.init(rawValue: character)!), at: self.cursor)
                    cursor += 1
                case "(", ")":
                    logic.insert(.bracket(.init(rawValue: character)!), at: self.cursor)
                    cursor += 1
                case "&", "|":
                    logic.insert(.logicalOperator(.init(rawValue: character)!), at: self.cursor)
                    cursor += 1
                case "!":
                    var handled = false
                    // Check if can combine with subsequent =
                    if !handled && cursor < logic.count - 1, case let .comparisonOperator(value) = logic[cursor - 1], value == .equal {
                        logic[cursor - 1] = .comparisonOperator(.notEqual)
                        cursor = cursor + 1
                        handled = true
                    }
                    if !handled {
                        logic.insert(.operatorSymbol(.init(rawValue: character)!), at: self.cursor)
                        cursor += 1
                    }
                case "<", ">", "=":
                    switch character {
                    case "<", ">":
                        var handled = false
                        // Check if can combine with subsequent =
                        if cursor < logic.count, case let .comparisonOperator(value) = logic[cursor] {
                            if value == .equal {
                                logic[cursor] = .comparisonOperator(.init(rawValue: character + "=")!)
                                cursor += 1
                                handled = true
                            }
                        }
                        if !handled {
                            logic.insert(.comparisonOperator(.init(rawValue: character)!), at: self.cursor)
                            cursor += 1
                        }
                    case "=":
                        var handled = false
                        // Check if can combine with preceding < or >
                        if cursor >= 1, case let .comparisonOperator(value) = logic[cursor - 1], value == .lessThan || value == .greaterThan {
                            logic[cursor - 1] = .comparisonOperator(value == .lessThan ? .lessThanOrEqual : .greaterThanOrEqual)
                            handled = true
                        }
                        // Check if can combine with previous !
                        if !handled && cursor >= 1, case let .operatorSymbol(value) = logic[cursor - 1], value == .not {
                            logic[cursor - 1] = .comparisonOperator(.notEqual)
                            handled = true
                        }
                        if !handled {
                            logic.insert(.comparisonOperator(.equal), at: self.cursor)
                            cursor += 1
                        }
                    default:
                        break
                    }
                case ",", "?", ":":
                    logic.insert(.punctuation(.init(rawValue: character)!), at: self.cursor)
                    cursor += 1
                case "\"":
                    // Start a new string literal
                    logic.insert(.literal(DerivedLiteral(characters: "", type: .string)), at: self.cursor)
                    literalCursor = 0
                    clearLiteralCursor = false
                case "t", "f", "T", "F":
                    // Only letters allowed outside a literal are t and f for true and false booleans
                    logic.insert(.literal(DerivedLiteral(characters: "\(character.lowercased() == "t")", type: .boolean)), at: self.cursor)
                    cursor += 1
                case let char where char.isNumber, let char where char == ".":
                    var handled = false
                    if cursor > 0, case .literal(let literal) = logic[cursor - 1], literal.type == .numeric {
                        // Combine with preceding literal
                        let combined = literal.characters + character
                        if let _ = Float(combined) {
                            logic[cursor-1] = .literal(DerivedLiteral(characters: combined, type: .numeric))
                        }
                        handled = true
                    }
                    if !handled, cursor < logic.count - 1 ,case .literal(let literal) = logic[cursor], literal.type == .numeric {
                        // Combine with subsequent literal
                        let combined = character + literal.characters
                        if Float(combined) != nil {
                            logic[cursor] = .literal(DerivedLiteral(characters: combined, type: .numeric))
                        }
                        handled = true
                    }
                    if !handled {
                        // Create new literal
                        let combined = character
                        if let _ = Float(combined) {
                            logic.insert(.literal(DerivedLiteral(characters: combined, type: .numeric)), at: self.cursor)
                            cursor += 1
                        }
                    }
                    clearLiteralCursor = handled
                default:
                    clearLiteralCursor = false
                }
            }
        }
        if clearLiteralCursor {
            literalCursor = nil
        }
    }
}
