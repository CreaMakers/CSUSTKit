import Alamofire
import DotEnvy
import Foundation
import Testing

@testable import CSUSTKit

// 定义错误类型
enum SetupError: Error, LocalizedError {
    case missingCredentials
    var errorDescription: String? {
        return "❌ 终止测试：无法从 .env 或环境变量中读取到账号密码"
    }
}

struct SSOTests {
    let username: String
    let password: String

    // MARK: - Setup

    init() async throws {
        let environment = try? DotEnvironment.make()

        guard let user = environment?["CSUST_AUTHSERVER_USERNAME"],
            let pass = environment?["CSUST_AUTHSERVER_PASSWORD"],
            !user.isEmpty, !pass.isEmpty
        else {
            throw SetupError.missingCredentials
        }

        self.username = user
        self.password = pass
    }

    // MARK: - Tests

    @Test("SSO 全流程测试：登录 -> 课程中心 -> 教务系统 -> 登出")
    func ssoIntegrationFlow() async throws {
        let session = Session(interceptor: EduHelper.EduRequestInterceptor())
        let ssoHelper = SSOHelper(session: session)

        print("🚀 [1/5] 开始登录 SSO (账号: \(self.username))...")

        try await ssoHelper.login(username: self.username, password: self.password)
        let ssoUser = try await ssoHelper.getLoginUser()
        #expect(!ssoUser.userName.isEmpty)
        print("✅ SSO 登录成功: \(ssoUser.userName)")

        print("🚀 [2/5] 尝试登录网络课程中心...")
        do {
            let moocSession = try await ssoHelper.loginToMooc()
            let moocHelper = MoocHelper(session: moocSession)

            let profile = try await moocHelper.getProfile()
            #expect(!profile.name.isEmpty, "网络课程中心用户名不应为空")
            print("✅ 网络课程中心登录并获取资料成功: \(profile.name)")
        } catch {
            Issue.record("❌ 网络课程中心登录或获取资料失败: \(error)")
        }

        print("🚀 [3/5] 尝试跳转教务系统...")
        do {
            let eduSession = try await ssoHelper.loginToEducation()
            let eduHelper = EduHelper(session: eduSession)

            let eduProfile = try await eduHelper.profileService.getProfile()
            #expect(!eduProfile.name.isEmpty, "教务系统用户名不应为空")
            print("✅ 教务系统登录并获取资料成功: \(eduProfile.name)")
        } catch {
            Issue.record("❌ 教务系统登录或获取资料失败: \(error)")
        }

        print("🚀 [4/5] 执行登出...")
        try await ssoHelper.logout()
        print("✅ 登出指令发送成功")

        print("🚀 [5/5] 验证 Session 是否销毁...")
        do {
            _ = try await ssoHelper.getLoginUser()
            Issue.record("❌ 错误: 退出登录后仍然能获取数据 (Session 未销毁)")
        } catch {
            print("✅ 验证通过: 退出后无法再获取数据")
        }
    }
}
