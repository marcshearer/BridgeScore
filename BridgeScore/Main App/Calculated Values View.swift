//
//  Calculated Values View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 04/05/2026.
//

import SwiftUI

struct CalculatedValuesView<Focus:InsightsFocusIndexBridge> : View {
    @Binding var logic: [CalculatedElement]
    @Binding var cursor: Int
    var fieldType: Focus
    var nextFocusValue: Focus? = nil
    var previousFocusValue: Focus? = nil
    @Binding var focus: Focus?
    var height: CGFloat = 50
    var rowHeight: CGFloat = 32
    var color: ThemeBackgroundColorName
    var clearTextButton: Bool = true
    var onChange: (()->())?
    
    @State private var triggerId: UUID = UUID()
    @State private var literalCursor: Int? = nil
    
    var body: some View {
        ZStack {
            Rectangle().frame(height: height)
                .foregroundColor(PaletteColor(color).background)
                .cornerRadius(8)
            VStack {
                Spacer().frame(height: 5)
                HStack {
                    Spacer().frame(width: 4)
                    KeyDetectorView(processKey: processKey, fieldType: fieldType, nextFocusValue: nextFocusValue, previousFocusValue: previousFocusValue, focus: $focus)
                        .id(triggerId)
                    Spacer()
                    ScrollViewReader { proxy in
                        //GeometryReader { viewGeometry in
                            ScrollView(.vertical) {
                                FlowLayout(alignment: .leading, spacing: 0) {
                                    ForEach(0..<logic.count + 1, id: \.self) { index in
                                        HStack(alignment: .center, spacing: 0) {
                                            // Preceding cursor
                                            HStack(spacing: 0) {
                                                if index == cursor && literalCursor == nil && focus == fieldType {
                                                    HStack(spacing: 0) {
                                                        Spacer()
                                                        cursorBar
                                                        Spacer()
                                                    }
                                                    .frame(width: 10)
                                                } else {
                                                    HStack(spacing: 0) {
                                                        Text("").frame(width: 8)
                                                    }
                                                }
                                            }
                                            .frame(height: rowHeight)
                                            if index <= logic.count - 1 {
                                                let string = logic[index].string
                                                if case let .literal(literal) = logic[index] {
                                                    // Text with literal cursor - separate output of each character
                                                    ForEach(0..<string.count, id: \.self) { characterIndex in
                                                        let cIndex = string.index(string.startIndex, offsetBy: characterIndex)
                                                        let character = string[cIndex]
                                                        if let literalCursor = literalCursor {
                                                            if (characterIndex == (literalCursor + literal.literalCursorOffset)) && (cursor == index) {
                                                                HStack(spacing: 0) {
                                                                    Spacer()
                                                                    cursorBar
                                                                    Spacer()
                                                                }
                                                                .frame(width: 2, height: rowHeight)
                                                            }
                                                        }
                                                        Text(String(character))
                                                            .onTapGesture {
                                                                focus = fieldType
                                                                cursor = index
                                                                literalCursor = characterIndex
                                                            }
                                                            .frame(height: rowHeight)
                                                    }
                                                } else {
                                                    // Non-literal
                                                    Text(string)
                                                        .frame(height: rowHeight)
                                                }
                                            }
                                        }
                                        .id(index)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            focus = fieldType
                                            cursor = index
                                            literalCursor = nil
                                        }
                                    }
                                    Spacer()
                                }
                                Spacer().frame(width: 4)
                            }
                            .scrollIndicators(.automatic)
                            .onChange(of: cursor) {
                                withAnimation {
                                    proxy.scrollTo(cursor, anchor: nil)
                                }
                                
                            }
                            .frame(height: height - 10)
                            //.contentMargins(.bottom, 10, for: .scrollContent)
                        //}
                    }
                    if clearTextButton && !logic.isEmpty {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 12)
                            HStack {
                                Button {
                                    logic = []
                                    triggerId = UUID()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Palette.clearText)
                                }
                                Spacer().frame(width: 5)
                            }
                            Spacer()
                        }
                        .frame(height: height)
                    }
                    Spacer().frame(width: 4)
                }
            }
            .onTapGesture {
                focus = fieldType
                cursor = logic.count
                literalCursor = nil
            }
            .dropDestination(for: InsightsSetupTransfer.self) { (droppedValues, _) in
                return handleDrop(droppedValues, cursor)
            }
            .onAppear {
                cursor = logic.count
            }
        }
    }
    
    var cursorBar : some View {
        Rectangle().frame(width: 2, height: 30)
            .foregroundColor(.blue)
            .phaseAnimator([true, false]) { content, phase in
                content.opacity(phase || focus != fieldType ? 1 : 0)
            } animation: { _ in
                    .easeInOut(duration: 0.5)
            }
    }
    
    func handleDrop(_ droppedValues: [InsightsSetupTransfer], _ before: Int) {
        var lastIsFunction = false
        for value in droppedValues {
            if value.source.isColumns {
                logic.insert(.variable(value.column!), at: cursor)
                cursor += 1
                lastIsFunction = false
                onChange?()
            } else if value.source == .functions {
                logic.insert(contentsOf: [.function(value.function!), .bracket(.open), .bracket(.close)], at: cursor)
                cursor += 3
                lastIsFunction = true
                onChange?()
            }
        }
        if lastIsFunction {
            cursor -= 1
        }
    }
    
    func processKey(key: KeyEquivalent? = nil, character: String? = nil) {
        var clearLiteralCursor: Bool = true
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            var handled = false
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
                                        logic[cursor] = .literal(CalculatedLiteral(characters: String(string), type: literal.type))
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
                                        literal = CalculatedLiteral(characters: String(string), type: literal.type)
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
                    onChange?()
                case .deleteForward:
                    // Delete key
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
                                        logic[cursor] = .literal(CalculatedLiteral(characters: String(string), type: literal.type))
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
                                    logic[cursor] = .literal(CalculatedLiteral(characters: String(string), type: literal.type))
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
                    onChange?()
                case .home:
                    cursor = 0
                case .end:
                    cursor = logic.count
                default:
                    clearLiteralCursor = false
                }
            } else if let character = character {
                if literalCursor != nil, cursor < logic.count, case let .literal(literal) = logic[cursor] {
                    if literal.type == .string {
                        if character == "\"" {
                            // Ending string
                            var string = ""
                            if literalCursor != 0 {
                                // Truncate it at the literal cursor
                                string = String(literal.characters.prefix(literalCursor!))
                            }
                            logic[cursor] = .literal(CalculatedLiteral(characters: string, type: .string))
                            cursor += 1
                            handled = true
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
                            logic[cursor] = .literal(CalculatedLiteral(characters: combined, type: .string))
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
                            logic[cursor] = .literal(CalculatedLiteral(characters: combined, type: .numeric))
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
                        handled = true
                    case "(", ")":
                        logic.insert(.bracket(.init(rawValue: character)!), at: self.cursor)
                        cursor += 1
                        handled = true
                    case "&", "|":
                        logic.insert(.logicalOperator(.init(rawValue: character)!), at: self.cursor)
                        cursor += 1
                        handled = true
                    case "!":
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
                        handled = true
                    case "<", ">", "=":
                        switch character {
                        case "<", ">":
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
                            handled = true
                        case "=":
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
                            handled = true
                        default:
                            break
                        }
                    case ",", "?", ":":
                        logic.insert(.punctuation(.init(rawValue: character)!), at: self.cursor)
                        cursor += 1
                        handled = true
                    case "\"":
                        // Start a new string literal
                        logic.insert(.literal(CalculatedLiteral(characters: "", type: .string)), at: self.cursor)
                        literalCursor = 0
                        clearLiteralCursor = false
                        handled = true
                    case "t", "f", "T", "F":
                        // Only letters allowed outside a literal are t and f for true and false booleans
                        logic.insert(.literal(CalculatedLiteral(characters: "\(character.lowercased() == "t")", type: .boolean)), at: self.cursor)
                        cursor += 1
                        handled = true
                    case let char where char.isNumber, let char where char == ".":
                        if cursor > 0, case .literal(let literal) = logic[cursor - 1], literal.type == .numeric {
                            // Combine with preceding literal
                            let combined = literal.characters + character
                            if let _ = Float(combined) {
                                logic[cursor-1] = .literal(CalculatedLiteral(characters: combined, type: .numeric))
                            }
                            handled = true
                        }
                        if !handled, cursor < logic.count - 1 ,case .literal(let literal) = logic[cursor], literal.type == .numeric {
                            // Combine with subsequent literal
                            let combined = character + literal.characters
                            if Float(combined) != nil {
                                logic[cursor] = .literal(CalculatedLiteral(characters: combined, type: .numeric))
                            }
                            handled = true
                        }
                        if !handled {
                            // Create new literal
                            let combined = character
                            if let _ = Float(combined) {
                                logic.insert(.literal(CalculatedLiteral(characters: combined, type: .numeric)), at: self.cursor)
                                cursor += 1
                                handled = true
                            }
                        }
                        clearLiteralCursor = handled
                    default:
                        clearLiteralCursor = false
                    }
                }
                if handled {
                    onChange?()
                }
            }
            if clearLiteralCursor {
                literalCursor = nil
            }
        }
    }
}

