//
//  BTreeDatabaseTests.swift
//  DatabaseManagerTests
//
//  Created by Raymond Mccrae on 29/07/2018.
//  Copyright © 2018 Raymond Mccrae. All rights reserved.
//

import XCTest
import DatabaseManager

class BTreeDatabaseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func testExample() {
        do {
            let keyConverter = StringDataConverter()
            let valueConverter = StringDataConverter()
            let dbpath = "\(DatabaseManagerTests.docpath)/btree.db"
            let btree = try BTreeDatabase(keyConverter: keyConverter,
                                          valueConverter: valueConverter,
                                          path: dbpath)

            try btree.put(key: "test", value: "hello")
            let fetched = try btree.get(key: "test")
            XCTAssertEqual(fetched, "hello")
            for i in 1...1_000_000 {
                try btree.put(key: "\(i)", value: "test")
            }
            XCTAssertEqual(fetched, "hello")
        } catch {
            XCTFail("Error: \(error)")
        }
    }
    
}
