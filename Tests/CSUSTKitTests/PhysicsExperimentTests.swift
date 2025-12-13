import Alamofire
import DotEnvy
import Foundation
import Testing

@testable import CSUSTKit

private enum SetupError: Error, LocalizedError {
    case missingCredentials
    var errorDescription: String? {
        return "❌ 终止测试：无法从 .env 或环境变量中读取到物理实验账号密码 (CSUST_PHYSICS_EXPERIMENT_USERNAME/PASSWORD)"
    }
}

struct PhysicsExperimentTests {
    let username: String
    let password: String

    // MARK: - Setup

    init() async throws {
        let environment = try? DotEnvironment.make()

        guard let user = environment?["CSUST_PHYSICS_EXPERIMENT_USERNAME"],
            let pass = environment?["CSUST_PHYSICS_EXPERIMENT_PASSWORD"],
            !user.isEmpty, !pass.isEmpty
        else {
            throw SetupError.missingCredentials
        }

        self.username = user
        self.password = pass
    }

    // MARK: - Tests

    @Test("物理实验系统全流程测试：登录 -> 课表 -> 成绩 -> 登出 -> 验证登出")
    func physicsExperimentIntegrationFlow() async throws {
        let session = Session(interceptor: EduHelper.EduRequestInterceptor())
        let physicsHelper = PhysicsExperimentHelper(session: session)

        print("🚀 [1/5] 开始登录物理实验系统 (账号: \(self.username))...")
        try await physicsHelper.login(username: self.username, password: self.password)
        print("✅ 登录成功")

        print("🚀 [2/5] 获取物理实验课表...")
        let courses = try await physicsHelper.getCourses()
        #expect(!courses.isEmpty, "⚠️ 警告：课表为空 (可能是本学期无实验课，但也可能是解析失败)")
        if let firstCourse = courses.first {
            print("✅ 获取课表成功，共 \(courses.count) 门课，第一门: \(firstCourse.name) (\(firstCourse.week)周)")
        } else {
            print("✅ 获取课表成功 (为空)")
        }

        print("🚀 [3/5] 获取物理实验成绩...")
        do {
            let grades = try await physicsHelper.getCourseGrades()
            #expect(!grades.isEmpty, "⚠️ 警告：成绩表为空")
            if let firstGrade = grades.first {
                print("✅ 获取成绩成功，共 \(grades.count) 条记录，第一条: \(firstGrade.courseName) - \(firstGrade.itemName) (\(firstGrade.totalGrade)分)")
            } else {
                print("✅ 获取成绩成功 (为空)")
            }
        } catch {
            Issue.record("❌ 获取成绩失败: \(error)")
        }

        print("🚀 [4/5] 执行登出...")
        try await physicsHelper.logout()
        print("✅ 登出指令发送成功")

        print("🚀 [5/5] 验证 Session 是否销毁 (登出有效性)...")
        do {
            _ = try await physicsHelper.getCourses()
            Issue.record("❌ 错误: 退出登录后仍然能获取课表 (Session 未销毁或服务端未端开)")
        } catch PhysicsExperimentHelper.PhysicsExperimentError.notLoggedIn {
            print("✅ 验证通过: 退出后获取数据抛出 notLoggedIn 错误")
        } catch {
            print("✅ 验证通过: 退出后获取数据抛出错误: \(error)")
        }
    }
}
