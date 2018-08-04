//
//  Database.swift
//  DBM
//
//  Created by Raymond Mccrae on 19/07/2018.
//  Copyright © 2018 Raymond Mccrae. All rights reserved.
//

import Foundation
import dbm

public enum FileType {
    case hash
    case btree
    case record

    fileprivate var dbtype: DBTYPE {
        switch self {
        case .hash:
            return DB_HASH
        case .btree:
            return DB_BTREE
        case .record:
            return DB_RECNO
        }
    }
}

public class Database<KeyConverter: DataConverting, ValueConverter: DataConverting> {

    typealias Key = KeyConverter.ValueType
    typealias Value = ValueConverter.ValueType

    private let db: UnsafeMutablePointer<DB>
    let keyConverter: KeyConverter
    let valueConverter: ValueConverter
    let queue: DispatchQueue

    init(keyConverter: KeyConverter,
         valueConverter: ValueConverter,
         path: String,
         type: FileType,
         mode: Int32,
         info: UnsafeRawPointer?) throws {
        self.keyConverter = keyConverter
        self.valueConverter = valueConverter
        let flags = O_CREAT | O_RDWR
        let ptr = path.withCString { (pathPtr) in
            return dbopen(pathPtr, flags, mode, type.dbtype, info)
        }
        guard let p = ptr else {
            throw DatabaseError(errno: errno)
        }
        self.db = p
        self.queue = DispatchQueue(label: "DBM - \(path)")
    }

    deinit {
        _ = db.pointee.close(db)
    }

    func synchronize(flags: UInt32) throws {
        let result = db.pointee.sync(db, flags)
        guard result == 0 else {
            throw DatabaseError(errno: errno)
        }
    }

    func delete(key: Data, flags: UInt32) throws -> Bool {
        let result = key.withUnsafeDBTPointer({ (keyPtr) -> Int32 in
            db.pointee.del(db, keyPtr, flags)
        })

        guard result >= 0 else {
            throw DatabaseError(errno: errno)
        }
        return result == 0
    }

    func delete(key: Key, flags: UInt32) throws -> Bool {
        let data = try keyConverter.convert(from: key)
        return try delete(key: data, flags: flags)
    }

    func get(key: Data, flags: UInt32) throws -> Data? {
        var dbt = DBT(data: nil, size: 0)
        let result = withUnsafeMutablePointer(to: &dbt) { (valuePtr) -> Int32 in
            key.withUnsafeDBTPointer({ (keyPtr) -> Int32 in
                db.pointee.get(db, keyPtr, valuePtr, flags)
            })
        }

        guard result == 0 else {
            if result < 0 {
                throw DatabaseError(errno: errno)
            }
            return nil
        }
        return Data(bytesNoCopy: dbt.data, count: dbt.size, deallocator: .none)
    }

    func get(key: Key, flags: UInt32) throws -> Value? {
        let keyData = try keyConverter.convert(from: key)
        guard let valueData = try get(key: keyData, flags: flags) else {
            return nil
        }
        let value = try valueConverter.unconvert(from: valueData)
        return value
    }

    /// Puts a key value pair into the database. This method directly wraps
    /// the underlying call to the dbm put method. The key and value must
    /// have been converted to a data representation before calling this method.
    ///
    /// This is an internal method for the module and is not mean to get called
    /// directly by users of the module. Sub-classes of Database should hide the
    /// raw flag values with more meaningful and type-safe means.
    ///
    /// - Parameters:
    ///   - key: The key represented as data
    ///   - value: The value represented as data
    ///   - flags: The raw flag values passed to dbm put function. Type Dependent.
    func put(key: Data, value: Data, flags: UInt32) throws -> Bool {
        let result = key.withUnsafeMutableDBTPointer { (keyPtr) in
            value.withUnsafeDBTPointer({ (valuePtr) in
                db.pointee.put(db, keyPtr, valuePtr, flags)
            })
        }

        guard result >= 0 else {
            throw DatabaseError(errno: errno)
        }
        return result == 0
    }

    func put(key: Key, value: Value, flags: UInt32) throws -> Bool {
        let keyData = try keyConverter.convert(from: key)
        let valueData = try valueConverter.convert(from: value)
        return try put(key: keyData, value: valueData, flags: flags)
    }

    func sequenceRawData(key: Data? = nil, flag: UInt32) throws -> (Data, Data)? {
        var keyDBT = DBT(data: nil, size: 0)
        var valueDBT = DBT(data: nil, size: 0)

        if let key = key {
            key.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> Void in
                keyDBT.data = UnsafeMutableRawPointer(mutating: ptr)
                keyDBT.size = key.count
            }
        }

        let result = withUnsafeMutablePointer(to: &keyDBT) { (keyDBTPtr) -> Int32 in
            withUnsafeMutablePointer(to: &valueDBT) { (valueDBTPtr) -> Int32 in
                db.pointee.seq(db, keyDBTPtr, valueDBTPtr, flag)
            }
        }

        guard result == 0 else {
            if result < 0 {
                throw DatabaseError(errno: errno)
            }
            return nil
        }

        let key = Data(dbt: keyDBT)
        let value = Data(dbt: valueDBT)
        return (key, value)
    }

    func sequence(key: Key? = nil, flag: UInt32) throws -> (Key, Value)? {
        let keyData: Data?
        if let key = key {
            keyData = try keyConverter.convert(from: key)
        } else {
            keyData = nil
        }

        let result: (Data, Data)? = try sequenceRawData(key: keyData, flag: flag)
        guard let r = result else {
            return nil
        }
        let key = try keyConverter.unconvert(from: r.0)
        let value = try valueConverter.unconvert(from: r.1)
        return (key, value)
    }

    func enumerateValues(_ closure: (Key, Value, inout Bool) throws -> Void) throws {
        var stop: Bool = false
        var flag: UInt32 = UInt32(R_FIRST)

        repeat {
            let result: (Key, Value)? = try sequence(flag: flag)
            flag = UInt32(R_NEXT)
            guard let r = result else {
                break
            }
            try closure(r.0, r.1, &stop)
        } while !stop
    }

    func reverseEnumerateValues(_ closure: (Key, Value, inout Bool) throws -> Void) throws {
        var stop: Bool = false
        var flag: UInt32 = UInt32(R_LAST)

        repeat {
            let result: (Key, Value)? = try sequence(flag: flag)
            flag = UInt32(R_PREV)
            guard let r = result else {
                break
            }
            try closure(r.0, r.1, &stop)
        } while !stop
    }

    func enumerate(_ start: Key, _ end: Key? = nil, _ closure: (Key, Value, inout Bool) throws -> Void) throws {
        var stop: Bool = false
        var flag: UInt32 = 0
        var key: Key? = start

        repeat {
            let result: (Key, Value)? = try sequence(key: key, flag: flag)
            flag = UInt32(R_NEXT)
            key = nil
            guard let r = result else {
                break
            }
            try closure(r.0, r.1, &stop)
        } while !stop
    }

}
