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
