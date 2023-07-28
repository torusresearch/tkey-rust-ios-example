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
    @State private var tss_modules: [String: TssModule] = [:]
    @State var showAlert: Bool = false
    @State private var selected_tag: String = ""

    func getTssModule ( tag: String ) throws -> TssModule {
        guard let tss =  tss_modules[tag] else {
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
                            let tag = "default"
                            let saveId = tag + ":" + "0"
                            // generate factor key
                            let factorKey = try PrivateKey.generate()
                            // set factor key into keychain
                            try KeychainInterface.save(item: factorKey.hex, key: saveId)
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
                                tss_modules[tag] = tss
                                print(tss_modules)

                            } catch {

                                print("error tss")
                            }
                        }
                    }) { Text("create new tagged tss") }
                }
            }
//            .onAppear {
//                Task {
//                    let allTags = try threshold_key.get_all_tss_tag()
//                    // instantate tssModule
//                    for tag in allTags {
//                        let tss = try await TssModule(threshold_key: threshold_key, tss_tag: tag)
//                        // add to state
//                        tss_modules[tag] = tss
//                    }
//                }
//            }

            if !tss_modules.isEmpty {
                Section(header: Text("Tss Module")) {
                    VStack {
                        ForEach(Array(tss_modules.keys), id: \.self) { key in
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
                            // get tss share using factor key
                            // sign transaction using tss client
                            let parties = 4
                            let msg = "hello world"
                            let msgHash = TSSHelpers.hashMessage(message: msg)
                            let clientIndex = Int32(parties-1)
                            let session = TSSHelpers.assembleFullSession(verifier: "", verifierId: "", tssTag: "", tssNonce: "", sessionNonce: "")
                            let sigs: [String] = []
                            let endpoints: [String?] = []
                            let socketEndpoints: [String?] = []
                            let partyIndexes: [Int32] = [0, 1, 2, 3]
                            let share = BigInt(1)
                            let userSharePublicKey = Data(BigInt(1).serialize().suffix(32))
                            let dkgPub = Data(BigInt(1).serialize().suffix(32))
                            let publicKey = try! TSSHelpers.getFinalTssPublicKey(dkgPubKey: dkgPub, userSharePubKey: userSharePublicKey, userTssIndex: BigInt(1))
                            let coeffs = try! TSSHelpers.getServerCoeffiecients(participatingServerDKGIndexes: [BigInt(1)], userTssIndex: BigInt(1), serverIndex: BigInt(1))

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
