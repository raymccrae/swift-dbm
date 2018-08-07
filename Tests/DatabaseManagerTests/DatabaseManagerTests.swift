//
//  DatabaseManagerTests.swift
//  DatabaseManagerTests
//
//  Created by Raymond Mccrae on 20/07/2018.
//  Copyright © 2018 Raymond Mccrae. All rights reserved.
//

import XCTest
@testable import DatabaseManager

class DatabaseManagerTests: XCTestCase {

    static let docpath: String = {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDataCompare() {
        let a = Data("helo".utf8)
        let b = Data("hell".utf8)

        print(a < b)
    }
    
    func testExample() {
        do {
//            var info = HashDatabase<StringDataConverter,StringDataConverter>.Info()
//            info.hashBlock = { (buf, size) in
//                guard let buf = buf else {
//                    return 0
//                }
//                let data = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: buf),
//                                count: size,
//                                deallocator: .none)
//                return UInt32(data.hashValue)
//            }

            try FileManager.default.createDirectory(atPath: DatabaseManagerTests.docpath,
                                                withIntermediateDirectories: true,
                                                attributes: nil)

            let keyConverter = StringDataConverter()
            let valueConverter = StringDataConverter()
            let dbpath = "\(DatabaseManagerTests.docpath)/hash.db"
            print(dbpath)
            var info = HashDatabase<StringDataConverter,StringDataConverter>.Info()
            info.lorder = 0

            let database = try HashDatabase(keyConverter: keyConverter,
                                            valueConverter: valueConverter,
                                            path: dbpath,
                                            info: info)

            try database.put(key: "1", value: "hello")
            try database.synchronize()
            try database.put(key: "2", value: "goodbye")
            let result = try database.get(key: "1")
            XCTAssertEqual(result, "hello")

            try database.enumerate({ (key, value, stop) in
                print("Key: \(key)")
//                stop = true
            })

        } catch {
            XCTFail("Error: \(error)")
        }
    }
    
}
