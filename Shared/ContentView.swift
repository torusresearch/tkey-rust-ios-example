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
