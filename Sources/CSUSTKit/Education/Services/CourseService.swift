import Alamofire
import Foundation
import SwiftSoup

public class CourseService: BaseService {
    /**
     * 获取课程成绩
     * - Parameters:
     *   - academicYearSemester: 学年学期，格式为 "2023-2024-1"，如果为 `nil` 则为全部学期
     *   - courseNature: 课程性质，如果为 `nil` 则查询所有性质的课程
     *   - courseName: 课程名称，默认为空字符串表示查询所有课程
     *   - displayMode: 显示模式，默认为显示最好成绩
     *   - studyMode: 修读方式，默认为主修
     * - Returns: 课程成绩信息数组
     */
    public func getCourseGrades(
        academicYearSemester: String = "", courseNature: CourseNature? = nil,
        courseName: String = "",
        displayMode: DisplayMode = .bestGrade, studyMode: StudyMode = .major
    ) async throws -> [CourseGrade] {
        let queryParams = [
            "kksj": academicYearSemester,
            "kcxz": courseNature?.id ?? "",
            "kcmc": courseName,
            "xsfs": displayMode.id,
            "fxkc": studyMode.id,
        ]
        let response = try await performRequest(
            "http://xk.csust.edu.cn/jsxsd/kscj/cjcx_list", .post, queryParams)

        let document = try SwiftSoup.parse(response)

        guard let table = try document.select("#dataList").first() else {
            throw EduHelperError.courseGradesRetrievalFailed("Course grades table not found")
        }
        guard !(try table.html().contains("未查询到数据")) else {
            return []
        }

        let rows = try table.select("tr")
        var courseGrades: [CourseGrade] = []

        for (index, row) in rows.enumerated() {
            guard index > 0 else { continue }
            let cols = try row.select("td")
            guard cols.count >= 17 else {
                throw EduHelperError.courseGradesRetrievalFailed(
                    "Row does not contain enough columns: \(cols.count)")
            }

            let semester = try cols[1].text().trim()
            let courseID = try cols[2].text().trim()
            let courseName = try cols[3].text().trim()
            let groupName = try cols[4].text().trim()
            let gradeString = try cols[5].text().trim()
            guard let grade = Int(gradeString) else {
                throw EduHelperError.courseGradesRetrievalFailed(
                    "Invalid grade format: \(gradeString)")
            }
            let gradeDetailUrl = try cols[5].select("a").first()?.attr("href").trim()
            guard var gradeDetailUrl = gradeDetailUrl else {
                throw EduHelperError.courseGradesRetrievalFailed("Grade detail URL not found")
            }
            gradeDetailUrl =
                gradeDetailUrl
                .replacingOccurrences(of: "javascript:openWindow('", with: "http://xk.csust.edu.cn")
                .replacingOccurrences(of: "',700,500)", with: "")
            let studyMode = try cols[6].text().trim()
            let gradeIdentifier = try cols[7].text().trim()
            let creditString = try cols[8].text().trim()
            guard let credit = Double(creditString) else {
                throw EduHelperError.courseGradesRetrievalFailed(
                    "Invalid credit format: \(creditString)")
            }
            let totalHoursString = try cols[9].text().trim()
            guard let totalHours = Int(totalHoursString) else {
                throw EduHelperError.courseGradesRetrievalFailed(
                    "Invalid total hours format: \(totalHoursString)")
            }
            let gradePointString = try cols[10].text().trim()
            guard let gradePoint = Double(gradePointString) else {
                throw EduHelperError.courseGradesRetrievalFailed(
                    "Invalid grade point format: \(gradePointString)")
            }
            let retakeSemester = try cols[11].text().trim()
            let assessmentMethod = try cols[12].text().trim()
            let examNature = try cols[13].text().trim()
            let courseAttribute = try cols[14].text().trim()
            let courseNatureString = try cols[15].text().trim()
            guard let courseNature = CourseNature(rawValue: courseNatureString) else {
                throw EduHelperError.courseGradesRetrievalFailed(
                    "Invalid course nature: \(courseNatureString)")
            }
            let courseCategory = try cols[16].text().trim()

            let courseGrade = CourseGrade(
                semester: semester,
                courseID: courseID,
                courseName: courseName,
                groupName: groupName,
                grade: grade,
                gradeDetailUrl: gradeDetailUrl,
                studyMode: studyMode,
                gradeIdentifier: gradeIdentifier,
                credit: credit,
                totalHours: totalHours,
                gradePoint: gradePoint,
                retakeSemester: retakeSemester,
                assessmentMethod: assessmentMethod,
                examNature: examNature,
                courseAttribute: courseAttribute,
                courseNature: courseNature,
                courseCategory: courseCategory
            )

            courseGrades.append(courseGrade)
        }

        return courseGrades
    }

