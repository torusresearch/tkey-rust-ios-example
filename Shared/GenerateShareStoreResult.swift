//
//  GenerateShareStoreResult.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation

final class GenerateShareStoreResult {
    private(set) var pointer: OpaquePointer?
    var hex: String
    var share_store: ShareStoreMap

    init(pointer: OpaquePointer) throws {
        self.pointer = pointer
        var errorCode: Int32 = -1
        let hexPtr = withUnsafeMutablePointer(to: &errorCode, { error in
            generate_new_share_store_result_get_shares_index(pointer, error)
                })
        guard errorCode == 0 else {
        throw RuntimeError("Error in GenerateShareStoreResult, field hex")
        }
        hex = String.init(cString: hexPtr!)
        string_destroy(hexPtr)
        let storePtr = withUnsafeMutablePointer(to: &errorCode, { error in
           generate_new_share_store_result_get_share_store_map(pointer, error)
               })
        guard errorCode == 0 else {
            throw RuntimeError("Error in GenerateShareStoreResult, field share_store")
            }
        share_store = ShareStoreMap.init(pointer: storePtr!)
    }

    deinit {
        generate_share_store_result_free(pointer)
    }
}
