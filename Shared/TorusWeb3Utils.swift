//
//  TorusWeb3Utils.swift
//  tkey_ios
//
//  Created by himanshu on 09/08/23.
//

import BigInt
import Foundation
import web3
import CryptoKit

public typealias Ether = Double
public typealias Wei = BigUInt

public func keccak256Data(_ data: Data) -> String {
    let hash = data.sha3(.keccak256)
    return "0x" + hash.map { String(format: "%02x", $0) }.joined()
}

public final class TorusWeb3Utils {

    public static func timeMinToSec(val: Double) -> Double {
        return val * 60
    }

    // NOTE: calculate wei by 10^18
    private static let etherInWei = pow(Double(10), 18)
    private static let etherInGwei = pow(Double(10), 9)

    /// Convert Wei(BInt) unit to Ether(Decimal) unit
    public static func toEther(wei: Wei) -> Ether {
        guard let decimalWei = Double(wei.description) else {
            return 0
        }
        return decimalWei / etherInWei
    }

    public static func toEther(Gwie: BigUInt) -> Ether {
        guard let decimalWei = Double(Gwie.description) else {
            return 0
        }
        return decimalWei / etherInGwei
    }

    /// Convert Ether(Decimal) unit to Wei(BInt) unit
    public static func toWei(ether: Ether) -> Wei {
        let wei = Wei(ether * etherInWei)
        return wei
    }

    /// Convert Ether(String) unit to Wei(BInt) unit
    public static func toWei(ether: String) -> Wei {
        guard let decimalEther = Double(ether) else {
            return 0
        }
        return toWei(ether: decimalEther)
    }

    // Only used for calcurating gas price and gas limit.
    public static func toWei(GWei: Double) -> Wei {
        return Wei(GWei * 1000000000)
    }

    public static func generateAddressFromPubKey(publicKeyX: String, publicKeyY: String) -> String {
        let publicKeyHex = "04" + publicKeyX.addLeading0sForLength64()  + publicKeyY.addLeading0sForLength64()
        let publicKeyData = Data(hexString: publicKeyHex)!

        do {
            let publicKey = try P256.KeyAgreement.PublicKey(x963Representation: publicKeyData)
            let publicKeyBytes = publicKey.rawRepresentation// .dropFirst().dropLast() // Remove the first byte (0x04)
            let ethAddressLower = "0x" + keccak256Data(publicKeyBytes).suffix(40)
            return ethAddressLower.toChecksumAddress()
        } catch {
            // Handle the error if necessary
            print("Failed to derive public key: \(error)")
            return ""
        }
    }

}
