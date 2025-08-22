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
            throw MoocHelperError.courseRetrievalFailed("Invalid course table format")
        }

        var courses: [Course] = []

        for (index, row) in rows.enumerated() {
            guard index > 0 else { continue }
            let cols = try row.select("td")

            guard cols.count >= 4 else {
                throw MoocHelperError.courseRetrievalFailed("Unexpected course row format")
            }

            let number = try cols[0].text()
            let name = try cols[1].text()
            guard let a = try cols[1].getElementsByTag("a").first() else {
                throw MoocHelperError.courseRetrievalFailed("Course id not found")
            }
            let id = (try a.attr("onclick"))
                .replacingOccurrences(of: "window.open('../homepage/course/course_index.jsp?courseId=", with: "")
                .replacingOccurrences(of: "','manage_course')", with: "")
            let department = try cols[2].text()
            let teacher = try cols[3].text()

            let course = Course(
                id: id,
                number: number,
                name: name,
                department: department,
                teacher: teacher
            )
            courses.append(course)
        }

        return courses
    }

    public func getCourseHomeworks(courseId: String) async throws -> [Homework] {
        struct Response: Codable {
            struct Datas: Codable {
                let hwtList: [Homework]
                struct Homework: Codable {
                    let realName: String
                    let startDateTime: String
                    let mutualTask: String
                    let submitStruts: Bool
                    let id: Int
                    let title: String
                    let deadLine: String
                    let answerStatus: Bool?
                }
            }
            let datas: Datas
        }

        let response = try await session.request("http://pt.csust.edu.cn/meol/hw/stu/hwStuHwtList.do?sortDirection=-1&courseId=\(courseId)&pagingPage=1&pagingNumberPer=1000&sortColumn=deadline").serializingDecodable(Response.self).value

        return response.datas.hwtList.map {
            Homework(
                id: $0.id,
                title: $0.title,
                publisher: $0.realName,
                canSubmit: $0.submitStruts,
                submitStatus: $0.answerStatus != nil,
                deadline: $0.deadLine,
                startTime: $0.startDateTime
            )
        }
    }

    public func getCourseTests(courseId: String) async throws -> [Test] {
        let response = try await session.request("http://pt.csust.edu.cn/meol/common/question/test/student/list.jsp?sortColumn=createTime&sortDirection=-1&cateId=\(courseId)&pagingPage=1&status=1&pagingNumberPer=1000").serializingString(encoding: .gbk).value
        let document = try SwiftSoup.parse(response)

        guard let tableElement = try document.getElementsByClass("valuelist").first() else {
            throw MoocHelperError.testRetrievalFailed("Test table not found")
        }

        let rows = try tableElement.getElementsByTag("tr")

        guard rows.count >= 1 else {
            throw MoocHelperError.testRetrievalFailed("Invalid test table format")
        }

        var tests: [Test] = []

        for (index, row) in rows.enumerated() {
            guard index > 0 else { continue }
            let cols = try row.getElementsByTag("td")

            guard cols.count >= 8 else {
                throw MoocHelperError.testRetrievalFailed("Unexpected test row format")
            }

            let title = try cols[0].text()
            let startTime = try cols[1].text()
            let endTime = try cols[2].text()
            let rawAllowRetake = try cols[3].text()
            let allowRetake = rawAllowRetake == "不限制" ? nil : Int(rawAllowRetake)
            guard let timeLimit = Int(try cols[4].text()) else {
                throw MoocHelperError.testRetrievalFailed("Invalid time limit format")
            }
            let isSubmitted = try cols[7].html().contains("查看结果")
            tests.append(
                Test(
                    title: title,
                    startTime: startTime,
                    endTime: endTime,
                    allowRetake: allowRetake,
                    timeLimit: timeLimit,
                    isSubmitted: isSubmitted
                )
            )
        }

        return tests
    }

    public func logout() async throws {
        _ = try await session.request("http://pt.csust.edu.cn/meol/homepage/V8/include/logout.jsp")
            .serializingString(encoding: .gbk).value

        session = Session()
    }
}
