//
//  SFA.swift
//  tkey_ios
//
//  Created by CW Lee on 08/08/2023.
//

import Foundation
import SwiftUI
import TorusUtils
import BigInt

struct SFAView: View {

    @State var userData: [String: Any]
    @Binding var mfaSet: Bool

    @State var sfaPrivateKey: String = ""
    @State var sfaPostboxkey: String = ""
    @State var sfaNonce: String = ""

    var tintColor: Color = .blue
    var scaleSize: CGFloat = 1.0

    var body: some View {
        VStack {
            Text("SFA Detail")
            Text("PrivateKey : " +  sfaPrivateKey  )

            List {
                Section {
                    HStack {
                        Button(action: {
                            print(userData)
                            let userType = userData["userType"] as? TypeOfUser
                            print(userType?.rawValue)
                            mfaSet = true
                        }, label: {
                            Text("MFA")
                        })
                    }
                }
            }
        }.onAppear {
            sfaPrivateKey = userData["privateKey"] as! String
            sfaNonce = (userData["nonce"] as! BigUInt).serialize().toHexString()
        }
    }
}
