import Foundation

extension MoocHelper {
    enum MoocHelperError: Error, LocalizedError {
        case profileRetrievalFailed(String)
        case courseRetrievalFailed(String)
        case testRetrievalFailed(String)
        case courseNamesWithPendingHomeworksRetrievalFailed(String)

        var errorDescription: String? {
            switch self {
            case .profileRetrievalFailed(let message):
                return "获取个人信息失败: \(message)"
            case .courseRetrievalFailed(let message):
                return "获取课程信息失败: \(message)"
            case .testRetrievalFailed(let message):
                return "获取测验信息失败: \(message)"
            case .courseNamesWithPendingHomeworksRetrievalFailed(let message):
                return "获取有待完成作业的课程名称失败: \(message)"
            }
        }
    }
}
