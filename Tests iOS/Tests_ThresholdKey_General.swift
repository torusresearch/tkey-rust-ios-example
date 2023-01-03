//
//  ThresholdKey_General.swift
//  Tests iOS
//
//  Created by CW Lee on 14/12/2022.
//

import XCTest

final class ThresholdKey_General: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testGenerateDeleteShare() throws {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let curve_n = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
        let key1 = try! PrivateKey.generate(curve_n: curve_n)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex, curve_n: curve_n)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false, curve_n: curve_n)
        let key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)

        let new_share = try! threshold_key.generate_new_share(curve_n: curve_n)
        let share_index = new_share.hex

        let key_details_2 = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details_2.total_shares, 3)

        _ = try! threshold_key.output_share(shareIndex: share_index, shareType: nil, curve_n: curve_n)

        try! threshold_key.delete_share(share_index: share_index, curve_n: curve_n)
        let key_details_3 = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details_3.total_shares, 2)

        XCTAssertThrowsError(
            try threshold_key.output_share(shareIndex: share_index, shareType: nil, curve_n: curve_n)
        )

    }

    func testThresholdInputOutputShare() throws {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let curve_n = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
        let key1 = try! PrivateKey.generate(curve_n: curve_n)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex, curve_n: curve_n)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false, curve_n: curve_n)
        let key_reconstruction_details = try! threshold_key.reconstruct(curve_n: curve_n)

        let shareStore = try! threshold_key.generate_new_share(curve_n: curve_n)

        let shareOut = try! threshold_key.output_share(shareIndex: shareStore.hex, shareType: nil, curve_n: curve_n)

        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        _ = try! threshold_key2.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false, curve_n: curve_n)

        try! threshold_key2.input_share(share: shareOut, shareType: nil, curve_n: curve_n)

        let key2_reconstruction_details = try! threshold_key2.reconstruct(curve_n: curve_n)
        XCTAssertEqual( key_reconstruction_details.key, key2_reconstruction_details.key)
    }

}
