//
//  ContentView.swift
//  Shared
//
//  Created by David Main on 2022/08/29.
//

import SwiftUI
import tkey_pkg

let key1 = try! PrivateKey.generate()
let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
let threshold_key = try! ThresholdKey(
    storage_layer: storage_layer,
    service_provider: service_provider,
    enable_logging: true,
    manual_sync: true)

var logs: [String] = []

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            ThirdTabView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
            SecondTabView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Logs")
                }
        }
    }
}

struct ThirdTabView: View {
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertContent = "Sample"
    @State private var totalShares = 0
    @State private var threshold = 0
    @State private var finalKey = ""
    @State private var shareIndexCreated = ""
    @State private var phrase = ""

    func logger(data: String) {
        logs.append(data + "\n")
    }

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
                        Text("Create new tkey")
                        Spacer()
                        Button(action: {
                            isLoading = true
                            let key_details = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
                            let key = try! threshold_key.reconstruct()
                            // print(key_details.pub_key, key_details.required_shares)
                            totalShares = Int(key_details.total_shares)
                            threshold = Int(key_details.threshold)
                            finalKey = key.key

                            alertContent = "\(totalShares) shares created"
                            logger(data: alertContent.description)
                            isLoading = false
                            showAlert = true
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
                            let key = try! threshold_key.reconstruct()
                            finalKey = key.key
                            alertContent = "\(key.key) is the final private key"
                            logger(data: alertContent.description)
                            showAlert = true
                        }) {
                            Text("")
                        } .alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }

                    HStack {
                        Text("Get key details")
                        Spacer()
                        Button(action: {
                            let key_details = try! threshold_key.get_key_details()
                            totalShares = Int(key_details.total_shares)
                            threshold = Int(key_details.threshold)
                            alertContent = "You have \(totalShares) shares. \(key_details.required_shares) are required to reconstruct the final key"
                            logger(data: alertContent.description)
                            showAlert = true
                        }) {
                            Text("")
                        } .alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }

                    HStack {
                        Text("Generate new share")
                        Spacer()
                        Button(action: {
                            let shares = try! threshold_key.generate_new_share()
                            let index = shares.hex

                            let key_details = try! threshold_key.get_key_details()
                            totalShares = Int(key_details.total_shares)
                            threshold = Int(key_details.threshold)
                            shareIndexCreated = index
                            alertContent = "You have \(totalShares) shares. New share with index, \(index) was created"
                            logger(data: alertContent.description)
                            showAlert = true
                        }) {
                            Text("")
                        } .alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }

                    HStack {
                        Text("Delete share")
                        Spacer()
                        Button(action: {
                            try! threshold_key.delete_share(share_index: shareIndexCreated )
                            let key_details = try! threshold_key.get_key_details()
                            totalShares = Int(key_details.total_shares)
                            threshold = Int(key_details.threshold)
                            alertContent = "You have \(totalShares) shares. Share index, \(shareIndexCreated) was deleted"
                            logger(data: alertContent.description)
                            showAlert = true
                        }) {
                            Text("")
                        } .alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }

                }

                // MARK: Security questions or password
                Section(header: Text("Security Question")) {
                    HStack {
                        Text("Add password")
                        Spacer()
                        Button(action: {
                            let question = "what's your password?"
                            let answer = "blublu"

                            do {
                                let share = try SecurityQuestionModule.generate_new_share(threshold_key: threshold_key, questions: question, answer: answer)
                                print(share.share_store, share.hex)

                                let key_details = try! threshold_key.get_key_details()
                                totalShares = Int(key_details.total_shares)
                                threshold = Int(key_details.threshold)

                                alertContent = "New password share created with password: \(answer)"
                                logger(data: alertContent.description)
                                showAlert = true
                            } catch {
                                alertContent = "Password share already exists"
                                logger(data: alertContent.description)
                                showAlert = true
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
                            let question = "what's your password?"
                            let answer = "blublublu"
                            try! SecurityQuestionModule.change_question_and_answer(threshold_key: threshold_key, questions: question, answer: answer)
                            let key_details = try! threshold_key.get_key_details()
                            totalShares = Int(key_details.total_shares)
                            threshold = Int(key_details.threshold)

                            alertContent = "Password changed to: \(answer)"
                            logger(data: alertContent.description)
                            showAlert = true
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
                            let data = try! SecurityQuestionModule.get_answer(threshold_key: threshold_key)
                            let key_details = try! threshold_key.get_key_details()
                            totalShares = Int(key_details.total_shares)
                            threshold = Int(key_details.threshold)

                            alertContent = "Password is: \(data)"
                            logger(data: alertContent.description)
                            showAlert = true
                        }) {
                            Text("")
                        } .alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }
                }
                Section(header: Text("seed phrase")) {
                    HStack {
                        Text("Set seed pharse")
                        Spacer()
                        Button(action: {
                            let seedPhraseToSet = "seed sock milk update focus rotate barely fade car face mechanic mercy"

                            try! SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet, number_of_wallets: 0)
                            
                            phrase = seedPhraseToSet
                            alertContent = "set seed phrase complete"
                            showAlert = true
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
                            let seedPhraseToChange = "object brass success calm lizard science syrup planet exercise parade honey impulse"
                                
                            try! SeedPhraseModule.change_phrase(threshold_key: threshold_key, old_phrase: "seed sock milk update focus rotate barely fade car face mechanic mercy", new_phrase: seedPhraseToChange)
                            phrase = seedPhraseToChange
                            alertContent = "change seed phrase complete"
                            showAlert = true
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
                            
                            let seedResult = try!
                                SeedPhraseModule
                                .get_seed_phrases(threshold_key: threshold_key)
                            // TODO : get string result from seedResult
                            print("result",seedResult)
                            alertContent = "seed phrase is `\(seedResult)`"
                            
                            showAlert = true
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
                            try!
                            SeedPhraseModule
                                .delete_seedphrase(threshold_key: threshold_key, phrase: phrase)
                            
                            phrase = ""
                            alertContent = "delete seed phrase complete"

                            showAlert = true
                        }) {
                            Text("")
                        }.alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }
                }
                Section(header: Text("Share Serialization")) {
                    HStack {
                        Text("Share Serialization")
                        Spacer()
                        Button(action: {
                            let shareStore = try! threshold_key.generate_new_share()
                            let index = shareStore.hex
                            
                            let key_details = try! threshold_key.get_key_details()
                            totalShares = Int(key_details.total_shares)
                            threshold = Int(key_details.threshold)
                            shareIndexCreated = index
                            
                            let shareOut = try! threshold_key.output_share(shareIndex: index, shareType: nil)
                            
                            let result = try! ShareSerializationModule.serialize_share(threshold_key: threshold_key, share: shareOut, format: nil)
                            alertContent = "serialize result is \(result)"
                            showAlert = true
                        }) {
                            Text("")
                        }.alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }
                }
                
                Section(header: Text("Private Key")) {
                    HStack {
                        Text("Set Private Key")
                        Spacer()
                        Button(action: {
                            let key_module = try! PrivateKey.generate()

                            let result = try! PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: key_module.hex, format: "secp256k1n")
                            if result {
                                alertContent = "setting private key completed"
                            } else {
                                alertContent = "Setting private key failed"
                            }
                            showAlert = true
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
                            let result = try! PrivateKeysModule.get_private_keys(threshold_key: threshold_key)
                            
                            alertContent = "Get private key result is \(result)"
                            showAlert = true
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
                            let result = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
                            
                            alertContent = "Get accounts result is \(result)"
                            showAlert = true
                        }) {
                            Text("")
                        }.alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                        }
                    }
                }
            }
        }
    }
}

struct SecondTabView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(Array(logs.enumerated()), id: \.offset) { i, el in
                    Text("\(i+1): \(el)")
                }
            }
        }
    }
}

struct LoaderView: View {
    var tintColor: Color = .blue
    var scaleSize: CGFloat = 1.0

    var body: some View {
        ProgressView()
            .scaleEffect(scaleSize, anchor: .center)
            .progressViewStyle(CircularProgressViewStyle(tint: tintColor))
    }
}
