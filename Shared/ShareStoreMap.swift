//
//  ShareStoreMap.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation

final class ShareStoreMap {
    private(set) var pointer: OpaquePointer?
    
    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    deinit {
        share_store_map_free(pointer)
    }
}
