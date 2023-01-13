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

// struct ContentView: View {
//
//    var body: some View {
//        let key1 = try! PrivateKey.generate()
//        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
//        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
//        let threshold_key = try! ThresholdKey(
//            storage_layer: storage_layer,
//            service_provider: service_provider,
//            enable_logging: true,
//            manual_sync: true)
//
//        let key_details = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
//        let key_reconstruction_details = try! threshold_key.reconstruct()
//        try! KeychainInterface.syncShare(threshold_key: threshold_key, share_index: nil)
//
//        let encoder = JSONEncoder()
//        encoder.outputFormatting = .prettyPrinted
//        var data = try! encoder.encode(key_details)
//        let initialize_output = String(data: data, encoding: .utf8)!
//        encoder.outputFormatting = .prettyPrinted
//        data = try! encoder.encode(key_reconstruction_details)
//        let reconstruct_output = String(data: data, encoding: .utf8)!
//
//        let version = try! library_version()
//
//        // let shareStore = try! threshold_key.generate_new_share()
//
//        // let shareOut = try! threshold_key.output_share(shareIndex: shareStore.hex, shareType: nil)
//
//        // try! threshold_key.input_share(share: shareOut, shareType: nil)
//
//        let threshold_key2 = try! ThresholdKey(
//            storage_layer: storage_layer,
//            service_provider: service_provider,
//            enable_logging: true,
//            manual_sync: true)
//
//        _ = try! threshold_key2.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false)
//
//        try! KeychainInterface.syncShare(threshold_key: threshold_key2, share_index: nil)
//
//        // try! threshold_key2.input_share(share: shareOut, shareType: nil)
//
//        _ = try! threshold_key2.reconstruct()
//
//        let metadata = try! threshold_key.get_metadata()
//        let metadata_json = try! metadata.export()
//
//        return VStack(alignment: .center, spacing: 10) {
//                Text(initialize_output)
//                Spacer()
//                Text(reconstruct_output)
//                Spacer()
//                Text(metadata_json)
//                Spacer()
//                Text(version)
//                Spacer()
//                Text("Success").font(.title)
//        }
//    }
// }

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
            FirstTabView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Logs")
                }
            SecondTabView()
                .tabItem {
                    Image(systemName: "2.circle")
                    Text("Second Tab")
                }

        }
    }
}

struct ThirdTabView: View {
    @State private var showAlert = false
    @State private var alertContent = "Sample"
    @State private var totalShares = 0
    @State private var threshold = 0
    @State private var finalKey = ""

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "person")
                    .resizable()
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading) {
                    Text("Final key: \(totalShares)")
                        .font(.headline)
                    Text("total shares: \(totalShares)")
                        .font(.subheadline)
                    Text("threshold: \(threshold)")
                        .font(.subheadline)

                }
//                Spacer()
            }
            .padding()
            List {
                HStack {
                    Text("Create new tkey")
                    Spacer()
                    Button(action: {
                        let key_details = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
                        let key = try! threshold_key.reconstruct()
                        // print(key_details.pub_key, key_details.required_shares)
                        totalShares = Int(key_details.total_shares)
                        threshold = Int(key_details.threshold)
                        finalKey = key.key

                        alertContent = "\(totalShares) shares created"
                        showAlert = true
                    }) {
                        Text("Click")
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
                        showAlert = true
                    }) {
                        Text("Click")
                    } .alert(isPresented: $showAlert) {
                        Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
                    }
                }

                HStack {
                    Text("Get key details")
                    Spacer()
                    Button(action: {
                        let key_details = try! threshold_key.get_key_details()
                        print(key_details.pub_key, key_details.required_shares)
                        let totalShares = key_details.total_shares
                        alertContent = "You have \(totalShares) shares. \(key_details.required_shares) are required to reconstruct the final key"
                        showAlert = true
                    }) {
                        Text("Click")
                    } .alert(isPresented: $showAlert) {
                        Alert(title: Text("Alert"), message: Text(alertContent), dismissButton: .default(Text("Ok")))
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
                Text("Text 1")
                    .padding()
                Text("Text 2")
                    .padding()
                Text("Text 3")
                    .padding()
            }
        }
    }
}

struct FirstTabView: View {
    var body: some View {
        List {
            ForEach(1...10, id: \.self) { row in
                HStack {
                    Text("Row \(row)")
                    Spacer()
                    Button(action: {}) {
                        Text("Button")
                    }
                }
            }
        }
    }
}
