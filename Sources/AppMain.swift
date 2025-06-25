import Foundation

@available(macOS 10.15, *)
@main
struct Main {
    static func main() async {
        let eduHelper = EduHelper()
        do {
            try await eduHelper.login(username: "", password: "")
            debugPrint(try await eduHelper.checkLoginStatus())
            let profile = try await eduHelper.getProfile()
            debugPrint(profile)
            try await eduHelper.logout()
            debugPrint(try await eduHelper.checkLoginStatus())
        } catch {
            print("Error: \(error)")
        }
    }
}
