//
//  DataConverting.swift
//  DatabaseManager
//
//  Created by Raymond Mccrae on 20/07/2018.
//  Copyright © 2018 Raymond Mccrae. All rights reserved.
//

import Foundation

public protocol DataConverting {

    associatedtype ValueType

    func convert(from value: ValueType) -> Data

    func unconvert(from data: Data) throws -> ValueType

}

public enum DataConvertingError: Error {
    case invalidEncoding
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
