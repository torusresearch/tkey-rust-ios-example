//
//  PrivateKeyModule.swift
//  Tests iOS
//
//  Created by CW Lee on 03/01/2023.
//

import XCTest

final class Tests_PrivateKeyModule: XCTestCase {

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
    
    
    func testPrivateKeyModule() throws {
        let curve_n = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
        let key1 = try! PrivateKey.generate(curve_n: curve_n)
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex, curve_n: curve_n)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true
        )

        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false, curve_n: curve_n)
        _ = try! threshold_key.reconstruct(curve_n: curve_n)

        let result = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        assert(result.count == 0)

        let key_module = try! PrivateKey.generate(curve_n: curve_n)
        let key_module2 = try! PrivateKey.generate(curve_n: curve_n)
        // Done setup

        // Try set and get privatekey from privatekey module
        _ = try! PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: key_module.hex, format: "secp256k1n", curve_n: curve_n)
        let result_1 = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        assert(result_1 == [key_module.hex] )

        // Try set 2nd privatekey
        _ = try! PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: key_module2.hex, format: "secp256k1n", curve_n: curve_n)
        let result_2 = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        assert( result_2 == [key_module.hex, key_module2.hex] )

        // Try set privateKey module with nil key
        _ = try! PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: nil, format: "secp256k1n", curve_n: curve_n)
        let result_3 = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        assert(result_3.count == 3 )

        //        try PrivateKeysModule.remove_private_key()

        // Reconstruct on second instance and check value ?

    }


}
