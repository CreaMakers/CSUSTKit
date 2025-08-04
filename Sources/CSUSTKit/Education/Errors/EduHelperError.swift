import Foundation

extension EduHelper {
    enum EduHelperError: Error, LocalizedError {
        case loginFailed(String)
        case profileRetrievalFailed(String)
        case notLoggedIn(String)
        case examScheduleRetrievalFailed(String)
        case availableSemestersForExamScheduleRetrievalFailed(String)
        case courseGradesRetrievalFailed(String)
        case availableSemestersForCourseGradesRetrievalFailed(String)
        case gradeDetailRetrievalFailed(String)
        case courseScheduleRetrievalFailed(String)
        case availableSemestersForCourseScheduleRetrievalFailed(String)
        case semesterStartDateRetrievalFailed(String)
        case availableSemestersForStartDateRetrievalFailed(String)
        case dateParsingFailed(String)

        var errorDescription: String? {
            switch self {
            case .loginFailed(let message):
                return "Login failed: \(message)"
            case .profileRetrievalFailed(let message):
                return "Profile retrieval failed: \(message)"
            case .notLoggedIn(let message):
                return "Not logged in: \(message)"
            case .examScheduleRetrievalFailed(let message):
                return "Exam schedule retrieval failed: \(message)"
            case .availableSemestersForExamScheduleRetrievalFailed(let message):
                return "Available semesters for exam schedule retrieval failed: \(message)"
            case .courseGradesRetrievalFailed(let message):
                return "Course grades retrieval failed: \(message)"
            case .availableSemestersForCourseGradesRetrievalFailed(let message):
                return "Available semesters for course grades retrieval failed: \(message)"
            case .gradeDetailRetrievalFailed(let message):
                return "Grade detail retrieval failed: \(message)"
            case .courseScheduleRetrievalFailed(let message):
                return "Course schedule retrieval failed: \(message)"
            case .availableSemestersForCourseScheduleRetrievalFailed(let message):
                return "Available semesters for course schedule retrieval failed: \(message)"
            case .semesterStartDateRetrievalFailed(let message):
                return "Semester start date retrieval failed: \(message)"
            case .availableSemestersForStartDateRetrievalFailed(let message):
                return "Available semesters for start date retrieval failed: \(message)"
            case .dateParsingFailed(let message):
                return "Date parsing failed: \(message)"
            }
        }
    }
}
