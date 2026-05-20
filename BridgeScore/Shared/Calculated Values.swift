//
//  Calculated Values.swift
//  BridgeScore
//
//  Created by Marc Shearer on 04/05/2026.
//

import SwiftUI

enum CalculatedType: Int, Codable, CaseIterable {
    case numeric = 0
    case boolean = 1
    case string = 2
    
    var string: String {
        "\(self)".capitalized
    }
    
    var isNumeric: Bool {
        self == .numeric
    }
    
    var isString: Bool {
        self == .string
    }
    
    var isBoolean: Bool {
        self == .boolean
    }
}
                        
enum CalculatedElement : Equatable, Codable, Hashable {
    case bracket(CalculatedBracket)
    case literal(CalculatedLiteral)
    case variable(InsightColumn)
    case calculatedVariable(CalculatedColumn)
    case operatorSymbol(CalculatedOperator)
    case logicalOperator(CalculatedLogicalOperator)
    case comparisonOperator(CalculatedComparisonOperator)
    case function(CalculatedFunction)
    case punctuation(CalculatedPunctuation)
    case endOfCalculation
    
    
    var string : String {
        switch self {
        case .bracket(let bracket):
            bracket.string
        case .punctuation(let comma):
            comma.string
        case .literal(let literal):
            literal.string
        case .variable(let variable):
            variable.name
        case .calculatedVariable(let variable):
            variable.name
        case .operatorSymbol(let binaryOperator):
            binaryOperator.string
        case .logicalOperator(let logicalOperator):
            logicalOperator.string
        case .comparisonOperator(let comparisonOperator):
            comparisonOperator.string
        case .function(let function):
            function.string
        case .endOfCalculation:
            "End of calculation"
        }
    }
    
    static func == (lhs: CalculatedElement, rhs: CalculatedElement) -> Bool {
        switch lhs {
        case .bracket(let lhsValue):
            if case .bracket(let rhsValue) = rhs {
                return lhsValue == rhsValue
            } else {
                return false
            }
        case .literal(let lhsValue):
            if case .literal(let rhsValue) = rhs {
                return lhsValue == rhsValue
            } else {
                return false
            }
        case .variable(let lhsValue):
            if case .variable(let rhsValue) = rhs {
                return lhsValue == rhsValue
            } else {
                return false
            }
        case .calculatedVariable(let lhsValue):
            if case .calculatedVariable(let rhsValue) = rhs {
                return lhsValue == rhsValue
            } else {
                return false
            }
        case .operatorSymbol(let lhsValue):
            if case .operatorSymbol(let rhsValue) = rhs {
                return lhsValue == rhsValue
            } else {
                return false
            }
        case .logicalOperator(let lhsValue):
            if case .logicalOperator(let rhsValue) = rhs {
                return lhsValue == rhsValue
            } else {
                return false
            }
        case .comparisonOperator(let lhsValue):
            if case .comparisonOperator(let rhsValue) = rhs {
                return lhsValue == rhsValue
            } else {
                return false
            }
        case .function(let lhsValue):
            if case .function(let rhsValue) = rhs {
                return lhsValue == rhsValue
            } else {
                return false
            }
        case .punctuation(let lhsValue):
            if case .punctuation(let rhsValue) = rhs {
                return lhsValue == rhsValue
            } else {
                return false
            }
        case .endOfCalculation:
            if case .endOfCalculation = rhs {
                return true
            } else {
                return false
            }
        }
    }
    
}

struct CalculatedLiteral : Hashable, Codable {
    var characters: String
    var type: CalculatedType
    
    var string: String {
        switch type {
        case .numeric:
            characters
        case .string:
            "\"\(characters)\""
        case .boolean:
            characters
        }
    }
    
    var literalCursorLow: Int {
        switch type {
        case .string:
            0
        default:
            1
        }
    }
    
    var literalCursorOffset: Int {
        switch type {
        case .string:
            1
        default:
            0
        }
    }
    
    var literalCursorHigh: Int {
        switch type {
        case .string:
            characters.count
        default:
            characters.count - 1
        }
    }
    
    var isString: Bool {
        type == .string
    }
    
    var isNumeric: Bool {
        type == .numeric
    }
    
    var isBoolean: Bool {
        type == .boolean
    }
}

enum CalculatedPunctuation : String, Codable {
    case comma = ","
    case colon = ":"
    case query = "?"
    
    var string: String { self.rawValue }
}

