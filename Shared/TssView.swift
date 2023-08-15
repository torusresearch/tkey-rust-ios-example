import BigInt
import CommonSources
import CryptoKit
import FetchNodeDetails
import Foundation
import SwiftUI
import tkey_pkg
import TorusUtils
import tss_client_swift
import web3

func helperTssClient(threshold_key: ThresholdKey, factorKey: String, verifier: String, verifierId: String, tssEndpoints: [String], nodeDetails: AllNodeDetailsModel, torusUtils: TorusUtils) async throws -> (TSSClient, [String: String]) {
    let selected_tag = try TssModule.get_tss_tag(threshold_key: threshold_key)
    let (tssIndex, tssShare) = try await TssModule.get_tss_share(threshold_key: threshold_key, tss_tag: selected_tag, factorKey: factorKey)
    let tssNonce = try TssModule.get_tss_nonce(threshold_key: threshold_key, tss_tag: selected_tag)

    // generate a random nonce for sessionID
    let randomKey = BigUInt(tss_client_swift.SECP256K1.generatePrivateKey()!)
    let random = BigInt(sign: .plus, magnitude: randomKey) + BigInt(Date().timeIntervalSince1970)
    let sessionNonce = TSSHelpers.hashMessage(message: String(random))
    // create the full session string
    let session = TSSHelpers.assembleFullSession(verifier: verifier, verifierId: verifierId, tssTag: selected_tag, tssNonce: String(tssNonce), sessionNonce: sessionNonce)
    let tssPublicAddressInfo = try await TssModule.get_dkg_pub_key(threshold_key: threshold_key, tssTag: selected_tag, nonce: String(tssNonce), nodeDetails: nodeDetails, torusUtils: torusUtils)
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

    let publicKey = try await TssModule.get_tss_pub_key(threshold_key: threshold_key, tss_tag: selected_tag)
    let keypoint = try KeyPoint(address: publicKey)
    let fullAddress = try "04" + keypoint.getX() + keypoint.getY()

    let client = try TSSClient(session: session, index: Int32(clientIndex), parties: partyIndexes.map({ Int32($0) }), endpoints: urls.map({ URL(string: $0 ?? "") }), tssSocketEndpoints: socketUrls.map({ URL(string: $0 ?? "") }), share: TSSHelpers.base64Share(share: share), pubKey: try TSSHelpers.base64PublicKey(pubKey: Data(hex: fullAddress)))

    return (client, coeffs)
}

struct TssView: View {
    @Binding var threshold_key: ThresholdKey!
    @Binding var verifier: String!
    @Binding var verifierId: String!
    @Binding var signatures: [[String: Any]]!
    @Binding var tssEndpoints: [String]!
    @Binding var showTss: Bool
    @Binding var nodeDetails: AllNodeDetailsModel?
    @Binding var torusUtils: TorusUtils?
    @Binding var metadataPublicKey: String
    @Binding var deviceFactorPub: String

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

    @State var showSpinner = false

    func updateTag ( key: String) {
        Task {
            selected_tag = key
            tss_pub_key = try await TssModule.get_tss_pub_key(threshold_key: threshold_key, tss_tag: selected_tag)
            allFactorPub = try await TssModule.get_all_factor_pub(threshold_key: threshold_key, tss_tag: selected_tag)
            print(allFactorPub)
            signingData = true
        }
    }