struct FlowLayout: Layout {
    var alignment: Alignment = .leading
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return CGSize(width: proposal.width ?? result.size.width, height: result.size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        var lineIndex = 0
        var x = bounds.minX
        var y = bounds.minY

        for (index, subview) in subviews.enumerated() {
            if lineIndex < result.lineStarts.count, index == result.lineStarts[lineIndex] {
                if lineIndex > 0 {
                    y += result.lineHeights[lineIndex - 1] + spacing
                }
                x = bounds.minX
                lineIndex += 1
            }
            
            let size = subview.sizeThatFits(.unspecified)
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, lineStarts: [Int], lineHeights: [CGFloat]) {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxLineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        var lineStarts: [Int] = [0]
        var lineHeights: [CGFloat] = []
        
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                lineHeights.append(maxLineHeight)
                currentY += maxLineHeight + spacing
                totalWidth = max(totalWidth, currentX - spacing)
                
                currentX = 0
                maxLineHeight = 0
                lineStarts.append(index)
            }
            
            currentX += size.width + spacing
            maxLineHeight = max(maxLineHeight, size.height)
        }
        
        lineHeights.append(maxLineHeight)
        totalWidth = max(totalWidth, currentX - spacing)
        let totalHeight = currentY + maxLineHeight
        
        return (CGSize(width: totalWidth, height: totalHeight), lineStarts, lineHeights)
    }
}
