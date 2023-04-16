import SwiftUI

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(vm: LoginModel())
    }
}

struct ContentView: View {
    @StateObject var vm: LoginModel
    @State var showAlert = false
    var body: some View {
        TabView {
            if vm.isLoading {
                ProgressView()
            } else {
                if vm.loggedIn {
                    ThresholdKeyView(userData: vm.userData)
                        .tabItem {
                            Image(systemName: "person")
                            Text("Profile")
                        }.alert(isPresented: $showAlert) {
                            Alert(title: Text("Alert"), message: Text("Please setup a security question first. This account might be lost if security question not created"), dismissButton: .default(Text("OK")))
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
