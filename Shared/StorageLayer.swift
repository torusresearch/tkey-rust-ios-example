//
//  StorageLayer.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation

final class StorageLayer {
    private(set) var pointer: OpaquePointer
    
    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    init(enable_logging: Bool, host_url: String, server_time_offset: UInt) throws {
        var errorCode: Int32 = -1
        let urlPointer = UnsafeMutablePointer<Int8>(mutating: (host_url as NSString).utf8String)
        
        let network_interface: (@convention(c) (UnsafeMutablePointer<CChar>?, UnsafeMutablePointer<CChar>?, Int32) -> UnsafeMutablePointer<CChar>?) = {url, data, error_code in
            let result: NSString = "Hello"
            let resultPointer = UnsafeMutablePointer<CChar>(mutating: result.utf8String)
            return resultPointer
        }
        
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            storage_layer(enable_logging, urlPointer, server_time_offset,  network_interface, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in StorageLayer")
            }
        pointer = result!
    }
    
    deinit {
        storage_layer_free(pointer)
    }
}
