import Foundation
import CustomAuth
import TorusUtils
import BigInt

class LoginModel: ObservableObject {
    @Published var loggedIn: Bool = false
    @Published var isLoading = false
    @Published var navigationTitle: String = ""
    @Published var userData: [String: Any]!

    func setup() async {
        await MainActor.run(body: {
            isLoading = true
            navigationTitle = "Loading"
        })
        await MainActor.run(body: {
            if self.userData != nil {
                loggedIn = true
            }
            isLoading = false
            navigationTitle = loggedIn ? "UserInfo" : "SignIn"
        })
    }

    func loginWithCustomAuth() {
        Task {
            let sub = SubVerifierDetails(loginType: .web,
                                         loginProvider: .google,
                                         clientId: "221898609709-obfn3p63741l5333093430j3qeiinaa8.apps.googleusercontent.com",
                                         verifier: "google-lrc",
                                         redirectURL: "tdsdk://tdsdk/oauthCallback",
                                         browserRedirectURL: "https://scripts.toruswallet.io/redirect.html")
            // SFA MODE, enableOneKey = true
            let tdsdk = CustomAuth(aggregateVerifierType: .singleLogin, aggregateVerifier: "google-lrc", subVerifierDetails: [sub], network: .CYAN, enableOneKey: true )
            var data = try await tdsdk.triggerLogin()

            let resp = RetrieveSharesResponseModel.init(publicKey: data["publicAddress"] as! String, privateKey: data["privateKey"] as! String, nonce: data["nonce"] as! BigUInt, typeOfUser: data["typeOfUser"] as! TypeOfUser)

            if resp.typeOfUser == TypeOfUser.v1 {
                if resp.nonce == BigUInt(0) {
                    data["upgraded"] = false
                } else {
                    data["upgraded"] = true
                }
            } else if resp.typeOfUser == TypeOfUser.v2 {
                if resp.nonce == BigUInt(0) {
                    data["upgraded"] = true
                } else {
                    data["upgraded"] = false
                }
            }

            let immutableData = data
            await MainActor.run(body: {
                self.userData = immutableData
                loggedIn = true
            })
        }
    }

}
