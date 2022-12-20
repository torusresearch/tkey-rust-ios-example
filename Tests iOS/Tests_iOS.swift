//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by David Main on 2022/08/29.
//

import XCTest
import tkey_ios

class ThresholdKey_Test: XCTestCase {

    func testGenerateDeleteShare() {
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

        let output_share = try! threshold_key.output_share(shareIndex: share_index, shareType: nil, curve_n: curve_n)
        XCTAssertNotNil(output_share)

        try! threshold_key.delete_share(share_index: share_index, curve_n: curve_n)
        let key_details_3 = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details_3.total_shares, 2)

        do {
            _ = try threshold_key.output_share(shareIndex: share_index, shareType: nil, curve_n: curve_n)
        } catch let error as RuntimeError {
            XCTAssertEqual(error.message, "Error in ThresholdKey generate_new_share")
        } catch let error {
            print(error.localizedDescription)
        }
    }

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

        try! threshold_key2.input_share(share: shareOut, shareType: nil,                        curve_n: curve_n)

        let key2_reconstruction_details = try! threshold_key2.reconstruct(curve_n: curve_n)
        assert( key_reconstruction_details.key ==
        key2_reconstruction_details.key, "key should be same")
        debugPrint(version)
    }

    func testSecurityQuestionModule() throws {
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

        let question = "favorite marvel character"
        let answer = "iron man"
        let answer_2 = "captain america"

        // generate new security share
        let new_share = try! SecurityQuestionModule.generate_new_share(threshold_key: threshold_key, questions: question, answer: answer, curve_n: curve_n)
        let share_index = new_share.hex

        let sq_question = try! SecurityQuestionModule.get_questions(threshold_key: threshold_key)
        XCTAssertEqual(sq_question, question)

        let security_input_share: Bool = try! SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer, curve_n: curve_n)
        XCTAssertEqual(security_input_share, true)

        do {
            _ = try SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: "ant man", curve_n: curve_n)
        } catch let error as RuntimeError {
            XCTAssertEqual(error.message, "Error in SecurityQuestionModule, input_share")
        }

        // change answer for already existing question
        let change_answer_result = try! SecurityQuestionModule.change_question_and_answer(threshold_key: threshold_key, questions: question, answer: answer_2, curve_n: curve_n)
        XCTAssertEqual(change_answer_result, true)

        do {
            _ = try SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer, curve_n: curve_n)
        } catch let error as RuntimeError {
            XCTAssertEqual(error.message, "Error in SecurityQuestionModule, input_share")
        }

        let security_input_share_2 = try! SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer_2, curve_n: curve_n)
        XCTAssertEqual(security_input_share_2, true)

        let get_answer = try! SecurityQuestionModule.get_answer(threshold_key: threshold_key)
        XCTAssertEqual(get_answer, answer_2)

        let key_reconstruction_details_2 = try! threshold_key.reconstruct(curve_n: curve_n)
        assert(key_reconstruction_details.key == key_reconstruction_details_2.key, "security question fail")

        // delete newly security share
        try! threshold_key.delete_share(share_index: share_index, curve_n: curve_n)

        do {
            _ = try SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer, curve_n: curve_n)
        } catch let error as RuntimeError {
            XCTAssertEqual(error.message, "Error in SecurityQuestionModule, input_share")
        }
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

        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false, curve_n: curve_n)
        let key_reconstruction_details = try! threshold_key.reconstruct(curve_n: curve_n)

        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        _ = try! threshold_key2.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false, curve_n: curve_n)

        let request_enc = try! ShareTransferModule.request_new_share(threshold_key: threshold_key2, user_agent: "agent", available_share_indexes: "[]", curve_n: curve_n)

        let lookup = try! ShareTransferModule.look_for_request(threshold_key: threshold_key)
        let encPubKey = lookup[0]
        let newShare = try! threshold_key.generate_new_share(curve_n: curve_n)

        try! ShareTransferModule.approve_request_with_share_index(threshold_key: threshold_key, enc_pub_key_x: encPubKey, share_index: newShare.hex, curve_n: curve_n)

        _ = try! ShareTransferModule.request_status_check(threshold_key: threshold_key2, enc_pub_key_x: request_enc, delete_request_on_completion: true, curve_n: curve_n)

        let key_reconstruction_details_2 = try! threshold_key2.reconstruct(curve_n: curve_n)

        assert(key_reconstruction_details.key == key_reconstruction_details_2.key, "Share transfer fail")
    }

    func testPrivateKeyModule() {
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
//        Done setup

//        Try set and get privatekey from privatekey module
        _ = try! PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: key_module.hex, format: "secp256k1n", curve_n: curve_n)
        let result_1 = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        assert(result_1 == [key_module.hex] )

//        Try set 2nd privatekey
        _ = try! PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: key_module2.hex, format: "secp256k1n", curve_n: curve_n)
        let result_2 = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        assert( result_2 == [key_module.hex, key_module2.hex] )

//        Try set privateKey module with nil key
        _ = try! PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: nil, format: "secp256k1n", curve_n: curve_n)
        let result_3 = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        assert(result_3.count == 3 )

        //        try PrivateKeysModule.remove_private_key()

//        Reconstruct on second instance and check value ?

    }

    func testSeedPhraseModule() {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let curve_n = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
        let key1 = try! PrivateKey.generate(curve_n: curve_n)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex, curve_n: curve_n)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true
            )

        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false, curve_n: curve_n)
        _ = try! threshold_key.reconstruct(curve_n: curve_n)
        let seedPhraseToSet = "seed sock milk update focus rotate barely fade car face mechanic mercy"
        let seedPhraseToSet2 = "object brass success calm lizard science syrup planet exercise parade honey impulse"

//        Check the seedphrase module is empty
        let seedResult = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        assert(seedResult.count == 0 )

//        set and get seedphrases
        try! SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet, number_of_wallets: 0, curve_n: curve_n)
        let seedResult_2 = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        assert(seedResult_2[0].seedPhrase == seedPhraseToSet )

//        Try delete unknown seedphrase - expect fail
        do {
            try SeedPhraseModule.delete_seedphrase(threshold_key: threshold_key, phrase: seedPhraseToSet2, curve_n: curve_n)
            assert(false)
        } catch {
            debugPrint("expected delete failed")
        }

//        Try to set and get 2nd seedphrases
        try! SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet2, number_of_wallets: 0, curve_n: curve_n)
        let seedResult_3 = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        assert(seedResult_3[0].seedPhrase == seedPhraseToSet )
        assert(seedResult_3[1].seedPhrase == seedPhraseToSet2 )

//        Try set seedphrase with existing seed phrase
        do {
            try SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet2, number_of_wallets: 0, curve_n: curve_n)
            assert(false, "unexpected set same seedphrase")
        } catch {
        }
//        Try set seedphrase with nil
        try! SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: nil, number_of_wallets: 0, curve_n: curve_n)
        let seedResult_4 = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        assert(seedResult_4.count == 3 )

//        Try reconstruct 2nd Tkey instance to check if seed phrase is persistance
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
        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false, curve_n: curve_n)
        _ = try! threshold_key.reconstruct(curve_n: curve_n)
        let metadata = try! threshold_key.get_metadata()
        let json = try! metadata.export()
        assert(json.lengthOfBytes(using: .utf8) > 0)
        _ = try! Metadata.init(json: json)
    }
}
