//
//  Data+DBM.swift
//  DBM
//
//  Created by Raymond Mccrae on 19/07/2018.
//  Copyright © 2018 Raymond Mccrae. All rights reserved.
//

import Foundation
import dbm

extension Data {

    init?(dbt: UnsafePointer<DBT>?) {
        guard let dbt = dbt, let ptr = dbt.pointee.data else {
            return nil
        }
        self.init(bytesNoCopy: ptr, count: dbt.pointee.size, deallocator: .none)
    }

    func withUnsafeDBTPointer<ResultType>(_ body: (UnsafePointer<DBT>) throws -> ResultType) rethrows  -> ResultType {
        let size = count
        return try withUnsafeBytes { (bytesPtr: UnsafePointer<Int8>) -> ResultType in
            let opaquePtr = OpaquePointer(bytesPtr)
            var dbt = DBT(data: UnsafeMutableRawPointer(opaquePtr), size: size)
            return try withUnsafePointer(to: &dbt, body)
        }
    }

    func withUnsafeMutableDBTPointer<ResultType>(_ body: (UnsafeMutablePointer<DBT>) throws -> ResultType) rethrows -> ResultType {
        let size = count
        return try withUnsafeBytes { (bytesPtr: UnsafePointer<Int8>) -> ResultType in
            let opaquePtr = OpaquePointer(bytesPtr)
            var dbt = DBT(data: UnsafeMutableRawPointer(opaquePtr), size: size)
            return try withUnsafeMutablePointer(to: &dbt, body)
        }
    }

}
