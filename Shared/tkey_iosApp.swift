import SwiftUI

@main
// swiftlint:disable:next  type_name
struct tkey_iosApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(vm: LoginModel())
        }
    }
}
