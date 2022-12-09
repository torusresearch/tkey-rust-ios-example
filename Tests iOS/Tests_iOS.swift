//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by David Main on 2022/08/29.
//

import XCTest
import tkey_ios
import Security

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

        let _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false, curve_n: curve_n)
        let key_reconstruction_details = try! threshold_key.reconstruct(curve_n: curve_n)

        let shareStore = try! threshold_key.generate_new_share(curve_n: curve_n)
        
        let shareOut = try! threshold_key.output_share(shareIndex: shareStore.hex, shareType: nil, curve_n: curve_n)
        
        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)
        
        let _ = try! threshold_key2.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false, curve_n: curve_n)
        
        try! threshold_key2.input_share(share: shareOut, shareType: nil,  curve_n: curve_n)
        
        
        let key2_reconstruction_details = try! threshold_key2.reconstruct(curve_n: curve_n)
        assert( key_reconstruction_details.key ==
        key2_reconstruction_details.key, "key should be same")
        debugPrint(version)
    }
    
    func testThresholdShareTransfer () {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)

        let curve_n = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
        let key1 = try! PrivateKey.generate(curve_n: curve_n)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex, curve_n: curve_n)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        let _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false, curve_n: curve_n)
        let key_reconstruction_details = try! threshold_key.reconstruct(curve_n: curve_n)

        
        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)
        
        let _ = try! threshold_key2.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false, curve_n: curve_n)

        let request_enc = try! ShareTransferModule.request_new_share(threshold_key: threshold_key2, user_agent: "agent", available_share_indexes: "[]", curve_n: curve_n)
        
        
        let lookup = try! ShareTransferModule.look_for_request(threshold_key: threshold_key)
        let encPubKey = lookup[0]
        let newShare = try! threshold_key.generate_new_share(curve_n: curve_n)

        
        try! ShareTransferModule.approve_request_with_share_index(threshold_key: threshold_key, enc_pub_key_x: encPubKey, share_index: newShare.hex, curve_n: curve_n)
        
        
        let _ = try! ShareTransferModule.request_status_check(threshold_key: threshold_key2, enc_pub_key_x: request_enc, delete_request_on_completion: true, curve_n: curve_n)
        
        let key_reconstruction_details_2 = try! threshold_key2.reconstruct(curve_n: curve_n)
        
        assert(key_reconstruction_details.key == key_reconstruction_details_2.key, "Share transfer fail")
    }
    


    func testAddPassword() {
        try! KeychainInterface.getAllAccount();
        let password = "mypassword"
        let account = "myaccount"
        let success = addPassword(password: password, account: account)
        XCTAssertTrue(success)
    }

    func addPassword(password: String, account: String) -> Bool {
        // Create a dictionary with the password and account name
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: password.data(using: .utf8)!
        ]

        // Add the password to the keychain
        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }
//    keychain not able to test
//    tested on contentView()
    func testDeviceShare () {
        
        
        
        
        
        
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)

        let curve_n = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
        let key1 = try! PrivateKey.generate(curve_n: curve_n)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex, curve_n: curve_n)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        let key_details = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false, curve_n: curve_n)
        // Create an expectation for the keychain operation

        try! KeychainInterface.syncShare(threshold_key: threshold_key, share_index: nil, curve_n: curve_n)


        
        let key_reconstruction_details = try! threshold_key.reconstruct(curve_n: curve_n)


        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        let key_details2 = try! threshold_key2.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false, curve_n: curve_n)
        try! KeychainInterface.syncShare(threshold_key: threshold_key2, share_index: nil, curve_n: curve_n)

        try! KeychainInterface.getAllAccount()

        let key_reconstruction_details2 = try! threshold_key2.reconstruct(curve_n: curve_n)
        assert( key_reconstruction_details.key == key_reconstruction_details2.key)
        
    }
    
    func test_get_metadata() {
        let curve_n = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
        let key1 = try! PrivateKey.generate(curve_n: curve_n)
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex, curve_n: curve_n)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true) 
        let _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false, curve_n: curve_n)
        let _ = try! threshold_key.reconstruct(curve_n: curve_n)
        let metadata = try! threshold_key.get_metadata()
        let json = try! metadata.export()
        assert(json.lengthOfBytes(using: .utf8) > 0)
        let new_metadata = try! Metadata.init(json: json)
    }
}
