import SwiftUI

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(vm: LoginModel())
    }
}

struct ContentView: View {
    @StateObject var vm: LoginModel
    @State var showAlert = false
    @State var seedPhrase = ""
    var body: some View {
        TabView {
            if vm.isLoading {
                ProgressView()
            } else {
                if vm.loggedIn {
                    ThresholdKeyView(userData: vm.userData)
                        .tabItem {
                            Image(systemName: "house.circle")
                            Text("Home")
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
