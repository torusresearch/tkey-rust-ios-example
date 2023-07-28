//
//  TssView.swift
//  tkey_ios
//
//  Created by CW Lee on 28/07/2023.
//

import Foundation
import SwiftUI
import tkey_pkg

struct TssView: View {
    @State var threshold_key: ThresholdKey!
    @State private var tss_modules: [String: TssModule] = [:]

    var body: some View {
            Section(header: Text("Tss Module")) {
                HStack {
                    Button(action: {
                        Task {

                        }
                    }) { Text("text") }
                }
                HStack {

                    Button(action: {
                        Task {

                        }
                    }) { Text("text") }

                }
            }.onAppear {
                Task {
//                    threshold_key.get_tss_tag()
                }
            }
    }

}
