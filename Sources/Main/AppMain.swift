import DotEnvy
import Foundation

func loadAccount() -> (String?, String?) {
    let environment = try? DotEnvironment.make()
    return (environment?["CSUST_USERNAME"], environment?["CSUST_PASSWORD"])
}

@available(macOS 13.0, *)
@main
struct Main {
    static func main() async {
        let eduHelper = EduHelper()
        let financeHelper = FinanceHelper()
        do {
            let (username, password) = loadAccount()
            guard let username = username, let password = password else {
                print("Username or password not found in environment variables.")
                return
            }

            try await eduHelper.authService.login(username: username, password: password)
            try await eduHelper.authService.logout()

            let result = try await financeHelper.getBuildings(for: .yuntang)
            debugPrint(result)
        } catch {
            print("Error: \(error)")
        }
    }
}
