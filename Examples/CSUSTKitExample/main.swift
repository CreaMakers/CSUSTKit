import CSUSTKit
import DotEnvy
import Foundation

func loadAccount() -> (String?, String?) {
    let environment = try? DotEnvironment.make()
    return (environment?["CSUST_USERNAME"], environment?["CSUST_PASSWORD"])
}

@main
struct Main {
    static func main() async {
        let ssoHelper = SSOHelper()
        do {
            let (username, password) = loadAccount()
            guard let username = username, let password = password else {
                print("Username or password not found in environment variables.")
                return
            }

            try await ssoHelper.login(username: username, password: password)

            debugPrint(try await ssoHelper.getLoginUser())

            let moocHelper = MoocHelper(session: try await ssoHelper.loginToMooc())
            let eduHelper = EduHelper(session: try await ssoHelper.loginToEducation())

            debugPrint(try await moocHelper.getProfile())
            debugPrint(try await moocHelper.getCourses())

            debugPrint(try await eduHelper.profileService.getProfile())
            debugPrint(try await eduHelper.examService.getExamSchedule())
            debugPrint(try await eduHelper.courseService.getCourseGrades())
            debugPrint(try await eduHelper.courseService.getCourseSchedule())

            try await ssoHelper.logout()
        } catch {
            print("Error: \(error)")
        }
    }
}
