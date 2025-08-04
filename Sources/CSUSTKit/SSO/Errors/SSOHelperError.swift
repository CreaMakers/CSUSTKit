import Foundation

extension SSOHelper {
    enum SSOHelperError: Error, LocalizedError {
        case getLoginFormFailed(String)
        case loginFailed(String)
        case loginUserRetrievalFailed(String)
        case loginToEducationFailed(String)
        case captchaRetrievalFailed(String)
        case dynamicCodeRetrievalFailed(String)
        case loginToMoocFailed(String)

        var errorDescription: String? {
            switch self {
            case .getLoginFormFailed(let message):
                return "Get login form failed: \(message)"
            case .loginFailed(let message):
                return "Login failed: \(message)"
            case .loginUserRetrievalFailed(let message):
                return "Login user retrieval failed: \(message)"
            case .loginToEducationFailed(let message):
                return "Login to education system failed: \(message)"
            case .captchaRetrievalFailed(let message):
                return "Captcha retrieval failed: \(message)"
            case .dynamicCodeRetrievalFailed(let message):
                return "Dynamic code retrieval failed: \(message)"
            case .loginToMoocFailed(let message):
                return "Login to MOOC system failed: \(message)"
            }
        }
    }
}
