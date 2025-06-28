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
        do {
            let (username, password) = loadAccount()
            guard let username = username, let password = password else {
                print("Username or password not found in environment variables.")
                return
            }

            try await eduHelper.authService.login(username: username, password: password)

            let courses = try await eduHelper.courseService.getCourseSchedule()
            for course in courses {
                debugPrint(course)
            }

            try await eduHelper.authService.logout()
        } catch {
            print("Error: \(error)")
        }
    }
}
