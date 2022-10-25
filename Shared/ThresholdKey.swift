//
//  ThresholdKey.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation

final class ThresholdKey {
    private(set) var pointer: OpaquePointer
    
    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    init(private_key: String, metadata: OpaquePointer, shares: OpaquePointer, storage_layer: StorageLayer, service_provider: ServiceProvider, local_matadata_transitions: OpaquePointer, last_fetch_cloud_metadata: OpaquePointer, enable_logging: Bool, manual_sync: Bool) throws {
        var errorCode: Int32 = -1
        let keyPointer = UnsafeMutablePointer<Int8>(mutating: (private_key as NSString).utf8String)
        
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key(keyPointer, metadata, shares, storage_layer.pointer, service_provider.pointer, local_matadata_transitions, last_fetch_cloud_metadata, enable_logging, manual_sync, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey")
            }
        pointer = result!
    }
    
    public func initialize(import_share: String, input: OpaquePointer, never_initialize_new_key: Bool, service_provider: ServiceProvider, include_local_metadata_transitions: Bool, curve_n: String) throws -> KeyResult
    {
        var errorCode: Int32 = -1
        let sharePointer = UnsafeMutablePointer<Int8>(mutating: (import_share as NSString).utf8String)
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_initialize(pointer, sharePointer, input, never_initialize_new_key, service_provider.pointer, include_local_metadata_transitions, curvePointer, error)})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey Initialize")
            }
        return KeyResult.init(pointer: result!);
    }
    
    public func reconstruct(curve_n: String) throws -> ReconstructionResult
    {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_reconstruct(pointer, curvePointer, error)})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey Reconstruct")
            }
        return ReconstructionResult.init(pointer: result!)
    }
    
    deinit {
        threshold_key_free(pointer)
    }
}
