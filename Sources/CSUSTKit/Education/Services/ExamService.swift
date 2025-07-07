import Alamofire
import SwiftSoup

public class ExamService: BaseService {
    /**
     * 获取考试安排
     * - Parameters:
     *   - academicYearSemester: 学年学期，格式为 "2023-2024-1"，如果为 `nil` 则使用当前默认学期
     *   - semesterType: 学期类型，如果为 `nil` 则查询所有类型的考试
     * - Returns: 考试信息数组
     */
    public func getExamSchedule(academicYearSemester: String? = nil, semesterType: SemesterType? = nil)
        async throws
        -> [Exam]
    {
        var queryAcademicYearSemester: String
        if let academicYearSemester = academicYearSemester {
            queryAcademicYearSemester = academicYearSemester
        } else {
            let semesters = try await getAvailableSemestersForExamSchedule()
            queryAcademicYearSemester = semesters.1
        }

        let queryParams = [
            "xqlbmc": semesterType?.rawValue ?? "",
            "xnxqid": queryAcademicYearSemester,
            "xqlb": semesterType?.id ?? "",
        ]
        let response = try await performRequest(
            "http://xk.csust.edu.cn/jsxsd/xsks/xsksap_list", .post, queryParams)

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

            let exam = Exam(
                campus: try cols[1].text().trim(),
                session: try cols[2].text().trim(),
                courseID: try cols[3].text().trim(),
                courseName: try cols[4].text().trim(),
                teacher: try cols[5].text().trim(),
                examTime: try cols[6].text().trim(),
                examRoom: try cols[7].text().trim(),
                seatNumber: try cols[8].text().trim(),
                admissionTicketNumber: try cols[9].text().trim(),
                remarks: try cols[10].text().trim()
            )
            exams.append(exam)
        }

        return exams
    }

    /**
     * 获取考试安排的所有可用学期以及默认学期
     * - Returns: 包含所有可用学期的数组和默认学期
     */
    public func getAvailableSemestersForExamSchedule() async throws -> ([String], String) {
        let response = try await performRequest(
            "http://xk.csust.edu.cn/jsxsd/xsks/xsksap_query")

        let document = try SwiftSoup.parse(response)
        guard let semesterSelect = try document.select("#xnxqid").first() else {
            throw EduHelperError.availableSemestersForExamScheduleRetrievalFailed(
                "Semester select element not found")
        }

        let options = try semesterSelect.select("option")
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
            throw EduHelperError.availableSemestersForExamScheduleRetrievalFailed(
                "No semesters found in the select element")
        }

        guard let defaultSemester = defaultSemester else {
            throw EduHelperError.availableSemestersForExamScheduleRetrievalFailed(
                "Default semester not found")
        }

        return (semesters, defaultSemester)
    }
}
