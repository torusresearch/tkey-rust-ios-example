//
//  SFA.swift
//  tkey_ios
//
//  Created by CW Lee on 14/08/2023.
//

import Foundation
import TorusUtils
import BigInt
import tkey_pkg

public func checkForUpgradedAccount ( typeOfUser: TypeOfUser, nonce: BigUInt ) -> Bool {
    if typeOfUser == TypeOfUser.v1 {
        if nonce == BigUInt(0) {
            return false
        } else {
            return true
        }
    } else if typeOfUser == TypeOfUser.v2 {
        if nonce == BigUInt(0) {
            return true
        } else {
            return false
        }
    }
    return false
}

public func getPostboxKeyAndNonce (sfaKey: String, typeOfUser: TypeOfUser, nonce: BigUInt) throws -> ( String, BigUInt ) {
    var postboxKey: String = sfaKey
    var newNonce: BigUInt = nonce
    if typeOfUser == TypeOfUser.v1 {
        //                              user v1 and upgrade is false -> generate nonce, add to finalkey -> postboxkey
        if nonce == 0 {
            let modulusValue = BigInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16)!
            let random = try PrivateKey.generate().hex
            newNonce = BigUInt(hex: random)!
            let key = BigInt(sfaKey, radix: 16)!
            let result = key + BigInt(sign: .plus, magnitude: nonce)
            let modResult = result.modulus(modulusValue)
            postboxKey =  modResult.serialize().toHexString()
        }
    } else {
        //                              user v2 and upgrade is false -> finalkey substract nonce from sdk -> postboxkey
        if nonce > 0 {
            let modulusValue = BigInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16)!
            let key = BigInt(sfaKey, radix: 16)!
            let result = key - BigInt(sign: .plus, magnitude: nonce)
            let modResult = result.modulus(modulusValue)
            postboxKey =  modResult.serialize().toHexString()
        }
    }
    return ( postboxKey, newNonce )
}

public func upgradeSFAToMFA (importKey: String, sfaKey: String, postboxKey: String, nonce: BigUInt, typeOfUser: TypeOfUser) async throws -> (ThresholdKey, KeyDetails) {
    guard let storage_layer = try? StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2) else {
        throw "Failed to create storage layer"
    }

    guard let service_provider = try? ServiceProvider(enable_logging: true, postbox_key: postboxKey) else {
        throw "Failed to create service provider"
    }

    guard let thresholdKey = try? ThresholdKey(
        storage_layer: storage_layer,
        service_provider: service_provider,
        enable_logging: true,
        manual_sync: true) else {
            throw "Failed to create threshold key"
    }

    print("nonce :" + nonce.serialize().toHexString() )
    print("postbox :" + postboxKey )

    // delete_1of1 should be true for v2 user
    let delete1of1 = typeOfUser == TypeOfUser.v2

    guard let key_details = try? await thresholdKey.initialize( import_key: importKey, never_initialize_new_key: false, include_local_metadata_transitions: false, delete_1_of_1: delete1of1) else {
        throw "Failed to get key details"
    }

    // v1 -> setMetadata nonce
    if typeOfUser == TypeOfUser.v1 {
        let data = [ "message": "__ONE_KEY_ADD_NONCE__", "data": nonce.serialize().toHexString()]
        let jsonData = try! JSONSerialization.data(withJSONObject: data)
        let jsonStr = String(data: jsonData, encoding: .utf8)!
        try! thresholdKey.add_local_metadata_transitions(input_json: jsonStr, private_key: sfaKey )
    }

    return (thresholdKey, key_details)
}
