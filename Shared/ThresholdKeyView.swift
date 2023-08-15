import SwiftUI
import tkey_pkg
import TorusUtils
import FetchNodeDetails
import CommonSources

enum SpinnerLocation {
    case add_password_btn, change_password_btn, init_reconstruct_btn, nowhere
}

// struct TokenSignature: Codable {
//    var data: String // base64
//    var sig: String // hex
// }

struct ThresholdKeyView: View {
    @State var userData: [String: Any]
    @State private var showAlert = false
    @State private var alertContent = ""
    @State private var totalShares = 0
    @State private var threshold = 0
    @State private var metadataKey = ""
    @State private var metadataPublicKey = ""
    @State private var metadataDescription = ""
    @State private var tssPublicKey = ""
    @State private var shareIndexCreated = ""
    @State private var phrase = ""
    @State private var tkeyInitalized = false
    @State private var tkeyReconstructed = false
    @State private var resetAccount = true
    @State var threshold_key: ThresholdKey!
    @State var shareCount = 0
    @State private var showInputPasswordAlert = false
    @State private var showChangePasswordAlert = false
    @State private var password = ""
    @State private var showSpinner = SpinnerLocation.nowhere

    @State private var signatures: [[String: Any]]!
    @State private var tssEndpoint: [String]!
    @State private var verifier: String!
    @State private var verifierId: String!
    @State private var tssModules: [String: TssModule] = [:]
    @State private var showTss = false
    @State private var nodeDetails: AllNodeDetailsModel?
    @State private var torusUtils: TorusUtils?
    @State var deviceFactorPub: String = ""

    //    @State

    func resetAppState() {
        totalShares = 0
        threshold = 0
        metadataKey = ""
        metadataPublicKey=""
        tssPublicKey = ""
        deviceFactorPub = ""
        shareIndexCreated = ""

        phrase = ""
        tkeyInitalized = false
        tkeyReconstructed = false
        resetAccount = true
        // remove any data saved to keychain for this app
        // TODO: remove data for affected account
        let secItemClasses = [kSecClassGenericPassword,
                              kSecClassInternetPassword,
                              kSecClassCertificate,
                              kSecClassKey,
                              kSecClassIdentity]
        for secItemClass in secItemClasses {
            let dictionary = [kSecClass as String: secItemClass]
            SecItemDelete(dictionary as CFDictionary)
        }
    }

    func initialize () {
        Task {
            showSpinner = SpinnerLocation.init_reconstruct_btn
            guard let finalKeyData = userData["finalKeyData"] as? [String: Any] else {
                alertContent = "Failed to get public address from userinfo"
                showAlert = true
                showSpinner = SpinnerLocation.nowhere
                return
            }

            guard let verifierLocal = userData["verifier"] as? String, let verifierIdLocal = userData["verifierId"] as? String else {
                alertContent = "Failed to get verifier or verifierId from userinfo"
                showAlert = true
                showSpinner = SpinnerLocation.nowhere
                return
            }
            verifier = verifierLocal
            verifierId = verifierIdLocal

            guard let postboxkey = finalKeyData["privKey"] as? String else {
                alertContent = "Failed to get postboxkey"
                showAlert = true
                showSpinner = SpinnerLocation.nowhere
                return
            }

            print(finalKeyData)
            guard let sessionData = userData["sessionData"] as? [String: Any] else {
                alertContent = "Failed to get sessionData"
                showAlert = true
                showSpinner = SpinnerLocation.nowhere
                return
            }
            guard let sessionTokenData = sessionData["sessionTokenData"] as? [SessionToken] else {
                alertContent = "Failed to get sessionTokenData"
                showAlert = true
                showSpinner = SpinnerLocation.nowhere
                return
            }

            signatures = sessionTokenData.map { token in
                return [  "data": Data(hex: token.token)!.base64EncodedString(),
                           "sig": token.signature ]
            }
            assert(signatures.isEmpty != true)

            guard let storage_layer = try? StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2) else {
                alertContent = "Failed to create storage layer"
                showAlert = true
                showSpinner = SpinnerLocation.nowhere
                return
            }
            torusUtils = TorusUtils( enableOneKey: true,
                                     network: .sapphire(.SAPPHIRE_MAINNET)
                                     )
            let fnd = NodeDetailManager(network: .sapphire(.SAPPHIRE_MAINNET))
            nodeDetails = try await fnd.getNodeDetails(verifier: verifier, verifierID: verifierId)

            tssEndpoint = nodeDetails!.torusNodeTSSEndpoints
            print(verifier!)
            print(verifierId!)
            guard let service_provider = try? ServiceProvider(enable_logging: true, postbox_key: postboxkey, useTss: true, verifier: verifier, verifierId: verifierId, nodeDetails: nodeDetails)

            else {
                alertContent = "Failed to create service provider"
                showAlert = true
                showSpinner = SpinnerLocation.nowhere
                return
            }
            let rss_comm = try RssComm()
            guard let thresholdKey = try? ThresholdKey(
                storage_layer: storage_layer,
                service_provider: service_provider,
                enable_logging: true,
                manual_sync: false,
                rss_comm: rss_comm) else {
                alertContent = "Failed to create threshold key"
                showAlert = true
                showSpinner = SpinnerLocation.nowhere
                return
            }

            threshold_key = thresholdKey

            guard let key_details = try? await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false) else {
                alertContent = "Failed to get key details"
                showAlert = true
                showSpinner = SpinnerLocation.nowhere
                return
            }

