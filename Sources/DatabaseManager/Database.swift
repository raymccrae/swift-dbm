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

    func sequence(key: inout Data, flag: UInt32) throws -> Data? {
        var dbt = DBT(data: nil, size: 0)
        let result = key.withUnsafeMutableDBTPointer { (keyPtr) -> Int32 in
            withUnsafeMutablePointer(to: &dbt) { (valuePtr: UnsafeMutablePointer<DBT>) -> Int32 in
                db.pointee.seq(db, keyPtr, valuePtr, flag)
            }
        }

        guard result == 0 else {
            if result < 0 {
                throw DatabaseError(errno: errno)
            }
            return nil
        }
        return Data(bytesNoCopy: dbt.data, count: dbt.size, deallocator: .none)
    }

    func sequence(key: inout Key, flag: UInt32) throws -> Value? {
        var keyData = try keyConverter.convert(from: key)
        guard let valueData = try sequence(key: &keyData, flag: flag) else {
            return nil
        }
        key = try keyConverter.unconvert(from: keyData)
        return try valueConverter.unconvert(from: valueData)
    }

}
