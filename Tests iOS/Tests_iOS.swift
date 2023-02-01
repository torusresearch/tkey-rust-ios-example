//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by David Main on 2022/08/29.
//

import XCTest
import tkey_ios
import SwiftUI
import tkey_pkg


class ThresholdKey_Test: XCTestCase {
    

    func testCreateTkeyAsyncButton() {
        
        let view = CreateTkeyAsyncButton(threshold_key: threshold_key)
        let host = UIHostingController(rootView: view)

        // Access the root view and the button from the view hierarchy
        let rootView = host.view
        let createTkeyAsyncButton = rootView.subviews.first(where: { $0 is UIButton }) as! UIButton

        // Verify that the button is not currently in a loading state
        XCTAssertFalse(view.isLoading)

        // Simulate a tap on the button
        createTkeyAsyncButton.sendActions(for: .touchUpInside)

        // Verify that the button is now in a loading state
        XCTAssertTrue(view.isLoading)

        // Wait for the asynchronous call to complete
        let expectation = self.expectation(description: "Wait for threshold_key.initializeAsync to complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        // Verify that the totalShares and threshold properties were updated correctly
        XCTAssertGreaterThan(view.totalShares, 0)
        XCTAssertGreaterThan(view.threshold, 0)

        // Verify that the alertContent property was updated correctly
        XCTAssertEqual(view.alertContent, "\(view.totalShares) shares created")

        // Verify that the button is no longer in a loading state
        XCTAssertFalse(view.isLoading)

        // Verify that the showAlert property is now true
        XCTAssertTrue(view.showAlert)
    }
}
