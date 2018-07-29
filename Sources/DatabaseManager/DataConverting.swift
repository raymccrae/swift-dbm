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

public enum DataConvertingError: Error {
    case invalidEncoding
}

protocol AnyDataConverting {
    func convert(from value: Any) throws -> Data
    func unconvert(from data: Data) throws -> Any
}

struct AnyDataConverterBox<T: DataConverting>: AnyDataConverting {
    let boxed: T

    init(boxed: T) {
        self.boxed = boxed
    }

    func convert(from value: Any) throws -> Data {
        return try boxed.convert(from: value as! T.ValueType)
    }

    func unconvert(from data: Data) throws -> Any {
        return try boxed.unconvert(from: data)
    }
}

protocol AnyDataComparing {
    func compare(a: Data, b: Data) throws -> ComparisonResult
}

struct AnyDataComparatorBox<T: DataConverting>: AnyDataComparing where T.ValueType: Comparable {

    let boxed: T

    init(boxed: T) {
        self.boxed = boxed
    }

    func compare(a: Data, b: Data) throws -> ComparisonResult {
        let valueA = try boxed.unconvert(from: a)
        let valueB = try boxed.unconvert(from: b)

        if valueA > valueB {
            return .orderedDescending
        } else if valueA == valueB {
            return .orderedSame
        } else {
            return .orderedAscending
        }
    }

}

public class StringDataConverter: DataConverting {

    public typealias ValueType = String

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
