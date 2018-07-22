//
//  DatabaseError.swift
//  DatabaseManager
//
//  Created by Raymond Mccrae on 20/07/2018.
//  Copyright © 2018 Raymond Mccrae. All rights reserved.
//

import Foundation

struct DatabaseError: Error {
    let errno: Int32
}
