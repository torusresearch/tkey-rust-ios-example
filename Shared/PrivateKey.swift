//
//  PrivateKey.swift
//  tkey_ios (iOS)
//
//  Created by David Main on 2022/11/01.
//

import Foundation

final class PrivateKey {
    var hex: String

    init(pointer: UnsafeMutablePointer<Int8>) {
        hex = String.init(cString: pointer)
        string_destroy(pointer)
    }

    static func generate(curve_n: String) throws -> PrivateKey {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            generate_private_key(curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in PrivateKey, generate")
            }
        return PrivateKey.init(pointer: result!)
    }
}
