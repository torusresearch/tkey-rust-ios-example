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
           print("address", evmAddress, self.address.value)
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
            var connected = false
            while !connected {
                connected = try client.checkConnected()
            }

            let precompute = try client.precompute(serverCoeffs: coeffs, signatures: self.authSigs)

            while !(try client.isReady()) {
                // no-op
            }

           guard let raw = transaction.raw else {
               throw EthereumSignerError.emptyRawTransaction
           }

            let msg = raw.web3.hexString
            let msgHash = TSSHelpers.hashMessage(message: msg)
            let (s, r, v) = try! client.sign(message: msgHash, hashOnly: true, original_message: msg, precompute: precompute, signatures: self.authSigs)

            var modifiedV = v
            if modifiedV <= 1 {
               modifiedV = modifiedV + 27
            }

            var modifiedR = r
            modifiedR = r.modulus(TSSClient.modulusValueSigned)
            try! client.cleanup(signatures: self.authSigs)

            let encodedR = RLP.encodeBigInt(modifiedR)!
            let encodedS = RLP.encodeBigInt(s)!
            let rSerialized = BigUInt(r)
            print("r val", rSerialized.serialize(),       r.magnitude.serialize(), r.serialize().hexString, s.magnitude.serialize(), s.serialize().hexString)
            return SignedTransaction(transaction: transaction, v: Int(modifiedV), r: encodedR, s: encodedS)
       }
}
