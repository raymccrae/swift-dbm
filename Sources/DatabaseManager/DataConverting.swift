//
//  DataConverting.swift
//  DatabaseManager
//
//  Created by Raymond Mccrae on 20/07/2018.
//  Copyright © 2018 Raymond Mccrae. All rights reserved.
//

import Foundation
import dbm

public protocol DataConverting {

    associatedtype ValueType

    func convert(from value: ValueType) throws -> Data

    func unconvert(from data: Data) throws -> ValueType

}

public protocol ComparableDataConverting: DataConverting {

    func compare(a: Data, b: Data) -> ComparisonResult

}

public protocol DataComparing {
    func compare(a: Data, b: Data) -> ComparisonResult
}

public enum DataConvertingError: Error {
    case invalidEncoding
}

protocol AnyComparableDataConverting {
    func convert(from value: Any) throws -> Data
    func unconvert(from data: Data) throws -> Any
    func compare(a: Data, b: Data) -> ComparisonResult
}

struct AnyComparableDataConverterBox<T: ComparableDataConverting>: AnyComparableDataConverting {
    let boxed: T

    init(_ boxed: T) {
        self.boxed = boxed
    }

    func convert(from value: Any) throws -> Data {
        return try boxed.convert(from: value as! T.ValueType)
    }

    func unconvert(from data: Data) throws -> Any {
        return try boxed.unconvert(from: data)
    }

    func compare(a: Data, b: Data) -> ComparisonResult {
        return boxed.compare(a: a, b: b)
    }
}

public class StringDataConverter: DataConverting {

    public typealias ValueType = String

    public init() {
    }

    public func convert(from value: ValueType) -> Data {
        return Data(value.utf8)
    }

    public func unconvert(from data: Data) throws -> ValueType {
        guard let value = String(data: data, encoding: .utf8) else {
            throw DataConvertingError.invalidEncoding
        }
        return value
    }

}

public class IntDataConverter: ComparableDataConverting {

    public typealias ValueType = Int

    private let sizeOfInt: Int

    public init() {
        let value: Int = 0
        sizeOfInt = MemoryLayout.size(ofValue: value)
    }

    public func compare(a: Data, b: Data) -> ComparisonResult {
        let intA = (try? unconvert(from: a)) ?? 0
        let intB = (try? unconvert(from: b)) ?? 0

        if (intA < intB) {
            return .orderedAscending
        } else if intA == intB {
            return .orderedSame
        } else {
            return .orderedDescending
        }
    }

    public func convert(from value: Int) -> Data {
        var i = value
        let data = withUnsafePointer(to: &i) { (intPtr) -> Data in
            Data(bytes: intPtr, count: sizeOfInt)
        }
        return data
    }

    public func unconvert(from data: Data) throws -> Int {
        guard data.count == sizeOfInt else {
            throw DatabaseError(errno: 0)
        }

        let value = data.withUnsafeBytes { (intPtr: UnsafePointer<Int>) -> Int in
            intPtr.pointee
        }

        return value
    }

}

public class CaseInsensitiveUTF8DataConverter: ComparableDataConverting {

    public typealias ValueType = String

    public init() {
    }

    public func compare(a: Data, b: Data) -> ComparisonResult {
        let strA = (try? unconvert(from: a)) ?? ""
        let strB = (try? unconvert(from: b)) ?? ""

        return strA.caseInsensitiveCompare(strB)
    }

    public func convert(from value: ValueType) -> Data {
        return Data(value.utf8)
    }

    public func unconvert(from data: Data) throws -> ValueType {
        guard let value = String(data: data, encoding: .utf8) else {
            throw DataConvertingError.invalidEncoding
        }
        return value
    }
}
