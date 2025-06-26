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

            try await eduHelper.login(username: username, password: password)

            let exams = try await eduHelper.getExamSchedule(
                academicYearSemester: nil, semesterType: nil)
            for exam in exams {
                debugPrint(exam)
            }

            try await eduHelper.logout()
        } catch {
            print("Error: \(error)")
        }
    }
}