    var body: some View {
        Section(header: Text("TSS Example")) {
            Button(action: {
                Task {
                    showTss = false
                }
            }) { Text("Home") }
        }.onAppear {
            updateTag(key: "default")
        }

//        Section(header: Text("Tss Module")) {
//            HStack {
//                Button(action: {
//                    // show input popup
//                    let alert = UIAlertController(title: "Enter New Tss Tag", message: nil, preferredStyle: .alert)
//                    alert.addTextField { textField in
//                        textField.placeholder = "New Tag"
//                    }
//                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] _ in
//                        guard let textField = alert?.textFields?.first else { return }
//                        Task {
//                            let tag = textField.text ?? "default"
//                            let saveId = tag + ":0"
//                            // generate factor key
//                            let factorKey = try PrivateKey.generate()
//                            // derive factor pub
//                            let factorPub = try factorKey.toPublic()
//                            // use input to create tag tss share
//                            do {
//                                print(try threshold_key.get_all_tss_tags())
//                                try await TssModule.create_tagged_tss_share(threshold_key: self.threshold_key, tss_tag: tag, deviceTssShare: nil, factorPub: factorPub, deviceTssIndex: 2, nodeDetails: self.nodeDetails!, torusUtils: self.torusUtils!)
//                                // set factor key into keychain
//                                try KeychainInterface.save(item: factorKey.hex, key: saveId)
//                                alertContent = factorKey.hex
//                            } catch {
//                                print("error tss")
//                            }
//                        }
//                    }))
//
//                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
//                        windowScene.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
//                    }
//                }) { Text("create new tagged tss") }
//            }
//        }.alert(isPresented: $showAlert) {
//            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
//        }

        let tss_tags = try! threshold_key.get_all_tss_tags()
        

//        if !tss_tags.isEmpty {
//            Section(header: Text("TSS Tag")) {
//                ForEach(tss_tags, id: \.self) { key in
//                    HStack {
//                        Button(action: {
//                            Task {
//                                selected_tag = key
//                                tss_pub_key = try await TssModule.get_tss_pub_key(threshold_key: threshold_key, tss_tag: selected_tag)
//                                allFactorPub = try await TssModule.get_all_factor_pub(threshold_key: threshold_key, tss_tag: selected_tag)
//                                print(allFactorPub)
//                                signingData = true
//                            }
//                        }) { Text(key) }
//                    }
//                }
//            }
//        }

        if tss_pub_key != "" {
            Text("Tss public key for " + selected_tag)
            Text(tss_pub_key)

            Section(header: Text("Tss : " + selected_tag + " : Factors")) {
                ForEach(Array(allFactorPub), id: \.self) { factorPub in
                    Text(factorPub)
                }
            }
        }

        if !selected_tag.isEmpty {
            Section(header: Text("TSS : " + selected_tag)) {
                HStack {
                    if showSpinner {
                        LoaderView()
                    }
                    Button(action: {

                            Task {
                                showSpinner = true
                                // generate factor key if input is empty
                                // derive factor pub
                                let newFactorKey = try PrivateKey.generate()
                                let newFactorPub = try newFactorKey.toPublic()

                                // use exising factor to generate tss share with index 3 with new factor
                                let fetchId = metadataPublicKey + ":" + selected_tag + ":" + "0"
                                let factorKey = try KeychainInterface.fetch(key: fetchId)

                                // for now only tss index 2 and index 3 are supported
                                let tssShareIndex = Int32(3)
                                let sigs: [String] = try signatures.map { String(decoding: try JSONSerialization.data(withJSONObject: $0), as: UTF8.self) }
                                try await TssModule.add_factor_pub(threshold_key: threshold_key, tss_tag: selected_tag, factor_key: factorKey, auth_signatures: sigs, new_factor_pub: newFactorPub, new_tss_index: tssShareIndex, nodeDetails: nodeDetails!, torusUtils: torusUtils!)

                                let saveNewFactorId = newFactorPub
                                try KeychainInterface.save(item: newFactorKey.hex, key: saveNewFactorId)

                                let description = [
                                    "module": "Manual Backup",
                                    "tssTag": selected_tag,
                                    "tssShareIndex": tssShareIndex,
                                    "dateAdded": Date().timeIntervalSince1970
                                ] as [String: Codable]
                                let jsonStr = try factorDescription(dataObj: description)
                                try await threshold_key.add_share_description(key: newFactorPub, description: jsonStr)
                                // show factor key used

                                let (newTssIndex, newTssShare) = try await TssModule.get_tss_share(threshold_key: threshold_key, tss_tag: selected_tag, factorKey: newFactorKey.hex)
                                updateTag(key: selected_tag)
                                alertContent = "tssIndex:" + newTssIndex + "\n" + "tssShare:" + newTssShare + "\n" + "newFactorKey" + newFactorKey.hex
                                showAlert = true
                                showSpinner = false
                            }
                    }) { Text("Create New TSSShare Into Manual Backup Factor") }
                }.alert(isPresented: $showAlert) {
                    Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                }.disabled(showSpinner )
                .opacity(showSpinner ? 0.5 : 1)

                HStack {
                    if showSpinner {
                        LoaderView()
                    }
                    Button(action: {
                            Task {
                                showSpinner = true
                                // generate factor key if input is empty
                                // derive factor pub
                                let newFactorKey = try PrivateKey.generate()
                                let newFactorPub = try convertPublicKeyFormat(publicKey: newFactorKey.toPublic(), outFormat: .EllipticCompress)

                                // get existing factor key
                                let fetchId = metadataPublicKey + ":" + selected_tag + ":" + "0"
                                let factorKey = try KeychainInterface.fetch(key: fetchId)

                                let (tssShareIndex, _ ) = try await TssModule.get_tss_share(threshold_key: threshold_key, tss_tag: selected_tag, factorKey: factorKey)

                                // tssShareIndex provided will be cross checked with factorKey to prevent wrong tss share copied
                                try await TssModule.copy_factor_pub(threshold_key: threshold_key, tss_tag: selected_tag, factorKey: factorKey, newFactorPub: newFactorPub, tss_index: Int32(tssShareIndex)!)

                                let saveNewFactorId = newFactorPub
                                try KeychainInterface.save(item: newFactorKey.hex, key: saveNewFactorId)
                                // show factor key used
                                let description = [
                                    "module": "Manual Backup",
                                    "tssTag": selected_tag,
                                    "tssShareIndex": tssShareIndex,
                                    "dateAdded": Date().timeIntervalSince1970
                                ] as [String: Codable]
                                let jsonStr = try factorDescription(dataObj: description)
                                try await threshold_key.add_share_description(key: newFactorPub, description: jsonStr)

                                let (newTssIndex, newTssShare) = try await TssModule.get_tss_share(threshold_key: threshold_key, tss_tag: selected_tag, factorKey: newFactorKey.hex)
                                updateTag(key: selected_tag)
                                alertContent = "tssIndex:" + newTssIndex + "\n" + "tssShare:" + newTssShare + "\n" + "newFactorKey" + newFactorKey.hex
                                showAlert = true
                                showSpinner = false
                            }
                    }) { Text("Copy Existing TSS Share For New Factor Manual") }
                }.alert(isPresented: $showAlert) {
                    Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                }.disabled(showSpinner )
                 .opacity(showSpinner ? 0.5 : 1)

                HStack {
                    if showSpinner {
                        LoaderView()
                    }
                    Button(action: {
                        Task {
                            // get factor key from keychain if input is empty

                            showSpinner = true
                            var deleteFactorKey: String?
                            var deleteFactor: String?
                            do {
                                let allFactorPub = try await TssModule.get_all_factor_pub(threshold_key: threshold_key, tss_tag: selected_tag)
                                print(allFactorPub)
                                // filterout device factor
                                let filterFactorPub = allFactorPub.filter({ $0 != deviceFactorPub })
                                print(filterFactorPub)

                                deleteFactor = filterFactorPub[0]

                                deleteFactorKey = try KeychainInterface.fetch(key: deleteFactor!)
                                if deleteFactorKey == "" {
                                    throw RuntimeError("")
                                }
                            } catch {
                                alertContent = "There is no extra factor key to be deleted"
                                showAlert = true
                                return
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

                            let saveId = metadataPublicKey + ":" + selected_tag + ":" + "0"
                            let factorKey = try KeychainInterface.fetch(key: saveId)
                            let sigs: [String] = try signatures.map { String(decoding: try JSONSerialization.data(withJSONObject: $0), as: UTF8.self) }
                            try await TssModule.delete_factor_pub(threshold_key: threshold_key, tss_tag: selected_tag, factor_key: factorKey, auth_signatures: sigs, delete_factor_pub: deleteFactorPK.toPublic(), nodeDetails: nodeDetails!, torusUtils: torusUtils!)
                            print("done delete factor pub")
                            try KeychainInterface.save(item: "", key: deleteFactor!)
                            updateTag(key: selected_tag)
                            alertContent = "deleted factor key :" + deleteFactorKey
                            showAlert = true
                            showSpinner = false
                        }
                    }) { Text("Delete Most Recent Factor") }
                }.alert(isPresented: $showAlert) {
                    Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                }.disabled(showSpinner )
                    .opacity(showSpinner ? 0.5 : 1)
            }
        }
        HStack {
            if showSpinner {
                LoaderView()
            }

            Button(action: {
                Task {
                    showSpinner = true
                    do {
                        let sigs: [String] = try signatures.map { String(decoding: try JSONSerialization.data(withJSONObject: $0), as: UTF8.self) }
                        // get the factor key information

                        let factorKey = try KeychainInterface.fetch(key: metadataPublicKey + ":" + selected_tag + ":0")
                        // Create tss Client using helper
                        let (client, coeffs) = try await helperTssClient(threshold_key: threshold_key, factorKey: factorKey, verifier: verifier, verifierId: verifierId, tssEndpoints: tssEndpoints, nodeDetails: nodeDetails!, torusUtils: torusUtils!)

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
                        let publicKey = try await TssModule.get_tss_pub_key(threshold_key: threshold_key, tss_tag: selected_tag)
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
                    showSpinner = false
                }
            }) { Text("Sign Message") }
                .disabled( !signingData )
                .disabled(showSpinner )
                .opacity(showSpinner ? 0.5 : 1)
        }
    }
}
