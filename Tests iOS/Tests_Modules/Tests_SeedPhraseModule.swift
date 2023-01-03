//
//  SeedPhraseModule.swift
//  Tests iOS
//
//  Created by CW Lee on 03/01/2023.
//

import XCTest

final class Tests_SeedPhraseModule: XCTestCase {

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

    func testSeedPhraseModule() throws {
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

        // Check the seedphrase module is empty
        let seedResult = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult.count, 0 )

        // set and get seedphrases
        try! SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet, number_of_wallets: 0, curve_n: curve_n)
        let seedResult_2 = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult_2[0].seedPhrase, seedPhraseToSet )

        // Try delete unknown seedphrase - expect fail
        XCTAssertThrowsError(try SeedPhraseModule.delete_seedphrase(threshold_key: threshold_key, phrase: seedPhraseToSet2, curve_n: curve_n))

        // Try to set and get 2nd seedphrases
        try! SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet2, number_of_wallets: 0, curve_n: curve_n)
        let seedResult_3 = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult_3[0].seedPhrase, seedPhraseToSet )
        XCTAssertEqual(seedResult_3[1].seedPhrase, seedPhraseToSet2 )

        // Try set seedphrase with existing seed phrase
        XCTAssertThrowsError(try SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet2, number_of_wallets: 0, curve_n: curve_n))

        // Try set seedphrase with nil
        try! SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: nil, number_of_wallets: 0, curve_n: curve_n)
        let seedResult_4 = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult_4.count, 3 )

        // Try reconstruct 2nd Tkey instance to check if seed phrase is persistance
    }

}