    /**
     * 获取课程成绩的所有可用学期
     * - Returns: 包含所有可用学期的数组
     */
    public func getAvailableSemestersForCourseGrades() async throws -> [String] {
        let response = try await performRequest("http://xk.csust.edu.cn/jsxsd/kscj/cjcx_query")

        let document = try SwiftSoup.parse(response)
        guard let semesterSelect = try document.select("#kksj").first() else {
            throw EduHelperError.availableSemestersForCourseGradesRetrievalFailed(
                "Semester select element not found")
        }

        let options = try semesterSelect.select("option")
        var semesters: [String] = []
        for option in options {
            let name = try option.text().trim()
            if name.contains("全部学期") {
                continue
            }
            semesters.append(name)
        }

        return semesters
    }

    public func getGradeDetail(url: String) async throws -> GradeDetail {
        let response = try await performRequest(url)

        let document = try SwiftSoup.parse(response)
        guard let table = try document.select("#dataList").first() else {
            throw EduHelperError.gradeDetailRetrievalFailed("Grade detail table not found")
        }
        let rows = try table.select("tr")
        guard rows.count >= 2 else {
            throw EduHelperError.gradeDetailRetrievalFailed(
                "Grade detail table does not contain enough rows")
        }
        let headerRow = rows[0]
        let headerCols = try headerRow.select("th")
        let valueRow = rows[1]
        let valueCols = try valueRow.select("td")

        guard headerCols.count >= 4, valueCols.count >= 4 else {
            throw EduHelperError.gradeDetailRetrievalFailed(
                "Grade detail table does not contain enough columns: \(headerCols.count), \(valueCols.count)"
            )
        }

        var components: [GradeComponent] = []

        for i in stride(from: 1, to: headerCols.count - 1, by: 2) {
            let type = try headerCols[i].text().trim()
            let grade = try valueCols[i].text().trim()
            let ratio = try valueCols[i + 1].text().trim()
            guard let gradeValue = Double(grade) else {
                throw EduHelperError.gradeDetailRetrievalFailed("Invalid grade format: \(grade)")
            }
            let component = GradeComponent(
                type: type,
                grade: gradeValue,
                ratio: ratio
            )
            components.append(component)
        }

        let totalGrade = try valueCols.last()?.text().trim()
        guard let totalGradeString = totalGrade, let totalGradeValue = Int(totalGradeString) else {
            throw EduHelperError.gradeDetailRetrievalFailed(
                "Invalid total grade format: \(String(describing: totalGrade))")
        }
        return GradeDetail(components: components, totalGrade: totalGradeValue)
    }

