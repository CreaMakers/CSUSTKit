import DotEnvy
import Foundation

func loadAccount() -> (String?, String?) {
    let environment = try? DotEnvironment.make()
    return (environment?["CSUST_USERNAME"], environment?["CSUST_PASSWORD"])
}

@available(macOS 13.0, *)
@main
struct Main {
    static func main() async {
        let eduHelper = EduHelper()
        do {
            let (username, password) = loadAccount()
            guard let username = username, let password = password else {
                print("Username or password not found in environment variables.")
                return
            }

            try await eduHelper.authService.login(username: username, password: password)

            let courses = try await eduHelper.courseService.getCourseSchedule(
                academicYearSemester: "2025-2026-1")
            for course in courses {
                print("Course Name: \(course.courseName)")
                print("Group Name: \(course.groupName ?? "N/A")")
                print("Teacher: \(course.teacher)")
                print("Sessions:")
                for session in course.sessions {
                    print(
                        "  Weeks: \(session.weeks) Sections: \(session.sections) Day of Week: \(session.dayOfWeek) Classroom: \(session.classroom ?? "N/A")"
                    )
                }
                print("-----------------------------")
            }

            try await eduHelper.authService.logout()
        } catch {
            print("Error: \(error)")
        }
    }
}
