//
//  ShareTransferModule.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation

final class ShareTransferModule {
    
   static func request_new_share(threshold_key: ThresholdKey, user_agent: String, available_share_indexes: String, curve_n: String) throws -> String
    {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let agentPointer = UnsafeMutablePointer<Int8>(mutating: (user_agent as NSString).utf8String)
        let indexesPointer = UnsafeMutablePointer<Int8>(mutating: (available_share_indexes as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_request_new_share(threshold_key.pointer, agentPointer, indexesPointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, request share. Error Code: \(errorCode)")
            }
        let string = String.init(cString: result!)
        string_destroy(result)
        return string
    }
    
    static func add_custom_info_to_request(threshold_key: ThresholdKey, enc_pub_key_x: String, custom_info: String, curve_n: String) throws
    {
        var errorCode: Int32 = -1
        let encPointer = UnsafeMutablePointer<Int8>(mutating: (enc_pub_key_x as NSString).utf8String)
        let customPointer = UnsafeMutablePointer<Int8>(mutating: (custom_info as NSString).utf8String)
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_add_custom_info_to_request(threshold_key.pointer, encPointer, customPointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, add custom info to request. Error Code: \(errorCode)")
            }
    }
    
    static func look_for_request(threshold_key: ThresholdKey) throws -> [String]
    {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_look_for_request(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, lookup for request. Error Code: \(errorCode)")
            }
        let string = String.init(cString: result!)
        let indicator_array = try! JSONSerialization.jsonObject(with: string.data(using: String.Encoding.utf8)!, options: .allowFragments) as! [String]
        string_destroy(result)
        return indicator_array
    }
    
    static func approve_request(threshold_key: ThresholdKey, enc_pub_key_x: String, share_store: ShareStore, curve_n: String) throws
    {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let encPointer = UnsafeMutablePointer<Int8>(mutating: (enc_pub_key_x as NSString).utf8String)
        withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_approve_request(threshold_key.pointer, encPointer, share_store.pointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, change_question_and_answer. Error Code: \(errorCode)")
            }
    }
    
    static func approve_request_with_share_index(threshold_key: ThresholdKey, enc_pub_key_x: String, share_index: String, curve_n: String) throws
    {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let encPointer = UnsafeMutablePointer<Int8>(mutating: (enc_pub_key_x as NSString).utf8String)
        let indexesPointer = UnsafeMutablePointer<Int8>(mutating: (share_index as NSString).utf8String)
        withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_approve_request_with_share_indexes(threshold_key.pointer, encPointer, indexesPointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, approve request with share index. Error Code: \(errorCode)")
            }
    }
    
    static func get_store(threshold_key: ThresholdKey) throws -> ShareTransferStore
    {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_get_store(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, get store. Error Code: \(errorCode)")
            }
        return ShareTransferStore.init(pointer: result!)
    }
    
    static func set_store(threshold_key: ThresholdKey, store: ShareTransferStore, curve_n: String) throws -> Bool
    {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_set_store(threshold_key.pointer, store.pointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, set store. Error Code: \(errorCode)")
            }
        return result
    }
    
    static func delete_store(threshold_key: ThresholdKey, enc_pub_key_x: String, curve_n: String) throws -> Bool
    {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let encPointer = UnsafeMutablePointer<Int8>(mutating: (enc_pub_key_x as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_delete_store(threshold_key.pointer, encPointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, delete store. Error Code: \(errorCode)")
            }
        return result
    }
    
    static func get_current_encryption_key(threshold_key: ThresholdKey) throws -> String
    {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_get_current_encryption_key(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, get current encryption key. Error Code: \(errorCode)")
            }
        let string = String.init(cString: result!)
        string_destroy(result)
        return string
    }

    
    static func request_status_check(threshold_key: ThresholdKey, enc_pub_key_x: String, delete_request_on_completion: Bool, curve_n: String) throws -> String
    {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let encPointer = UnsafeMutablePointer<Int8>(mutating: (enc_pub_key_x as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_request_status_check(threshold_key.pointer, encPointer, delete_request_on_completion, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, request status check. Error Code: \(errorCode)")
            }
        let string = String(cString: result!)
        string_destroy(result)
        return string
    }
    
    static func cleanup_request(threshold_key: ThresholdKey) throws {
        var errorCode: Int32 = -1
        withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_cleanup_request(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, cleanup request. Error Code: \(errorCode)")
            }
    }
}
