//
//  HashDatabase.swift
//  DatabaseManager
//
//  Created by Raymond Mccrae on 20/07/2018.
//  Copyright © 2018 Raymond Mccrae. All rights reserved.
//

import Foundation
import dbm

public class HashDatabase<KeyConverter: DataConverting, ValueConverter: DataConverting>: Database<KeyConverter.ValueType, ValueConverter.ValueType, KeyConverter, ValueConverter> {

    public typealias Key = KeyConverter.ValueType
    public typealias Value = ValueConverter.ValueType

    public init(keyConverter: KeyConverter,
                valueConverter: ValueConverter,
                path: String,
                mode: Int32 = 644) throws {
        try super.init(keyConverter: keyConverter,
                       valueConverter: valueConverter,
                       path: path,
                       type: .hash,
                       mode: mode)
    }

    public func synchronize() throws {
        try synchronize(flags: 0)
    }

    public func get(key: Key) throws -> Value? {
        return try get(key: key, flags: 0)
    }

    @discardableResult
    public func put(key: Key, value: Value, noOverwrite: Bool = false) throws -> Bool {
        return try put(key: key, value: value, flags: noOverwrite ? UInt32(R_NOOVERWRITE) : 0)
    }

}
