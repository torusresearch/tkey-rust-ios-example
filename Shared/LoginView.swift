import SwiftUI

struct LoginView: View {
    @StateObject var vm: LoginModel
    var body: some View {
        List {
            Button(
                action: {
                    vm.loginWithAuth0()
                },
                label: {
                    Text("Sign In With Google")
                }
            )

        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(vm: LoginModel())
    }
}
