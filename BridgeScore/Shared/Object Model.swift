//
//  Object Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 25/04/2026.
//

import CoreData

@propertyWrapper public struct IntProperty<RowType: NSManagedObject, IntType: BinaryInteger> {
    public let key: ReferenceWritableKeyPath<RowType, IntType>
    @available(*, unavailable) public var wrappedValue: Int {
        get { fatalError("This wrapper only works on instance properties of classes") }
        set { fatalError("This wrapper only works on instance properties of classes") }
    }
    
    init(_ key: ReferenceWritableKeyPath<RowType, IntType>) {
        self.key = key
    }
    
    public static subscript(
        _enclosingInstance instance: RowType,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<RowType, Int>,
        storage storageKeyPath: ReferenceWritableKeyPath<RowType, Self>
    ) -> Int {
        get {
            let propertyWrapper = instance[keyPath: storageKeyPath]
            return Int(instance[keyPath: propertyWrapper.key])
        }
        set {
            let propertyWrapper = instance[keyPath: storageKeyPath]
            instance[keyPath: propertyWrapper.key] = IntType(newValue)
        }
    }
}

@propertyWrapper public struct EnumProperty<RowType: NSManagedObject, IntType: BinaryInteger, EnumType: RawRepresentable> where EnumType.RawValue == Int {
    
    public let key: ReferenceWritableKeyPath<RowType, IntType>
    
    @available(*, unavailable) public var wrappedValue: EnumType {
        get { fatalError("This wrapper only works on instance properties of classes") }
        set { fatalError("This wrapper only works on instance properties of classes") }
    }
    
    init(_ key: ReferenceWritableKeyPath<RowType, IntType>) {
        self.key = key
    }
    
    public static subscript(
        _enclosingInstance instance: RowType,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<RowType, EnumType>,
        storage storageKeyPath: ReferenceWritableKeyPath<RowType, Self>
    ) -> EnumType {
        get {
            let propertyWrapper = instance[keyPath: storageKeyPath]
            return EnumType(rawValue: Int(instance[keyPath: propertyWrapper.key]))!
        }
        set {
            let propertyWrapper = instance[keyPath: storageKeyPath]
            instance[keyPath: propertyWrapper.key] = IntType(newValue.rawValue)
        }
    }
}
