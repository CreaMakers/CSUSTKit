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

            let building = Building(name: "西苑11栋", id: "75", campus: .jinpenling)
            let electricity = try await financeHelper.getElectricity(
                building: building, room: "233")
            debugPrint(electricity)
        } catch {
            print("Error: \(error)")
        }
    }
}
