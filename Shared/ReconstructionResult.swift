//
//  ReconstructionResult.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation

final class ReconstructionResult {
    private(set) var pointer: OpaquePointer?
    
    init(pointer: OpaquePointer?) {
        self.pointer = pointer
    }
    
    deinit {
        tkey_reconstruction_free(pointer)
    }
}
