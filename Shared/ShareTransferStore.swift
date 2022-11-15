//
//  ShareTransferStore.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation

final class ShareTransferStore {
    private(set) var pointer: OpaquePointer?
    
    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    deinit {
        share_transfer_store_free(pointer)
    }
}
