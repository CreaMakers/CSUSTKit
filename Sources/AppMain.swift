import Foundation

@available(macOS 10.15, *)
@main
struct Main {
    static func main() async {
        let eduHelper = EduHelper()
        do {
            try await eduHelper.login(username: "", password: "")

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
