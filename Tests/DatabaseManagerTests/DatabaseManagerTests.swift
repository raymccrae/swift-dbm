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
    
    func testExample() {
        do {
            try FileManager.default.createDirectory(atPath: DatabaseManagerTests.docpath,
                                                withIntermediateDirectories: true,
                                                attributes: nil)

            let keyConverter = StringDataConverter()
            let valueConverter = StringDataConverter()
            let dbpath = "\(DatabaseManagerTests.docpath)/test.db"
            print(dbpath)
            let database = try HashDatabase(keyConverter: keyConverter,
                                            valueConverter: valueConverter,
                                            path: dbpath)

            try database.put(key: "1", value: "hello", noOverwrite: false)
            let result = try database.get(key: "1")
            XCTAssertEqual(result, "hello")
        } catch {
            XCTFail("Error: \(error)")
        }
    }
    
}
