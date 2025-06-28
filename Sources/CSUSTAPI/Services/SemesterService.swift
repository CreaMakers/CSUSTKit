import Foundation
import SwiftSoup

class SemesterService: BaseService {
    /**
     * 获取学期首日
     * - Parameter academicYearSemester: 学年学期，格式为 "2023-2024-1"，如果为 `nil` 则使用当前默认学期
     * - Returns: 学期首日
     */
    func getSemesterStartDate(academicYearSemester: String? = nil) async throws -> Date {
        let queryParams = [
            "xnxq01id": academicYearSemester ?? ""
        ]
        let response = try await performRequest(
            "http://xk.csust.edu.cn/jsxsd/jxzl/jxzl_query", .post, queryParams)
        let document = try SwiftSoup.parse(response)

        guard let table = try document.select("#kbtable").first() else {
            throw EduHelperError.semesterStartDateRetrievalFailed(
                "Semester start date table not found")
        }

        let rows = try table.select("tr")
        guard rows.count > 1 else {
            throw EduHelperError.semesterStartDateRetrievalFailed(
                "Semester start date table does not contain enough rows")
        }
        let targetRow = rows[1]
        let cols = try targetRow.select("td")
        guard cols.count > 1 else {
            throw EduHelperError.semesterStartDateRetrievalFailed(
                "Target row does not contain enough columns")
        }
        let startDateText = try cols[1].attr("title").trim()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd"
        guard let startDate = dateFormatter.date(from: startDateText) else {
            throw EduHelperError.semesterStartDateRetrievalFailed(
                "Failed to parse semester start date: \(startDateText)")
        }

        return startDate
    }

    /**
     * 获取学期首日所有可选的学期
     * - Returns: 包含所有可用学期的数组和默认学期
     */
    func getAvailableSemestersForStartDate() async throws -> ([String], String) {
        let response = try await performRequest("http://xk.csust.edu.cn/jsxsd/jxzl/jxzl_query")
        let document = try SwiftSoup.parse(response)

        guard let select = try document.select("#xnxq01id").first() else {
            throw EduHelperError.availableSemestersForStartDateRetrievalFailed(
                "Semester select element not found")
        }

        let options = try select.select("option")
        var semesters: [String] = []
        var defaultSemester: String?

        for option in options {
            let name = try option.text().trim()
            if option.hasAttr("selected") {
                defaultSemester = name
            }
            semesters.append(name)
        }

        guard !semesters.isEmpty else {
            throw EduHelperError.availableSemestersForStartDateRetrievalFailed(
                "No semesters found in the select element")
        }

        guard let defaultSemester = defaultSemester else {
            throw EduHelperError.availableSemestersForStartDateRetrievalFailed(
                "Default semester not found")
        }

        return (semesters, defaultSemester)
    }
}
