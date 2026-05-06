//
//  Derived Values.swift
//  BridgeScore
//
//  Created by Marc Shearer on 04/05/2026.
//

import Foundation

protocol DerivedVariable : Hashable, Equatable {
    var name: String {get}
    func value<ViewModel: NSObject>(viewModel: ViewModel) -> DerivedValue
    var type: DerivedType {get}
    var decimalPlaces: Int {get}
    // static func == (lhs: Self, rhs: Self) -> Bool
}

extension DerivedVariable where Self: Equatable {
    func isEqualTo(_ other: any DerivedVariable) -> Bool {
        if let otherVariable = other as? Self {
            return self == otherVariable
        } else {
            return false
        }
    }
}

enum DerivedType {
    case numeric
    case boolean
    case string
    
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
                        
enum DerivedElement : Equatable {
    case bracket(DerivedBracket)
    case literal(DerivedLiteral)
    case variable(any DerivedVariable)
    case operatorSymbol(DerivedOperator)
    case logicalOperator(DerivedLogicalOperator)
    case comparisonOperator(DerivedComparisonOperator)
    case function(DerivedFunction)
    case punctuation(DerivedPunctuation)
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
    
    static func == (lhs: DerivedElement, rhs: DerivedElement) -> Bool {
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
                return lhsValue.isEqualTo(rhsValue)
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

struct DerivedLiteral : Hashable {
    var characters: String
    var type: DerivedType
    
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

enum DerivedPunctuation : String {
    case comma = ","
    case colon = ":"
    case query = "?"
    
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
    case not = "!"
    
    var string: String { self.rawValue }
}

enum DerivedComparisonOperator : String {
    case equal = "="
    case notEqual = "!="
    case lessThan = "<"
    case greaterThan = ">"
    case lessThanOrEqual = "<="
    case greaterThanOrEqual = ">="
    
    var string: String { self.rawValue }
}

enum DerivedLogicalOperator : String {
    case and = "&"
    case or = "|"
    
    var string: String { self.rawValue }
}

enum DerivedFunction : String {
    case min = "min"
    case max = "max"
    case average = "average"
    case sum = "sum"
    case abs = "abs"
    case mod = "mod"
    
    var string: String { self.rawValue }
    
    var argumentLimits: (min: Int?, max: Int?) {
        switch self {
        case .min, .max, .average, .sum:
            return (min: 2, max: nil)
        case .abs:
            return (min: 1, max: 1)
        case .mod:
            return (min: 2, max: 2)
        }
    }
    
    // At the moment all arguments must be numeric
    var argumentType: DerivedType { .numeric }
    
    // At the moment all results are numeric
    var type: DerivedType { .numeric }
}

struct DerivedValue {
    var numeric: Float?
    var string: String?
    var boolean: Bool?
    var type: DerivedType
    
    init(numeric: Float, string: String, boolean: Bool, type: DerivedType) {
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
    
    var text: String { (isNumeric ? "\(numeric!)" : (isString ? string! : "\(boolean!)"))}
    
    var integerText: String { (isNumeric ? "\(Int(numeric!))" : (isString ? string! : "\(boolean!)"))}
    
    var isNumeric: Bool { type == .numeric}
    
    var isString: Bool { type == .string}
    
    var isBoolean: Bool { type == .boolean}
    
    static func + (lhs: DerivedValue, rhs:DerivedValue) throws -> DerivedValue {
        if rhs.type != lhs.type {
            throw DerivedEvaluateError.typeMismatchOperator(.plus, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return DerivedValue(lhs.numeric! + rhs.numeric!)
        case .string:
            return DerivedValue(lhs.string! + rhs.string!)
        default:
            throw DerivedEvaluateError.invalidOperationForType(.plus, lhs.type)
        }
    }
    
    static func - (lhs: DerivedValue, rhs:DerivedValue) throws -> DerivedValue {
        if rhs.type != lhs.type {
            throw DerivedEvaluateError.typeMismatchOperator(.minus, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return DerivedValue(lhs.numeric! - rhs.numeric!)
        default:
            throw DerivedEvaluateError.invalidOperationForType(.minus, lhs.type)
        }
    }
    
    static func * (lhs: DerivedValue, rhs:DerivedValue) throws -> DerivedValue {
        if rhs.type != lhs.type {
            throw DerivedEvaluateError.typeMismatchOperator(.multiply, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return DerivedValue(lhs.numeric! * rhs.numeric!)
        default:
            throw DerivedEvaluateError.invalidOperationForType(.multiply, lhs.type)
        }
    }
    
    static func / (lhs: DerivedValue, rhs:DerivedValue) throws -> DerivedValue {
        if rhs.type != lhs.type {
            throw DerivedEvaluateError.typeMismatchOperator(.divide, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            if rhs.numeric == 0 {
                throw DerivedEvaluateError.divideByZero
            }
            return DerivedValue(lhs.numeric! / rhs.numeric!)
        default:
            throw DerivedEvaluateError.invalidOperationForType(.divide, lhs.type)
        }
    }
    
    static func == (lhs: DerivedValue, rhs:DerivedValue) throws -> DerivedValue {
        if rhs.type != lhs.type {
            throw DerivedEvaluateError.typeMismatchComparison(.equal, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return DerivedValue(lhs.numeric! == rhs.numeric!)
        case .string:
            return DerivedValue(lhs.string! == rhs.string!)
        case .boolean:
            return DerivedValue(lhs.boolean! == rhs.boolean!)
        }
    }
    
    static func != (lhs: DerivedValue, rhs:DerivedValue) throws -> DerivedValue {
        if rhs.type != lhs.type {
            throw DerivedEvaluateError.typeMismatchComparison(.notEqual, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return DerivedValue(lhs.numeric! != rhs.numeric!)
        case .string:
            return DerivedValue(lhs.string! != rhs.string!)
        case .boolean:
            return DerivedValue(lhs.boolean! != rhs.boolean!)
        }
    }
    
    static func < (lhs: DerivedValue, rhs:DerivedValue) throws -> DerivedValue {
        if rhs.type != lhs.type {
            throw DerivedEvaluateError.typeMismatchComparison(.lessThan, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return DerivedValue(lhs.numeric! < rhs.numeric!)
        case .string:
            return DerivedValue(lhs.string! > rhs.string!)
        case .boolean:
            throw DerivedEvaluateError.invalidComparisonOperationForType(.lessThan, lhs.type)
        }
    }
    
    static func > (lhs: DerivedValue, rhs:DerivedValue) throws -> DerivedValue {
        if rhs.type != lhs.type {
            throw DerivedEvaluateError.typeMismatchComparison(.greaterThan, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return DerivedValue(lhs.numeric! > rhs.numeric!)
        case .string:
            return DerivedValue(lhs.string! > rhs.string!)
        case .boolean:
            throw DerivedEvaluateError.invalidComparisonOperationForType(.greaterThan, lhs.type)
        }
    }
    
    static func <= (lhs: DerivedValue, rhs:DerivedValue) throws -> DerivedValue {
        if rhs.type != lhs.type {
            throw DerivedEvaluateError.typeMismatchComparison(.lessThanOrEqual, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return DerivedValue(lhs.numeric! <= rhs.numeric!)
        case .string:
            return DerivedValue(lhs.string! <= rhs.string!)
        case .boolean:
            throw DerivedEvaluateError.invalidComparisonOperationForType(.lessThanOrEqual, lhs.type)
        }
    }
    
    static func >= (lhs: DerivedValue, rhs:DerivedValue) throws -> DerivedValue {
        if rhs.type != lhs.type {
            throw DerivedEvaluateError.typeMismatchComparison(.greaterThanOrEqual, rhs.type, lhs.type)
        }
        switch lhs.type {
        case .numeric:
            return DerivedValue(lhs.numeric! >= rhs.numeric!)
        case .string:
            return DerivedValue(lhs.string! >= rhs.string!)
        case .boolean:
            throw DerivedEvaluateError.invalidComparisonOperationForType(.greaterThanOrEqual, lhs.type)
        }
    }
    
    static func && (lhs: DerivedValue, rhs:DerivedValue) throws -> DerivedValue {
        if lhs.type != .boolean || rhs.type != .boolean {
            throw DerivedEvaluateError.typeMismatchLogical(.and, .boolean, .boolean)
        }
        return DerivedValue(lhs.boolean! && rhs.boolean!)
    }
    
    static func || (lhs: DerivedValue, rhs:DerivedValue) throws -> DerivedValue {
        if lhs.type != .boolean || rhs.type != .boolean {
            throw DerivedEvaluateError.typeMismatchLogical(.or, .boolean, .boolean)
        }
        return DerivedValue(lhs.boolean! || rhs.boolean!)
    }
    
    static prefix func - (value: DerivedValue) throws -> DerivedValue {
        if value.type != .numeric {
            throw DerivedEvaluateError.invalidOperationForType(.minus, value.type)
        }
        return DerivedValue(-value.numeric!)
    }
    
    static prefix func ! (value: DerivedValue) throws -> DerivedValue {
        if value.type != .numeric {
            throw DerivedEvaluateError.invalidOperationForType(.not, value.type)
        }
        return DerivedValue(!value.boolean!)
    }
}

indirect enum DerivedNode {
    case numeric(value: Float)
    case string(value: String)
    case boolean(value: Bool)
    case variable(variable: any DerivedVariable)
    case binaryOp(lhs: DerivedNode, op: DerivedOperator, rhs: DerivedNode)
    case unaryOp(op: DerivedOperator, value: DerivedNode)
    case logicalOp(lhs: DerivedNode, op: DerivedLogicalOperator, rhs: DerivedNode)
    case comparisonOp(lhs: DerivedNode, op: DerivedComparisonOperator, rhs: DerivedNode)
    case ternaryOp(condition: DerivedNode, ifTrue: DerivedNode, ifFalse: DerivedNode)
    case function(function: DerivedFunction, arguments: [DerivedNode])
    
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
    
    func type(variableType: (any DerivedVariable)->DerivedType?) throws -> DerivedType {
        switch self {
        case .numeric:
            return .numeric
        case .string:
            return .string
        case .boolean:
            return .boolean
        case .variable(let variable):
            if let type = variableType(variable) {
                return type
            } else {
                throw DerivedTypeError.invalidVariableName(variable.name)
            }
        case .binaryOp(let lhs, let op, let rhs):
            let lhsType = try lhs.type(variableType: variableType)
            let rhsType = try rhs.type(variableType: variableType)
            switch op {
            case .plus:
                if lhsType != rhsType {
                    throw DerivedTypeError.typeMismatchOperator(op, lhsType, rhsType)
                } else if lhsType.isBoolean {
                    throw DerivedTypeError.invalidOperationForType(op, lhsType)
                } else {
                    return lhsType
                }
            case .minus, .divide, .multiply:
                if lhsType != rhsType {
                    throw DerivedTypeError.typeMismatchOperator(op, lhsType, rhsType)
                } else if !lhsType.isNumeric {
                    throw DerivedTypeError.invalidOperationForType(op, lhsType)
                } else {
                    return lhsType
                }
            default:
                throw DerivedTypeError.invalidToken(op.string)
            }
        case .unaryOp(let op, let value):
            let valueType = try value.type(variableType: variableType)
            switch op {
            case .minus:
                if valueType.isNumeric {
                    return valueType
                } else {
                    throw DerivedTypeError.invalidOperationForType(op, valueType)
                }
            case .not:
                if valueType.isBoolean {
                    return valueType
                } else {
                    throw DerivedTypeError.invalidOperationForType(op, valueType)
                }
            default:
                throw DerivedTypeError.invalidToken(op.string)
            }
        case .logicalOp(let lhs, let op, let rhs):
            let lhsType = try lhs.type(variableType: variableType)
            let rhsType = try rhs.type(variableType: variableType)
            if lhsType != rhsType {
                throw DerivedTypeError.typeMismatchLogical(op, lhsType, rhsType)
            } else if !lhsType.isBoolean {
                throw DerivedTypeError.invalidLogicalOperationForType(op, lhsType)
            } else {
                return lhsType
            }
        case .comparisonOp(let lhs, let op, let rhs):
            let lhsType = try lhs.type(variableType: variableType)
            let rhsType = try rhs.type(variableType: variableType)
            if lhsType != rhsType {
                throw DerivedTypeError.typeMismatchComparison(op, lhsType, rhsType)
            } else if (op != .equal && op != .notEqual) && lhsType.isBoolean {
                throw DerivedTypeError.invalidComparisonOperationForType(op, lhsType)
            } else {
                return lhsType
            }
        case .ternaryOp(let condition, let ifTrue, let ifFalse):
            let conditionType = try condition.type(variableType: variableType)
            let ifTrueType = try ifTrue.type(variableType: variableType)
            let ifFalseType = try ifFalse.type(variableType: variableType)
            if conditionType != .boolean {
                throw DerivedTypeError.typeMismatchTernaryCondition(conditionType)
            } else if ifTrueType != ifFalseType {
                throw DerivedTypeError.typeMismatchTernaryValues(ifTrueType, ifFalseType)
            } else {
                return ifTrueType
            }
        case .function(let function, let arguments):
            for argument in arguments {
                let argumentType = try argument.type(variableType: variableType)
                if argumentType != function.argumentType {
                    throw DerivedTypeError.invalidArgumentType(function, argumentType)
                }
            }
            return function.type
        default:
            break
        }
    }
    
    public func value(variableValue: (any DerivedVariable)->DerivedValue?) throws -> DerivedValue {
        switch self {
        case .numeric(let value):
            return DerivedValue(value)
        case .string(let value):
            return DerivedValue(value)
        case .boolean(let value):
            return DerivedValue(value)
        case .variable(let variable):
            if let value = variableValue(variable) {
                return value
            } else {
                throw DerivedEvaluateError.invalidVariableName(variable.name)
            }
        case .binaryOp(lhs: let lhs, op: let op, rhs: let rhs):
            let lhsValue = try lhs.value(variableValue: variableValue)
            let rhsValue = try rhs.value(variableValue: variableValue)
            switch op {
            case .plus: return try lhsValue + rhsValue
            case .minus: return try lhsValue - rhsValue
            case .divide: return try lhsValue / rhsValue
            case .multiply: return try lhsValue * rhsValue
            default: throw DerivedEvaluateError.invalidToken(op.string)
            }
        case .unaryOp(op: let op, value: let value):
            let value = try value.value(variableValue: variableValue)
            switch op {
            case .minus: return try DerivedValue(-1) * value
            case .not:
                if value.isBoolean {
                    if value.boolean! == false {
                        return DerivedValue(true)
                    } else {
                        return DerivedValue(false)
                    }
                } else {
                    throw DerivedEvaluateError.invalidOperationForType(.not, value.type)
                }
            default: throw DerivedEvaluateError.invalidToken(op.string)
            }
        case .logicalOp(lhs: let lhs, op: let op, rhs: let rhs):
            let lhsValue = try lhs.value(variableValue: variableValue)
            if lhsValue.isBoolean {
                switch op {
                case .and:
                    if !lhsValue.boolean! {
                        return DerivedValue(false)
                    } else {
                        let rhsValue = try rhs.value(variableValue: variableValue)
                        if rhsValue.isBoolean {
                            return DerivedValue(rhsValue.boolean!)
                        } else {
                            throw DerivedEvaluateError.typeMismatchLogical(.and, lhsValue.type, rhsValue.type)
                        }
                    }
                case .or:
                    if lhsValue.boolean! {
                        return DerivedValue(true)
                    } else {
                        let rhsValue = try rhs.value(variableValue: variableValue)
                        if rhsValue.isBoolean {
                            return DerivedValue(rhsValue.boolean!)
                        } else {
                            throw DerivedEvaluateError.typeMismatchLogical(.or, lhsValue.type, rhsValue.type)
                        }
                    }
                }
            } else {
                throw DerivedEvaluateError.invalidLogicalOperationForType(.and, lhsValue.type)
            }
        case .comparisonOp(lhs: let lhs, op: let op, rhs: let rhs):
            let lhsValue = try lhs.value(variableValue: variableValue)
            let rhsValue = try rhs.value(variableValue: variableValue)
            switch op {
            case .equal: return try lhsValue == rhsValue
            case .notEqual: return try lhsValue != rhsValue
            case .lessThan: return try lhsValue < rhsValue
            case .greaterThan: return try lhsValue > rhsValue
            case .lessThanOrEqual: return try lhsValue <= rhsValue
            case .greaterThanOrEqual: return try lhsValue >= rhsValue
            }
        case .ternaryOp(condition: let condition, ifTrue: let ifTrue, ifFalse: let ifFalse):
            let conditionValue = try condition.value(variableValue: variableValue)
            if conditionValue.isBoolean {
                if conditionValue.boolean! {
                    return try ifTrue.value(variableValue: variableValue)
                } else {
                    return try ifFalse.value(variableValue: variableValue)
                }
            } else {
                throw DerivedEvaluateError.typeMismatchTernaryCondition(conditionValue.type)
            }
        case .function(function: let function, arguments: let arguments):
            let (minArgs, maxArgs) = function.argumentLimits
            let values = try arguments.map({try $0.value(variableValue: variableValue)})
            if values.count < minArgs ?? 0 || values.count > maxArgs ?? Int.max {
                throw DerivedEvaluateError.invalidArgumentTypes(function)
            }
            let invalidArgTypes = values.contains(where: {!(function.argumentType != $0.type)})
            if invalidArgTypes {
                throw DerivedEvaluateError.invalidArgumentTypes(function)
            }
            switch function {
            case .min:
                return DerivedValue(values.map{$0.numeric!}.min()!)
            case .max:
                return DerivedValue(values.map{$0.numeric!}.max()!)
            case .sum:
                return DerivedValue(values.map{$0.numeric!}.reduce(0, +))
            case .average:
                return DerivedValue(values.map{$0.numeric!}.reduce(0, +) / Float(values.count))
            case .abs:
                return DerivedValue(values[0].numeric!.magnitude)
            case .mod:
                return DerivedValue(Float(Int(values[0].numeric!) % Int(values[1].numeric!)))
            }
        }
    }
}

enum DerivedParseError: Error {
    case unexpectedToken(found: DerivedElement, expected: DerivedElement)
    case invalidNumberOfArgumentsToFunction(DerivedFunction, Int)
}

enum DerivedEvaluateError: Error {
    case invalidToken(String)
    case typeMismatchOperator(DerivedOperator,DerivedType, DerivedType)
    case typeMismatchLogical(DerivedLogicalOperator,DerivedType, DerivedType)
    case typeMismatchComparison(DerivedComparisonOperator,DerivedType, DerivedType)
    case typeMismatchTernaryCondition(DerivedType)
    case invalidOperationForType(DerivedOperator, DerivedType)
    case invalidLogicalOperationForType(DerivedLogicalOperator, DerivedType)
    case invalidComparisonOperationForType(DerivedComparisonOperator, DerivedType)
    case invalidNumberOfArgumentsToFunction(DerivedFunction, Int)
    case invalidArgumentTypes(DerivedFunction)
    case divideByZero
    case invalidVariableName(String)
}

enum DerivedTypeError: Error {
    case invalidToken(String) //
    case typeMismatchOperator(DerivedOperator,DerivedType, DerivedType)
    case typeMismatchLogical(DerivedLogicalOperator,DerivedType, DerivedType)
    case typeMismatchComparison(DerivedComparisonOperator,DerivedType, DerivedType)
    case typeMismatchTernaryCondition(DerivedType)
    case typeMismatchTernaryValues(DerivedType, DerivedType)
    case invalidOperationForType(DerivedOperator, DerivedType)
    case invalidLogicalOperationForType(DerivedLogicalOperator, DerivedType)
    case invalidComparisonOperationForType(DerivedComparisonOperator, DerivedType)
    case invalidArgumentType(DerivedFunction, DerivedType)
    case invalidVariableName(String)
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
        if have(.endOfCalculation) {
            completion(nil, "Unexpected '\(DerivedElement.endOfCalculation.string)'")
        } else {
            do {
                let root = try parseTernary()
                if !have(.endOfCalculation) {
                    completion(nil, "'\(current.string)' found where '\(DerivedElement.endOfCalculation.string)' expected")
                } else {
                    completion(root, nil)
                }
            } catch DerivedParseError.unexpectedToken(let found, let expected) {
                let message = "'\(found.string)' found where '\(expected.string)' expected"
                completion(nil, message)
            } catch {
                completion(nil, "Unexpected error (\(error))")
            }
        }
    }
    
    func parseTernary() throws -> DerivedNode {
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
    
    func parseLogicalOr() throws -> DerivedNode {
        var left = try parseLogicalAnd()
        while current == .logicalOperator(.or) {
            try must(.logicalOperator(.or))
            let right = try parseLogicalAnd()
            left = .logicalOp(lhs: left, op: .or, rhs: right)
        }
        return left
    }
    
    func parseLogicalAnd() throws -> DerivedNode {
        var left = try parseComparison()
        while current == .logicalOperator(.and) {
            try must(.logicalOperator(.and))
            let right = try parseComparison()
            left = .logicalOp(lhs: left, op: .and, rhs: right)
        }
        return left
    }
    
    func parseComparison() throws -> DerivedNode {
        var left = try parseExpression1()
        while case .comparisonOperator(let op) = current {
            try must(.comparisonOperator(op))
            let right = try parseExpression1()
            left = .comparisonOp(lhs: left, op: op, rhs: right)
        }
        return left
    }
    
    func parseExpression1() throws -> DerivedNode {
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
        if current == .operatorSymbol(.minus) || current == .operatorSymbol(.plus) {
           // Unary minus or plus
            if case .operatorSymbol(let op) = nextSymbol() {
                let expression = try parseExpression3()
                return .unaryOp(op: op, value: expression)
            }
        } else if case .variable(let variable) = current {
            // Variable
            nextSymbol()
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
            var args: [DerivedNode] = []
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
                throw DerivedParseError.invalidNumberOfArgumentsToFunction(function, args.count)
            } else if let maxArgs = maxArgs, args.count > maxArgs {
                // Error - at most n arguments allowed, but m (>n) found
                throw DerivedParseError.invalidNumberOfArgumentsToFunction(function, args.count)
            }
            let expression = DerivedNode.function(function: function, arguments: args)
            try must(.bracket(.close))
            return expression
        } else if current == .bracket(.open) {
            try must(.bracket(.open))
            let expression = try parseTernary()
            try must(.bracket(.close))
            return expression
        }
        throw DerivedParseError.unexpectedToken(found: current, expected: .endOfCalculation)
    }
}
