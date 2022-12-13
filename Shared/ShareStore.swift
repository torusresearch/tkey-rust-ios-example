//
//  ShareStore.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation

final class ShareStore {
    private(set) var pointer: OpaquePointer?

    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    init(json: String) throws {
        var errorCode: Int32 = -1
        let jsonPointer = UnsafeMutablePointer<Int8>(mutating: (json as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            json_to_share_store(jsonPointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore \(errorCode)")
            }
        pointer = result
    }

    func toJson() throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_store_to_json(pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore to Json \(errorCode)")
        }
        let string = String(cString: result!)
        string_destroy(result)
        return string
    }
    deinit {
        share_store_free(pointer)
    }
}
