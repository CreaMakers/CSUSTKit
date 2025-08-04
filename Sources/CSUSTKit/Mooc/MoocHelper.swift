import Alamofire
import SwiftSoup

public class MoocHelper {
    var session: Session

    public init(session: Session = Session()) {
        self.session = session
    }

    public func getProfile() async throws -> Profile {
        let response = try await session.request("http://pt.csust.edu.cn/meol/personal.do")
            .serializingString(encoding: .gbk).value

        let document = try SwiftSoup.parse(response)

        let elements = try document.select(".userinfobody > ul > li")

        guard elements.count >= 5 else {
            throw MoocHelperError.profileRetrievalFailed("Unexpected profile format")
        }

        let name = try elements[1].text()
        let lastLoginTime = try elements[2].text().replacingOccurrences(of: "登录时间：", with: "")
        let totalOnlineTime = try elements[3].text().replacingOccurrences(of: "在线总时长： ", with: "")
        let loginCountText = try elements[4].text().replacingOccurrences(of: "登录次数：", with: "")

        guard let loginCount = Int(loginCountText) else {
            throw MoocHelperError.profileRetrievalFailed("Invalid login count format")
        }

        return Profile(
            name: name,
            lastLoginTime: lastLoginTime,
            totalOnlineTime: totalOnlineTime,
            loginCount: loginCount
        )
    }

    public func getCourses() async throws -> [Course] {
        let response = try await session.request(
            "http://pt.csust.edu.cn/meol/lesson/blen.student.lesson.list.jsp"
        ).serializingString(encoding: .gbk).value
        let document = try SwiftSoup.parse(response)

        guard let tableElement = try document.getElementById("table2") else {
            throw MoocHelperError.courseRetrievalFailed("Course table not found")
        }

        let rows = try tableElement.select("tr")

        guard rows.count >= 1 else {
            throw MoocHelperError.courseRetrievalFailed("No courses found")
        }

        var courses: [Course] = []

        for (index, row) in rows.enumerated() {
            guard index > 0 else { continue }
            let cols = try row.select("td")

            guard cols.count >= 4 else {
                throw MoocHelperError.courseRetrievalFailed("Unexpected course row format")
            }

            let id = try cols[0].text()
            let name = try cols[1].text()
            let department = try cols[2].text()
            let teacher = try cols[3].text()

            let course = Course(
                id: id,
                name: name,
                department: department,
                teacher: teacher
            )
            courses.append(course)
        }

        return courses
    }

    public func logout() async throws {
        _ = try await session.request("http://pt.csust.edu.cn/meol/homepage/V8/include/logout.jsp")
            .serializingString(encoding: .gbk).value

        session = Session()
    }
}
