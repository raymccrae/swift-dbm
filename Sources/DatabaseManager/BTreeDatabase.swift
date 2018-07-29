//
//  BTreeDatabase.swift
//  DatabaseManager
//
//  Created by Raymond Mccrae on 28/07/2018.
//  Copyright © 2018 Raymond Mccrae. All rights reserved.
//

import Foundation
import dbm

let KeyConvertingKey = DispatchSpecificKey<AnyComparableDataConverting>()

public class BTreeDatabase<KeyConverter: DataConverting, ValueConverter: DataConverting>: Database<KeyConverter, ValueConverter> where KeyConverter.ValueType: Comparable {

    public typealias Key = KeyConverter.ValueType
    public typealias Value = ValueConverter.ValueType

//    enum Comparison {
//        case `default`
//        case dataComparing(DataComparing)
//    }

    public struct Info {

        func hashinfo() -> UnsafeMutablePointer<BTREEINFO> {
            let ptr = UnsafeMutablePointer<BTREEINFO>.allocate(capacity: 1)

            ptr.pointee.compare = { (a, b) in
                guard let comparator = DispatchQueue.getSpecific(key: KeyConvertingKey) else {
                    fatalError("Key comparator not set on dispatch queue specific")
                }

                guard let dataA = Data(dbt: a) else {
                    return b != nil ? 1 : 0
                }
                guard let dataB = Data(dbt: b) else {
                    return -1
                }
                let comparison = comparator.compare(a: dataA, b: dataB)
                return Int32(comparison.rawValue)
            }
            return ptr
        }
    }

    private let comparator: AnyComparableDataConverting?

    fileprivate init(keyConverter: KeyConverter,
                     valueConverter: ValueConverter,
                     path: String,
                     mode: Int32,
                     btreeinfo: UnsafeMutablePointer<BTREEINFO>?,
                     comparator: AnyComparableDataConverting?) throws {
        self.comparator = comparator
        try super.init(keyConverter: keyConverter,
                       valueConverter: valueConverter,
                       path: path,
                       type: .btree,
                       mode: mode,
                       info: btreeinfo)
    }

    public convenience init(keyConverter: KeyConverter,
                            valueConverter: ValueConverter,
                            path: String,
                            mode: Int32 = 0o664,
                            info: Info? = nil) throws {
        let btreeinfo: UnsafeMutablePointer<BTREEINFO>?
        if let info = info {
            btreeinfo = info.hashinfo()
        } else {
            btreeinfo = nil
        }

        try self.init(keyConverter: keyConverter,
                  valueConverter: valueConverter,
                  path: path,
                  mode: mode,
                  btreeinfo: btreeinfo,
                  comparator: nil)

        if let ptr = btreeinfo {
            ptr.deallocate()
        }
    }

//    public init(keyConverter: KeyConverter,
//                valueConverter: ValueConverter,
//                path: String,
//                mode: Int32 = 0o664,
//                info: Info? = nil) throws {
//        comparator = AnyComparableDataConverterBox(keyConverter)
//        self.comparator = nil
//
//        let btreeinfo: UnsafeMutablePointer<BTREEINFO>?
//        if let info = info {
//            btreeinfo = info.hashinfo()
//        } else {
//            btreeinfo = nil
//        }
//
//        try super.init(keyConverter: keyConverter,
//                       valueConverter: valueConverter,
//                       path: path,
//                       type: .btree,
//                       mode: mode,
//                       info: btreeinfo)
//
//        if let ptr = btreeinfo {
//            ptr.deallocate()
//        }
//    }

    public func synchronize() throws {
        try queue.sync {
            try synchronize(flags: 0)
        }
    }

    public func get(key: Key) throws -> Value? {
        return try queue.sync {
            queue.setSpecific(key: KeyConvertingKey, value: comparator)
            return try get(key: key, flags: 0)
        }
    }

    @discardableResult
    public func put(key: Key,
                    value: Value) throws -> Bool {
        return try queue.sync {
            queue.setSpecific(key: KeyConvertingKey, value: comparator)
            return try put(key: key,
                           value: value,
                           flags: 0)
        }
    }

}

extension BTreeDatabase where KeyConverter: ComparableDataConverting {

    public convenience init(keyConverter: KeyConverter,
                            valueConverter: ValueConverter,
                            path: String,
                            mode: Int32 = 0o664,
                            info: Info? = nil) throws {
        let btreeinfo: UnsafeMutablePointer<BTREEINFO>?
        if let info = info {
            btreeinfo = info.hashinfo()
        } else {
            btreeinfo = nil
        }

        try self.init(keyConverter: keyConverter,
                      valueConverter: valueConverter,
                      path: path,
                      mode: mode,
                      btreeinfo: btreeinfo,
                      comparator: AnyComparableDataConverterBox(keyConverter))

        if let ptr = btreeinfo {
            ptr.deallocate()
        }
    }

//    public init(keyConverter: KeyConverter,
//                valueConverter: ValueConverter,
//                path: String,
//                mode: Int32 = 0o664,
//                info: Info? = nil) throws {
//        comparator = AnyComparableDataConverterBox(keyConverter)
//        let btreeinfo: UnsafeMutablePointer<BTREEINFO>?
//        if let info = info {
//            btreeinfo = info.hashinfo()
//        } else {
//            btreeinfo = nil
//        }
//
//        try super.init(keyConverter: keyConverter,
//                       valueConverter: valueConverter,
//                       path: path,
//                       type: .btree,
//                       mode: mode,
//                       info: btreeinfo)
//
//        if let ptr = btreeinfo {
//            ptr.deallocate()
//        }
//    }
}
