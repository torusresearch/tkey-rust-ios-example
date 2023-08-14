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

struct TssView: View {

    @Binding var threshold_key: ThresholdKey!
    @Binding var verifier: String!
    @Binding var verifierId: String!

    @Binding var signatures: [[String: Any]]!
    @Binding var tssEndpoints: [String]!
    @Binding var showTss: Bool
    @Binding var nodeDetails: AllNodeDetailsModel?
    @Binding var torusUtils: TorusUtils?
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
                                print(try threshold_key.get_all_tss_tags())
                                try await TssModule.create_tagged_tss_share(threshold_key: self.threshold_key, tss_tag: tag, deviceTssShare: nil, factorPub: factorPub, deviceTssIndex: 2, nodeDetails: self.nodeDetails!, torusUtils: self.torusUtils!)
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
        }.alert(isPresented: $showAlert) {
            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
        }

        if tss_pub_key != "" {
            Text("Tss public key for " + selected_tag)
            Text(tss_pub_key)

            Section(header: Text("Tss : " + selected_tag + " : FactorPub")) {
                ForEach(Array(allFactorPub), id: \.self) { factorPub in
                    Text(factorPub)
                }
            }
        }

        let tss_tags = try! threshold_key.get_all_tss_tags()

        if !tss_tags.isEmpty {
            Section(header: Text("Tss Module")) {
                ForEach(tss_tags, id: \.self) { key in
                    HStack {
                        Button(action: {
                            Task {
                                selected_tag = key
                                tss_pub_key = try await TssModule.get_tss_pub_key(threshold_key: threshold_key, tss_tag: selected_tag)
                                allFactorPub = try await TssModule.get_all_factor_pub(threshold_key: threshold_key, tss_tag: selected_tag)
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
                            let (tssIndex, tssShare) = try await TssModule.get_tss_share(threshold_key: threshold_key, tss_tag: selected_tag, factorKey: factorKey)
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
                                    let checkFactorKey = try KeychainInterface.fetch(key: checkSaveId)
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
                                let factorKey = try KeychainInterface.fetch(key: saveId)
                                let tssShareIndex = Int32(3)
                                let sigs: [String] = try signatures.map { String(decoding: try JSONSerialization.data(withJSONObject: $0), as: UTF8.self) }
                                try await TssModule.add_factor_pub(threshold_key: threshold_key, tss_tag: selected_tag, factor_key: factorKey, auth_signatures: sigs, new_factor_pub: newFactorPub, new_tss_index: tssShareIndex, nodeDetails: nodeDetails!, torusUtils: torusUtils!)

                                let saveNewFactorId = selected_tag + ":" + "1"
                                try KeychainInterface.save(item: newFactorKey.hex, key: saveNewFactorId)
                                // show factor key used

                                let (newTssIndex, newTssShare) = try await TssModule.get_tss_share(threshold_key: threshold_key, tss_tag: selected_tag, factorKey: newFactorKey.hex)
                                alertContent = "tssIndex:" + newTssIndex + "\n" + "tssShare:" + newTssShare + "\n" + "newFactorKey" + newFactorKey.hex
                                showAlert = true
                            }
                        }))

                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            windowScene.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                        }
                    }) { Text(selected_tag + " : add factor pub") }
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
                                    let checkFactorKey = try KeychainInterface.fetch(key: checkSaveId)
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
                                let factorKey = try KeychainInterface.fetch(key: saveId)
                                // use input to generate tss share with index 3
                                let tssShareIndex = Int32(2)
                                try await TssModule.copy_factor_pub(threshold_key: threshold_key, tss_tag: selected_tag, factorKey: factorKey, newFactorPub: newFactorPub, tss_index: tssShareIndex)

                                let saveNewFactorId = selected_tag + ":" + "2"
                                try KeychainInterface.save(item: newFactorKey.hex, key: saveNewFactorId)
                                // show factor key used

                                let (newTssIndex, newTssShare) = try await TssModule.get_tss_share(threshold_key: threshold_key, tss_tag: selected_tag, factorKey: newFactorKey.hex)
                                alertContent = "tssIndex:" + newTssIndex + "\n" + "tssShare:" + newTssShare + "\n" + "newFactorKey" + newFactorKey.hex
                                showAlert = true
                                // copy factor pub
                            }
                        }))
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            windowScene.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                        }
                    }) { Text(selected_tag + " : copy factor pub") }
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
                                deleteFactorKey = try KeychainInterface.fetch(key: targetSaveId)
                                if deleteFactorKey == "" {
                                    throw RuntimeError("")
                                }
                            } catch {
                                do {
                                    targetSaveId = selected_tag + ":" + "2"
                                    deleteFactorKey = try KeychainInterface.fetch(key: targetSaveId)
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
                            let factorKey = try KeychainInterface.fetch(key: saveId)
                            let sigs: [String] = try signatures.map { String(decoding: try JSONSerialization.data(withJSONObject: $0), as: UTF8.self) }
                            try await TssModule.delete_factor_pub(threshold_key: threshold_key, tss_tag: selected_tag, factor_key: factorKey, auth_signatures: sigs, delete_factor_pub: deleteFactorPK.toPublic(), nodeDetails: nodeDetails!, torusUtils: torusUtils!)
                            print("done delete factor pub")
                            try KeychainInterface.save(item: "", key: targetSaveId)

                            alertContent = "deleted factor key :" + deleteFactorKey
                            showAlert = true
                        }
                    }) { Text(selected_tag + " : delete factor pub") }
                }.alert(isPresented: $showAlert) {
                    Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                }
            }
        }

        Button(action: {
            Task {
                do {
                    let selected_tag = try TssModule.get_tss_tag(threshold_key: threshold_key)

                    let factorKey = try KeychainInterface.fetch(key: selected_tag + ":0")

                    let (tssIndex, tssShare) = try await TssModule.get_tss_share(threshold_key: threshold_key, tss_tag: selected_tag, factorKey: factorKey)
                    let tssNonce = try TssModule.get_tss_nonce(threshold_key: threshold_key, tss_tag: selected_tag)
                    let tssPublicAddressInfo = try await TssModule.getTssPubAddress(threshold_key: threshold_key, tssTag: selected_tag, nonce: String(tssNonce), nodeDetails: nodeDetails!, torusUtils: torusUtils!)
                    let publicKey = try await TssModule.get_tss_pub_key(threshold_key: threshold_key, tss_tag: selected_tag)

                    let sigs: [String] = try signatures.map { String(decoding: try JSONSerialization.data(withJSONObject: $0), as: UTF8.self) }

                    let (client, coeffs) = try helperTssClient(selected_tag: selected_tag, tssNonce: tssNonce, publicKey: publicKey, tssShare: tssShare, tssIndex: tssIndex, nodeIndexes: tssPublicAddressInfo.nodeIndexes, factorKey: factorKey, verifier: verifier, verifierId: verifierId, tssEndpoints: tssEndpoints)

                    // wait for sockets to connect
                    var connected = try client.checkConnected()
                    if connected {
                        // Create a precompute, each server also creates a precompute.
                        // This calls setup() followed by precompute() for all parties
                        // If meesages cannot be exchanged by all parties, between all parties, this will fail, since it will timeout waiting for socket messages.
                        // This will also fail if a single failure notification is received.
                        // ~puid_seed is the first message set exchanged, ~checkpt123_raw is the last message set exchanged.
                        // Once ~checkpt123_raw is received, precompute_complete notifications should be received shortly thereafter.
                        let precompute = try client.precompute(serverCoeffs: coeffs, signatures: sigs)

                        let ready = try client.isReady()

                        if ready {

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
                            let tssPubKey = try await TssModule.get_tss_pub_key(threshold_key: threshold_key, tss_tag: selected_tag)
                            let tssKeyAddress = try KeyPoint(address: tssPubKey).getAsCompressedPublicKey(format: "")

                            if TSSHelpers.verifySignature(msgHash: msgHash, s: s, r: r, v: v, pubKey: Data(hex: tssKeyAddress)) {
                                let sigHex = try TSSHelpers.hexSignature(s: s, r: r, v: v)
                                alertContent = "Signature: " + sigHex
                                showAlert = true
                                print(try TSSHelpers.hexSignature(s: s, r: r, v: v))
                            } else {
                                alertContent = "Signature could not be verified"
                                showAlert = true
                            }
                        } else {
                            alertContent = "Client is not ready, please try again"
                            showAlert = true
                        }
                    } else {
                        alertContent = "Client is not connected, please try again"
                        showAlert = true
                    }
                } catch {
                    alertContent = "Signing could not be completed. please try again"
                    showAlert = true
                }
            }
        }) { Text("Sign") }// .disabled( !signingData )

        Button(action: {
            Task {
                do {
                    let selected_tag = try TssModule.get_tss_tag(threshold_key: threshold_key)

                    let factorKey = try KeychainInterface.fetch(key: selected_tag + ":0")

                    let (tssIndex, tssShare) = try await TssModule.get_tss_share(threshold_key: threshold_key, tss_tag: selected_tag, factorKey: factorKey)

                    let tssNonce = try TssModule.get_tss_nonce(threshold_key: threshold_key, tss_tag: selected_tag)

                    let tssPublicAddressInfo = try await TssModule.getTssPubAddress(threshold_key: threshold_key, tssTag: selected_tag, nonce: String(tssNonce), nodeDetails: nodeDetails!, torusUtils: torusUtils!)

                    let finalPubKey = try await TssModule.get_tss_pub_key(threshold_key: threshold_key, tss_tag: selected_tag)

                    // get the uncompressed public key, empty format returns uncompressed
                    let fullTssPubKey = try KeyPoint(address: finalPubKey).getAsCompressedPublicKey(format: "")

                    let evmAddress = Data(hexString: TSSHelpers.hashMessage(message: fullTssPubKey))?.suffix(20).hexString ?? ""

                    // step 2. getting signature
                    let sigs: [String] = try signatures.map { String(decoding: try JSONSerialization.data(withJSONObject: $0), as: UTF8.self) }

                    let tssAccount = try EthereumTssAccount(evmAddress: "0x\(evmAddress)", pubkey: fullTssPubKey, factorKey: factorKey, tssNonce: tssNonce, tssShare: tssShare, tssIndex: tssIndex, selectedTag: selected_tag, verifier: verifier, verifierID: verifierId, nodeIndexes: tssPublicAddressInfo.nodeIndexes, tssEndpoints: tssEndpoints, authSigs: sigs)

                    let RPC_URL = "https://rpc.ankr.com/eth_goerli"
                    let chainID = 5
                    let web3Client = EthereumHttpClient(url: URL(string: RPC_URL)!)

                    let amount = 0.001
                    let toAddress = tssAccount.address
                    let fromAddress = tssAccount.address
                    let gasPrice = try await web3Client.eth_gasPrice()
                    let maxTipInGwie = BigUInt(TorusWeb3Utils.toEther(Gwie: BigUInt(amount)))
                    let totalGas = gasPrice + maxTipInGwie
                    let gasLimit = BigUInt(21000)

                    let amtInGwie = TorusWeb3Utils.toWei(ether: amount)
                    let nonce = try await web3Client.eth_getTransactionCount(address: fromAddress, block: .Latest)
                    let transaction = EthereumTransaction(from: fromAddress, to: toAddress, value: amtInGwie, data: Data(), nonce: nonce + 1, gasPrice: totalGas, gasLimit: gasLimit, chainId: chainID)
                    // let signed = try tssAccount.sign(transaction: transaction)
                    let val = try await web3Client.eth_sendRawTransaction(transaction, withAccount: tssAccount)
                    alertContent = "transaction sent"
                    // alertContent = "transaction signature: " + //(signed.hash?.toHexString() ?? "")
                    showAlert = true
                } catch {
                    alertContent = "Signing could not be completed. please try again"
                    showAlert = true
                }

            }
        }) { Text("transaction signing: send eth") }
    }
}
