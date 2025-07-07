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

            let data = try await ssoHelper.getCaptcha()

            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                "captcha.png")
            try data.write(to: fileURL)
            debugPrint(fileURL)

            print("Please enter the captcha code:")
            guard let captcha = readLine(), !captcha.isEmpty else {
                print("Captcha code cannot be empty.")
                return
            }

            try await ssoHelper.getDynamicCode(mobile: username, captcha: captcha)

            print("Please enter the dynamic code sent to your mobile:")
            guard let dynamicCode = readLine(), !dynamicCode.isEmpty else {
                print("Dynamic code cannot be empty.")
                return
            }

            try await ssoHelper.dynamicLogin(
                username: username, dynamicCode: dynamicCode, captcha: captcha)

            debugPrint(try await ssoHelper.getLoginUser())

            try await ssoHelper.logout()
        } catch {
            print("Error: \(error)")
        }
    }
}
