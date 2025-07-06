import DotEnvy
import Foundation

func loadAccount() -> (String?, String?) {
    let environment = try? DotEnvironment.make()
    return (environment?["CSUST_USERNAME"], environment?["CSUST_PASSWORD"])
}

@main
struct Main {
    static func main() async {
        let eduHelper = EduHelper()
        let campusCardHelper = CampusCardHelper()
        let ssoHelper = SSOHelper()
        do {
            let (username, password) = loadAccount()
            guard let username = username, let password = password else {
                print("Username or password not found in environment variables.")
                return
            }

            try await ssoHelper.login(username: username, password: password)
            debugPrint(try await ssoHelper.getLoginUser())

            let session = try await ssoHelper.loginToEducation()
            let eduHelper = EduHelper(session: session)

            debugPrint(try await eduHelper.profileService.getProfile())

            try await ssoHelper.logout()
        } catch {
            print("Error: \(error)")
        }
    }
}
