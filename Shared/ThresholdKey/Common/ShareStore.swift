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
            share_store_from_json(jsonPointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore")
            }
        pointer = result
    }

    public func share() throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_store_get_share(pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore")
            }
        let value = String.init(cString: result!)
        string_destroy(result)
        return value
    }

    public func share_index() throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_store_get_share_index(pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore")
            }
        let value = String.init(cString: result!)
        string_destroy(result)
        return value
    }

    public func polynomial_id() throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_store_get_polynomial_id(pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore")
            }
        let value = String.init(cString: result!)
        string_destroy(result)
        return value
    }

    deinit {
        share_store_free(pointer)
    }
}
