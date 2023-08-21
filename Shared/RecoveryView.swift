//
//  RecoveryView.swift
//  tkey_ios
//
//  Created by CW Lee on 16/08/2023.
//

import Foundation
import SwiftUI
import tkey_pkg

struct RecoveryView: View {
    var recover: (String) async throws -> Void
    var reset: () async throws -> Void
    var deserializeShare: (String) throws -> String
    @State private var seedPharse: String = ""

    var body: some View {
        VStack {
            List {
                TextField("Key In SeedPhrase", text: $seedPharse)
                Text( seedPharse )

                Button(action: {
                    Task {
                        var factorKey = seedPharse
                        do {
                            factorKey = try deserializeShare(seedPharse)
                        } catch {
                            print(factorKey)
                            print("fail to deserialize")
                        }
                        try await recover( factorKey )
                    }
                }, label: {
                    Text("Recover")
                })

                Button(action: {
                    let alert = UIAlertController(title: "Reset Account", message: "This action will reset your account. Use it with extreme caution.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { _ in
                        Task {
                            try await reset()
                        }
                    }))
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                    }
                }, label: {
                    Text("Reset Account (CAUTION)")
                })
            }
        }
    }
}
