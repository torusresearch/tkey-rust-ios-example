//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by David Main on 2022/08/29.
//

import XCTest
import tkey_ios

class ThresholdKey_Test: XCTestCase {

    func testLibraryVersion() {
        _ = try! library_version()
    }
}
