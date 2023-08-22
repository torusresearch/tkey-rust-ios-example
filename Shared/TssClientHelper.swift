import BigInt
import Foundation
import SwiftUI
import tkey_pkg
import tss_client_swift
import web3

public func helperTssClient (selected_tag: String, tssNonce: Int32, publicKey: String, tssShare: String, tssIndex: String, nodeIndexes: [Int], factorKey: String, verifier: String, verifierId: String, tssEndpoints: [String] ) throws -> (TSSClient, [String: String]) {

    // generate a random nonce for sessionID
    let randomKey = BigUInt(SECP256K1.generatePrivateKey()!)
    let random = BigInt(sign: .plus, magnitude: randomKey) + BigInt(Date().timeIntervalSince1970)
    let sessionNonce = TSSHelpers.hashMessage(message: String(random))
    // create the full session string
    let session = TSSHelpers.assembleFullSession(verifier: verifier, verifierId: verifierId, tssTag: selected_tag, tssNonce: String(tssNonce), sessionNonce: sessionNonce)

    let userTssIndex = BigInt(tssIndex, radix: 16)!
    // total parties, including the client
    let parties = 4
    // index of the client, last index of partiesIndexes
    let clientIndex = Int32(parties - 1)

    let (urls, socketUrls, partyIndexes, nodeInd) = try TSSHelpers.generateEndpoints(parties: parties, clientIndex: Int(clientIndex), nodeIndexes: nodeIndexes, urls: tssEndpoints)

    let coeffs = try TSSHelpers.getServerCoefficients(participatingServerDKGIndexes: nodeInd.map({ BigInt($0) }), userTssIndex: userTssIndex)

    let shareUnsigned = BigUInt(tssShare, radix: 16)!
    let share = BigInt(sign: .plus, magnitude: shareUnsigned)

    let uncompressedPubKey = try KeyPoint(address: publicKey).getPublicKey(format: PublicKeyEncoding.FullAddress)

    let client = try TSSClient(session: session, index: Int32(clientIndex), parties: partyIndexes.map({Int32($0)}), endpoints: urls.map({ URL(string: $0 ?? "") }), tssSocketEndpoints: socketUrls.map({ URL(string: $0 ?? "") }), share: TSSHelpers.base64Share(share: share), pubKey: try TSSHelpers.base64PublicKey(pubKey: Data(hex: uncompressedPubKey)))

    return (client, coeffs)
 }
