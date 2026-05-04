//
//  Derived Values.swift
//  BridgeScore
//
//  Created by Marc Shearer on 04/05/2026.
//

import Foundation

enum DerivedElement : Hashable {
    case bracket(DerivedBracket)
    case literal(String)
    case variable(String)
    case operatorSymbol(DerivedOperator)
    case function(DerivedFunction)
    case punctuation(DerivedPunctuation)
    case endOfCalculation
    
    var string : String {
        switch self {
        case .bracket(let bracket):
            bracket.string
        case .punctuation(let comma):
            comma.string
        case .literal(let value):
            value
        case .variable(let value):
            value
        case .operatorSymbol(let binaryOperator):
            binaryOperator.string
        case .function(let function):
            function.string
        case .endOfCalculation:
            "End"
        }
    }
}

enum DerivedPunctuation : String {
    case comma = ","
    
    var string: String { self.rawValue }
}

enum DerivedBracket : String {
    case open = "("
    case close = ")"
    
    var string: String { self.rawValue }
}

enum DerivedOperator : String {
    case plus = "+"
    case minus = "-"
    case multiply = "*"
    case divide = "/"
    
    var string: String { self.rawValue }
}

enum DerivedFunction : String {
    case min = "min"
    case max = "max"
    case average = "average"
    case sum = "sum"
    
    var string: String { self.rawValue }
    
    var arguments: (min: Int?, max: Int?) {
        switch self {
        case .min, .max, .average, .sum:
            return (2, nil)
        }
    }
}

indirect enum DerivedNode {
    case number(value: Float)
    case variable(name: String)
    case binaryOp(lhs: DerivedNode, op: DerivedOperator, rhs: DerivedNode)
    case unaryOp(op: DerivedOperator, node: DerivedNode)
    case function(name: String, arguments: [DerivedNode])
}

enum DerivedParseError: Error {
    case unexpectedToken(found: DerivedElement, expected: DerivedElement)
}

class DerivedParser {
    
    let tokens: [DerivedElement] // Simplified for example
    var index = 0

    init(tokens: [DerivedElement]) {
        self.tokens = tokens
    }

    var current: DerivedElement {
        index < tokens.count ? tokens[index] : .endOfCalculation
    }
        
    @discardableResult func nextSymbol() -> DerivedElement {
        let token = current
        index += 1
        return token
    }
    
    func must(_ expected: DerivedElement) throws {
        if current == expected {
            nextSymbol()
        } else {
            throw DerivedParseError.unexpectedToken(found: current, expected: expected)
        }
    }
    
    func have(_ expected: DerivedElement) -> Bool {
        return current == expected
    }
    
    func parse(completion: (DerivedNode?, String?)->()) {
        do {
            let root = try parseExpression()
            completion(root, nil)
        } catch DerivedParseError.unexpectedToken(let found, let expected) {
            let message = "'\(found)' found where '\(expected)' expected"
            completion(nil, message)
        } catch {
            completion(nil, "Unexpected error (\(error))")
        }
    }
    
    func parseExpression() throws -> DerivedNode {
        var left = try parseExpression2()

        while current == .operatorSymbol(.plus) || current == .operatorSymbol(.minus) {
            if case .operatorSymbol(let op) = nextSymbol() {
                let right = try parseExpression2()
                left = .binaryOp(lhs: left, op: op, rhs: right)
            }
        }
        return left
    }

    func parseExpression2() throws -> DerivedNode {
        var left = try parseExpression3()

        while current == .operatorSymbol(.multiply) || current == .operatorSymbol(.divide) {
            if case .operatorSymbol(let op) = nextSymbol() {
                let right = try parseExpression3()
                left = .binaryOp(lhs: left, op: op, rhs: right)
            }
        }
        return left
    }

    func parseExpression3() throws -> DerivedNode {
        if case .literal(let value) = current {
            // Literal number
            nextSymbol()
            return .number(value: Float(value)!)
        } else if current == .operatorSymbol(.minus) {
            // Unary minus
            try must(.operatorSymbol(.minus))
            let expression = try parseExpression()
            return .unaryOp(op: .minus, node: expression)
        } else if case .function(let function) = current {
            var args: [DerivedNode] = []
            let (minArgs, maxArgs) = function.arguments
            try must(.function(function))
            try must(.bracket(.open))
            while !have(.bracket(.close)) {
                if !args.isEmpty {
                    try must(.punctuation(.comma))
                }
                let arg = try parseExpression()
                args.append(arg)
            }
            if let minArgs = minArgs, args.count < minArgs {
                // Error - at least n arguments required but only m (<n) found
            } else if let maxArgs = maxArgs, args.count > maxArgs {
                // Error - at most n arguments allowed, but m (>n) found
            }
            let expression = DerivedNode.function(name: function.string, arguments: args)
            try must(.bracket(.close))
            return expression
        } else if current == .bracket(.open) {
            try must(.bracket(.open))
            let expression = try parseExpression()
            try must(.bracket(.close))
            return expression
        }
        throw DerivedParseError.unexpectedToken(found: current, expected: .endOfCalculation)
    }
}
