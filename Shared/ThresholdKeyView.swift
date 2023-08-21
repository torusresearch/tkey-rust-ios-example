import SwiftUI
import tkey_pkg
import TorusUtils
import FetchNodeDetails
import CommonSources

enum SpinnerLocation {
    case addPasswordBtn, changePasswordBtn, initReconstructBtn, nowhere
}

// struct TokenSignature: Codable {
//    var data: String // base64
//    var sig: String // hex
// }

// swiftlint:disable type_body_length
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
    @State var thresholdKey: ThresholdKey!
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

    @State var showRecovery: Bool = false
    @State var seedPhrase: String = ""

    //    @State

    func resetAppState() {
        totalShares = 0
        threshold = 0
        metadataKey = ""
        metadataPublicKey=""
        tssPublicKey = ""
        deviceFactorPub = ""
        shareIndexCreated = ""
        showRecovery = false

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

    func deserializeShare (seedPhrase: String) throws -> String {
        return try ShareSerializationModule.deserialize_share(thresholdKey: thresholdKey, share: seedPhrase, format: "mnemonic")
    }

//    swiftlint:disable function_body_length
    func initialize () {
        Task {
            showSpinner = SpinnerLocation.initReconstructBtn
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
                return [  "data": Data(hex: token.token).base64EncodedString(),
                           "sig": token.signature ]
            }
            assert(signatures.isEmpty != true)

            guard let storageLayer = try? StorageLayer(enableLogging: true, hostUrl: "https://metadata.tor.us", serverTimeOffset: 2) else {
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
            guard let serviceProvider = try? ServiceProvider(enableLogging: true, postboxKey: postboxkey, useTss: true, verifier: verifier, verifierId: verifierId, nodeDetails: nodeDetails)

            else {
                alertContent = "Failed to create service provider"
                showAlert = true
                showSpinner = SpinnerLocation.nowhere
                return
            }
            let rssComm = try RssComm()
            guard let thresholdKey = try? ThresholdKey(
                storageLayer: storageLayer,
                serviceProvider: serviceProvider,
                enableLogging: true,
                manualSync: false,
                rssComm: rssComm) else {
                alertContent = "Failed to create threshold key"
                showAlert = true
                showSpinner = SpinnerLocation.nowhere
                return
            }

            self.thresholdKey = thresholdKey

            guard let keyDetails = try? await thresholdKey.initialize(neverInitializeNewKey: false, includeLocalMetadataTransitions: false) else {
                alertContent = "Failed to get key details"
                showAlert = true
                showSpinner = SpinnerLocation.nowhere
                return
            }

            totalShares = Int(keyDetails.totalShares)
            threshold = Int(keyDetails.threshold)
            tkeyInitalized = true

            // public key of the metadatakey
            metadataPublicKey = try keyDetails.pubKey.getPublicKey(format: .ellipticCompress )

            if keyDetails.requiredShares > 0 {
                // exising user
                let allTags = try thresholdKey.get_all_tss_tags()
                print(allTags)
                let tag = "default" // allTags[0]
//
                guard let factorPub = UserDefaults.standard.string(forKey: metadataPublicKey ) else {
                    alertContent = "Failed to find device share."
                    showAlert = true
                    showSpinner = SpinnerLocation.nowhere
                    showRecovery = true
                    return
                }

                do {
                    deviceFactorPub = factorPub
                    let factorKey = try KeychainInterface.fetch(key: factorPub)
                    try await thresholdKey.input_factor_key(factorKey: factorKey)
                } catch {
                    alertContent = "Failed to find device share or Incorrect device share"
                    showAlert = true
                    resetAccount = true
                    showSpinner = SpinnerLocation.nowhere
                    showRecovery = true
                    return
                }

                guard let reconstructionDetails = try? await thresholdKey.reconstruct() else {

                    alertContent = "Failed to reconstruct key with available shares."
                    resetAccount = true
                    showAlert = true
                    showSpinner = SpinnerLocation.nowhere
                    showRecovery = true
                    return
                }

                metadataKey = reconstructionDetails.key
                tkeyReconstructed = true
                resetAccount = false

                // check if default in all tags else ??
                tssPublicKey = try await TssModule.get_tss_pub_key(thresholdKey: thresholdKey, tssTag: tag )

                let defaultTssShareDescription = try thresholdKey.get_share_descriptions()
                metadataDescription = "\(defaultTssShareDescription)"
                print(defaultTssShareDescription)

            } else {
                // new user
                guard (try? await thresholdKey.reconstruct()) != nil else {
                    alertContent = "Failed to reconstruct key. \(keyDetails.requiredShares) more share(s) required." +
                    " If you have security question share, we suggest you to enter security question PW to recover your account"
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
                try await TssModule.create_tagged_tss_share(thresholdKey: thresholdKey, tssTag: defaultTag,
                                                            deviceTssShare: nil, factorPub: factorPub, deviceTssIndex: tssIndex,
                                                            nodeDetails: self.nodeDetails!, torusUtils: self.torusUtils!)

                tssPublicKey = try await TssModule.get_tss_pub_key(thresholdKey: thresholdKey, tssTag: defaultTag)

                // finding device share index
                var shareIndexes = try thresholdKey.get_shares_indexes()
                shareIndexes.removeAll(where: {$0 == "1"})

                // backup metadata share using factorKey
                try TssModule.backup_share_with_factor_key(thresholdKey: thresholdKey, shareIndex: shareIndexes[0], factorKey: factorKey.hex)
                let description = [
                    "module": "Device Factor key",
                    "tssTag": defaultTag,
                    "tssShareIndex": tssIndex,
                    "dateAdded": Date().timeIntervalSince1970
                ] as [String: Codable]
                let jsonStr = try factorDescription(dataObj: description)

                try await thresholdKey.add_share_description(key: factorPub, description: jsonStr )

                // point metadata pubkey to factorPub
                UserDefaults.standard.set(factorPub, forKey: metadataPublicKey)

                // save factor key in keychain using factorPub ( this factor key should be saved in any where that is accessable by the device)
                guard let _ = try? KeychainInterface.save(item: factorKey.hex, key: factorPub) else {
                    alertContent = "Failed to save factor key"
                    resetAccount = true
                    showAlert = true
                    showSpinner = SpinnerLocation.nowhere
                    return
                }

                guard let reconstructionDetails = try? await thresholdKey.reconstruct() else {
                    alertContent = "Failed to reconstruct key. \(keyDetails.requiredShares) more share(s) required."
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

    func recover (factorKey: String) async throws {
        do {
            try await thresholdKey.input_factor_key(factorKey: factorKey)
            let keyDetails = try await thresholdKey.reconstruct()

            metadataKey = keyDetails.key

            // set to factorkey to keychain
            let fk = PrivateKey(hex: factorKey)
            let factorPub = try fk.toPublic()

            UserDefaults.standard.set(factorPub, forKey: metadataPublicKey)
            try KeychainInterface.save(item: factorKey, key: factorPub)

            // set current deviceFactor
            deviceFactorPub = factorPub

            let tag = "default"
            tssPublicKey = try await TssModule.get_tss_pub_key(thresholdKey: thresholdKey, tssTag: tag )

            let defaultTssShareDescription = try thresholdKey.get_share_descriptions()
            metadataDescription = "\(defaultTssShareDescription)"

            tkeyReconstructed = true
            resetAccount = false
            showRecovery = false
        } catch {
            alertContent = "Invalid Seed Phrase"
            showAlert = true
        }
    }

    var body: some View {
        VStack {

            if showTss {
                List {
                    TssView(thresholdKey: $thresholdKey, verifier: $verifier, verifierId: $verifierId, signatures: $signatures,
                            tssEndpoints: $tssEndpoint, showTss: $showTss, nodeDetails: $nodeDetails, torusUtils: $torusUtils,
                            metadataPublicKey: $metadataPublicKey, deviceFactorPub: $deviceFactorPub, selectedFactorPub: deviceFactorPub)
                }
            } else if showRecovery {
                RecoveryView( recover: recover, reset: reset, deserializeShare: deserializeShare).alert(isPresented: $showAlert) {
                    Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
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
                                if showSpinner == SpinnerLocation.initReconstructBtn {
                                    LoaderView()
                                }
                                Button(action: {
                                    initialize()

                                }) {
                                    Text("")
                                }
                                .disabled(showSpinner == SpinnerLocation.initReconstructBtn)
                                .opacity(showSpinner == SpinnerLocation.initReconstructBtn ? 0.5 : 1)
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

                                        let description = try thresholdKey.get_share_descriptions()
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
                                            guard let postboxkey = finalKeyData["privKey"] as? String else {
                                                throw RuntimeError("invalid private key")
                                            }

                                            let tempStorageLayer = try StorageLayer(enableLogging: true, hostUrl: "https://metadata.tor.us", serverTimeOffset: 2)
                                            let tempServiceProvider = try ServiceProvider(enableLogging: true, postboxKey: postboxkey)
                                            let tempThresholdKey = try ThresholdKey(
                                                storageLayer: tempStorageLayer,
                                                serviceProvider: tempServiceProvider,
                                                enableLogging: true,
                                                manualSync: false)

                                            try await tempThresholdKey.storage_layer_set_metadata(privateKey: postboxkey, json: "{ \"message\": \"KEY_NOT_FOUND\" }")
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
        }.alert(isPresented: $showAlert, content: {
            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
        })
    }

    func reset () async throws {
        showAlert = true
        alertContent = "Resetting your accuont.."
        do {
            guard let finalKeyData = userData["finalKeyData"] as? [String: Any] else {
                alertContent = "Failed to get public address from userinfo"
                showAlert = true
                showSpinner = SpinnerLocation.nowhere
                return
            }
            guard let postboxkey = finalKeyData["privKey"] as? String else {
                throw RuntimeError("Invalid Private Key")
            }
            let tempStorageLayer = try StorageLayer(enableLogging: true, hostUrl: "https://metadata.tor.us", serverTimeOffset: 2)
            let tempServiceProvider = try ServiceProvider(enableLogging: true, postboxKey: postboxkey)
            let tempThresholdKey = try ThresholdKey(
                storageLayer: tempStorageLayer,
                serviceProvider: tempServiceProvider,
                enableLogging: true,
                manualSync: false)

            try await tempThresholdKey.storage_layer_set_metadata(privateKey: postboxkey, json: "{ \"message\": \"KEY_NOT_FOUND\" }")
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
}