enum CalculatedBracket : String, Codable {
    case open = "("
    case close = ")"
    
    var string: String { self.rawValue }
}

enum CalculatedOperator : String, Codable {
    case plus = "+"
    case minus = "-"
    case multiply = "*"
    case divide = "/"
    case not = "!"
    
    var string: String { self.rawValue }
}

enum CalculatedComparisonOperator : String, Codable {
    case equal = "="
    case notEqual = "!="
    case lessThan = "<"
    case greaterThan = ">"
    case lessThanOrEqual = "<="
    case greaterThanOrEqual = ">="
    
    var string: String { self.rawValue }
}

enum CalculatedLogicalOperator : String, Codable {
    case and = "&"
    case or = "|"
    
    var string: String { self.rawValue }
}

enum CalculatedFunction : String, CaseIterable, Codable {
    case min = "min"
    case max = "max"
    case average = "average"
    case sum = "sum"
    case abs = "abs"
    case mod = "mod"
    case lowercased = "lowercased"
    case uppercased = "uppercased"
    case capitalized = "capitalized"
    case match = "match"
    
    var string: String { self.rawValue }
    
    var argumentLimits: (min: Int?, max: Int?) {
        switch self {
        case .min, .max, .average, .sum:
            return (min: 2, max: nil)
        case .abs:
            return (min: 1, max: 1)
        case .mod, .match:
            return (min: 2, max: 2)
        case .lowercased, .uppercased, .capitalized:
            return (min: 1, max: 1)
        }
    }
    
    var argumentType: CalculatedType {
        switch self {
        case .lowercased, .uppercased, .capitalized, .match:
                .string
        default:
                .numeric
        }
    }

    var type: CalculatedType {
        switch self {
        case .lowercased, .uppercased, .capitalized:
                .string
        case .match:
                .boolean
        default:
                .numeric
        }
    }
}

class CalculatedValue : Codable, Equatable, Hashable {
    var numeric: Float?
    var string: String?
    var boolean: Bool?
    var type: CalculatedType
    
    init(numeric: Float, string: String, boolean: Bool, type: CalculatedType) {
        self.numeric = numeric
        self.string = string
        self.boolean = boolean
        self.type = type
    }
    
    init(_ numeric: Float) {
        self.numeric = numeric
        self.type = .numeric
    }
    
    init(_ integer: Int) {
        self.numeric = Float(integer)
        self.type = .numeric
    }
    
    init(_ string: String) {
        self.string = string
        self.type = .string
    }
    
    init(_ boolean: Bool) {
        self.boolean = boolean
        self.type = .boolean
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        switch type {
        case .string:
            hasher.combine(string)
        case .numeric:
            hasher.combine(numeric)
        case .boolean:
            hasher.combine(boolean)
        }
    }
    
    var text: String { (isNumeric ? "\(numeric!)" : (isString ? string! : "\(boolean!)"))}
    
    var textBinding: Binding<String> {
        Binding(
            get: { self.text },
            set: { newValue in
                switch self.type {
                case .numeric:
                    self.numeric = Float(newValue) ?? 0
                case .boolean:
                    self.boolean = (newValue.lowercased() == "true")
                case .string:
                    self.string = newValue
                }
            })}
    
    var isNumeric: Bool { type == .numeric}
    
    var isString: Bool { type == .string}
    
    var isBoolean: Bool { type == .boolean}
    
    static func == (lhs: CalculatedValue, rhs:CalculatedValue)  -> Bool {
        var result = true
        do {
            result = try isEqual(lhs: lhs,rhs: rhs).boolean!
        } catch {
            result = false
        }
        return result
    }
    
