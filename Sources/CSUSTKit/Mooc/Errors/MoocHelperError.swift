import Foundation

enum MoocHelperError: Error, LocalizedError {
    case profileRetrievalFailed(String)
    case courseRetrievalFailed(String)

    var errorDescription: String? {
        switch self {
        case .profileRetrievalFailed(let message):
            return "Profile retrieval failed: \(message)"
        case .courseRetrievalFailed(let message):
            return "Course retrieval failed: \(message)"
        }
    }
}
