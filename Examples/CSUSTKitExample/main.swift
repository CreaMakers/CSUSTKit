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
        let originalURL = "https://www.lofter.com/front/login"
        do {
            print("原始 URL: \(originalURL)")
            let encryptedURL = try WebVPNHelper.encryptURL(originalURL: originalURL)
            print("WebVPN URL: \(encryptedURL)")
            let decryptedURL = try WebVPNHelper.decryptURL(vpnURL: encryptedURL)
            print("解密后 URL: \(decryptedURL)")
            if decryptedURL == originalURL {
                print("验证成功")
            } else {
                print("验证失败")
            }
        } catch {
            print("Error: \(error)")
        }

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
            debugPrint(try await moocHelper.getCourseHomeworks(courseId: "69571"))
            debugPrint(try await moocHelper.getCourseTests(courseId: "66392"))
            debugPrint(try await moocHelper.getCourseNamesWithPendingHomeworks())

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
