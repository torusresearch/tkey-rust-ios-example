//
//  SecurityQuestion.swift
//  Tests iOS
//
//  Created by CW Lee on 03/01/2023.
//

import XCTest

final class Tests_SecurityQuestion: XCTestCase {

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
}
