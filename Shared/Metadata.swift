//
//  Metadata.swift
//  tkey_ios
//
//  Created by David Main on 2022/12/06.
//

import Foundation

final class Metadata {
    private(set) var pointer: OpaquePointer?

    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    init(json: String) throws {
        var errorCode: Int32 = -1
        let jsonPointer = UnsafeMutablePointer<Int8>(mutating: (json as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            metadata_from_json(jsonPointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore")
            }
        pointer = result
    }

    public func export() throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            metadata_to_json(pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore")
            }
        let value = String.init(cString: result!)
        string_destroy(result)
        return value
    }

    deinit {
        metadata_free(pointer)
    }
}
