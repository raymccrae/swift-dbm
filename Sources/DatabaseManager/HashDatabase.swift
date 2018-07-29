//
//  HashDatabase.swift
//  DatabaseManager
//
//  Created by Raymond Mccrae on 20/07/2018.
//  Copyright © 2018 Raymond Mccrae. All rights reserved.
//

import Foundation
import dbm

public class HashDatabase<KeyConverter: DataConverting, ValueConverter: DataConverting>: Database<KeyConverter, ValueConverter> {

    public typealias Key = KeyConverter.ValueType
    public typealias Value = ValueConverter.ValueType

//    public enum HashAlgorithm {
//        case `default`
//        case rawData((Data) -> UInt32)
//        case valueHash((Key) -> UInt32)
//    }

    public struct Info {
        var bucketSize: UInt32 = 256
        var ffactor: UInt32 = 8
        var numberOfElements: UInt32 = 1
        var cacheSize: UInt32 = 0
        var hashBlock: (@convention(c) (UnsafeRawPointer?, Int) -> UInt32)? = nil
        var lorder: Int32 = 0

        func hashinfo() -> UnsafeMutablePointer<HASHINFO> {
            let ptr = UnsafeMutablePointer<HASHINFO>.allocate(capacity: 1)
            ptr.pointee.bsize = bucketSize
            ptr.pointee.ffactor = ffactor
            ptr.pointee.nelem = numberOfElements
            ptr.pointee.hash = hashBlock
            ptr.pointee.lorder = lorder
            return ptr
        }
    }

    public init(keyConverter: KeyConverter,
                valueConverter: ValueConverter,
                path: String,
                mode: Int32 = 0o664,
                info: Info? = nil) throws {
        let hashinfo: UnsafeMutablePointer<HASHINFO>?
        if let info = info {
            hashinfo = info.hashinfo()
        } else {
            hashinfo = nil
        }

        try super.init(keyConverter: keyConverter,
                       valueConverter: valueConverter,
                       path: path,
                       type: .hash,
                       mode: mode,
                       info:hashinfo)
        if let ptr = hashinfo {
            ptr.deallocate()
        }
    }

    public func synchronize() throws {
        try synchronize(flags: 0)
    }

    public func get(key: Key) throws -> Value? {
        return try get(key: key, flags: 0)
    }

    @discardableResult
    public func put(key: Key,
                    value: Value,
                    noOverwrite: Bool = false) throws -> Bool {
        return try put(key: key,
                       value: value,
                       flags: noOverwrite ? UInt32(R_NOOVERWRITE) : 0)
    }

    public func delete(key: Key) throws -> Bool {
        return try delete(key: key, flags: 0)
    }

}
