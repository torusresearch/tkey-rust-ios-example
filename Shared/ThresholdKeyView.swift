import SwiftUI
import tkey_pkg

struct ThresholdKeyView: View {
    @State var userData: [String: Any]
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertContent = "Sample"
    @State private var totalShares = 0
    @State private var threshold = 0
    @State private var finalKey = ""
    @State private var shareIndexCreated = ""
    @State private var phrase = ""
    @State private var tkeyInitalized = false
    @State private var tkeyReconstructed = false
    @State var service_provider: ServiceProvider!
    @State var storage_layer: StorageLayer!
    @State var threshold_key: ThresholdKey!

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "person")
                    .resizable()
                    .frame(width: 50, height: 50)
                VStack(alignment: .leading) {
                    Text("Final key: \(finalKey)")
                        .font(.subheadline)
                    Text("total shares: \(totalShares)")
                        .font(.subheadline)
                    Text("threshold: \(threshold)")
                        .font(.subheadline)
                }
                Spacer()
            }
            .padding()
            List {
                Section(header: Text("Basic functionality")) {
                    HStack {
                        Text("Initialize tkey")
                        Spacer()
                        Button(action: {
                            Task {
                                let postboxkey = userData["privateKey"] as! String

                                storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
                                service_provider = try ServiceProvider(enable_logging: true, postbox_key: postboxkey)
                                threshold_key = try! ThresholdKey(
                                    storage_layer: storage_layer,
                                    service_provider: service_provider,
                                    enable_logging: true,
                                    manual_sync: false )

                                isLoading = true
                                let key_details = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)

                                // try? await KeychainInterface.syncShare(threshold_key: threshold_key, share_index: nil)

                                totalShares = Int(key_details.total_shares)
                                threshold = Int(key_details.threshold)

                                // FIX: check what this condition is ??
                                if totalShares >= threshold {
                                    tkeyInitalized = true
                                }
                                
                                // TODO: Add proper messages, 1/2 and 2/2 (old accounts, new accounts)
                                alertContent = "\(totalShares) shares created"
                                isLoading = false
                                showAlert = true
                            }
                        }) {
                            Text("")
                        } .alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }
                    HStack {
                        Text("Reconstruct key")
                        Spacer()
                        Button(action: {
                            Task {
                                // Why does the application state Panic ??
                                let key = try? await threshold_key.reconstruct()
                                if key == nil {
                                    alertContent = "Reconstruction failed"
                                    showAlert = true
                                    tkeyReconstructed = false
                                } else {
                                    finalKey = key!.key
                                    alertContent = "\(key!.key) is the final private key"
                                    showAlert = true
                                    tkeyReconstructed = true
                                }
                            }
                        }) {
                            Text("")
                        } .alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }.disabled( !tkeyInitalized)
                        .opacity( !tkeyInitalized ? 0.5 : 1 )

                    HStack {
                        Text("Get key details")
                        Spacer()
                        Button(action: {
                            Task {
                            let key_details = try! threshold_key.get_key_details()
                            totalShares = Int(key_details.total_shares)
                            threshold = Int(key_details.threshold)
                            alertContent = "You have \(totalShares) shares. \(key_details.required_shares) are required to reconstruct the final key"
                            showAlert = true

                            }
                        }) {
                            Text("")
                        } .alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }.disabled(!tkeyInitalized)
                        .opacity( !tkeyInitalized ? 0.5 : 1 )

                    HStack {
                        Text("Generate new share")
                        Spacer()
                        Button(action: {
                            Task {

                                let shares = try! await threshold_key.generate_new_share()
                                let index = shares.hex

                                let key_details = try! threshold_key.get_key_details()
                                totalShares = Int(key_details.total_shares)
                                threshold = Int(key_details.threshold)
                                shareIndexCreated = index
                                alertContent = "You have \(totalShares) shares. New share with index, \(index) was created"
                                showAlert = true
                            }
                        }) {
                            Text("")
                        } .alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }.disabled(!tkeyReconstructed)
                        .opacity( !tkeyReconstructed ? 0.5 : 1 )

                    HStack {
                        Text("Delete share")
                        Spacer()
                        Button(action: {
                            Task {
                                try! await threshold_key.delete_share(share_index: shareIndexCreated )
                                let key_details = try! threshold_key.get_key_details()
                                totalShares = Int(key_details.total_shares)
                                threshold = Int(key_details.threshold)
                                alertContent = "You have \(totalShares) shares. Share index, \(shareIndexCreated) was deleted"
                                showAlert = true
                            }
                        }) {
                            Text("")
                        } .alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }.disabled(!tkeyReconstructed)
                        .opacity( !tkeyReconstructed ? 0.5 : 1 )

                    HStack {
                        Text("Reset account")
                        Spacer()
                        Button(action: {
                            Task {
                                // Set metadata for service provider to be empty.
                                // storageLayer.setMetatadata(service_provider_key, { message: KEY_NOT_FOUND })
                            }
                        }) {
                            Text("")
                        } .alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }
                }
                Section(header: Text("Security Question")) {
                    HStack {
                        Text("Add password")
                        Spacer()
                        Button(action: {
                            let question = "what's your password?"
                            let answer = "blublu"
                            Task {

                                do {
                                    let share = try await SecurityQuestionModule.generate_new_share(threshold_key: threshold_key, questions: question, answer: answer)
                                    print(share.share_store, share.hex)

                                    let key_details = try! threshold_key.get_key_details()
                                    totalShares = Int(key_details.total_shares)
                                    threshold = Int(key_details.threshold)

                                    alertContent = "New password share created with password: \(answer)"
                                    showAlert = true
                                } catch {
                                    alertContent = "Password share already exists"
                                    showAlert = true
                                }
                            }
                        }) {
                            Text("")
                        } .alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }

                    HStack {
                        Text("Change password")
                        Spacer()
                        Button(action: {
                            Task {
                                let question = "what's your password?"
                                let answer = "blublublu"
                                _ = try! await SecurityQuestionModule.change_question_and_answer(threshold_key: threshold_key, questions: question, answer: answer)
                                let key_details = try! threshold_key.get_key_details()
                                totalShares = Int(key_details.total_shares)
                                threshold = Int(key_details.threshold)

                                alertContent = "Password changed to: \(answer)"
                                showAlert = true
                            }
                        }) {
                            Text("")
                        } .alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }

                    HStack {
                        Text("Show password")
                        Spacer()
                        Button(action: {
                            Task {

                                let data = try! SecurityQuestionModule.get_answer(threshold_key: threshold_key)
                                let key_details = try! threshold_key.get_key_details()
                                totalShares = Int(key_details.total_shares)
                                threshold = Int(key_details.threshold)

                                alertContent = "Password is: \(data)"
                                showAlert = true
                            }
                        }) {
                            Text("")
                        } .alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }
                }.disabled(!tkeyReconstructed)
                    .opacity( !tkeyReconstructed ? 0.5 : 1 )
                Section(header: Text("seed phrase")) {
                    HStack {
                        Text("Set seed pharse")
                        Spacer()
                        Button(action: {
                            Task {

                                let seedPhraseToSet = "seed sock milk update focus rotate barely fade car face mechanic mercy"

                                try! await SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet, number_of_wallets: 0)

                                phrase = seedPhraseToSet
                                alertContent = "set seed phrase complete"
                                showAlert = true
                            }
                        }) {
                            Text("")
                        }.alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }

                    HStack {
                        Text("Change seed pharse")
                        Spacer()
                        Button(action: {
                            Task {
                                let seedPhraseToChange = "object brass success calm lizard science syrup planet exercise parade honey impulse"

                                try! await SeedPhraseModule.change_phrase(threshold_key: threshold_key, old_phrase: "seed sock milk update focus rotate barely fade car face mechanic mercy", new_phrase: seedPhraseToChange)
                                phrase = seedPhraseToChange
                                alertContent = "change seed phrase complete"
                                showAlert = true
                            }
                        }) {
                            Text("")
                        }.alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }

                    HStack {
                        Text("Get seed pharse")
                        Spacer()
                        Button(action: {
                            Task {

                                let seedResult = try!
                                SeedPhraseModule
                                    .get_seed_phrases(threshold_key: threshold_key)
                                print("result", seedResult)
                                alertContent = "seed phrase is `\(seedResult[0].seedPhrase)`"

                                showAlert = true
                            }
                        }) {
                            Text("")
                        }.alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }

                    HStack {
                        Text("Delete Seed phrase")
                        Spacer()
                        Button(action: {
                            Task {
                                try! await
                                SeedPhraseModule
                                    .delete_seed_phrase(threshold_key: threshold_key, phrase: phrase)

                                phrase = ""
                                alertContent = "delete seed phrase complete"

                                showAlert = true
                            }
                        }) {
                            Text("")
                        }.alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }
                }.disabled(!tkeyReconstructed)
                    .opacity( !tkeyReconstructed ? 0.5 : 1 )
                Section(header: Text("Share Serialization")) {
                    HStack {
                        Text("Export share")
                        Spacer()
                        Button(action: {
                            Task {
                                let shareStore = try! await threshold_key.generate_new_share()
                                let index = shareStore.hex

                                let key_details = try! threshold_key.get_key_details()
                                totalShares = Int(key_details.total_shares)
                                threshold = Int(key_details.threshold)
                                shareIndexCreated = index

                                let shareOut = try! threshold_key.output_share(shareIndex: index, shareType: nil)

                                let result = try! ShareSerializationModule.serialize_share(threshold_key: threshold_key, share: shareOut, format: nil)
                                alertContent = "serialize result is \(result)"
                                showAlert = true
                            }
                        }) {
                            Text("")
                        }.alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }
                }.disabled(!tkeyReconstructed)
                    .opacity( !tkeyReconstructed ? 0.5 : 1 )

                Section(header: Text("Private Key")) {
                    HStack {
                        Text("Set Private Key")
                        Spacer()
                        Button(action: {
                            Task {
                                let key_module = try! PrivateKey.generate()

                                let result = try! await PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: key_module.hex, format: "secp256k1n")
                                if result {
                                    alertContent = "setting private key completed"
                                } else {
                                    alertContent = "Setting private key failed"
                                }
                                showAlert = true
                            }
                        }) {
                            Text("")
                        }.alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }

                    HStack {
                        Text("Get Private Key")
                        Spacer()
                        Button(action: {
                            Task {
                                let result = try! PrivateKeysModule.get_private_keys(threshold_key: threshold_key)

                                alertContent = "Get private key result is \(result)"
                                showAlert = true
                            }
                        }) {
                            Text("")
                        }.alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }

                    HStack {
                        Text("Get Accounts")
                        Spacer()
                        Button(action: {
                            Task {
                                let result = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)

                                alertContent = "Get accounts result is \(result)"
                                showAlert = true
                            }
                        }) {
                            Text("")
                        }.alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }
                }.disabled(!tkeyReconstructed)
                    .opacity( !tkeyReconstructed ? 0.5 : 1 )
            }
        }
    }
}
