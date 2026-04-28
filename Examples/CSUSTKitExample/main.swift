import Alamofire
import CSUSTKit
import Foundation

@main
struct Main {
    static func main() async {
        let session = Session(interceptor: EduHelper.EduRequestInterceptor())
        await runEntryMenu(session: session)
        print("程序已退出。")
    }
}

private func runEntryMenu(session: Session) async {
    let campusCardHelper = CampusCardHelper(session: session)

    while true {
        print("")
        print("=== 入口菜单 ===")
        print("1. 登录演示")
        print("2. WebVPN 工具")
        print("3. 宿舍电量查询")
        print("0. 退出")

        switch prompt("请选择操作") {
        case "1":
            await runLoginDemo(session: session)
        case "2":
            runWebVPNMenu()
        case "3":
            await runDormElectricityMenu(using: campusCardHelper)
        case "0":
            return
        default:
            print("输入无效，请重新选择。")
        }
    }
}

private func runLoginDemo(session: Session) async {
    let connectionMode = selectConnectionMode()
    let ssoHelper = SSOHelper(mode: connectionMode, session: session)

    let didLogin = await performSSOLogin(using: ssoHelper)
    guard didLogin else {
        print("已返回入口菜单。")
        return
    }

    await runMainMenu(using: ssoHelper, connectionMode: connectionMode, session: session)
}

private func selectConnectionMode() -> ConnectionMode {
    while true {
        print("")
        print("=== 网络模式 ===")
        print("1. 直接连接")
        print("2. WebVPN")
        let input = prompt("请选择网络模式")

        switch input {
        case "1":
            return .direct
        case "2":
            return .webVpn
        default:
            print("输入无效，请输入 1 或 2。")
        }
    }
}

private func performSSOLogin(using ssoHelper: SSOHelper) async -> Bool {
    while true {
        do {
            print("")
            print("=== 统一认证登录 ===")

            let loginForm = try await ssoHelper.getLoginForm()
            let username = promptNonEmpty("请输入用户名")
            let needCaptcha = try await ssoHelper.checkNeedCaptcha(username: username)

            var captcha: String?
            if needCaptcha {
                let captchaImageData = try await ssoHelper.getCaptcha()
                let captchaImageURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent("captcha.jpg")
                try captchaImageData.write(to: captchaImageURL)
                print("验证码已保存到 \(captchaImageURL.path)")
                captcha = promptNonEmpty("请输入验证码")
            }

            let password = promptNonEmpty("请输入密码")
            try await ssoHelper.login(
                loginForm: loginForm,
                username: username,
                password: password,
                captcha: captcha
            )

            let user = try await ssoHelper.getLoginUser()
            print("")
            print("登录成功")
            print("姓名: \(user.userName)")
            print("学号: \(user.userAccount)")
            print("学院: \(user.deptName)")
            return true
        } catch {
            print("")
            print("登录失败: \(error)")
            print("1. 重试登录")
            print("0. 返回入口菜单")
            let retryChoice = prompt("请选择")
            if retryChoice == "1" {
                continue
            }
            return false
        }
    }
}

private func runMainMenu(using ssoHelper: SSOHelper, connectionMode: ConnectionMode, session: Session) async {
    let moocHelper: MoocHelper = MoocHelper(mode: connectionMode, session: session)
    let eduHelper: EduHelper = EduHelper(mode: connectionMode, session: session)

    while true {
        print("")
        print("=== 主菜单 ===")
        print("1. 网络课程中心")
        print("2. 教务系统")
        print("0. 返回入口菜单")

        switch prompt("请选择操作") {
        case "1":
            do {
                _ = try await ssoHelper.loginToMooc()
                await runMoocMenu(using: moocHelper)
            } catch {
                print("进入网络课程中心失败: \(error)")
            }
        case "2":
            do {
                _ = try await ssoHelper.loginToEducation()
                await runEducationMenu(using: eduHelper)
            } catch {
                print("进入教务系统失败: \(error)")
            }
        case "0":
            return
        default:
            print("输入无效，请重新选择。")
        }
    }
}

