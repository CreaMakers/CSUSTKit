import Foundation

extension MoocHelper {
    /// 网络课程中心助手相关错误
    enum MoocHelperError: Error, LocalizedError {
        /// 个人信息获取失败
        case profileRetrievalFailed(String)
        /// 课程信息获取失败
        case courseRetrievalFailed(String)
        /// 测验信息获取失败
        case testRetrievalFailed(String)
        /// 获取有待完成作业的课程名称失败
        case courseNamesWithPendingHomeworksRetrievalFailed(String)

        /// 错误描述
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
