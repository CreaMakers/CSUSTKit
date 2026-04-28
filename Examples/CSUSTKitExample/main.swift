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

        // let originalURL = "https://www.lofter.com/front/login"
        // do {
        //     print("原始 URL: \(originalURL)")
        //     let encryptedURL = try WebVPNHelper.encryptURL(originalURL: originalURL)
        //     print("WebVPN URL: \(encryptedURL)")
        //     let decryptedURL = try WebVPNHelper.decryptURL(vpnURL: encryptedURL)
        //     print("解密后 URL: \(decryptedURL)")
        //     if decryptedURL == originalURL {
        //         print("验证成功")
        //     } else {
        //         print("验证失败")
        //     }
        // } catch {
        //     print("Error: \(error)")
        // }

        // MARK: - SSO Login

        let session: Session = Session(interceptor: EduHelper.EduRequestInterceptor())

        print("选择网络模式（1. 直接连接，2. WebVPN）：")
        guard let networkMode = readLine(),
            networkMode == "1" || networkMode == "2"
        else {
            return
        }

        let connectionMode: ConnectionMode = networkMode == "1" ? .direct : .webVpn

        let ssoHelper = SSOHelper(mode: connectionMode, session: session)
        do {
            print("选择登录方式（1. 密码，2. 验证码）：")
            guard let loginMethod = readLine(),
                loginMethod == "1" || loginMethod == "2"
            else {
                return
            }
            if loginMethod == "1" {
                let loginForm = try await ssoHelper.getLoginForm()
                debugPrint("Login Form: \(loginForm)")
                print("请输入用户名：")
                guard let username = readLine() else {
                    return
                }
                let needCaptcha = try await ssoHelper.checkNeedCaptcha(username: username)
                debugPrint("Need Captcha: \(needCaptcha)")
                var captcha: String? = nil
                if needCaptcha {
                    let captchaImageData = try await ssoHelper.getCaptcha()
                    let captchaImageURL = URL(fileURLWithPath: "captcha.jpg")
                    try captchaImageData.write(to: captchaImageURL)
                    print("验证码已保存到 \(captchaImageURL.path)，请输入验证码：")
                    guard let captchaInput = readLine() else {
                        return
                    }
                    captcha = captchaInput
                }
                print("请输入密码：")
                guard let password = readLine() else {
                    return
                }
                try await ssoHelper.login(loginForm: loginForm, username: username, password: password, captcha: captcha)
            } else {
                let loginForm = try await ssoHelper.getLoginForm()
                debugPrint("Login Form: \(loginForm)")
                print("请输入用户名：")
                guard let username = readLine() else {
                    return
                }
                let captchaImageData = try await ssoHelper.getCaptcha()
                let captchaImageURL = URL(fileURLWithPath: "captcha.jpg")
                try captchaImageData.write(to: captchaImageURL)
                print("验证码已保存到 \(captchaImageURL.path)，请输入验证码：")
                guard let captchaInput = readLine() else {
                    return
                }
                try await ssoHelper.sendDynamicCode(mobile: username, captcha: captchaInput)
                print("短信动态码已发送，请输入动态码：")
                guard let dynamicCode = readLine() else {
                    return
                }
                try await ssoHelper.dynamicLogin(loginForm: loginForm, username: username, dynamicCode: dynamicCode, captcha: captchaInput)
            }

            let loginUser = try await ssoHelper.getLoginUser()
            debugPrint("Login User: \(loginUser)")

            // let (username, password) = loadAuthServerAccount()
            // guard let username, let password else {
            //     print("Username or password not found in environment variables.")
            //     return
            // }

            // try await ssoHelper.login(username: username, password: password)

            // debugPrint(try await ssoHelper.getLoginUser())

            // MARK: - Mooc Login

            // let moocHelper = MoocHelper(session: try await ssoHelper.loginToMooc())
            // debugPrint(try await moocHelper.getProfile())
            // debugPrint(try await moocHelper.getCourses())
            // debugPrint(try await moocHelper.getCourseAssignments(courseId: "69571"))
            // debugPrint(try await moocHelper.getCourseTests(courseId: "69571"))
            // debugPrint(try await moocHelper.getCourseNamesWithPendingAssignments())

            // MARK: - Education Login

            // let eduHelper = EduHelper(session: try await ssoHelper.loginToEducation())
            // debugPrint(try await eduHelper.courseService.getAvailableClassrooms(campus: .jinpenling, week: 18, dayOfWeek: .thursday, section: 2))
            // debugPrint(try await eduHelper.profileService.getProfile())
            // debugPrint(try await eduHelper.examService.getExamSchedule())
            // debugPrint(try await eduHelper.courseService.getCourseGrades())
            // debugPrint(try await eduHelper.courseService.getCourseSchedule())

            // try await ssoHelper.logout()
        } catch {
            print("Error: \(error)")
        }

        // MARK: - Physics Experiment Login

        // let physicsExperimentHelper = PhysicsExperimentHelper()
        // do {
        //     let (username, password) = loadPhysicsExperimentAccount()
        //     guard let username = username, let password = password else {
        //         print("Username or password not found in environment variables.")
        //         return
        //     }

        //     try await physicsExperimentHelper.login(username: username, password: password)

        //     debugPrint(try await physicsExperimentHelper.getCourses())
        //     debugPrint(try await physicsExperimentHelper.getCourseGrades())

        //     try await physicsExperimentHelper.logout()
        // } catch {
        //     print("Error: \(error)")
        // }
    }
}
