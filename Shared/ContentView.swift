//
//  ContentView.swift
//  Shared
//
//  Created by David Main on 2022/08/29.
//

import SwiftUI
import tkey_pkg

struct ContentView: View {

    var body: some View {
        let key1 = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        let key_details = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let key_reconstruction_details = try! threshold_key.reconstruct()
        try! KeychainInterface.syncShare(threshold_key: threshold_key, share_index: nil)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        var data = try! encoder.encode(key_details)
        let initialize_output = String(data: data, encoding: .utf8)!
        encoder.outputFormatting = .prettyPrinted
        data = try! encoder.encode(key_reconstruction_details)
        let reconstruct_output = String(data: data, encoding: .utf8)!

        let version = try! library_version()

        // let shareStore = try! threshold_key.generate_new_share()

        // let shareOut = try! threshold_key.output_share(shareIndex: shareStore.hex, shareType: nil)

        // try! threshold_key.input_share(share: shareOut, shareType: nil)

        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        _ = try! threshold_key2.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false)

        try! KeychainInterface.syncShare(threshold_key: threshold_key2, share_index: nil)

        // try! threshold_key2.input_share(share: shareOut, shareType: nil)

        _ = try! threshold_key2.reconstruct()

        let metadata = try! threshold_key.get_metadata()
        let metadata_json = try! metadata.export()

        return VStack(alignment: .center, spacing: 10) {
                Text(initialize_output)
                Spacer()
                Text(reconstruct_output)
                Spacer()
                Text(metadata_json)
                Spacer()
                Text(version)
                Spacer()
                Text("Success").font(.title)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
