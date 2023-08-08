//
//  EthereumTssAccount.swift
//  tkey_ios
//
//  Created by himanshu on 09/08/23.
//

import Foundation
import web3
import secp256k1
import tss_client_swift
import CryptoKit
import tkey_pkg

public enum CustomError: Error {
    case unknownError
    case methodUnavailable

    public var errorDescription: String {
        switch self {
        case .unknownError:
            return "unknownError"
        case .methodUnavailable:
            return "method unavailable/unimplemented"
        }
    }
}

enum EthereumSignerError: Error {
    case emptyRawTransaction
    case unknownError
}


public class EthereumTssAccount: EthereumAccountProtocol {
    public let tssClient: TSSClient
    public let publicKey: String;
    public let authSigs: [String]
    public let address: EthereumAddress;
    public let precompute: Precompute

    required public init(pubkey: String, tssClient: TSSClient, authSigs: [String], precompute: Precompute) throws {
           self.tssClient = tssClient
           self.precompute = precompute
           self.publicKey = pubkey
           let pubKeyHash = Data(pubkey.utf8).sha3(.keccak256)
           let address = pubKeyHash.subdata(in: 12 ..< pubKeyHash.count)
           self.address = EthereumAddress(address.hexString)
           self.authSigs = authSigs
           print("address", address.hexString, self.address.value)
       }

       public func sign(data: Data) throws -> Data {
           throw CustomError.methodUnavailable
       }

       public func sign(hex: String) throws -> Data {
           throw CustomError.methodUnavailable
       }

       public func sign(hash: String) throws -> Data {
           throw CustomError.methodUnavailable
       }

       public func sign(message: Data) throws -> Data {
           throw CustomError.methodUnavailable
       }

       public func sign(message: String) throws -> Data {
           throw CustomError.methodUnavailable
       }

       public func signMessage(message: Data) throws -> String {
           throw CustomError.methodUnavailable
       }

       public func signMessage(message: TypedData) throws -> String {
           throw CustomError.methodUnavailable
       }
    
    
        public func sign(transaction: EthereumTransaction) throws -> SignedTransaction {
           guard let raw = transaction.raw else {
               throw EthereumSignerError.emptyRawTransaction
           }
            
            let msg = raw.web3.hexString
            guard let msgHash = transaction.hash?.toHexString() else {
                throw RuntimeError("Could not get tx hash")
            }
            let (s, r, v) = try! self.tssClient.sign(message: msgHash, hashOnly: true, original_message: msg, precompute: self.precompute, signatures: self.authSigs)

            let encodedR = RLP.encodeBigInt(r)!
            let encodedS = RLP.encodeBigInt(s)!
            return SignedTransaction(transaction: transaction, v: Int(v), r: encodedR , s: encodedS)
       }
}
