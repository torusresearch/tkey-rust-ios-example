//
//  ContentView.swift
//  Shared
//
//  Created by David Main on 2022/08/29.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
            let curve_n = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141"
            
            let storage_layer = try! StorageLayer.init(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        
        let threshold_key = try! ThresholdKey.init(
            private_key: "",
            storage_layer: storage_layer,
            service_provider: nil,
            enable_logging: true,
            manual_sync: true)
         
        let _ = try! threshold_key.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false, curve_n: curve_n)
        let _ = try! threshold_key.reconstruct(curve_n: curve_n)
        Text("success").padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
