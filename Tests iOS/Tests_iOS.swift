//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by David Main on 2022/08/29.
//

import XCTest
import tkey_ios

class ThresholdKey_Test : XCTestCase {

    func testThresholdInputOutputShare() throws {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let version = try! library_version()
        let curve_n = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
        let key1 = try! PrivateKey.generate(curve_n: curve_n)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex, curve_n: curve_n)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        let key_details = try! threshold_key.initialize(never_initialize_new_key: false, service_provider: service_provider, include_local_metadata_transitions: false, curve_n: curve_n)
        let key_reconstruction_details = try! threshold_key.reconstruct(curve_n: curve_n)

        let shareStore = try! threshold_key.generate_new_share(curve_n: curve_n)
        
        let shareOut = try! threshold_key.output_share(shareIndex: shareStore.hex, shareType: nil, curve_n: curve_n)
        
        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)
        
        let key_details2 = try! threshold_key2.initialize(never_initialize_new_key: true, service_provider: service_provider, include_local_metadata_transitions: false, curve_n: curve_n)
        
        try! threshold_key2.input_share(share: shareOut, shareType: nil,  curve_n: curve_n)
        
        
        let key2_reconstruction_details = try! threshold_key2.reconstruct(curve_n: curve_n)
        assert( key_reconstruction_details.key ==
        key2_reconstruction_details.key, "key should be same")
        debugPrint(version)
    }
}

