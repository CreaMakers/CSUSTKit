import Foundation

extension SSOHelper {
    /// 统一身份认证相关错误
    enum SSOHelperError: Error, LocalizedError {
        /// 获取登录表单失败
        case getLoginFormFailed(String)
        /// 登录失败
        case loginFailed(String)
        /// 获取登录用户信息失败
        case loginUserRetrievalFailed(String)
        /// 教务系统登录失败
        case loginToEducationFailed(String)
        /// 验证码获取失败
        case captchaRetrievalFailed(String)
        /// 动态码获取失败
        case dynamicCodeRetrievalFailed(String)
        /// 网络课程中心登录失败
        case loginToMoocFailed(String)

        /// 错误描述
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