    static func + (lhs: CalculatedValue, rhs:CalculatedValue) throws -> CalculatedValue {
        if rhs.type != lhs.type {
            throw CalculatedError.typeMismatchOperator(.plus, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return CalculatedValue(lhs.numeric! + rhs.numeric!)
        case .string:
            return CalculatedValue(lhs.string! + rhs.string!)
        default:
            throw CalculatedError.invalidOperationForType(.plus, lhs.type)
        }
    }
    
    static func - (lhs: CalculatedValue, rhs:CalculatedValue) throws -> CalculatedValue {
        if rhs.type != lhs.type {
            throw CalculatedError.typeMismatchOperator(.minus, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return CalculatedValue(lhs.numeric! - rhs.numeric!)
        default:
            throw CalculatedError.invalidOperationForType(.minus, lhs.type)
        }
    }
    
    static func * (lhs: CalculatedValue, rhs:CalculatedValue) throws -> CalculatedValue {
        if rhs.type != lhs.type {
            throw CalculatedError.typeMismatchOperator(.multiply, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return CalculatedValue(lhs.numeric! * rhs.numeric!)
        default:
            throw CalculatedError.invalidOperationForType(.multiply, lhs.type)
        }
    }
    
    static func / (lhs: CalculatedValue, rhs:CalculatedValue) throws -> CalculatedValue {
        if rhs.type != lhs.type {
            throw CalculatedError.typeMismatchOperator(.divide, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            if rhs.numeric == 0 {
                throw CalculatedError.divideByZero
            }
            return CalculatedValue(lhs.numeric! / rhs.numeric!)
        default:
            throw CalculatedError.invalidOperationForType(.divide, lhs.type)
        }
    }
    
    static func isEqual(lhs: CalculatedValue, rhs:CalculatedValue) throws -> CalculatedValue {
        if rhs.type != lhs.type {
            throw CalculatedError.typeMismatchComparison(.equal, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return CalculatedValue(lhs.numeric! == rhs.numeric!)
        case .string:
            return CalculatedValue(lhs.string! == rhs.string!)
        case .boolean:
            return CalculatedValue(lhs.boolean! == rhs.boolean!)
        }
    }
    
    static func == (lhs: CalculatedValue, rhs:CalculatedValue) throws -> CalculatedValue {
        try isEqual(lhs: lhs, rhs: rhs)
    }
    
    static func != (lhs: CalculatedValue, rhs:CalculatedValue) throws -> CalculatedValue {
        if rhs.type != lhs.type {
            throw CalculatedError.typeMismatchComparison(.notEqual, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return CalculatedValue(lhs.numeric! != rhs.numeric!)
        case .string:
            return CalculatedValue(lhs.string! != rhs.string!)
        case .boolean:
            return CalculatedValue(lhs.boolean! != rhs.boolean!)
        }
    }
    
    static func < (lhs: CalculatedValue, rhs:CalculatedValue) throws -> CalculatedValue {
        if rhs.type != lhs.type {
            throw CalculatedError.typeMismatchComparison(.lessThan, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return CalculatedValue(lhs.numeric! < rhs.numeric!)
        case .string:
            return CalculatedValue(lhs.string! < rhs.string!)
        case .boolean:
            return CalculatedValue(lhs.boolean! == false && rhs.boolean! == true)
        }
    }
    
    static func > (lhs: CalculatedValue, rhs:CalculatedValue) throws -> CalculatedValue {
        if rhs.type != lhs.type {
            throw CalculatedError.typeMismatchComparison(.greaterThan, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return CalculatedValue(lhs.numeric! > rhs.numeric!)
        case .string:
            return CalculatedValue(lhs.string! > rhs.string!)
        case .boolean:
            return CalculatedValue(lhs.boolean! == true && rhs.boolean! == false)
        }
    }
    
    static func <= (lhs: CalculatedValue, rhs:CalculatedValue) throws -> CalculatedValue {
        if rhs.type != lhs.type {
            throw CalculatedError.typeMismatchComparison(.lessThanOrEqual, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return CalculatedValue(lhs.numeric! <= rhs.numeric!)
        case .string:
            return CalculatedValue(lhs.string! <= rhs.string!)
        case .boolean:
            return CalculatedValue(lhs.boolean! == false && rhs.boolean! == true || lhs.boolean! == rhs.boolean!)
        }
    }
    
    static func >= (lhs: CalculatedValue, rhs:CalculatedValue) throws -> CalculatedValue {
        if rhs.type != lhs.type {
            throw CalculatedError.typeMismatchComparison(.greaterThanOrEqual, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return CalculatedValue(lhs.numeric! >= rhs.numeric!)
        case .string:
            return CalculatedValue(lhs.string! >= rhs.string!)
        case .boolean:
            return CalculatedValue(lhs.boolean! == true && rhs.boolean! == false || lhs.boolean! == rhs.boolean!)
        }
    }
    
    static func && (lhs: CalculatedValue, rhs:CalculatedValue) throws -> CalculatedValue {
        if lhs.type != .boolean || rhs.type != .boolean {
            throw CalculatedError.typeMismatchLogical(.and, .boolean, .boolean)
        }
        return CalculatedValue(lhs.boolean! && rhs.boolean!)
    }
    
    static func || (lhs: CalculatedValue, rhs:CalculatedValue) throws -> CalculatedValue {
        if lhs.type != .boolean || rhs.type != .boolean {
            throw CalculatedError.typeMismatchLogical(.or, .boolean, .boolean)
        }
        return CalculatedValue(lhs.boolean! || rhs.boolean!)
    }
    
    static prefix func - (value: CalculatedValue) throws -> CalculatedValue {
        if value.type != .numeric {
            throw CalculatedError.invalidOperationForType(.minus, value.type)
        }
        return CalculatedValue(-value.numeric!)
    }
    
    static prefix func ! (value: CalculatedValue) throws -> CalculatedValue {
        if value.type != .numeric {
            throw CalculatedError.invalidOperationForType(.not, value.type)
        }
        return CalculatedValue(!value.boolean!)
    }
}

indirect enum CalculatedParseNode : Equatable {
    case numeric(value: Float)
    case string(value: String)
    case boolean(value: Bool)
    case variable(variable: InsightColumn)
    case binaryOp(lhs: CalculatedParseNode, op: CalculatedOperator, rhs: CalculatedParseNode)
    case unaryOp(op: CalculatedOperator, value: CalculatedParseNode)
    case logicalOp(lhs: CalculatedParseNode, op: CalculatedLogicalOperator, rhs: CalculatedParseNode)
    case comparisonOp(lhs: CalculatedParseNode, op: CalculatedComparisonOperator, rhs: CalculatedParseNode)
    case ternaryOp(condition: CalculatedParseNode, ifTrue: CalculatedParseNode, ifFalse: CalculatedParseNode)
    case function(function: CalculatedFunction, arguments: [CalculatedParseNode])
    
    public var string: String {
        switch self {
        case .numeric(let value):
            "\(value)"
        case .string(let value):
            "\"\(value)\""
        case .boolean(let value):
            "\(value ? "true" : "false")"
        case .variable(variable: let variable):
            "\(variable.name)"
        case .binaryOp(lhs: let lhs, op: let op, rhs: let rhs):
            "(\(lhs.string) \(op.string) \(rhs.string))"
        case .unaryOp(op: let op, value: let node):
            "\(op.string)\(node.string)"
        case .logicalOp(lhs: let lhs, op: let op, rhs: let rhs):
            "(\(lhs.string) \(op.string) \(rhs.string))"
        case .comparisonOp(lhs: let lhs, op: let op, rhs: let rhs):
            "(\(lhs.string) \(op.string) \(rhs.string))"
        case .ternaryOp(condition: let condition, ifTrue: let ifTrue, ifFalse: let ifFalse):
            "(\(condition.string) ? \(ifTrue.string) : \(ifFalse.string))"
        case .function(function: let function, arguments: let arguments):
            "\(function.string)(\(arguments.map(\.string).joined(separator: ", ")))"
        }
    }
    
    func type(variableType: (InsightColumn) throws ->CalculatedType?) throws -> CalculatedType {
        switch self {
        case .numeric:
            return .numeric
        case .string:
            return .string
        case .boolean:
            return .boolean
        case .variable(let variable):
            if let type = try variableType(variable) {
                return type
            } else {
                throw CalculatedError.invalidVariableName(variable.name)
            }
        case .binaryOp(let lhs, let op, let rhs):
            let lhsType = try lhs.type(variableType: variableType)
            let rhsType = try rhs.type(variableType: variableType)
            switch op {
            case .plus:
                if lhsType != rhsType {
                    throw CalculatedError.typeMismatchOperator(op, lhsType, rhsType)
                } else if lhsType.isBoolean {
                    throw CalculatedError.invalidOperationForType(op, lhsType)
                } else {
                    return lhsType
                }
            case .minus, .divide, .multiply:
                if lhsType != rhsType {
                    throw CalculatedError.typeMismatchOperator(op, lhsType, rhsType)
                } else if !lhsType.isNumeric {
                    throw CalculatedError.invalidOperationForType(op, lhsType)
                } else {
                    return lhsType
                }
            default:
                throw CalculatedError.invalidToken(op.string)
            }
        case .unaryOp(let op, let value):
            let valueType = try value.type(variableType: variableType)
            switch op {
            case .minus:
                if valueType.isNumeric {
                    return valueType
                } else {
                    throw CalculatedError.invalidOperationForType(op, valueType)
                }
            case .not:
                if valueType.isBoolean {
                    return valueType
                } else {
                    throw CalculatedError.invalidOperationForType(op, valueType)
                }
            default:
                throw CalculatedError.invalidToken(op.string)
            }
        case .logicalOp(let lhs, let op, let rhs):
            let lhsType = try lhs.type(variableType: variableType)
            let rhsType = try rhs.type(variableType: variableType)
            if lhsType != rhsType {
                throw CalculatedError.typeMismatchLogical(op, lhsType, rhsType)
            } else if !lhsType.isBoolean {
                throw CalculatedError.invalidLogicalOperationForType(op, lhsType)
            } else {
                return .boolean
            }
        case .comparisonOp(let lhs, let op, let rhs):
            let lhsType = try lhs.type(variableType: variableType)
            let rhsType = try rhs.type(variableType: variableType)
            if lhsType != rhsType {
                throw CalculatedError.typeMismatchComparison(op, lhsType, rhsType)
            } else if (op != .equal && op != .notEqual) && lhsType.isBoolean {
                throw CalculatedError.invalidComparisonOperationForType(op, lhsType)
            } else {
                return .boolean
            }
        case .ternaryOp(let condition, let ifTrue, let ifFalse):
            let conditionType = try condition.type(variableType: variableType)
            let ifTrueType = try ifTrue.type(variableType: variableType)
            let ifFalseType = try ifFalse.type(variableType: variableType)
            if conditionType != .boolean {
                throw CalculatedError.typeMismatchTernaryCondition(conditionType)
            } else if ifTrueType != ifFalseType {
                throw CalculatedError.typeMismatchTernaryValues(ifTrueType, ifFalseType)
            } else {
                return ifTrueType
            }
        case .function(let function, let arguments):
            for argument in arguments {
                let argumentType = try argument.type(variableType: variableType)
                if argumentType != function.argumentType {
                    throw CalculatedError.invalidArgumentTypes(function, argumentType)
                }
            }
            return function.type
        }
    }
    
    public func traverse(_ action: (InsightColumn) throws -> ()) throws {
        switch self {
        case .variable(let variable):
            try action(variable)
        case .binaryOp(let lhs, _, let rhs):
            try lhs.traverse(action)
            try rhs.traverse(action)
        case .unaryOp( _, let value):
            try value.traverse(action)
        case .logicalOp(let lhs, _, let rhs):
            try lhs.traverse(action)
            try rhs.traverse(action)
        case .comparisonOp(let lhs, _, let rhs):
            try lhs.traverse(action)
            try rhs.traverse(action)
        case .ternaryOp(let condition, let ifTrue, let ifFalse):
            try condition.traverse(action)
            try ifTrue.traverse(action)
            try ifFalse.traverse(action)
        case .function(_, let arguments):
            for argument in arguments {
                try argument.traverse(action)
            }
        default:
            break
        }
    }
    
    public func value<ViewModel>(viewModel: ViewModel, variableValue: (InsightColumn, ViewModel) throws ->CalculatedValue?) throws -> CalculatedValue {
        switch self {
        case .numeric(let value):
            return CalculatedValue(value)
        case .string(let value):
            return CalculatedValue(value)
        case .boolean(let value):
            return CalculatedValue(value)
        case .variable(let variable):
            if let value = try variableValue(variable, viewModel) {
                return value
            } else {
                throw CalculatedError.invalidVariableName(variable.name)
            }
        case .binaryOp(lhs: let lhs, op: let op, rhs: let rhs):
            let lhsValue = try lhs.value(viewModel: viewModel, variableValue: variableValue)
            let rhsValue = try rhs.value(viewModel: viewModel, variableValue: variableValue)
            switch op {
            case .plus: return try lhsValue + rhsValue
            case .minus: return try lhsValue - rhsValue
            case .divide: return try lhsValue / rhsValue
            case .multiply: return try lhsValue * rhsValue
            default: throw CalculatedError.invalidToken(op.string)
            }
        case .unaryOp(op: let op, value: let value):
            let value = try value.value(viewModel: viewModel, variableValue: variableValue)
            switch op {
            case .minus: return try CalculatedValue(-1) * value
            case .not:
                if value.isBoolean {
                    if value.boolean! == false {
                        return CalculatedValue(true)
                    } else {
                        return CalculatedValue(false)
                    }
                } else {
                    throw CalculatedError.invalidOperationForType(.not, value.type)
                }
            default: throw CalculatedError.invalidToken(op.string)
            }
        case .logicalOp(lhs: let lhs, op: let op, rhs: let rhs):
            let lhsValue = try lhs.value(viewModel: viewModel, variableValue: variableValue)
            if lhsValue.isBoolean {
                switch op {
                case .and:
                    if !lhsValue.boolean! {
                        return CalculatedValue(false)
                    } else {
                        let rhsValue = try rhs.value(viewModel: viewModel, variableValue: variableValue)
                        if rhsValue.isBoolean {
                            return CalculatedValue(rhsValue.boolean!)
                        } else {
                            throw CalculatedError.typeMismatchLogical(.and, lhsValue.type, rhsValue.type)
                        }
                    }
                case .or:
                    if lhsValue.boolean! {
                        return CalculatedValue(true)
                    } else {
                        let rhsValue = try rhs.value(viewModel: viewModel, variableValue: variableValue)
                        if rhsValue.isBoolean {
                            return CalculatedValue(rhsValue.boolean!)
                        } else {
                            throw CalculatedError.typeMismatchLogical(.or, lhsValue.type, rhsValue.type)
                        }
                    }
                }
            } else {
                throw CalculatedError.invalidLogicalOperationForType(.and, lhsValue.type)
            }
        case .comparisonOp(lhs: let lhs, op: let op, rhs: let rhs):
            let lhsValue = try lhs.value(viewModel: viewModel, variableValue: variableValue)
            let rhsValue = try rhs.value(viewModel: viewModel, variableValue: variableValue)
            switch op {
            case .equal: return try lhsValue == rhsValue
            case .notEqual: return try lhsValue != rhsValue
            case .lessThan: return try lhsValue < rhsValue
            case .greaterThan: return try lhsValue > rhsValue
            case .lessThanOrEqual: return try lhsValue <= rhsValue
            case .greaterThanOrEqual: return try lhsValue >= rhsValue
            }
        case .ternaryOp(condition: let condition, ifTrue: let ifTrue, ifFalse: let ifFalse):
            let conditionValue = try condition.value(viewModel: viewModel, variableValue: variableValue)
            if conditionValue.isBoolean {
                if conditionValue.boolean! {
                    return try ifTrue.value(viewModel: viewModel, variableValue: variableValue)
                } else {
                    return try ifFalse.value(viewModel: viewModel, variableValue: variableValue)
                }
            } else {
                throw CalculatedError.typeMismatchTernaryCondition(conditionValue.type)
            }
        case .function(function: let function, arguments: let arguments):
            let (minArgs, maxArgs) = function.argumentLimits
            let values = try arguments.map({try $0.value(viewModel: viewModel, variableValue: variableValue)})
            if values.count < minArgs ?? 0 || values.count > maxArgs ?? Int.max {
                throw CalculatedError.invalidArgumentTypes(function, nil)
            }
            let invalidArgTypes = values.contains(where: {!(function.argumentType == $0.type)})
            if invalidArgTypes {
                throw CalculatedError.invalidArgumentTypes(function, nil)
            }
            switch function {
            case .min:
                return CalculatedValue(values.map{$0.numeric!}.min()!)
            case .max:
                return CalculatedValue(values.map{$0.numeric!}.max()!)
            case .sum:
                return CalculatedValue(values.map{$0.numeric!}.reduce(0, +))
            case .average:
                return CalculatedValue(values.map{$0.numeric!}.reduce(0, +) / Float(values.count))
            case .abs:
                return CalculatedValue(values[0].numeric!.magnitude)
            case .mod:
                return CalculatedValue(Float(Int(values[0].numeric!) % Int(values[1].numeric!)))
            case .lowercased:
                return CalculatedValue(values[0].string!.lowercased())
            case .uppercased:
                return CalculatedValue(values[0].string!.uppercased())
            case .capitalized:
                return CalculatedValue(values[0].string!.capitalized)
            case .match:
                return CalculatedValue((values[0].string! == "") || (values[0].string!.lowercased() == values[1].string!.lowercased()))
            }
        }
    }
}

enum CalculatedError: Error {
    case unexpectedToken(found: CalculatedElement, expected: CalculatedElement)
    case invalidNumberOfArgumentsToFunction(CalculatedFunction, Int)
    case errorEvaluatingCalculatedColumn(String)
    case invalidToken(String)
    case circularReference(String)
    case typeMismatchOperator(CalculatedOperator, CalculatedType, CalculatedType)
    case typeMismatchLogical(CalculatedLogicalOperator, CalculatedType, CalculatedType)
    case typeMismatchComparison(CalculatedComparisonOperator,CalculatedType, CalculatedType)
    case typeMismatchTernaryCondition(CalculatedType)
    case typeMismatchTernaryValues(CalculatedType, CalculatedType)
    case invalidOperationForType(CalculatedOperator, CalculatedType)
    case invalidLogicalOperationForType(CalculatedLogicalOperator, CalculatedType)
    case invalidComparisonOperationForType(CalculatedComparisonOperator, CalculatedType)
    case invalidArgumentTypes(CalculatedFunction, CalculatedType?)
    case invalidVariableName(String)
    case divideByZero
    case errorEvaluatingSelection(String)
    
    var errorDescription: String {
        switch self {
        case .unexpectedToken(found: let found, expected: let expected):
            return "Unexpected token: \(found), expected: \(expected)"
        case .invalidNumberOfArgumentsToFunction(let function, let count):
            let (lower, upper) = function.argumentLimits
            return "Invalid number of arguments to function \(function.string): \(count) found were \(lower ?? 0)\(upper == nil ? "" : " - \(upper!)") required"
        case .errorEvaluatingCalculatedColumn(let string):
            return "Error evaluating calculated column: \(string)"
        case .invalidToken(let token):
            return "Invalid token: \(token)"
        case .circularReference(let name):
            return "Circular reference to calculated column: '\(name)'"
        case .invalidVariableName(let name):
            return "Invalid variable name \(name)"
        case .divideByZero:
            return "Division by zero"
        case .typeMismatchOperator(let op, let type1, let type2):
            return "Type mismatch for \(op.string): types \(type1.string) and \(type2.string)"
        case .typeMismatchLogical(let op, let type1, let type2):
            return "Type mismatch for \(op.string): types \(type1.string) and \(type2.string)"
        case .typeMismatchComparison(let op, let type1, let type2):
            return "Type mismatch for \(op.string): types \(type1.string) and \(type2.string)"
        case .typeMismatchTernaryCondition(let type):
            return "Type mismatch for ternary condition: \(type.string) found where Boolean expected"
        case .typeMismatchTernaryValues(let type1, let type2):
            return "Type mismatch for ternary values: types \(type1.string) and \(type2.string) are not equal"
        case .invalidOperationForType(let op, let type):
            return "Invalid argment type for operator '\(op.string)': \(type.string)"
        case .invalidLogicalOperationForType(let op, let type):
            return "Type mismatch for operator \(op.string): \(type.string) found where Boolean expected"
        case .invalidComparisonOperationForType(let op, let type):
            return "Type mismatch for operator \(op.string): \(type.string) found where other expected"
        case .invalidArgumentTypes(let function, let type):
            return "Type mismatch for argument of \(function.string)(): \(type?.string ?? "Other type")) found where \(function.argumentType.string) expected"
        case .errorEvaluatingSelection(let level):
            return "Error evaluating selection at \(level)"
        }
    }
}

class CalculatedParser {
    
    let tokens: [CalculatedElement] // Simplified for example
    var index = 0
    let report: Report
    
    init(report: Report, tokens: [CalculatedElement]) {
        self.report = report
        self.tokens = tokens
    }
    
    var current: CalculatedElement {
        index < tokens.count ? tokens[index] : .endOfCalculation
    }
    
    @discardableResult func nextSymbol() -> CalculatedElement {
        let token = current
        index += 1
        return token
    }
    
    func must(_ expected: CalculatedElement) throws {
        if current == expected {
            nextSymbol()
        } else {
            throw CalculatedError.unexpectedToken(found: current, expected: expected)
        }
    }
    
    func have(_ expected: CalculatedElement) -> Bool {
        return current == expected
    }
    
    func parse(completion: (CalculatedParseNode?, String?) -> ()) {
        if have(.endOfCalculation) {
            completion(nil, "Unexpected '\(CalculatedElement.endOfCalculation.string)'")
        } else {
            do {
                let root = try parseTernary()
                if !have(.endOfCalculation) {
                    completion(nil, "'\(current.string)' found where '\(CalculatedElement.endOfCalculation.string)' expected")
                } else {
                    completion(root, nil)
                }
            } catch CalculatedError.unexpectedToken(let found, let expected) {
                let message = "'\(found.string)' found where '\(expected.string)' expected"
                completion(nil, message)
            } catch {
                completion(nil, "Unexpected error (\(error))")
            }
        }
    }
    
    func parseTernary() throws -> CalculatedParseNode {
        let condition = try parseLogicalOr()
        if have(.punctuation(.query)) {
            nextSymbol()
            let ifTrue = try parseTernary()
            try must(.punctuation(.colon))
            let ifFalse = try parseTernary()
            return .ternaryOp(condition: condition, ifTrue: ifTrue, ifFalse: ifFalse)
        }
        return condition
    }
    
    func parseLogicalOr() throws -> CalculatedParseNode {
        var left = try parseLogicalAnd()
        while current == .logicalOperator(.or) {
            try must(.logicalOperator(.or))
            let right = try parseLogicalAnd()
            left = .logicalOp(lhs: left, op: .or, rhs: right)
        }
        return left
    }
    
    func parseLogicalAnd() throws -> CalculatedParseNode {
        var left = try parseComparison()
        while current == .logicalOperator(.and) {
            try must(.logicalOperator(.and))
            let right = try parseComparison()
            left = .logicalOp(lhs: left, op: .and, rhs: right)
        }
        return left
    }
    
    func parseComparison() throws -> CalculatedParseNode {
        var left = try parseExpression1()
        while case .comparisonOperator(let op) = current {
            try must(.comparisonOperator(op))
            let right = try parseExpression1()
            left = .comparisonOp(lhs: left, op: op, rhs: right)
        }
        return left
    }
    
    func parseExpression1() throws -> CalculatedParseNode {
        var left = try parseExpression2()
        
        while current == .operatorSymbol(.plus) || current == .operatorSymbol(.minus) {
            if case .operatorSymbol(let op) = nextSymbol() {
                let right = try parseExpression2()
                left = .binaryOp(lhs: left, op: op, rhs: right)
            }
        }
        return left
    }
    
    func parseExpression2() throws -> CalculatedParseNode {
        var left = try parseExpression3()
        
        while current == .operatorSymbol(.multiply) || current == .operatorSymbol(.divide) {
            if case .operatorSymbol(let op) = nextSymbol() {
                let right = try parseExpression3()
                left = .binaryOp(lhs: left, op: op, rhs: right)
            }
        }
        return left
    }
    
    func parseExpression3() throws -> CalculatedParseNode {
        if current == .operatorSymbol(.minus) || current == .operatorSymbol(.plus) {
            // Unary minus or plus
            if case .operatorSymbol(let op) = nextSymbol() {
                let expression = try parseExpression3()
                return .unaryOp(op: op, value: expression)
            }
        } else if case .variable(let variable) = current {
            // Variable
            nextSymbol()
            // Important - This variable may be a stale copy from the logic of the parent - need to get the latest
            var variable = variable
            if variable.isCalculated {
                if let calculated = report.values.calculatedColumns.first(where: {$0.name == variable.name}) {
                    variable = calculated
                } else {
                    throw CalculatedError.invalidVariableName(variable.name)
                }
            }
            
            return .variable(variable: variable)
        } else if case .literal(let literal) = current {
            // Literal
            nextSymbol()
            switch literal.type {
            case .numeric:
                return .numeric(value: Float(literal.characters)!)
            case .string:
                return .string(value: literal.characters)
            case .boolean:
                return .boolean(value: literal.characters == "true")
            }
        } else if case .function(let function) = current {
            var args: [CalculatedParseNode] = []
            let (minArgs, maxArgs) = function.argumentLimits
            try must(.function(function))
            try must(.bracket(.open))
            while !have(.bracket(.close)) {
                if !args.isEmpty {
                    try must(.punctuation(.comma))
                }
                let arg = try parseTernary()
                args.append(arg)
            }
            if let minArgs = minArgs, args.count < minArgs {
                // Error - at least n arguments required but only m (<n) found
                throw CalculatedError.invalidNumberOfArgumentsToFunction(function, args.count)
            } else if let maxArgs = maxArgs, args.count > maxArgs {
                // Error - at most n arguments allowed, but m (>n) found
                throw CalculatedError.invalidNumberOfArgumentsToFunction(function, args.count)
            }
            let expression = CalculatedParseNode.function(function: function, arguments: args)
            try must(.bracket(.close))
            return expression
        } else if current == .bracket(.open) {
            try must(.bracket(.open))
            let expression = try parseTernary()
            try must(.bracket(.close))
            return expression
        }
        throw CalculatedError.unexpectedToken(found: current, expected: .endOfCalculation)
    }
}
