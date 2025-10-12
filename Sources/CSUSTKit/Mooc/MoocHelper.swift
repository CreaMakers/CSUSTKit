import Alamofire
import Foundation
import SwiftSoup

/// 网络课程中心助手
public class MoocHelper {
    private struct HomeworksResponse: Codable {
        struct Datas: Codable {
            let hwtList: [Homework]?
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

    var session: Session

    public init(session: Session = Session()) {
        self.session = session
    }

    /// 获取个人信息
    /// - Throws: `MoocHelperError`
    /// - Returns: 个人信息
    public func getProfile() async throws -> Profile {
        let response = try await session.request("http://pt.csust.edu.cn/meol/personal.do").string(.gbk)
        let document = try SwiftSoup.parse(response)
        let elements = try document.select(".userinfobody > ul > li")
        guard elements.count >= 5 else {
            throw MoocHelperError.profileRetrievalFailed("个人信息格式异常")
        }
        let name = try elements[1].text()
        let lastLoginTime = try elements[2].text().replacingOccurrences(of: "登录时间：", with: "")
        let totalOnlineTime = try elements[3].text().replacingOccurrences(of: "在线总时长： ", with: "")
        let loginCountText = try elements[4].text().replacingOccurrences(of: "登录次数：", with: "")
        guard let loginCount = Int(loginCountText) else {
            throw MoocHelperError.profileRetrievalFailed("登录次数格式无效")
        }
        return Profile(
            name: name,
            lastLoginTime: lastLoginTime,
            totalOnlineTime: totalOnlineTime,
            loginCount: loginCount
        )
    }

    /// 获取课程列表
    /// - Throws: `MoocHelperError`
    /// - Returns: 课程列表
    public func getCourses() async throws -> [Course] {
        let response = try await session.request("http://pt.csust.edu.cn/meol/lesson/blen.student.lesson.list.jsp").string(.gbk)
        let document = try SwiftSoup.parse(response)
        guard let tableElement = try document.getElementById("table2") else {
            throw MoocHelperError.courseRetrievalFailed("未找到课程表格")
        }
        let rows = try tableElement.select("tr")
        guard rows.count >= 1 else {
            throw MoocHelperError.courseRetrievalFailed("课程表格格式无效")
        }
        var courses: [Course] = []
        for (index, row) in rows.enumerated() {
            guard index > 0 else { continue }
            let cols = try row.select("td")
            guard cols.count >= 4 else {
                throw MoocHelperError.courseRetrievalFailed("课程行格式异常")
            }
            let number = try cols[0].text()
            let name = try cols[1].text()
            guard let a = try cols[1].getElementsByTag("a").first() else {
                throw MoocHelperError.courseRetrievalFailed("未找到课程ID")
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

    /// 获取课程作业列表
    /// - Parameter courseId: 课程ID
    /// - Throws: `MoocHelperError`
    /// - Returns: 课程作业列表
    public func getCourseHomeworks(courseId: String) async throws -> [Homework] {
        let response = try await session.request("http://pt.csust.edu.cn/meol/hw/stu/hwStuHwtList.do?sortDirection=-1&courseId=\(courseId)&pagingPage=1&pagingNumberPer=1000&sortColumn=deadline").decodable(HomeworksResponse.self)
        return response.datas.hwtList?.map {
            Homework(
                id: $0.id,
                title: $0.title,
                publisher: $0.realName,
                canSubmit: $0.submitStruts,
                submitStatus: $0.answerStatus != nil,
                deadline: $0.deadLine,
                startTime: $0.startDateTime
            )
        } ?? []
    }

    /// 获取课程测验列表
    /// - Parameter courseId: 课程ID
    /// - Throws: `MoocHelperError`
    /// - Returns: 课程测验列表
    public func getCourseTests(courseId: String) async throws -> [Test] {
        let response = try await session.request("http://pt.csust.edu.cn/meol/common/question/test/student/list.jsp?sortColumn=createTime&sortDirection=-1&cateId=\(courseId)&pagingPage=1&status=1&pagingNumberPer=1000").string(.gbk)
        let document = try SwiftSoup.parse(response)
        guard let tableElement = try document.getElementsByClass("valuelist").first() else {
            throw MoocHelperError.testRetrievalFailed("未找到测试表格")
        }
        let rows = try tableElement.getElementsByTag("tr")
        guard rows.count >= 1 else {
            throw MoocHelperError.testRetrievalFailed("测试表格格式无效")
        }
        var tests: [Test] = []
        for (index, row) in rows.enumerated() {
            guard index > 0 else { continue }
            let cols = try row.getElementsByTag("td")
            guard cols.count >= 8 else {
                throw MoocHelperError.testRetrievalFailed("测试表格行格式异常")
            }
            let title = try cols[0].text()
            let startTime = try cols[1].text()
            let endTime = try cols[2].text()
            let rawAllowRetake = try cols[3].text()
            let allowRetake = rawAllowRetake == "不限制" ? nil : Int(rawAllowRetake)
            guard let timeLimit = Int(try cols[4].text()) else {
                throw MoocHelperError.testRetrievalFailed("时间限制格式无效")
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

    /// 获取有待完成作业的课程名称
    /// - Throws: `MoocHelperError`
    /// - Returns: 课程名称列表及其对应的课程ID
    public func getCourseNamesWithPendingHomeworks() async throws -> [(name: String, id: String)] {
        let response = try await session.request("http://pt.csust.edu.cn/meol/welcomepage/student/interaction_reminder_v8.jsp").string(.gbk)
        let document = try SwiftSoup.parse(response)
        guard let reminderElement = try document.getElementById("reminder") else {
            throw MoocHelperError.courseNamesWithPendingHomeworksRetrievalFailed("未找到提醒区域")
        }
        let homeworkListElement = reminderElement.children()
            .first(where: { (element: Element) -> Bool in
                guard let linkText = try? element.select("a").first()?.ownText() else {
                    return false
                }
                return linkText.contains("待提交作业")
            })

        guard let courseNamesContainer = homeworkListElement else {
            return []
        }

        let courseNameElements = try courseNamesContainer.select("ul > li > a")
        if courseNameElements.isEmpty() {
            return []
        }

        var courseNames: [(name: String, id: String)] = []
        for courseNameElement in courseNameElements {
            let onclickAttr = try courseNameElement.attr("onclick")
            let regex = try NSRegularExpression(pattern: "lid=(\\d+)")
            guard let match = regex.firstMatch(in: onclickAttr, range: NSRange(onclickAttr.startIndex..., in: onclickAttr)),
                let range = Range(match.range(at: 1), in: onclickAttr)
            else {
                continue
            }
            let id = String(onclickAttr[range])
            let courseName = try courseNameElement.text().trim()
            courseNames.append((name: courseName, id: id))
        }
        return courseNames
    }

    /// 登出
    public func logout() async throws {
        try await session.request("http://pt.csust.edu.cn/meol/homepage/V8/include/logout.jsp").data()
        session = Session()
    }
}
