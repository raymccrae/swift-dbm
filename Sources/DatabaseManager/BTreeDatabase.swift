//
//  BTreeDatabase.swift
//  DatabaseManager
//
//  Created by Raymond Mccrae on 28/07/2018.
//  Copyright © 2018 Raymond Mccrae. All rights reserved.
//

import Foundation
import dbm

let KeyComparatorKey = DispatchSpecificKey<AnyDataComparing>()

public class BTreeDatabase<KeyConverter: DataConverting, ValueConverter: DataConverting>: Database<KeyConverter, ValueConverter> where KeyConverter.ValueType: Comparable {

    public typealias Key = KeyConverter.ValueType
    public typealias Value = ValueConverter.ValueType

    public struct Info {

        func hashinfo() -> UnsafeMutablePointer<BTREEINFO> {
            let ptr = UnsafeMutablePointer<BTREEINFO>.allocate(capacity: 1)
//            ptr.pointee.compare = StringDataConverterCompare
            ptr.pointee.compare = { (a, b) in
                do {
                    guard let comparator = DispatchQueue.getSpecific(key: KeyComparatorKey) else {
                        assertionFailure()
                        return 0
                    }

                    guard let ptrA = a, let ptrB = b else {
                        return a == b ? 0 : a != nil ? -1 : 1
                    }

                    guard let dataA = Data.data(from: ptrA),
                        let dataB = Data.data(from: ptrB) else {
                            return 0
                    }
                    let comparison = try comparator.compare(a: dataA, b: dataB)
                    return Int32(comparison.rawValue)
                } catch {
                    fatalError()
                }
            }
            return ptr
        }
    }

    private let comparator: AnyDataComparing

    public init(keyConverter: KeyConverter,
                valueConverter: ValueConverter,
                path: String) throws {
        comparator = AnyDataComparatorBox(boxed: keyConverter)

        try super.init(keyConverter: keyConverter,
                       valueConverter: valueConverter,
                       path: path,
                       type: .btree,
                       mode: 0o664,
                       info: nil)
    }

    public func synchronize() throws {
        try queue.sync  {
            try synchronize(flags: 0)
        }
    }

    public func get(key: Key) throws -> Value? {
        return try queue.sync {
            queue.setSpecific(key: KeyComparatorKey, value: comparator)
            return try get(key: key, flags: 0)
        }
    }

    @discardableResult
    public func put(key: Key,
                    value: Value) throws -> Bool {
        return try queue.sync {
            return try put(key: key,
                           value: value,
                           flags: 0)
        }
    }

}
