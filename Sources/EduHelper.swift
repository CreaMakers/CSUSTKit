import Alamofire
import Foundation
import SwiftSoup

enum EduHelperError: Error {
    case loginFailed(String)
    case profileRetrievalFailed(String)
    case notLoggedIn(String)
    case examScheduleRetrievalFailed(String)
    case examScheduleForAllSemestersRetrievalFailed(String)
}

/// 学生档案信息
struct Profile {
    /// 院系
    let department: String
    /// 专业
    let major: String
    /// 学制
    let educationSystem: String
    /// 班级
    let className: String
    /// 学号
    let studentID: String
    /// 姓名
    let name: String
    /// 性别
    let gender: String
    /// 姓名拼音
    let namePinyin: String
    /// 出生日期
    let birthDate: String
    /// 民族
    let ethnicity: String
    /// 学习层次
    let studyLevel: String
    /// 家庭现住址
    let homeAddress: String
    /// 家庭电话
    let homePhone: String
    /// 本人电话
    let personalPhone: String
    /// 入学日期
    let enrollmentDate: String
    /// 入学考号
    let entranceExamID: String
    /// 身份证编号
    let idCardNumber: String
}

/// 学期信息
struct Semester {
    /// 学期名称
    let name: String
    /// 是否为默认选项
    let isDefault: Bool
}

enum SemesterType: String {
    /// 期初
    case beginning = "期初"
    /// 期中
    case middle = "期中"
    /// 期末
    case end = "期末"

    var id: String {
        switch self {
        case .beginning:
            return "1"
        case .middle:
            return "2"
        case .end:
            return "3"
        }
    }
}

/// 考试信息
struct Exam {
    /// 校区
    let campus: String
    /// 考试场次
    let session: String
    /// 课程编号
    let courseID: String
    /// 课程名称
    let courseName: String
    /// 授课教师
    let teacher: String
    /// 考试时间
    let examTime: String
    /// 考场
    let examRoom: String
    /// 座位号
    let seatNumber: String
    /// 准考证号
    let admissionTicketNumber: String
    /// 备注
    let remarks: String
}

@available(macOS 10.15, *)
class EduHelper {
    var session: Session

    init() {
        session = Session()
    }

    private func isLoginRequired(response: String) -> Bool {
        return response.contains("请输入账号")
    }

    /**
     * 检查当前登录状态
     */
    func checkLoginStatus() async throws -> Bool {
        let response = try await session.request(
            "http://xk.csust.edu.cn/jsxsd/framework/xsMain.jsp"
        ).serializingString().value

        return !isLoginRequired(response: response)
    }

    /**
     * 登录
     * - Parameters:
     *   - username: 用户名
     *   - password: 密码
     */
    func login(username: String, password: String) async throws {
        let codeResponse = try await session.request(
            "http://xk.csust.edu.cn/Logon.do?method=logon&flag=sess", method: .post
        ).serializingString().value
        guard !codeResponse.isEmpty else {
            throw EduHelperError.loginFailed("Code response is empty")
        }

        let params = codeResponse.components(separatedBy: "#")
        guard params.count == 2 else {
            throw EduHelperError.loginFailed("Invalid code response format")
        }
        var sourceCode = params[0]
        let sequenceHint = params[1]
        let code = "\(username)%%%\(password)"
        var encoded = ""
        for i in 0..<code.count {
            if i < 20 {
                let charFromCode = String(code[code.index(code.startIndex, offsetBy: i)])
                let hintChar = sequenceHint[
                    sequenceHint.index(sequenceHint.startIndex, offsetBy: i)]
                guard let n = Int(String(hintChar)) else {
                    throw EduHelperError.loginFailed("Invalid character in sequenceHint")
                }
                let extractedChars = String(sourceCode.prefix(n))
                encoded += charFromCode + extractedChars
                sourceCode.removeFirst(n)
            } else {
                let remaining = code[code.index(code.startIndex, offsetBy: i)...]
                encoded += remaining
                break
            }
        }

        let loginParameters: [String: String] = [
            "userAccount": username,
            "userPassword": password,
            "encoded": encoded,
        ]
        let loginResponse = try await session.request(
            "http://xk.csust.edu.cn/Logon.do?method=logon",
            method: .post,
            parameters: loginParameters,
            encoding: URLEncoding.default
        ).serializingString().value
        if isLoginRequired(response: loginResponse) {
            throw EduHelperError.loginFailed("Invalid username or password")
        }
    }

