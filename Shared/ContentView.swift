import SwiftUI

import TorusUtils

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(vm: LoginModel())
    }
}

struct ContentView: View {
    @StateObject var vm: LoginModel
    @State var mfaSet = false
    @State var showAlert = false

    var body: some View {
        TabView {
            if vm.isLoading {
                ProgressView()
            } else {
                if vm.loggedIn {
//                    let upgraded = vm.userData["upgraded"] as! Bool
                    let upgraded = false
                    if !mfaSet && !upgraded {
                        SFAView(userData: vm.userData, mfaSet: $mfaSet).tabItem {
                        }
                    } else {
                        ThresholdKeyView(userData: vm.userData, mfaSet: $mfaSet)
                            .tabItem {
                                Image(systemName: "person")
                                Text("Profile")
                            }
                    }
                } else {
                    LoginView(vm: vm)
                }
            }
        }
        .onAppear {
            Task {
                await vm.setup()
                showAlert = true
            }
        }
    }
}
