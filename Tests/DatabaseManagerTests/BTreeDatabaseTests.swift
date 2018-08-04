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
            let keyConverter = IntDataConverter()
            let valueConverter = StringDataConverter()
            let dbpath = "\(DatabaseManagerTests.docpath)/btree.db"
            let btree = try BTreeDatabase(keyConverter: keyConverter,
                                          valueConverter: valueConverter,
                                          path: dbpath)

            try btree.put(key: 1_000_000, value: "hello")
            let fetched = try btree.get(key: 1_000_000)
            XCTAssertEqual(fetched, "hello")
            for i in 1...10 {
                try btree.put(key: i, value: "test")
            }
            XCTAssertEqual(fetched, "hello")

//            try btree.enumerateValues { (key, value, _) in
//                print("\(key): \(value)")
//            }

            try btree.enumerate(5) { (key, value, _) in
                print("\(key): \(value)")
            }
        } catch {
            XCTFail("Error: \(error)")
        }
    }
    
}
