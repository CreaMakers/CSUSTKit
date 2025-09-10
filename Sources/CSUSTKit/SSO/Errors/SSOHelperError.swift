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
                return "获取登录表单失败: \(message)"
            case .loginFailed(let message):
                return "登录失败: \(message)"
            case .loginUserRetrievalFailed(let message):
                return "获取登录用户信息失败: \(message)"
            case .loginToEducationFailed(let message):
                return "教务系统登录失败: \(message)"
            case .captchaRetrievalFailed(let message):
                return "验证码获取失败: \(message)"
            case .dynamicCodeRetrievalFailed(let message):
                return "动态码获取失败: \(message)"
            case .loginToMoocFailed(let message):
                return "网络课程中心登录失败: \(message)"
            }
        }
    }
}
