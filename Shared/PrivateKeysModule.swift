//
//  PrivateKeysModule.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation

final class PrivateKeysModule {
    static func set_private_key(threshold_key: ThresholdKey, key: String?, format: String, curve_n: String) throws -> Bool
    {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        var keyPointer: UnsafeMutablePointer<Int8>?
        if key != nil {
            keyPointer = UnsafeMutablePointer<Int8>(mutating: (key! as NSString).utf8String)
        }
        let formatPointer = UnsafeMutablePointer<Int8>(mutating: (format as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            private_keys_set_private_key(threshold_key.pointer, keyPointer, formatPointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in PrivateKeysModule, private_keys_set_private_keys")
            }
        return result
    }
    
    static func get_private_keys(threshold_key: ThresholdKey) throws -> String
    {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            private_keys_get_private_keys(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in PrivateKeysModule, private_keys_get_private_keys")
            }
        let json = String.init(cString: result!)
        string_destroy(result)
        return json
    }
    
    static func get_private_key_accounts(threshold_key: ThresholdKey) throws -> String
    {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            private_keys_get_accounts(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in PrivateKeysModule, private_keys_get_accounts")
            }
        let json = String.init(cString: result!)
        string_destroy(result)
        return json
    }

}
