//
//  Point.swift
//  tkey_ios
//
//  Created by David Main on 2022/11/01.
//

import Foundation

final class KeyPoint: Codable {
    var x, y: String

    init(pointer: OpaquePointer) throws {
        var errorCode: Int32 = -1
        var result = withUnsafeMutablePointer(to: &errorCode, { error in
            point_get_x(pointer, error)
                })
        x = String.init(cString: result!)
        string_destroy(result)
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, field X")
            }
        result = withUnsafeMutablePointer(to: &errorCode, { error in
            point_get_y(pointer, error)
                })
        y = String.init(cString: result!)
        string_destroy(result)
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, field Y")
            }
        point_free(pointer)
    }
}
