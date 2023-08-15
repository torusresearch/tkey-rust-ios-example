//
//  helper.swift
//  tkey_ios
//
//  Created by CW Lee on 15/08/2023.
//

import Foundation
import tkey_pkg

func convertPublicKeyFormat ( publicKey: String, outFormat: PublicKeyEncoding ) throws -> String {
    let point = try KeyPoint(address: publicKey)
    let result = try point.getPublicKey(format: outFormat)
    return result
}

func factorDescription ( dataObj: [String: Codable]  ) throws -> String {
    let json = try JSONSerialization.data(withJSONObject: dataObj)
    guard let jsonStr = String(data: json, encoding: .utf8) else {
        throw "Invalid data structure"
    }
    return jsonStr
}