    /**
     * 获取学生档案信息
     * - Returns: 学生档案信息
     */
    func getProfile() async throws -> Profile {
        let profileResponse = try await session.request("http://xk.csust.edu.cn/jsxsd/grxx/xsxx")
            .serializingString().value
        guard !isLoginRequired(response: profileResponse) else {
            throw EduHelperError.notLoggedIn("User is not logged in")
        }

        let document = try SwiftSoup.parse(profileResponse)
        guard let table = try document.select("#xjkpTable > tbody").first() else {
            throw EduHelperError.profileRetrievalFailed("Profile table not found")
        }
        let rows = try table.select("tr")

        func parseTableCell(_ rows: Elements, _ rowIndex: Int, _ colIndex: Int) throws -> String {
            guard rowIndex < rows.count else {
                throw EduHelperError.profileRetrievalFailed("Row index out of bounds")
            }
            let row = rows[rowIndex]
            let cols = try row.select("td")
            guard colIndex < cols.count else {
                throw EduHelperError.profileRetrievalFailed("Column index out of bounds")
            }
            return try cols[colIndex].text().trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let department = try parseTableCell(rows, 2, 0).components(separatedBy: "：")[1]
        let major = try parseTableCell(rows, 2, 1).components(separatedBy: "：")[1]
        let educationSystem = try parseTableCell(rows, 2, 2).components(separatedBy: "：")[1]
        let className = try parseTableCell(rows, 2, 3).components(separatedBy: "：")[1]
        let studentID = try parseTableCell(rows, 2, 4).components(separatedBy: "：")[1]
        let name = try parseTableCell(rows, 3, 1)
        let gender = try parseTableCell(rows, 3, 3)
        let namePinyin = try parseTableCell(rows, 3, 5)
        let birthDate = try parseTableCell(rows, 4, 1)
        let personalPhone = try parseTableCell(rows, 4, 5)
        let ethnicity = try parseTableCell(rows, 7, 3)
        let studyLevel = try parseTableCell(rows, 8, 3)
        let homeAddress = try parseTableCell(rows, 9, 1)
        let homePhone = try parseTableCell(rows, 10, 3)
        let enrollmentDate = try parseTableCell(rows, 46, 1)
        let entranceExamID = try parseTableCell(rows, 47, 1)
        let idCardNumber = try parseTableCell(rows, 47, 3)

        return Profile(
            department: department,
            major: major,
            educationSystem: educationSystem,
            className: className,
            studentID: studentID,
            name: name,
            gender: gender,
            namePinyin: namePinyin,
            birthDate: birthDate,
            ethnicity: ethnicity,
            studyLevel: studyLevel,
            homeAddress: homeAddress,
            homePhone: homePhone,
            personalPhone: personalPhone,
            enrollmentDate: enrollmentDate,
            entranceExamID: entranceExamID,
            idCardNumber: idCardNumber
        )
    }

    /**
     * 登出
     */
    func logout() async throws {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        _ = try await session.request(
            "http://xk.csust.edu.cn/jsxsd/xk/LoginToXk?method=exit&tktime=\(timestamp)"
        )
        .serializingData().value

        session = Session()
    }

    /**
     * 获取考试安排
     * - Parameters:
     *   - academicYearSemester: 学年学期，格式为 "2023-2024-1"，如果为 `nil` 则使用当前默认学期
     *   - semesterType: 学期类型，如果为 `nil` 则查询所有类型的考试
     * - Returns: 考试信息数组
     */
    func getExamSchedule(academicYearSemester: String?, semesterType: SemesterType?) async throws
        -> [Exam]
    {
        var queryAcademicYearSemester: String
        if let academicYearSemester = academicYearSemester {
            queryAcademicYearSemester = academicYearSemester
        } else {
            let semesters = try await getAvailableSemestersForExamSchedule()
            queryAcademicYearSemester = semesters.1.name
        }

        let queryParams = [
            "xqlbmc": semesterType?.rawValue ?? "",
            "xnxqid": queryAcademicYearSemester,
            "xqlb": semesterType?.id ?? "",
        ]
        let response = try await session.request(
            "http://xk.csust.edu.cn/jsxsd/xsks/xsksap_list", method: .post, parameters: queryParams,
            encoding: URLEncoding.default
        )
        .serializingString().value
        guard !isLoginRequired(response: response) else {
            throw EduHelperError.notLoggedIn("User is not logged in")
        }

        let document = try SwiftSoup.parse(response)
        guard let table = try document.select("#dataList").first() else {
            throw EduHelperError.examScheduleRetrievalFailed("Exam schedule table not found")
        }
        guard !(try table.html().contains("未查询到数据")) else {
            return []
        }

        let rows = try table.select("tr")
        var exams: [Exam] = []

        for (index, row) in rows.enumerated() {
            guard index > 0 else { continue }
            let cols = try row.select("td")
            guard cols.count >= 11 else {
                throw EduHelperError.examScheduleRetrievalFailed(
                    "Row does not contain enough columns: \(cols.count)")
            }
            let campus = try cols[1].text().trimmingCharacters(in: .whitespacesAndNewlines)
            let session = try cols[2].text().trimmingCharacters(in: .whitespacesAndNewlines)
            let courseID = try cols[3].text().trimmingCharacters(in: .whitespacesAndNewlines)
            let courseName = try cols[4].text().trimmingCharacters(in: .whitespacesAndNewlines)
            let teacher = try cols[5].text().trimmingCharacters(in: .whitespacesAndNewlines)
            let examTime = try cols[6].text().trimmingCharacters(in: .whitespacesAndNewlines)
            let examRoom = try cols[7].text().trimmingCharacters(in: .whitespacesAndNewlines)
            let seatNumber = try cols[8].text().trimmingCharacters(in: .whitespacesAndNewlines)
            let admissionTicketNumber = try cols[9].text().trimmingCharacters(
                in: .whitespacesAndNewlines)
            let remarks = try cols[10].text().trimmingCharacters(in: .whitespacesAndNewlines)

            let exam = Exam(
                campus: campus,
                session: session,
                courseID: courseID,
                courseName: courseName,
                teacher: teacher,
                examTime: examTime,
                examRoom: examRoom,
                seatNumber: seatNumber,
                admissionTicketNumber: admissionTicketNumber,
                remarks: remarks
            )
            exams.append(exam)
        }

        return exams
    }

    /**
     * 获取考试安排的所有可用学期以及默认学期
     * - Returns: 包含所有可用学期的数组和默认学期
     */
    func getAvailableSemestersForExamSchedule() async throws -> ([Semester], Semester) {
        let response = try await session.request("http://xk.csust.edu.cn/jsxsd/xsks/xsksap_query")
            .serializingString().value
        guard !isLoginRequired(response: response) else {
            throw EduHelperError.notLoggedIn("User is not logged in")
        }

        let document = try SwiftSoup.parse(response)
        guard let semesterSelect = try document.select("#xnxqid").first() else {
            throw EduHelperError.examScheduleForAllSemestersRetrievalFailed(
                "Semester select element not found")
        }

        let options = try semesterSelect.select("option")
        var semesters: [Semester] = []
        var defaultSemester: Semester?
        for option in options {
            let name = try option.text().trimmingCharacters(in: .whitespacesAndNewlines)
            let isDefault = option.hasAttr("selected")
            if isDefault {
                defaultSemester = Semester(name: name, isDefault: true)
            }
            semesters.append(Semester(name: name, isDefault: isDefault))
        }

        guard !semesters.isEmpty else {
            throw EduHelperError.examScheduleForAllSemestersRetrievalFailed(
                "No semesters found in the select element")
        }

        guard let defaultSemester = defaultSemester else {
            throw EduHelperError.examScheduleForAllSemestersRetrievalFailed(
                "Default semester not found")
        }

        return (semesters, defaultSemester)
    }
}
