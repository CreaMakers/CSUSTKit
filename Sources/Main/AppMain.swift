import DotEnvy
import Foundation

func loadAccount() -> (String?, String?) {
    let environment = try? DotEnvironment.make()
    return (environment?["CSUST_USERNAME"], environment?["CSUST_PASSWORD"])
}

@available(macOS 10.15, *)
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

            let profile = try await eduHelper.profileService.getProfile()
            debugPrint(profile)

            let exams = try await eduHelper.examService.getExamSchedule()
            for exam in exams {
                debugPrint(exam)
            }

            let grades = try await eduHelper.courseService.getCourseGrades()
            for grade in grades {
                debugPrint(grade)
                let gradeDetail = try await eduHelper.courseService.getGradeDetail(
                    url: grade.gradeDetailUrl)
                debugPrint(gradeDetail)
            }

            try await eduHelper.authService.logout()
        } catch {
            print("Error: \(error)")
        }
    }
}
