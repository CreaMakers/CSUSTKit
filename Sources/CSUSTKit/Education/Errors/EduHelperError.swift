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
                return "登录失败: \(message)"
            case .profileRetrievalFailed(let message):
                return "个人信息获取失败: \(message)"
            case .notLoggedIn(let message):
                return "未登录: \(message)"
            case .examScheduleRetrievalFailed(let message):
                return "考试安排获取失败: \(message)"
            case .availableSemestersForExamScheduleRetrievalFailed(let message):
                return "考试安排可选学期获取失败: \(message)"
            case .courseGradesRetrievalFailed(let message):
                return "课程成绩获取失败: \(message)"
            case .availableSemestersForCourseGradesRetrievalFailed(let message):
                return "课程成绩可选学期获取失败: \(message)"
            case .gradeDetailRetrievalFailed(let message):
                return "成绩详情获取失败: \(message)"
            case .courseScheduleRetrievalFailed(let message):
                return "课程表获取失败: \(message)"
            case .availableSemestersForCourseScheduleRetrievalFailed(let message):
                return "课程表可选学期获取失败: \(message)"
            case .semesterStartDateRetrievalFailed(let message):
                return "学期开始日期获取失败: \(message)"
            case .availableSemestersForStartDateRetrievalFailed(let message):
                return "开始日期可选学期获取失败: \(message)"
            case .dateParsingFailed(let message):
                return "日期解析失败: \(message)"
            }
        }
    }
}
