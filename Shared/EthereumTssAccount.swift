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
import BigInt
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
    public let selectedTag: String
    public let verifier: String
    public let factorKey: String
    public let verifierID: String
    public let publicKey: String
    public let authSigs: [String]
    public let tssNonce: Int32
    public let tssShare: String
    public let tssIndex: String
    public let nodeIndexes: [Int]
    public let tssEndpoints: [String]
    public let address: EthereumAddress

    required public init(evmAddress: String, pubkey: String, factorKey: String, tssNonce: Int32, tssShare: String, tssIndex: String, selectedTag: String, verifier: String, verifierID: String, nodeIndexes: [Int], tssEndpoints: [String], authSigs: [String]) throws {
           self.factorKey = factorKey
           self.selectedTag = selectedTag
           self.verifier = verifier
           self.verifierID = verifierID
           self.publicKey = pubkey
           self.nodeIndexes = nodeIndexes
           self.tssEndpoints = tssEndpoints
           self.tssNonce = tssNonce
           self.tssIndex = tssIndex
           self.tssShare = tssShare
        self.address = EthereumAddress(evmAddress)
           self.authSigs = authSigs
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
                        // Create tss Client using helper
            let (client, coeffs) = try helperTssClient(selected_tag: self.selectedTag, tssNonce: self.tssNonce, publicKey: self.publicKey, tssShare: self.tssShare, tssIndex: self.tssIndex, nodeIndexes: self.nodeIndexes, factorKey: self.factorKey, verifier: self.verifier, verifierId: self.verifierID, tssEndpoints: self.tssEndpoints)

            // Wait for sockets to be connected
            let connected = try client.checkConnected()
            if !(connected) {
                throw EthereumSignerError.unknownError
            }

            let precompute = try client.precompute(serverCoeffs: coeffs, signatures: self.authSigs)

            let ready = try client.isReady()
            if !(ready) {
                throw EthereumSignerError.unknownError
            }

           guard let raw = transaction.raw else {
               throw EthereumSignerError.emptyRawTransaction
           }

            let msg = raw.web3.hexString
            let msgHash = TSSHelpers.hashMessage(message: msg)
            let (s, r, v) = try! client.sign(message: msgHash, hashOnly: true, original_message: msg, precompute: precompute, signatures: self.authSigs)

            /*
             If block.number >= FORK_BLKNUM and CHAIN_ID is available, then when computing the hash of a transaction for the purposes of signing, instead of hashing only six rlp encoded elements (nonce, gasprice, startgas, to, value, data), you SHOULD hash nine rlp encoded elements (nonce, gasprice, startgas, to, value, data, chainid, 0, 0). If you do, then the v of the signature MUST be set to {0,1} + CHAIN_ID * 2 + 35 where {0,1} is the parity of the y value of the curve point for which r is the x-value in the secp256k1 signing process. If you choose to only hash 6 values, then v continues to be set to {0,1} + 27 as previously.

             If block.number >= FORK_BLKNUM and v = CHAIN_ID * 2 + 35 or v = CHAIN_ID * 2 + 36, then when computing the hash of a transaction for purposes of recovering, instead of hashing six rlp encoded elements (nonce, gasprice, startgas, to, value, data), hash nine rlp encoded elements (nonce, gasprice, startgas, to, value, data, chainid, 0, 0). The currently existing signature scheme using v = 27 and v = 28 remains valid and continues to operate under the same rules as it did previously.
             */

            var modifiedV = v
            let chainId = UInt8(try transaction.chainId ?? { throw EthereumSignerError.unknownError }())
            if v <= 1 {
                modifiedV = v + chainId * 2 + 35
            }

            try! client.cleanup(signatures: self.authSigs)

            guard let signature = Data(hexString: try TSSHelpers.hexSignature(s: s, r: r, v: modifiedV)) else { throw EthereumSignerError.unknownError }

            return SignedTransaction(transaction: transaction, signature: signature)
       }
}
