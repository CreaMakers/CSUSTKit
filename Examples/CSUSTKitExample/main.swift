import Alamofire
import CSUSTKit
import DotEnvy
import Foundation

// MARK: - Environment Loading

func loadAuthServerAccount() -> (String?, String?) {
    let environment = try? DotEnvironment.make()
    return (environment?["CSUST_AUTHSERVER_USERNAME"], environment?["CSUST_AUTHSERVER_PASSWORD"])
}

func loadPhysicsExperimentAccount() -> (String?, String?) {
    let environment = try? DotEnvironment.make()
    return (environment?["CSUST_PHYSICS_EXPERIMENT_USERNAME"], environment?["CSUST_PHYSICS_EXPERIMENT_PASSWORD"])
}

@main
struct Main {
    static func main() async {

        // MARK: - WebVPN Encryption

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

        // MARK: - SSO Login

        let session: Session = Session(interceptor: EduHelper.EduRequestInterceptor())

        let ssoHelper = SSOHelper(session: session)
        do {
            let (username, password) = loadAuthServerAccount()
            guard let username = username, let password = password else {
                print("Username or password not found in environment variables.")
                return
            }

            try await ssoHelper.login(username: username, password: password)

            debugPrint(try await ssoHelper.getLoginUser())

            // MARK: - Mooc Login

            let moocHelper = MoocHelper(session: try await ssoHelper.loginToMooc())
            debugPrint(try await moocHelper.getProfile())
            debugPrint(try await moocHelper.getCourses())
            debugPrint(try await moocHelper.getCourseAssignments(courseId: "69571"))
            debugPrint(try await moocHelper.getCourseTests(courseId: "69571"))
            debugPrint(try await moocHelper.getCourseNamesWithPendingAssignments())

            // MARK: - Education Login

            let eduHelper = EduHelper(session: try await ssoHelper.loginToEducation())
            debugPrint(try await eduHelper.profileService.getProfile())
            debugPrint(try await eduHelper.examService.getExamSchedule())
            debugPrint(try await eduHelper.courseService.getCourseGrades())
            debugPrint(try await eduHelper.courseService.getCourseSchedule())

            try await ssoHelper.logout()
        } catch {
            print("Error: \(error)")
        }

        // MARK: - Physics Experiment Login

        let physicsExperimentHelper = PhysicsExperimentHelper()
        do {
            let (username, password) = loadPhysicsExperimentAccount()
            guard let username = username, let password = password else {
                print("Username or password not found in environment variables.")
                return
            }

            try await physicsExperimentHelper.login(username: username, password: password)

            debugPrint(try await physicsExperimentHelper.getCourses())
            debugPrint(try await physicsExperimentHelper.getCourseGrades())

            try await physicsExperimentHelper.logout()
        } catch {
            print("Error: \(error)")
        }
    }
}
