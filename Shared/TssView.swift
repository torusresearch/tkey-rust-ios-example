//
//  TssView.swift
//  tkey_ios
//
//  Created by CW Lee on 28/07/2023.
//

import Foundation
import SwiftUI
import BigInt
import tkey_pkg
import tss_client_swift

struct TssView: View {
    @Binding var threshold_key: ThresholdKey!
    @Binding var verifier: String!
    @Binding var verifierId: String!
    @Binding var signatures: [String]!
    @Binding var tssEndpoints: [String]!

    @State var tssModules: [String: TssModule] = [:]
    @State var showAlert: Bool = false
    @State private var selected_tag: String = ""

    func getTssModule ( tag: String ) throws -> TssModule {
        guard let tss =  tssModules[tag] else {
            throw RuntimeError("tss not found")
        }
        return tss
    }
    var body: some View {

            Section(header: Text("Tss Module")) {
                HStack {

                    Button(action: {
                        Task {
                            print("enter")
                            // show input popup
                            let tag = "default1"
                            let saveId = tag + ":" + "0"
                            // generate factor key
                            let factorKey = try PrivateKey.generate()
                            // derive factor pub
                            let factorPub = try factorKey.toPublic()
                            print("enter 2")
                            // use input to create tag tss share
                            do {
                                print(try threshold_key.get_all_tss_tag())
                                let tss = try await TssModule( threshold_key: threshold_key, tss_tag: tag)

                                print("enter 3")
                                try tss.create_tagged_tss_share(deviceTssShare: nil, factorPub: factorPub, deviceTssIndex: 2)
                                print("enter 4")
                                tssModules[tag] = tss
                                print(tssModules)
                                // set factor key into keychain
                                try KeychainInterface.save(item: factorKey.hex, key: saveId)

                            } catch {

                                print("error tss")
                            }
                        }
                    }) { Text("create new tagged tss") }
                }
            }.onAppear {
                Task {
                    let allTags = try threshold_key.get_all_tss_tag()
                    print("get all tags ===========================")
                    print(allTags)
                    // instantate tssModule
                    for tag in allTags {
                        let tss = try await TssModule(threshold_key: threshold_key, tss_tag: tag)
                        // add to state
                        tssModules[tag] = tss
                    }
                }
            }

            if !tssModules.isEmpty {
                Section(header: Text("Tss Module")) {
                    VStack {
                        ForEach(Array(tssModules.keys), id: \.self) { key in
                            HStack {
                                Button(action: {
                                    Task {
                                        selected_tag = key
                                    }
                                }) { Text(key) }
                            }
                        }
                    }
                }
            }

        if !selected_tag.isEmpty {
            Section(header: Text("Tss : " + selected_tag ) ) {
                HStack {
                    Button(action: {
                        Task {
                            // show input popup for factor key input
                            // get factor key into keychain if input is empty
                            // get tss share using factor key
                        }
                    }) { Text("get tss share") }
                }
                HStack {
                    Button(action: {
                        Task {
                            // show input popup
                            // generate factor key if input is empty
                            // derive factor pub
                            // use input to generate tss share with index 3
                            // show factor key used
                        }
                    }) { Text("add factor pub") }
                }
                HStack {
                    Button(action: {
                        Task {
                            // show input popup for factor key input
                            // get factor key from keychain
                            // copy factor pub
                        }
                    }) { Text("copy factor pub") }
                }
                HStack {
                    Button(action: {
                        Task {
                            // show input popup for factor pub input
                            // get factor key into keychain if input is empty
                            // delete factor pub
                        }
                    }) { Text("delete factor pub") }
                }
                HStack {
                    Button(action: {
                        Task {
                            // get factor key from keychain
                            let factorKey = try KeychainInterface.fetch(key: selected_tag + ":0")
                            // get tss share using factor key
                            let tss = try getTssModule(tag: selected_tag)
                            let (tssIndex, tssShare) = try tss.get_tss_share(factorKey: factorKey)

                            let userTssIndex = BigInt(tssIndex, radix: 16)!

                            let nonce = String( try tss.get_tss_nonce() )
                            let result = try await threshold_key.serviceProvider?.getTssPubAddress(tssTag: selected_tag, nonce: nonce)

                            guard let dkgpubkey = result?.publicKey else {
                                throw RuntimeError("invalid dkgpubkey")
                            }
                            let nodeIndexes = result!.nodeIndexes.map { index in
                                return BigInt(index)
                            }
                            let sessionNonce = "1134134"

                            // sign transaction using tss client
                            let parties = 4
                            let msg = "hello world"
                            let msgHash = TSSHelpers.hashMessage(message: msg)
                            let clientIndex = Int32(parties-1)
                            let session = TSSHelpers.assembleFullSession(verifier: verifier, verifierId: verifierId, tssTag: selected_tag, tssNonce: nonce, sessionNonce: sessionNonce)
                            let sigs: [String] = [] // signature
                            let endpoints: [String?] = [] // tss endpoint
                            let socketEndpoints: [String?] = [] // tss endpoint
                            let partyIndexes: [Int32] = [0, 1, 2, 3]
                            let share = BigInt(1) // userShare
                            let userSharePublicKey = Data(hex: tssShare)!

                            let dkgPub = Data(BigInt(1).serialize().suffix(32)) // @ check
                            let publicKey = try! TSSHelpers.getFinalTssPublicKey(dkgPubKey: dkgPub, userSharePubKey: userSharePublicKey, userTssIndex: userTssIndex) //
                            let coeffs = try! TSSHelpers.getServerCoefficients(participatingServerDKGIndexes: nodeIndexes, userTssIndex: userTssIndex)

                            let client = try! TSSClient(session: session, index: clientIndex, parties: partyIndexes, endpoints: endpoints.map({ URL(string: $0 ?? "") }), tssSocketEndpoints: socketEndpoints.map({ URL(string: $0 ?? "") }), share: TSSHelpers.base64Share(share: share), pubKey: try TSSHelpers.base64PublicKey(pubKey: publicKey))
                            while !client.checkConnected() {

                            }

                            let precompute = try! client.precompute(serverCoeffs: coeffs, signatures: sigs)
                            while !(try! client.isReady()) {

                            }
                            let (s, r, v) = try! client.sign(message: msgHash, hashOnly: true, original_message: msg, precompute: precompute, signatures: sigs)
                            try! client.cleanup(signatures: sigs)
                            if TSSHelpers.verifySignature(msgHash: msgHash, s: s, r: r, v: v, pubKey: publicKey) {
                                showAlert = true
                            } else {
                                exit(EXIT_FAILURE)
                            }
                        }
                    }) { Text("sign with tagged tss share") }
                }
            }
        }
        }

}
