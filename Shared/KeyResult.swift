//
//  KeyResult.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation

final class KeyResult {
    private(set) var pointer: OpaquePointer
    
    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    deinit {
        tkey_free(pointer)
    }
}