private func runMoocMenu(using moocHelper: MoocHelper) async {
    while true {
        print("")
        print("=== 网络课程中心 ===")
        print("1. 查看个人信息")
        print("2. 查看课程列表")
        print("3. 查看待完成作业课程")
        print("4. 查看某门课程的作业")
        print("5. 查看某门课程的测验")
        print("0. 返回上一级")

        switch prompt("请选择操作") {
        case "1":
            await handleAsyncOperation {
                let profile = try await moocHelper.getProfile()
                print("")
                print("姓名: \(profile.name)")
                print("上次登录: \(profile.lastLoginTime)")
                print("在线总时长: \(profile.totalOnlineTime)")
                print("登录次数: \(profile.loginCount)")
            }
        case "2":
            await handleAsyncOperation {
                let courses = try await moocHelper.getCourses()
                printMoocCourses(courses)
            }
        case "3":
            await handleAsyncOperation {
                let courses = try await moocHelper.getCoursesWithPendingAssignments()
                if courses.isEmpty {
                    print("暂无待完成作业课程。")
                } else {
                    print("待完成作业课程:")
                    printMoocCourses(courses)
                }
            }
        case "4":
            await handleAsyncOperation {
                guard let course = try await selectMoocCourse(using: moocHelper) else {
                    return
                }
                let assignments = try await moocHelper.getCourseAssignments(course: course)
                printAssignments(assignments, for: course)
            }
        case "5":
            await handleAsyncOperation {
                guard let course = try await selectMoocCourse(using: moocHelper) else {
                    return
                }
                let exams = try await moocHelper.getCourseExams(course: course)
                printMoocExams(exams, for: course)
            }
        case "0":
            return
        default:
            print("输入无效，请重新选择。")
        }
    }
}

private func runEducationMenu(using eduHelper: EduHelper) async {
    while true {
        print("")
        print("=== 教务系统 ===")
        print("1. 查看个人信息")
        print("2. 查看考试安排")
        print("3. 查看课程成绩")
        print("4. 查看课程表")
        print("5. 查看空闲教室")
        print("0. 返回上一级")

        switch prompt("请选择操作") {
        case "1":
            await handleAsyncOperation {
                let profile = try await eduHelper.profileService.getProfile()
                print("")
                print("姓名: \(profile.name)")
                print("学号: \(profile.studentID)")
                print("院系: \(profile.department)")
                print("专业: \(profile.major)")
                print("班级: \(profile.className)")
                print("联系电话: \(profile.personalPhone)")
            }
        case "2":
            await handleAsyncOperation {
                let exams = try await eduHelper.examService.getExamSchedule()
                printEducationExams(exams)
            }
        case "3":
            await handleAsyncOperation {
                let grades = try await eduHelper.courseService.getCourseGrades()
                printCourseGrades(grades)
            }
        case "4":
            await handleAsyncOperation {
                let courses = try await eduHelper.courseService.getCourseSchedule()
                printEducationCourses(courses)
            }
        case "5":
            await handleAsyncOperation {
                let classroomQuery = promptClassroomQuery()
                let classrooms = try await eduHelper.courseService.getAvailableClassrooms(
                    campus: classroomQuery.campus,
                    week: classroomQuery.week,
                    dayOfWeek: classroomQuery.dayOfWeek,
                    section: classroomQuery.section
                )
                printAvailableClassrooms(classrooms, query: classroomQuery)
            }
        case "0":
            return
        default:
            print("输入无效，请重新选择。")
        }
    }
}

private func runWebVPNMenu() {
    while true {
        print("")
        print("=== WebVPN 工具 ===")
        print("1. 原始 URL 转 WebVPN URL")
        print("2. WebVPN URL 还原原始 URL")
        print("0. 返回上一级")

        switch prompt("请选择操作") {
        case "1":
            let originalURL = promptNonEmpty("请输入原始 URL")
            do {
                let vpnURL = try WebVPNHelper.encryptURL(originalURL: originalURL)
                print("")
                print("转换结果:")
                print(vpnURL)
            } catch {
                print("转换失败: \(error)")
            }
        case "2":
            let vpnURL = promptNonEmpty("请输入 WebVPN URL")
            do {
                let originalURL = try WebVPNHelper.decryptURL(vpnURL: vpnURL)
                print("")
                print("转换结果:")
                print(originalURL)
            } catch {
                print("转换失败: \(error)")
            }
        case "0":
            return
        default:
            print("输入无效，请重新选择。")
        }
    }
}

private func runDormElectricityMenu(using campusCardHelper: CampusCardHelper) async {
    while true {
        print("")
        print("=== 宿舍电量查询 ===")
        print("1. 查询宿舍电量")
        print("0. 返回上一级")

        switch prompt("请选择操作") {
        case "1":
            await handleAsyncOperation {
                let campus = promptCampus()
                let buildings = try await campusCardHelper.getBuildings(for: campus)
                guard !buildings.isEmpty else {
                    print("\(campus.displayName) 暂无可选楼栋。")
                    return
                }
                guard
                    let building = selectIndexedItem(
                        title: "\(campus.displayName) 楼栋列表",
                        items: buildings,
                        display: { $0.name }
                    )
                else {
                    return
                }
                let room = promptNonEmpty("请输入宿舍号")
                let electricity = try await campusCardHelper.getElectricity(building: building, room: room)
                print("")
                print("查询结果:")
                print("校区: \(campus.displayName)")
                print("楼栋: \(building.name)")
                print("宿舍号: \(room)")
                print("剩余电量: \(formatElectricity(electricity)) 度")
            }
        case "0":
            return
        default:
            print("输入无效，请重新选择。")
        }
    }
}

