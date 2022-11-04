//
//  RuntimeError.swift
//  tkey_ios
//
//  Created by David Main on 2022/10/25.
//

import Foundation

struct RuntimeError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    public var localizedDescription: String {
        return message
    }
}