            totalShares = Int(key_details.total_shares)
            threshold = Int(key_details.threshold)
            tkeyInitalized = true

            // public key of the metadatakey
            metadataPublicKey = try key_details.pub_key.getPublicKey(format: .EllipticCompress )

            if key_details.required_shares > 0 {
                // exising user
                let allTags = try threshold_key.get_all_tss_tags()
                print(allTags)
                let tag = "default" // allTags[0]

                let fetchId = metadataPublicKey + ":" + tag + ":0"
                // fetch all locally available shares for this google account
                print(fetchId)

                do {
                    let factorKey = try KeychainInterface.fetch(key: fetchId)
                    try await threshold_key.input_factor_key(factorKey: factorKey)
                    let pk = PrivateKey(hex: factorKey)
                    deviceFactorPub = try pk.toPublic()

                } catch {
                    alertContent = "Incorrect factor was used."
                    showAlert = true
                    resetAccount = true
                    showSpinner = SpinnerLocation.nowhere
                    return
                }

                guard let reconstructionDetails = try? await threshold_key.reconstruct() else {

                    alertContent = "Failed to reconstruct key with available shares."
                    resetAccount = true
                    showAlert = true
                    showSpinner = SpinnerLocation.nowhere
                    return
                }

                metadataKey = reconstructionDetails.key
                tkeyReconstructed = true
                resetAccount = false

                // check if default in all tags else ??
                tssPublicKey = try await TssModule.get_tss_pub_key(threshold_key: threshold_key, tss_tag: tag )

                let defaultTssShareDescription = try thresholdKey.get_share_descriptions()
                metadataDescription = "\(defaultTssShareDescription)"
                print(defaultTssShareDescription)
            } else {
                // new user
                guard (try? await threshold_key.reconstruct()) != nil else {
                    alertContent = "Failed to reconstruct key. \(key_details.required_shares) more share(s) required. If you have security question share, we suggest you to enter security question PW to recover your account"
                    resetAccount = true
                    showAlert = true
                    showSpinner = SpinnerLocation.nowhere
                    return
                }

                // TSS Module Initialize - create default tag
                // generate factor key
                let factorKey = try PrivateKey.generate()
                // derive factor pub
                let factorPub = try factorKey.toPublic()
                deviceFactorPub = factorPub
                // use input to create tag tss share
                let tssIndex = Int32(2)
                let defaultTag = "default"
                try await TssModule.create_tagged_tss_share(threshold_key: threshold_key, tss_tag: defaultTag, deviceTssShare: nil, factorPub: factorPub, deviceTssIndex: tssIndex, nodeDetails: self.nodeDetails!, torusUtils: self.torusUtils!)

                tssPublicKey = try await TssModule.get_tss_pub_key(threshold_key: threshold_key, tss_tag: defaultTag)

                // finding device share index
                var shareIndexes = try threshold_key.get_shares_indexes()
                shareIndexes.removeAll(where: {$0 == "1"})

                // backup metadata share using factorKey
                try TssModule.backup_share_with_factor_key(threshold_key: threshold_key, shareIndex: shareIndexes[0], factorKey: factorKey.hex)
                let description = [
                    "module": "Device Factor key",
                    "tssTag": defaultTag,
                    "tssShareIndex": tssIndex,
                    "dateAdded": Date().timeIntervalSince1970
                ] as [String: Codable]
                let jsonStr = try factorDescription(dataObj: description)

                try await threshold_key.add_share_description(key: factorPub, description: jsonStr )

                let saveId = metadataPublicKey + ":" + defaultTag + ":0"
                // save factor key in keychain ( this factor key should be saved in any where that is accessable by the device)
                guard let _ = try? KeychainInterface.save(item: factorKey.hex, key: saveId) else {
                    alertContent = "Failed to save factor key"
                    resetAccount = true
                    showAlert = true
                    showSpinner = SpinnerLocation.nowhere
                    return
                }

                guard let reconstructionDetails = try? await threshold_key.reconstruct() else {
                    alertContent = "Failed to reconstruct key. \(key_details.required_shares) more share(s) required."
                    resetAccount = true
                    showAlert = true
                    return
                }

                metadataKey = reconstructionDetails.key
                tkeyReconstructed = true
                resetAccount = false
                showSpinner = SpinnerLocation.nowhere
            }
            let defaultTssShareDescription = try thresholdKey.get_share_descriptions()
            metadataDescription = "\(defaultTssShareDescription)"
            showSpinner = SpinnerLocation.nowhere
        }
    }

    var body: some View {
        VStack {

            if showTss {
                List {
                    TssView(threshold_key: $threshold_key, verifier: $verifier, verifierId: $verifierId, signatures: $signatures, tssEndpoints: $tssEndpoint, showTss: $showTss, nodeDetails: $nodeDetails, torusUtils: $torusUtils, metadataPublicKey: $metadataPublicKey, deviceFactorPub: $deviceFactorPub)
                }
            } else {

            HStack {
                if metadataDescription != "" {
                    VStack(alignment: .leading) {
                        Text("TSS Pub Key: \(tssPublicKey)")
                            .font(.subheadline)
                        //                    Text("Metadata public key: \(metadataPublicKey)")
                        //                        .font(.subheadline)
                        Text("Metadata key: \(metadataKey)")
                            .font(.subheadline)
                        Text("With Factors/Shares: \(metadataDescription)")
                            .font(.subheadline)
                    }
                }
                Spacer()
            }
            .padding()

            List {
                    HStack {
                        Button(action: {
                            Task {
                                showTss = true
                            }
                        }) { Text("Signing functions") }
                    }.disabled( tkeyInitalized != true )

                    Section(header: Text("Basic functionality")) {
                        if !tkeyInitalized {
                            HStack {
                                Text("Initialize")
                                Spacer()
                                if showSpinner == SpinnerLocation.init_reconstruct_btn {
                                    LoaderView()
                                }
                                Button(action: {
                                    initialize()

                                }) {
                                    Text("")
                                }
                                .disabled(showSpinner == SpinnerLocation.init_reconstruct_btn)
                                .opacity(showSpinner == SpinnerLocation.init_reconstruct_btn ? 0.5 : 1)
                                .alert(isPresented: $showAlert) {
                                    Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                                }
                            }
                        }

                        HStack {
                            Text("Key Details")
                            Spacer()
                            Button(action: {
                                Task {
                                    do {

                                        let description = try threshold_key.get_share_descriptions()
                                        metadataDescription = "\(description)"

                                        alertContent = "TSS Pub Key: \(tssPublicKey) \n Metadata key: \(metadataKey) \n With Factors/Shares: \(metadataDescription)"

                                        showAlert = true
                                    } catch {
                                        alertContent = "get key details failed"
                                        showAlert = true
                                    }

                                }
                            }) {
                                Text("")
                            }.alert(isPresented: $showAlert) {
                                Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                            }
                        }.disabled(!tkeyInitalized)
                            .opacity(!tkeyInitalized ? 0.5 : 1)

                        HStack {
                            Text("See Login Response")
                            Spacer()
                            Button(action: {
                                Task {
                                    do {
                                        alertContent = "\(String(describing: userData))"
                                        showAlert = true
                                    }

                                }
                            }) {
                                Text("")
                            }.alert(isPresented: $showAlert) {
                                Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                            }
                        }.disabled(!tkeyInitalized)
                            .opacity(!tkeyInitalized ? 0.5 : 1)

                        HStack {
                            Text("Reset Account (CAUTION)")
                            Spacer()
                            Button(action: {
                                let alert = UIAlertController(title: "Reset Account", message: "This action will reset your account. Use it with extreme caution.", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                                alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { _ in
                                    Task {
                                        showAlert = true
                                        alertContent = "Resetting your accuont.."
                                        do {
                                            guard let finalKeyData = userData["finalKeyData"] as? [String: Any] else {
                                                alertContent = "Failed to get public address from userinfo"
                                                showAlert = true
                                                showSpinner = SpinnerLocation.nowhere
                                                return
                                            }
                                            let postboxkey = finalKeyData["privKey"] as! String
                                            let temp_storage_layer = try StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
                                            let temp_service_provider = try ServiceProvider(enable_logging: true, postbox_key: postboxkey)
                                            let temp_threshold_key = try ThresholdKey(
                                                storage_layer: temp_storage_layer,
                                                service_provider: temp_service_provider,
                                                enable_logging: true,
                                                manual_sync: false)

                                            try await temp_threshold_key.storage_layer_set_metadata(private_key: postboxkey, json: "{ \"message\": \"KEY_NOT_FOUND\" }")
                                            tkeyInitalized = false
                                            tkeyReconstructed = false
                                            metadataDescription = ""
                                            resetAccount = false
                                            alertContent = "Account reset successful"

                                            resetAppState() // Allow reinitialize
                                        } catch {
                                            alertContent = "Reset failed"
                                        }

                                    }
                                }))
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    windowScene.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                                }
                            }) {
                                Text("")
                            }.alert(isPresented: $showAlert) {
                                Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                            }
                        }

                    }
                }
            }
        }.onAppear {
            initialize()
        }
    }
}