private func handleAsyncOperation(_ operation: () async throws -> Void) async {
    do {
        try await operation()
    } catch {
        print("操作失败: \(error)")
    }
}

private func selectMoocCourse(using moocHelper: MoocHelper) async throws -> MoocHelper.Course? {
    let courses = try await moocHelper.getCourses()
    guard !courses.isEmpty else {
        print("暂无课程数据。")
        return nil
    }

    return selectIndexedItem(
        title: "请选择课程",
        items: courses,
        display: { course in
            let teacher = course.teacher?.isEmpty == false ? course.teacher! : "未知教师"
            let number = course.number?.isEmpty == false ? course.number! : "无编号"
            return "\(course.name) [\(number)] - \(teacher)"
        }
    )
}

private func promptCampus() -> CampusCardHelper.Campus {
    let campus: CampusCardHelper.Campus = promptSelection(
        title: "请选择校区",
        options: [("1", "云塘"), ("2", "金盆岭")],
        mapper: { input in
            switch input {
            case "1":
                return .yuntang
            case "2":
                return .jinpenling
            default:
                return nil
            }
        })
    return campus
}

private func promptClassroomQuery() -> ClassroomQuery {
    let campus = promptCampus()
    let week = promptInt("请输入周次", validRange: 1...30)
    let dayNumber = promptInt("请输入星期（1-7）", validRange: 1...7)
    let section = promptInt("请输入大节（1-5）", validRange: 1...5)

    let dayOfWeekMap: [Int: EduHelper.DayOfWeek] = [
        1: .monday,
        2: .tuesday,
        3: .wednesday,
        4: .thursday,
        5: .friday,
        6: .saturday,
        7: .sunday,
    ]

    return ClassroomQuery(
        campus: campus,
        week: week,
        dayOfWeek: dayOfWeekMap[dayNumber] ?? .monday,
        section: section
    )
}

private struct ClassroomQuery {
    let campus: CampusCardHelper.Campus
    let week: Int
    let dayOfWeek: EduHelper.DayOfWeek
    let section: Int
}

private func prompt(_ message: String) -> String {
    print("\(message)：", terminator: " ")
    return readLine()?.trimmed() ?? ""
}

private func promptNonEmpty(_ message: String) -> String {
    while true {
        let input = prompt(message)
        if !input.isEmpty {
            return input
        }
        print("输入不能为空，请重新输入。")
    }
}

private func promptInt(_ message: String, validRange: ClosedRange<Int>) -> Int {
    while true {
        let input = prompt(message)
        if let value = Int(input), validRange.contains(value) {
            return value
        }
        print("输入无效，请输入 \(validRange.lowerBound)-\(validRange.upperBound) 之间的整数。")
    }
}

private func promptSelection<T>(
    title: String,
    options: [(String, String)],
    mapper: (String) -> T?
) -> T {
    while true {
        print("")
        print(title)
        for option in options {
            print("\(option.0). \(option.1)")
        }
        let input = prompt("请选择")
        if let value = mapper(input) {
            return value
        }
        print("输入无效，请重新选择。")
    }
}

private func selectIndexedItem<T>(
    title: String,
    items: [T],
    display: (T) -> String
) -> T? {
    guard !items.isEmpty else {
        return nil
    }

    while true {
        print("")
        print(title)
        for (index, item) in items.enumerated() {
            print("\(index + 1). \(display(item))")
        }
        print("0. 返回")

        let input = prompt("请选择")
        if input == "0" {
            return nil
        }
        if let index = Int(input), items.indices.contains(index - 1) {
            return items[index - 1]
        }
        print("输入无效，请重新选择。")
    }
}

private func printMoocCourses(_ courses: [MoocHelper.Course]) {
    guard !courses.isEmpty else {
        print("暂无课程数据。")
        return
    }

    print("")
    print("课程列表:")
    for (index, course) in courses.enumerated() {
        let number = course.number?.isEmpty == false ? course.number! : "无编号"
        let teacher = course.teacher?.isEmpty == false ? course.teacher! : "未知教师"
        let department = course.department?.isEmpty == false ? course.department! : "未知院系"
        print("\(index + 1). \(course.name)")
        print("   编号: \(number) | 教师: \(teacher) | 院系: \(department)")
    }
}

private func printAssignments(_ assignments: [MoocHelper.Assignment], for course: MoocHelper.Course) {
    guard !assignments.isEmpty else {
        print("\(course.name) 暂无作业数据。")
        return
    }

    print("")
    print("\(course.name) 的作业:")
    for (index, assignment) in assignments.enumerated() {
        print("\(index + 1). \(assignment.title)")
        print("   发布人: \(assignment.publisher)")
        print("   开始时间: \(displayDate(assignment.startTime))")
        print("   截止时间: \(displayDate(assignment.deadline))")
        print("   可提交: \(assignment.canSubmit ? "是" : "否") | 已提交: \(assignment.submitStatus ? "是" : "否")")
    }
}