    private func parseDate(date: String) throws -> ([Int], [Int]) {
        enum WeekType: String, CaseIterable {
            case single = "(单周)"
            case double = "(双周)"
            case all = "(周)"
        }

        var weekType: WeekType? = nil
        for type in WeekType.allCases {
            if date.contains(type.rawValue) {
                weekType = type
                break
            }
        }
        guard let weekType = weekType else {
            throw EduHelperError.courseScheduleRetrievalFailed(
                "Invalid week type in date: \(date).")
        }

        let parts = date.components(separatedBy: weekType.rawValue)
        guard parts.count == 2 else {
            throw EduHelperError.courseScheduleRetrievalFailed("Invalid date format: \(date).")
        }
        let weekPart = parts[0]
        let sectionPart = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "[]节"))

        var weeks: [Int] = []
        var sections: [Int] = []

        for weekSection in weekPart.components(separatedBy: ",") {
            if weekSection.contains("-") {
                let rangeParts = weekSection.components(separatedBy: "-")
                guard rangeParts.count == 2, let startWeek = Int(rangeParts[0].trim()),
                    let endWeek = Int(rangeParts[1].trim())
                else {
                    throw EduHelperError.courseScheduleRetrievalFailed(
                        "Invalid week range format: \(weekSection)")
                }
                if startWeek > endWeek {
                    throw EduHelperError.courseScheduleRetrievalFailed(
                        "Start week \(startWeek) is greater than end week \(endWeek).")
                }
                switch weekType {
                case .single:
                    weeks.append(contentsOf: (startWeek...endWeek).filter { $0 % 2 != 0 })
                case .double:
                    weeks.append(contentsOf: (startWeek...endWeek).filter { $0 % 2 == 0 })
                case .all:
                    weeks.append(contentsOf: startWeek...endWeek)
                }
            } else {
                if let week = Int(weekSection) {
                    weeks.append(week)
                } else {
                    throw EduHelperError.courseScheduleRetrievalFailed(
                        "Invalid week format: \(weekSection)")
                }
            }
        }

        for section in sectionPart.components(separatedBy: "-") {
            guard let sectionNumber = Int(section) else {
                throw EduHelperError.courseScheduleRetrievalFailed(
                    "Invalid section format: \(section)")
            }
            sections.append(sectionNumber)
        }

        return (weeks, sections)
    }

    private struct ParsedItem {
        let courseName: String
        let groupName: String?
        let teacherName: String
        let weeks: [Int]
        let sections: [Int]
        let classroom: String?
    }

    private func parseCourse(element: Element) throws -> [ParsedItem] {
        guard !(try element.text().trim().isEmpty) else {
            return []
        }

        guard let contentElement = try element.select("div.kbcontent").first() else {
            throw EduHelperError.courseScheduleRetrievalFailed("Course content element not found")
        }

        var courseSchedules: [ParsedItem] = []

        let courseHTMLs = try contentElement.html().components(separatedBy: "---------------------")

        for courseHTML in courseHTMLs {
            let trimmedHTML = courseHTML.trim()
            guard !trimmedHTML.isEmpty else { continue }

            let courseFragment = try SwiftSoup.parseBodyFragment(trimmedHTML)
            guard let courseBody = try courseFragment.select("body").first() else {
                throw EduHelperError.courseScheduleRetrievalFailed("Course body not found")
            }

            guard let courseName = courseBody.textNodes().first?.text().trim() else {
                throw EduHelperError.courseScheduleRetrievalFailed("Course name not found")
            }

            var groupName: String? = nil
            if courseBody.textNodes().count > 1 && !courseBody.textNodes()[1].text().trim().isEmpty
            {
                groupName = courseBody.textNodes()[1].text().trim()
            }

            guard let teacherName = try courseBody.select("font[title='老师']").first()?.text()
            else {
                throw EduHelperError.courseScheduleRetrievalFailed("Teacher name not found")
            }
            let classroom = try courseBody.select("font[title='教室']").first()?.text()
            guard let dateText = try courseBody.select("font[title='周次(节次)']").first()?.text()
            else {
                throw EduHelperError.courseScheduleRetrievalFailed("Date text not found")
            }
            let (weeks, sections) = try parseDate(date: dateText)
            guard !weeks.isEmpty, !sections.isEmpty else {
                throw EduHelperError.courseScheduleRetrievalFailed("Invalid weeks or sections")
            }

            courseSchedules.append(
                ParsedItem(
                    courseName: courseName,
                    groupName: groupName,
                    teacherName: teacherName,
                    weeks: weeks,
                    sections: sections,
                    classroom: classroom
                )
            )
        }

        return courseSchedules
    }

    /**
     * 获取课程表
     * - Parameter academicYearSemester: 学年学期，格式为 "2023-2024-1"，如果为 `nil` 则查询默认学期
     * - Returns: 课程信息数组
     */
    public func getCourseSchedule(academicYearSemester: String? = nil) async throws -> [Course] {
        let queryParams: [String: String] = ["xnxq01id": academicYearSemester ?? ""]
        let response = try await performRequest(
            "http://xk.csust.edu.cn/jsxsd/xskb/xskb_list.do", .post, queryParams)
        let document = try SwiftSoup.parse(response)

        guard let table = try document.select("#kbtable").first() else {
            throw EduHelperError.courseScheduleRetrievalFailed("Course schedule table not found")
        }

        var courseDictionary: [String: Course] = [:]

        let rows = try table.select("tr")
        for (rowIndex, row) in rows.enumerated() {
            guard rowIndex > 0 else { continue }
            guard rowIndex < rows.count - 1 else { continue }
            let cols = try row.select("td")
            for (colIndex, col) in cols.enumerated() {
                guard let day = DayOfWeek(rawValue: colIndex) else {
                    throw EduHelperError.courseScheduleRetrievalFailed(
                        "Invalid day of week index: \(colIndex)")
                }

                let parsedItems = try parseCourse(element: col)
                for item in parsedItems {
                    let newSession = ScheduleSession(
                        weeks: item.weeks, sections: item.sections, dayOfWeek: day,
                        classroom: item.classroom)

                    if var existingCourse = courseDictionary[item.courseName] {
                        if !existingCourse.sessions.contains(newSession) {
                            existingCourse.sessions.append(newSession)
                        }
                        courseDictionary[item.courseName] = existingCourse
                    } else {
                        let newCourse = Course(
                            courseName: item.courseName,
                            groupName: item.groupName,
                            teacher: item.teacherName,
                            sessions: [newSession]
                        )
                        courseDictionary[item.courseName] = newCourse
                    }
                }
            }
        }

        return Array(courseDictionary.values)
    }

    /**
     * 获取课程表的所有可用学期
     * - Returns: 包含所有可用学期的数组和默认学期
     */
    public func getAvailableSemestersForCourseSchedule() async throws -> ([String], String) {
        let response = try await performRequest("http://xk.csust.edu.cn/jsxsd/xskb/xskb_list.do")
        let document = try SwiftSoup.parse(response)

        guard let semesterSelect = try document.select("#xnxq01id").first() else {
            throw EduHelperError.availableSemestersForCourseScheduleRetrievalFailed(
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
            throw EduHelperError.availableSemestersForCourseScheduleRetrievalFailed(
                "No semesters found in the select element")
        }

        guard let defaultSemester = defaultSemester else {
            throw EduHelperError.availableSemestersForCourseScheduleRetrievalFailed(
                "Default semester not found")
        }

        return (semesters, defaultSemester)
    }
}
