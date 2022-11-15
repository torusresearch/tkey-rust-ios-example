//
//  SecurityQuestionModule.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation

final class SecurityQuestionModule {
    static func generate_new_share(threshold_key: ThresholdKey, questions: String, answer: String, curve_n: String) throws -> GenerateShareStoreResult
    {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let questionsPointer = UnsafeMutablePointer<Int8>(mutating: (questions as NSString).utf8String)
        let answerPointer = UnsafeMutablePointer<Int8>(mutating: (answer as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            security_question_generate_new_share(threshold_key.pointer, questionsPointer, answerPointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SecurityQuestionModule, generate_new_share")
            }
        return try! GenerateShareStoreResult.init(pointer: result!)
    }
    
    static func input_share(threshold_key: ThresholdKey, answer: String, curve_n: String) throws -> Bool
    {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let answerPointer = UnsafeMutablePointer<Int8>(mutating: (answer as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            security_question_input_share(threshold_key.pointer, answerPointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SecurityQuestionModule, input_share")
            }
        return result
    }
    
    static func change_question_and_answer(threshold_key: ThresholdKey, questions: String, answer: String, curve_n: String) throws -> Bool
    {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let questionsPointer = UnsafeMutablePointer<Int8>(mutating: (questions as NSString).utf8String)
        let answerPointer = UnsafeMutablePointer<Int8>(mutating: (answer as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            security_question_change_question_and_answer(threshold_key.pointer, questionsPointer, answerPointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SecurityQuestionModule, change_question_and_answer")
            }
        return result
    }
    
    static func store_answer(threshold_key: ThresholdKey, answer: String, curve_n: String) throws -> Bool
    {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let answerPointer = UnsafeMutablePointer<Int8>(mutating: (answer as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            security_question_store_answer(threshold_key.pointer, answerPointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SecurityQuestionModule, change_question_and_answer")
            }
        return result
    }
    
    static func get_answer(threshold_key: ThresholdKey) throws -> String
    {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            security_question_get_answer(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SecurityQuestionModule, change_question_and_answer")
            }
        let string = String.init(cString: result!)
        string_destroy(result)
        return string
    }
    
    static func get_questions(threshold_key: ThresholdKey) throws -> String
    {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            security_question_get_questions(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SecurityQuestionModule, change_question_and_answer")
            }
        let string = String.init(cString: result!)
        string_destroy(result)
        return string
    }
}
