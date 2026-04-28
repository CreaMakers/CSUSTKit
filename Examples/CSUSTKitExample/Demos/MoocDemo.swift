import CSUSTKit

func runMoocMenu(using moocHelper: MoocHelper) async {
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
