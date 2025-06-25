import Foundation

@available(macOS 10.15, *)
@main
struct Main {
    static func main() async {
        let eduHelper = EduHelper()
        do {
            try await eduHelper.login(username: "", password: "")
        } catch {
            print("Login failed with error: \(error)")
        }
    }
}
