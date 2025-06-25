import Alamofire
import Foundation
import SwiftSoup

enum EduHelperError: Error {
    case loginFailed(String)
    case profileRetrievalFailed(String)
    case notLoggedIn(String)
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

@available(macOS 10.15, *)
class EduHelper {
    var session: Session

    init() {
        session = Session()
    }

    private func isLoginRequired(response: String) -> Bool {
        return response.contains("请输入账号")
    }

    func checkLoginStatus() async throws -> Bool {
        let response = try await session.request(
            "http://xk.csust.edu.cn/jsxsd/framework/xsMain.jsp"
        ).serializingString().value

        return !isLoginRequired(response: response)
    }

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

    func logout() async throws {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        _ = try await session.request(
            "http://xk.csust.edu.cn/jsxsd/xk/LoginToXk?method=exit&tktime=\(timestamp)"
        )
        .serializingData().value

        session = Session()
    }
}
