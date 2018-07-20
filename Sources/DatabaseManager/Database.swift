//
//  Database.swift
//  DBM
//
//  Created by Raymond Mccrae on 19/07/2018.
//  Copyright © 2018 Raymond Mccrae. All rights reserved.
//

import Foundation
import dbm

public class Database {

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

    private let db: UnsafeMutablePointer<DB>

    init?(path: String, type: FileType) {
        let ptr = path.withCString { (pathPtr) in
            return dbopen(pathPtr, 0, 0, type.dbtype, nil)
        }
        guard let p = ptr else {
            return nil
        }
        self.db = p
    }

    deinit {
        _ = db.pointee.close(db)
    }

    private func synchronize(flags: UInt32) -> Int32 {
        return db.pointee.sync(db, flags)
    }

    private func delete(key: Data, flags: UInt32) -> Int32 {
        return key.withUnsafeDBTPointer({ (keyPtr) -> Int32 in
            db.pointee.del(db, keyPtr, flags)
        })
    }

    private func get(key: Data, flags: UInt32) -> Data? {
        var dbt = DBT(data: nil, size: 0)
        let result = withUnsafeMutablePointer(to: &dbt) { (valuePtr) -> Int32 in
            key.withUnsafeDBTPointer({ (keyPtr) -> Int32 in
                db.pointee.get(db, keyPtr, valuePtr, flags)
            })
        }

        guard result == 0 else {
            return nil
        }
        return Data(bytesNoCopy: dbt.data, count: dbt.size, deallocator: .none)
    }

    private func put(key: Data, value: Data, flags: UInt32) -> Int32 {
        return key.withUnsafeMutableDBTPointer { (keyPtr) in
            value.withUnsafeDBTPointer({ (valuePtr) in
                db.pointee.put(db, keyPtr, valuePtr, flags)
            })
        }
    }

}
