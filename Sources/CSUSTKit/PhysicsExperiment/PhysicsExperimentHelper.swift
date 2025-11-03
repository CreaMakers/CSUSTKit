import Alamofire
import SwiftSoup

/// 物理实验教学管理助手
public class PhysicsExperimentHelper {
    var session: Session

    public init(session: Session = Session()) {
        self.session = session
    }

    /// 登录
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    /// - Throws: `PhysicsExperimentError`
    public func login(username: String, password: String) async throws {
        let usernameEncoded = username.base64String
        let passwordEncoded = password.base64String
        let urlString = "http://10.255.65.52/login.aspx?UserType=0&txtUserName=\(usernameEncoded)&txtPass=\(passwordEncoded)"

        let response = try await session.request(urlString, method: .post).string()

        guard response.contains("true") else {
            throw PhysicsExperimentError.loginFailed(response)
        }
    }

    /// 获取物理实验课程表
    /// - Throws: `PhysicsExperimentError`
    /// - Returns: 课程列表
    public func getCourses() async throws -> [Course] {
        let response = try await session.request("http://10.255.65.52/Student/myalltasklist.aspx?generalCourseId=2&generalCourseName=%E5%A4%A7%E5%AD%A6%E7%89%A9%E7%90%86%E5%AE%9E%E9%AA%8C").string()

        let document = try SwiftSoup.parse(response)
        guard let table = try document.getElementsByClass("msgtable").first() else {
            throw PhysicsExperimentError.schedulesRetrievalFailed("未找到课程表")
        }

        let rows = try table.getElementsByTag("tr")
        guard rows.count >= 1 else {
            throw PhysicsExperimentError.schedulesRetrievalFailed("课程表格式无效")
        }

        var courses: [Course] = []
        for (index, row) in rows.enumerated() {
            guard index > 0 else { continue }

            let cols = try row.getElementsByTag("td")
            guard cols.count >= 8 else {
                throw PhysicsExperimentError.schedulesRetrievalFailed("课表列数不足")
            }

            guard let id = Int(try cols[0].text()) else {
                throw PhysicsExperimentError.schedulesRetrievalFailed("课程ID格式无效")
            }
            let name = try cols[1].text().trim()
            let batch = try cols[2].text().trim()
            let teacher = try cols[3].text().trim()
            let location = try cols[4].text().trim()
            let time = try cols[5].text().trim()
            guard let classHours = Int(try cols[6].text().trim()) else {
                throw PhysicsExperimentError.schedulesRetrievalFailed("课时格式无效")
            }
            let weekInfo = try cols[7].text().trim()

            let course = Course(
                id: id,
                name: name,
                batch: batch,
                teacher: teacher,
                location: location,
                time: time,
                classHours: classHours,
                weekInfo: weekInfo
            )
            courses.append(course)
        }

        return courses
    }
}
