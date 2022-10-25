//
//  ServiceProvider.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation

final class ServiceProvider {
    private(set) var pointer: OpaquePointer
    
    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    init(enable_logging: Bool, postbox_key: String, curve_n: String) throws {
        var errorCode: Int32 = -1
        let postboxPointer = UnsafeMutablePointer<Int8>(mutating: (postbox_key as NSString).utf8String)
        let curve = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            service_provider(enable_logging,postboxPointer, curve, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ServiceProvider")
            }
        pointer = result!
    }
    
    deinit {
        service_provider_free(pointer)
    }
}
