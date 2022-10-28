//
//  ContentView.swift
//  Shared
//
//  Created by David Main on 2022/08/29.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: "f49b79f0cc4dae7044385d65bdf0335859fcee327c8b9c721669da3161786737", curve_n: "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141")
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)
        
        let _ = try! threshold_key.initialize(never_initialize_new_key: false, service_provider: service_provider, include_local_metadata_transitions: false, curve_n: "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141")
        //let _ = try! threshold_key.reconstruct(curve_n: curve_n)
        Text("Hello").padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
