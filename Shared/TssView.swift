import BigInt
import Foundation
import SwiftUI
import tkey_pkg
import tss_client_swift
import web3
import CryptoKit

func helperTssClient ( threshold_key: ThresholdKey, tssModule: TssModule, factorKey: String, verifier: String, verifierId: String, tssEndpoints: [String] ) async throws -> (TSSClient, [String: String]) {
    let selected_tag = try tssModule.get_tss_tag()
    let (tssIndex, tssShare) = try tssModule.get_tss_share(factorKey: factorKey)
    let tssNonce = try tssModule.get_tss_nonce()

    // generate a random nonce for sessionID
    let randomKey = BigUInt(SECP256K1.generatePrivateKey()!)
    let random = BigInt(sign: .plus, magnitude: randomKey) + BigInt(Date().timeIntervalSince1970)
    let sessionNonce = TSSHelpers.hashMessage(message: String(random))
    // create the full session string
    let session = TSSHelpers.assembleFullSession(verifier: verifier, verifierId: verifierId, tssTag: selected_tag, tssNonce: String(tssNonce), sessionNonce: sessionNonce)

    guard let tssPublicAddressInfo = try await threshold_key.serviceProvider?.getTssPubAddress(tssTag: selected_tag, nonce: String(tssNonce)) else {
        throw RuntimeError("Could not get tss public address info")
    }
    let nodeIndexes = tssPublicAddressInfo.nodeIndexes
    let userTssIndex = BigInt(tssIndex, radix: 16)!
    // total parties, including the client
    let parties = 4
    // index of the client, last index of partiesIndexes
    let clientIndex = Int32(parties - 1)

    let (urls, socketUrls, partyIndexes, nodeInd) = try TSSHelpers.generateEndpoints(parties: parties, clientIndex: Int(clientIndex), nodeIndexes: nodeIndexes, urls: tssEndpoints)

    let coeffs = try TSSHelpers.getServerCoefficients(participatingServerDKGIndexes: nodeInd.map({ BigInt($0) }), userTssIndex: userTssIndex)

    let shareUnsigned = BigUInt(tssShare, radix: 16)!
    let share = BigInt(sign: .plus, magnitude: shareUnsigned)

    let publicKey = try tssModule.get_tss_pub_key()
    let keypoint = try KeyPoint(address: publicKey)
    let fullAddress = try "04" + keypoint.getX() + keypoint.getY()

    let client = try TSSClient(session: session, index: Int32(clientIndex), parties: partyIndexes.map({Int32($0)}), endpoints: urls.map({ URL(string: $0 ?? "") }), tssSocketEndpoints: socketUrls.map({ URL(string: $0 ?? "") }), share: TSSHelpers.base64Share(share: share), pubKey: try TSSHelpers.base64PublicKey(pubKey: Data(hex: fullAddress)))

    return (client, coeffs)
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

    @State var clientIndex: Int32?
    @State var partyIndexes: [Int?] = []
    @State var session: String?
    @State var publicKey: Data?
    @State var share: BigInt?
    @State var socketUrls: [String?] = []
    @State var urls: [String?] = []
    @State var sigs: [String] = []
    @State var coeffs: [String: String] = [:]
    @State var signingData = false
    @State var sigHex = false
    @State var allFactorPub: [String] = []
    @State var tss_pub_key: String = ""

    func getTssModule(tag: String) throws -> TssModule {
        guard let tss = tssModules[tag] else {
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
                            let saveId = tag + ":0"
                            // generate factor key
                            let factorKey = try PrivateKey.generate()
                            // derive factor pub
                            let factorPub = try factorKey.toPublic()
                            // use input to create tag tss share
                            do {
                                print(try threshold_key.get_all_tss_tag())
                                let tss = try await TssModule(threshold_key: threshold_key, tss_tag: tag)
                                try tss.create_tagged_tss_share(deviceTssShare: nil, factorPub: factorPub, deviceTssIndex: 2)
                                tssModules[tag] = tss
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

        if tss_pub_key != "" {
            Text("Tss public key for " + selected_tag )
            Text(tss_pub_key)

            Section(header: Text("Tss : " + selected_tag + " : FactorPub")) {
                ForEach(Array(allFactorPub), id: \.self) { factorPub in
                    Text(factorPub)
                }
            }
        }

        if !tssModules.isEmpty {
            Section(header: Text("Tss Module")) {
                ForEach(Array(tssModules.keys), id: \.self) { key in
                    HStack {
                        Button(action: {
                            Task {
                                selected_tag = key
                                let tss = try getTssModule(tag: key)
                                tss_pub_key = try tss.get_tss_pub_key()
                                allFactorPub = try tss.get_all_factor_pub()
                                print(allFactorPub)
                            }
                        }) { Text(key) }
                    }
                }
            }
        }

        if !selected_tag.isEmpty {

            Section(header: Text("Tss : " + selected_tag)) {

                HStack {
                    Button(action: {
                        Task {
                            // show input popup for factor key input
                            // get factor key into keychain if input is empty
                            let saveId = selected_tag + ":" + "0"
                            let factorKey = try KeychainInterface.fetch(key: saveId)
                            // get tss share using factor key
                            let tss = try getTssModule(tag: selected_tag)
                            let (tssIndex, tssShare) = try tss.get_tss_share(factorKey: factorKey)
                            print("tssIndex:" + tssIndex)
                            print("tssShare:" + tssShare)
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
                            guard (alert?.textFields?.first) != nil else { return }
                            Task {
                                do {
                                    let checkSaveId = selected_tag + ":" + "1"
                                    let checkFactorKey = try KeychainInterface.fetch(key: checkSaveId )
                                    if checkFactorKey != "" {
                                        alertContent = "There is existing backup Factor Key"
                                        showAlert = true
                                        return
                                    }
                                } catch {}
                                // generate factor key if input is empty
                                // derive factor pub
                                let newFactorKey = try PrivateKey.generate()
                                let newFactorPub = try newFactorKey.toPublic()

                                // use input to generate tss share with index 3
                                let saveId = selected_tag + ":" + "0"
                                let factorKey = try KeychainInterface.fetch(key: saveId )
                                let tss = try getTssModule(tag: selected_tag)
                                let tssShareIndex = Int32(3)
                                let sigs: [String] = try signatures.map { String(decoding: try JSONSerialization.data(withJSONObject: $0), as: UTF8.self) }
                                try await tss.add_factor_pub(factor_key: factorKey, auth_signatures: sigs, new_factor_pub: newFactorPub, new_tss_index: tssShareIndex )

                                let saveNewFactorId = selected_tag + ":" + "1"
                                try KeychainInterface.save(item: newFactorKey.hex, key: saveNewFactorId)
                                // show factor key used

                                let (newTssIndex, newTssShare) = try tss.get_tss_share(factorKey: newFactorKey.hex)
                                alertContent = "tssIndex:" + newTssIndex + "\n" + "tssShare:" + newTssShare + "\n" + "newFactorKey" + newFactorKey.hex
                                showAlert = true
                            }
                        }))

                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            windowScene.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                        }
                    }) { Text( selected_tag + " : add factor pub") }
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
                            guard (alert?.textFields?.first) != nil else { return }
                            Task {
                                do {
                                    let checkSaveId = selected_tag + ":" + "2"
                                    let checkFactorKey = try KeychainInterface.fetch(key: checkSaveId )
                                    if checkFactorKey != "" {
                                        alertContent = "There is existing copied Factor Key"
                                        showAlert = true
                                        return
                                    }
                                } catch {}
                                // generate factor key if input is empty
                                // derive factor pub
                                let newFactorKey = try PrivateKey.generate()
                                let newFactorPub = try newFactorKey.toPublic()

                                // get existing factor key
                                let saveId = selected_tag + ":" + "0"
                                let factorKey = try KeychainInterface.fetch(key: saveId )
                                // use input to generate tss share with index 3
                                let tss = try getTssModule(tag: selected_tag)
                                let tssShareIndex = Int32(2)
                                try tss.copy_factor_pub(factorKey: factorKey, newFactorPub: newFactorPub, tss_index: tssShareIndex)

                                let saveNewFactorId = selected_tag + ":" + "2"
                                try KeychainInterface.save(item: newFactorKey.hex, key: saveNewFactorId)
                                // show factor key used

                                let (newTssIndex, newTssShare) = try tss.get_tss_share(factorKey: newFactorKey.hex)
                                alertContent = "tssIndex:" + newTssIndex + "\n" + "tssShare:" + newTssShare + "\n" + "newFactorKey" + newFactorKey.hex
                                showAlert = true
                                // copy factor pub
                            }
                        }))
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                          windowScene.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                        }
                    }) { Text( selected_tag + " : copy factor pub") }
                }.alert(isPresented: $showAlert) {
                    Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                }

                HStack {
                    Button(action: {
                        Task {
                            // get factor key from keychain if input is empty

                            var deleteFactorKey: String?
                            var targetSaveId = selected_tag + ":" + "1"
                            do {
                                deleteFactorKey = try KeychainInterface.fetch(key: targetSaveId )
                                if deleteFactorKey == "" {
                                    throw RuntimeError("")
                                }
                            } catch {
                                do {
                                    targetSaveId = selected_tag + ":" + "2"
                                    deleteFactorKey = try KeychainInterface.fetch(key: targetSaveId )
                                } catch {
                                    alertContent = "There is no extra factor key to be deleted"
                                    showAlert = true
                                    return
                                }
                            }
                            guard let deleteFactorKey = deleteFactorKey else {
                                alertContent = "There is no extra factor key to be deleted"
                                showAlert = true
                                return
                            }
                            if deleteFactorKey == "" {
                                alertContent = "There is no extra factor key to be deleted"
                                showAlert = true
                                return
                            }

                            // delete factor pub
                            let deleteFactorPK = PrivateKey(hex: deleteFactorKey)

                            let saveId = selected_tag + ":" + "0"
                            let factorKey = try KeychainInterface.fetch(key: saveId )

                            let tss = try getTssModule(tag: selected_tag)
                            let sigs: [String] = try signatures.map { String(decoding: try JSONSerialization.data(withJSONObject: $0), as: UTF8.self) }
                            try await tss.delete_factor_pub(factor_key: factorKey, auth_signatures: sigs, delete_factor_pub: deleteFactorPK.toPublic())
                            print("done delete factor pub")
                            try KeychainInterface.save(item: "", key: targetSaveId)

                            alertContent = "deleted factor key :" + deleteFactorKey
                            showAlert = true
                        }
                    }) { Text( selected_tag + " : delete factor pub") }
                }.alert(isPresented: $showAlert) {
                    Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                }
            }
        }
        Button(action: {
            Task {

                do {
                    let sigs: [String] = try signatures.map { String(decoding: try JSONSerialization.data(withJSONObject: $0), as: UTF8.self) }
                    // get the factor key information

                    let factorKey = try KeychainInterface.fetch(key: selected_tag + ":0")
                    // Create tss Client using helper
                    let (client, coeffs) = try await helperTssClient(threshold_key: threshold_key, tssModule: getTssModule(tag: selected_tag), factorKey: factorKey, verifier: verifier, verifierId: verifierId, tssEndpoints: tssEndpoints)

                    // wait for sockets to connect
                    var connected = false
                    while !connected {
                        connected = try client.checkConnected()
                    }

                    // Create a precompute, each server also creates a precompute.
                    // This calls setup() followed by precompute() for all parties
                    // If meesages cannot be exchanged by all parties, between all parties, this will fail, since it will timeout waiting for socket messages.
                    // This will also fail if a single failure notification is received.
                    // ~puid_seed is the first message set exchanged, ~checkpt123_raw is the last message set exchanged.
                    // Once ~checkpt123_raw is received, precompute_complete notifications should be received shortly thereafter.
                    let precompute = try client.precompute(serverCoeffs: coeffs, signatures: sigs)

                    while !(try client.isReady()) {
                        // no-op
                    }

                    // hash a message
                    let msg = "hello world"
                    let msgHash = TSSHelpers.hashMessage(message: msg)

                    // signs a hashed message, collecting signature fragments from the servers
                    // this function signs locally to produce its' own fragment
                    // this is combined with the server fragments
                    // local_verify is then used with the client precompute to produce a full signature and return the components
                    let (s, r, v) = try client.sign(message: msgHash, hashOnly: true, original_message: msg, precompute: precompute, signatures: sigs)

                    // cleanup sockets
                    try client.cleanup(signatures: sigs)

                    // verify the signature
                    let tss = try getTssModule(tag: selected_tag)
                    let publicKey = try tss.get_tss_pub_key()
                    let keypoint = try KeyPoint(address: publicKey)
                    let fullAddress = try "04" + keypoint.getX() + keypoint.getY()

                    if TSSHelpers.verifySignature(msgHash: msgHash, s: s, r: r, v: v, pubKey: Data(hex: fullAddress)) {
                        let sigHex = try TSSHelpers.hexSignature(s: s, r: r, v: v)
                        alertContent = "Signature: " + sigHex
                        showAlert = true
                        print(try TSSHelpers.hexSignature(s: s, r: r, v: v))
                    } else {
                        alertContent = "Signature could not be verified"
                        showAlert = true
                    }
                } catch {
                    alertContent = "Signing could not be completed. please try again"
                    showAlert = true
                }
            }
        }) { Text("Sign") }// .disabled( !signingData )
    }
}
