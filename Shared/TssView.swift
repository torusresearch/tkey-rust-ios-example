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

// export function generateEndpoints(parties: number, clientIndex: number, network: TORUS_SAPPHIRE_NETWORK_TYPE, nodeIndexes: number[] = []) {
//  console.log("generateEndpoints node indexes", nodeIndexes);
//  const networkConfig = fetchLocalConfig(network);
//  const endpoints = [];
//  const tssWSEndpoints = [];
//  const partyIndexes = [];
//
//  for (let i = 0; i < parties; i++) {
//    partyIndexes.push(i);
//
//    if (i === clientIndex) {
//      endpoints.push(null);
//      tssWSEndpoints.push(null);
//    } else {
//      endpoints.push(networkConfig.torusNodeTSSEndpoints[nodeIndexes[i] ?  nodeIndexes[i] - 1 : i]);
//      let wsEndpoint = networkConfig.torusNodeEndpoints[nodeIndexes[i] ? nodeIndexes[i] - 1 : i]
//      if (wsEndpoint) {
//        const urlObject = new URL(wsEndpoint);
//        wsEndpoint = urlObject.origin;
//      }
//      tssWSEndpoints.push(wsEndpoint);
//    }
//  }
//
//  return {
//    endpoints: endpoints,
//    tssWSEndpoints: tssWSEndpoints,
//    partyIndexes: partyIndexes
//  };
// }

// endpoint [ a, b, c, d, e ]
// 2,3,4

func selectEndpoints( endpoints: [String], nodeIndexes: [Int32]) -> ([String?], [String?], [Int32], [Int32] ) {
    let threshold = Int( endpoints.count / 2 ) + 1

    var selected: [String?] = []
    var socket: [String?] = []
    var partiesIndexes: [Int32] = []
    var nodeIndexesReturn: [Int32] = []

    if !nodeIndexes.isEmpty {
        for i in 0..<nodeIndexes.count {
            selected.append(endpoints[i])
            socket.append(endpoints[i].replacingOccurrences(of: "/tss", with: ""))
            partiesIndexes.append( Int32(i) )
        }
        socket.append(nil)
        selected.append(nil)
        partiesIndexes.append(Int32(nodeIndexes.count))
        return (selected, socket, partiesIndexes, nodeIndexes)
    }

    for i in 0..<threshold {
        selected.append(endpoints[i])
        socket.append(endpoints[i].replacingOccurrences(of: "/tss", with: ""))
        partiesIndexes.append(Int32(i))
        nodeIndexesReturn.append(Int32( i + 1 ))
    }
    socket.append(nil)
    selected.append(nil)
    partiesIndexes.append(Int32( threshold ))
    return (selected, socket, partiesIndexes, nodeIndexesReturn)
}

struct TssView: View {
    @Binding var threshold_key: ThresholdKey!
    @Binding var verifier: String!
    @Binding var verifierId: String!
    @Binding var signatures: [[String: Any]]!
    @Binding var tssEndpoints: [String]!
    @Binding var showTss: Bool

    @State var tssModules: [String: TssModule] = [:]
    @State var showAlert: Bool = false
    @State private var selected_tag: String = ""
    @State private var alertContent = ""

