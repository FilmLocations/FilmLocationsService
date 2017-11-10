//
//  serviceTests.swift
//  filmlocationsservicePackageDescription
//
//  Created by Jessica Thrasher on 10/17/17.
//

import Foundation
import Kitura
import SwiftyJSON
import XCTest
@testable import filmlocationsservice

class serviceTests: XCTestCase {
    
    
    func testHello() {
        XCTAssertEqual("Hello", "Hello")
    }
    
    static var allTests : [(String, (serviceTests) -> ()
        throws -> Void)] {
        return [
            ("testHello", testHello),
        ] }
}