private func printMoocExams(_ exams: [MoocHelper.Exam], for course: MoocHelper.Course) {
    guard !exams.isEmpty else {
        print("\(course.name) 暂无测验数据。")
        return
    }

    print("")
    print("\(course.name) 的测验:")
    for (index, exam) in exams.enumerated() {
        let retakeText = exam.allowRetake.map(String.init) ?? "不限制"
        print("\(index + 1). \(exam.title)")
        print("   开始时间: \(exam.startTime)")
        print("   截止时间: \(exam.endTime)")
        print("   限时: \(exam.timeLimit) 分钟 | 可重考次数: \(retakeText) | 已交卷: \(exam.isSubmitted ? "是" : "否")")
    }
}

private func printEducationExams(_ exams: [EduHelper.Exam]) {
    guard !exams.isEmpty else {
        print("暂无考试安排。")
        return
    }

    print("")
    print("考试安排:")
    for (index, exam) in exams.enumerated() {
        print("\(index + 1). \(exam.courseName) [\(exam.courseID)]")
        print("   时间: \(exam.examTime)")
        print("   校区: \(exam.campus) | 考场: \(exam.examRoom) | 座位号: \(exam.seatNumber)")
        print("   教师: \(exam.teacher) | 场次: \(exam.session)")
    }
}

private func printCourseGrades(_ grades: [EduHelper.CourseGrade]) {
    guard !grades.isEmpty else {
        print("暂无课程成绩。")
        return
    }

    print("")
    print("课程成绩:")
    for (index, grade) in grades.enumerated() {
        print("\(index + 1). \(grade.courseName) [\(grade.courseID)]")
        print("   学期: \(grade.semester) | 成绩: \(grade.grade) | 绩点: \(grade.gradePoint)")
        print("   学分: \(grade.credit) | 考核方式: \(grade.assessmentMethod) | 课程性质: \(grade.courseNature.rawValue)")
    }
}

private func printEducationCourses(_ courses: [EduHelper.Course]) {
    guard !courses.isEmpty else {
        print("暂无课程表数据。")
        return
    }

    print("")
    print("课程表:")
    for (index, course) in courses.enumerated() {
        let teacher = course.teacher?.isEmpty == false ? course.teacher! : "未知教师"
        print("\(index + 1). \(course.courseName) - \(teacher)")
        for session in course.sessions.sorted(by: compareSessions) {
            print("   \(displayDayOfWeek(session.dayOfWeek)) 第\(session.startSection)-\(session.endSection)节 | 周次: \(displayWeeks(session.weeks)) | 教室: \(session.classroom ?? "未提供")")
        }
    }
}

private func printAvailableClassrooms(_ classrooms: [String], query: ClassroomQuery) {
    let campus = query.campus.displayName
    let dayOfWeek = displayDayOfWeek(query.dayOfWeek)

    guard !classrooms.isEmpty else {
        print("\(campus) 第\(query.week)周 \(dayOfWeek) 第\(query.section)大节暂无空闲教室。")
        return
    }

    print("")
    print("\(campus) 第\(query.week)周 \(dayOfWeek) 第\(query.section)大节空闲教室:")
    for (index, classroom) in classrooms.enumerated() {
        print("\(index + 1). \(classroom)")
    }
}

private func compareSessions(_ lhs: EduHelper.ScheduleSession, _ rhs: EduHelper.ScheduleSession) -> Bool {
    if lhs.dayOfWeek.rawValue != rhs.dayOfWeek.rawValue {
        return lhs.dayOfWeek.rawValue < rhs.dayOfWeek.rawValue
    }
    if lhs.startSection != rhs.startSection {
        return lhs.startSection < rhs.startSection
    }
    return lhs.endSection < rhs.endSection
}

private func displayDayOfWeek(_ dayOfWeek: EduHelper.DayOfWeek) -> String {
    switch dayOfWeek {
    case .monday:
        return "星期一"
    case .tuesday:
        return "星期二"
    case .wednesday:
        return "星期三"
    case .thursday:
        return "星期四"
    case .friday:
        return "星期五"
    case .saturday:
        return "星期六"
    case .sunday:
        return "星期日"
    }
}

private func displayWeeks(_ weeks: [Int]) -> String {
    let sortedWeeks = weeks.sorted()
    return sortedWeeks.map(String.init).joined(separator: ",")
}

private func displayDate(_ date: Date) -> String {
    DateFormatters.display.string(from: date)
}

private func formatElectricity(_ electricity: Double) -> String {
    String(format: "%.2f", electricity)
}

extension String {
    fileprivate func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum DateFormatters {
    static let display: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter
    }()
}
