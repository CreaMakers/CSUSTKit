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
                return "Profile retrieval failed: \(message)"
            case .courseRetrievalFailed(let message):
                return "Course retrieval failed: \(message)"
            case .testRetrievalFailed(let message):
                return "Test retrieval failed: \(message)"
            case .courseNamesWithPendingHomeworksRetrievalFailed(let message):
                return "Course names with pending homeworks retrieval failed: \(message)"
            }
        }
    }
}
