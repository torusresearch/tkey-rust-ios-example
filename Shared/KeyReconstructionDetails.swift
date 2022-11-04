//
//  ReconstructionResult.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation

final class KeyReconstructionDetails: Codable {
    var key: String
    var seed_phrase: [String]
    var all_keys: [String]
    
    init(pointer: OpaquePointer) throws {
        var errorCode: Int32 = -1
        let key = withUnsafeMutablePointer(to: &errorCode, { error in
           key_reconstruction_get_private_key(pointer, error)
               })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyDetails, field Private Key")
            }
        self.key = String.init(cString: key!)
        string_destroy(key)
        
        self.seed_phrase = []
        let seed_len = withUnsafeMutablePointer(to: &errorCode, { error in
           key_reconstruction_get_seed_phrase_len(pointer, error)
               })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyDetails, field Seed Phrase")
            }
        if seed_len > 0
        {
            for index in 0...seed_len-1 {
                let seed_item = withUnsafeMutablePointer(to: &errorCode, { error in
                   key_reconstruction_get_seed_phrase_at(pointer, index, error)
                       })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in KeyDetails, field Seed Phrase, index " + index.formatted())
                    }
                self.seed_phrase.append(String.init(cString: seed_item!))
                string_destroy(seed_item)
            }
        }
        
        self.all_keys = []
        let keys_len = withUnsafeMutablePointer(to: &errorCode, { error in
           key_reconstruction_get_all_keys_len(pointer, error)
               })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyDetails, field Seed Phrase")
            }
        if keys_len > 0
        {
            for index in 0...keys_len-1 {
                let seed_item = withUnsafeMutablePointer(to: &errorCode, { error in
                   key_reconstruction_get_all_keys_at(pointer, index, error)
                       })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in KeyDetails, field Seed Phrase, index " + index.formatted())
                    }
                self.all_keys.append(String.init(cString: seed_item!))
                string_destroy(seed_item)
            }
        }
        
        key_reconstruction_details_free(pointer)
    }
}
