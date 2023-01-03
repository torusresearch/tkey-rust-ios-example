//
//  ThresholdKey.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation

final class ThresholdKey {
    private(set) var pointer: OpaquePointer?

    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    init(metadata: Metadata? = nil, shares: OpaquePointer? = nil, storage_layer: StorageLayer, service_provider: ServiceProvider? = nil, local_matadata_transitions: OpaquePointer? = nil, last_fetch_cloud_metadata: OpaquePointer? = nil, enable_logging: Bool, manual_sync: Bool) throws {
        var errorCode: Int32 = -1

        var providerPointer: OpaquePointer?
        if case .some(let provider) = service_provider {
            providerPointer = provider.pointer
        }

        let result = withUnsafeMutablePointer(to: &errorCode, { error -> OpaquePointer in
            if metadata == nil {
                return threshold_key(nil, shares, storage_layer.pointer, providerPointer, local_matadata_transitions, last_fetch_cloud_metadata, enable_logging, manual_sync, error)
            } else {
                return threshold_key(metadata!.pointer, shares, storage_layer.pointer, providerPointer, local_matadata_transitions, last_fetch_cloud_metadata, enable_logging, manual_sync, error)
            }
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey")
        }
        pointer = result
    }

    public func get_metadata() throws -> Metadata {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_get_metadata(pointer, error)})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_metadata")
        }
        return Metadata.init(pointer: result!)
    }

    public func initialize(import_share: String = "", input: OpaquePointer? = nil, never_initialize_new_key: Bool, include_local_metadata_transitions: Bool, curve_n: String) throws -> KeyDetails {
        var errorCode: Int32 = -1
        var sharePointer: UnsafeMutablePointer<Int8>?
        if !import_share.isEmpty {
            sharePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: import_share).utf8String)
        }

        let curvePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: curve_n).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_initialize(pointer, sharePointer, input, never_initialize_new_key, include_local_metadata_transitions, curvePointer, error)})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey Initialize")
        }
        return try! KeyDetails(pointer: result!)
    }

    public func reconstruct(curve_n: String) throws -> KeyReconstructionDetails {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_reconstruct(pointer, curvePointer, error)})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey Reconstruct")
        }
        return try! KeyReconstructionDetails(pointer: result!)
    }

    public func generate_new_share(curve_n: String) throws -> GenerateShareStoreResult {
        var errorCode: Int32  = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_generate_share(pointer, curvePointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey generate_new_share")
        }
        return try! GenerateShareStoreResult( pointer: result!)
    }

    public func delete_share(share_index: String, curve_n: String) throws {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let shareIndexPointer = UnsafeMutablePointer<Int8>(mutating: (share_index as NSString).utf8String)
        withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_delete_share(pointer, shareIndexPointer, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in Threshold while Deleting share")
        }
    }

    public func get_key_details() throws -> KeyDetails {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_get_key_details(pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in Threshold while Getting Key Details")
        }
        return try! KeyDetails(pointer: result!)
    }

    public func output_share( shareIndex: String, shareType: String?, curve_n: String ) throws -> String {
        var errorCode: Int32  = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let cShareIndex = UnsafeMutablePointer<Int8>(mutating: (shareIndex as NSString).utf8String)

        var cShareType: UnsafeMutablePointer<Int8>?
        if let shareType = shareType {
            cShareType = UnsafeMutablePointer<Int8>(mutating: (shareType as NSString).utf8String)
        }
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_output_share(pointer, cShareIndex, cShareType,                                           curvePointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey generate_new_share")
        }
        return String.init(cString: result!)
    }

    public func share_to_share_store(share: String, curve_n: String ) throws -> ShareStore {
        var errorCode: Int32  = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let sharePointer = UnsafeMutablePointer<Int8>(mutating: (share as NSString).utf8String)

        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_share_to_share_store(pointer, sharePointer, curvePointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey share_to_share_store")
        }
        return ShareStore.init(pointer: result!)
    }

    public func input_share( share: String, shareType: String?, curve_n: String ) throws {
        var errorCode: Int32  = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let cShare = UnsafeMutablePointer<Int8>(mutating: (share as NSString).utf8String)

        var cShareType: UnsafeMutablePointer<Int8>?
        if let shareType = shareType {
            cShareType = UnsafeMutablePointer<Int8>(mutating: (shareType as NSString).utf8String)
        }
        withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_input_share(pointer, cShare, cShareType,                                           curvePointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey generate_new_share")
        }
    }

    deinit {
        threshold_key_free(pointer)
    }
}