    func getTssModule ( tag: String ) throws -> TssModule {
        guard let tss =  tssModules[tag] else {
            throw RuntimeError("tss not found")
        }
        return tss
    }
    var body: some View {
            Button(action: {
                Task {
                    showTss = false
                }
            }) { Text("TKey Demo") }

            Section(header: Text("Tss Module")) {
                HStack {

                    Button(action: {
                        print("enter")
                        // show input popup
                        let alert = UIAlertController(title: "Enter New Tss Tag", message: nil, preferredStyle: .alert)
                        alert.addTextField { textField in
                            textField.placeholder = "New Tag"
                        }
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] _ in
                            guard let textField = alert?.textFields?.first else { return }
                            Task {
                                let tag = textField.text ?? "default"
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

                                    alertContent = factorKey.hex
                                } catch {
                                    print("error tss")
                                }
                            }
                        }))

                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            windowScene.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                        }
                    }) { Text("create new tagged tss") }
                }
            }.onAppear {
                Task {
                    let allTags = try threshold_key.get_all_tss_tag()
                    // instantate tssModule
                    for tag in allTags {
                        let tss = try await TssModule(threshold_key: threshold_key, tss_tag: tag)
                        // add to state
                        tssModules[tag] = tss
                    }
                }
            }.alert(isPresented: $showAlert) {
                Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
            }

            if !tssModules.isEmpty {
                Section(header: Text("Tss Module")) {
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

        if !selected_tag.isEmpty {
            Section(header: Text("Tss : " + selected_tag ) ) {
                HStack {
                    Button(action: {
                        Task {
                            // show input popup for factor key input
                            // get factor key into keychain if input is empty
                            let saveId = selected_tag + ":" + "0"
                            let factorKey = try KeychainInterface.fetch(key: saveId )
                            // get tss share using factor key
                            let tss = try getTssModule(tag: selected_tag)
                            let (tssIndex, tssShare) = try tss.get_tss_share(factorKey: factorKey)
                            print( "tssIndex:" + tssIndex)
                            print( "tssShare:" + tssShare)
                            alertContent = "tssIndex:" + tssIndex + "\n" + "tssShare:" + tssShare
                            showAlert = true
                        }
                    }) { Text(selected_tag + " :get tss share") }
                }.alert(isPresented: $showAlert) {
                    Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                }

                HStack {
                    Button(action: {
                        // show input popup
                        let alert = UIAlertController(title: "Key in Factor Key or randomly generated if left empty", message: nil, preferredStyle: .alert)
                        alert.addTextField { textField in
                            textField.placeholder = "Factor Key"
                        }
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] _ in
                            guard let textField = alert?.textFields?.first else { return }
                            Task {
                                // generate factor key if input is empty
                                // derive factor pub
                                // use input to generate tss share with index 3
                                // show factor key used
                            }
                        }))

                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                          windowScene.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                        }
                    }) { Text( selected_tag + " : add factor pub") }
                }
                HStack {
                    Button(action: {
                        Task {
                            // show input popup for factor key input
                            // get factor key from keychain
                            // copy factor pub
                        }
                    }) { Text( selected_tag + " : copy factor pub") }
                }
                HStack {
                    Button(action: {
                        Task {
                            // show input popup for factor pub input
                            // get factor key into keychain if input is empty
                            // delete factor pub
                        }
                    }) { Text( selected_tag + " : delete factor pub") }
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

                            guard let dkgPubkey = result?.publicKey.toFullAddr() else {
                                throw RuntimeError("invalid dkgpubkey")
                            }
                            let nodeIndexes = result!.nodeIndexes.map { index in
                                return BigInt(index)
                            }
                            let nodeIndexesI32 = result!.nodeIndexes.map { index in
                                return Int32(index)
                            }

                            let randomKey = BigUInt(SECP256K1.generatePrivateKey()!)
                            let random = BigInt(sign: .plus, magnitude: randomKey) + BigInt(Date().timeIntervalSince1970)
                            let sessionNonce = TSSHelpers.hashMessage(message: String(random))

                            // sign transaction using tss client
                            let msg = "hello world"
                            let msgHash = TSSHelpers.hashMessage(message: msg)
                            let session = TSSHelpers.assembleFullSession(verifier: verifier, verifierId: verifierId, tssTag: selected_tag, tssNonce: nonce, sessionNonce: sessionNonce)

                            print(signatures)
                            let sigs: [String] = try signatures.map { String(decoding: try JSONSerialization.data(withJSONObject: $0), as: UTF8.self) }

                            print(tssEndpoints)
                            print(nodeIndexesI32)
                            let (urls, socketUrls, partyIndexes, nodeIndexesReturn) = selectEndpoints(endpoints: tssEndpoints, nodeIndexes: nodeIndexesI32)
                            print(urls)
                            print(socketUrls)
                            print(partyIndexes)

                            let parties = partyIndexes.count
                            let clientIndex = Int32(parties-1)

                            let endpoints: [String?] = urls
                            let socketEndpoints: [String?] = socketUrls

                            let share = BigInt(tssShare, radix: 16)!
                            let userPublicHex = try! PrivateKey(hex: tssShare).toPublic()

                            let dkgPub =  try! KeyPoint(address: dkgPubkey).getAsCompressedPublicKey(format: "elliptic-compressed")
                            let userSharePublicKey = try! KeyPoint(address: userPublicHex).getAsCompressedPublicKey(format: "elliptic-comprezssed")

                            let publicKey = try! TSSHelpers.getFinalTssPublicKey(dkgPubKey: Data(hexString: dkgPub)!, userSharePubKey: Data(hexString: userSharePublicKey)!, userTssIndex: userTssIndex) //

                            print(userTssIndex)
                            print(nodeIndexesReturn)
                            let coeffs = try! TSSHelpers.getServerCoefficients(participatingServerDKGIndexes: nodeIndexesReturn.map { BigInt($0) }, userTssIndex: userTssIndex)
                            print(coeffs)
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
                    }) { Text( selected_tag + ": sign with " + selected_tag + " tss share") }
                }
            }
        }
        }

}
