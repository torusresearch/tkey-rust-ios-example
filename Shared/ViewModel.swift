import Foundation
import CustomAuth
import tkey_pkg

class ViewModel: ObservableObject {
    @Published var loggedIn: Bool = false
    @Published var isLoading = false
    @Published var navigationTitle: String = ""
    @Published var userData: [String:Any]?
    @Published var service_provider: ServiceProvider?
    @Published var threshold_key: ThresholdKey!
    
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

    
    
    func loginWithAuth0() {
        print("hi")
        Task{
            do {
                let sub = SubVerifierDetails(loginType: .web,
                                             loginProvider: .google,
                                             clientId: "221898609709-obfn3p63741l5333093430j3qeiinaa8.apps.googleusercontent.com",
                                             verifier: "google-lrc",
                                             redirectURL: "tdsdk://tdsdk/oauthCallback",
                                             browserRedirectURL: "https://scripts.toruswallet.io/redirect.html")

                let tdsdk = CustomAuth(aggregateVerifierType: .singleLogin, aggregateVerifier: "google-lrc", subVerifierDetails: [sub], network: .TESTNET)
                let data = try! await tdsdk.triggerLogin()

                print(data)

                let postboxkey = data["privateKey"] as! String


                
                
                try await MainActor.run(body: {
                    service_provider = try ServiceProvider(enable_logging: true, postbox_key: postboxkey)
                    threshold_key = try! ThresholdKey(
                        storage_layer: storage_layer,
                        service_provider: service_provider,
                        enable_logging: true,
                        manual_sync: true)
                    self.userData = data
                    loggedIn = true
                })

            } catch {
                print("Error")
            }
        }
    }
    
    
}

//extension ViewModel {
//    func showResult(result: Web3AuthState) {
//        print("""
//        Signed in successfully!
//            Private key: \(result.privKey ?? "")
//                Ed25519 Private key: \(result.ed25519PrivKey ?? "")
//            User info:
//                Name: \(result.userInfo?.name ?? "")
//                Profile image: \(result.userInfo?.profileImage ?? "N/A")
//                Type of login: \(result.userInfo?.typeOfLogin ?? "")
//        """)
//    }
//}
