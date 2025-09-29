import Alamofire
import Foundation

extension EduHelper {
    /// 认证服务
    public class AuthService: BaseService {
        /// 检查当前登录状态
        /// - Returns: 是否已登录
        public func checkLoginStatus() async throws -> Bool {
            let response = try await session.request("http://xk.csust.edu.cn/jsxsd/framework/xsMain.jsp").string()
            return !isLoginRequired(response: response)
        }

        /// 获取登录验证码
        /// - Returns: 登录验证码图片数据
        public func getCaptcha() async throws -> Data {
            return try await session.request("http://xk.csust.edu.cn/jsxsd/verifycode.servlet").data()
        }

        /// 登录
        /// - Parameters:
        ///   - username: 用户名
        ///   - password: 密码
        ///   - captcha: 验证码
        /// - Throws: `EduHelperError`
        public func login(username: String, password: String, captcha: String) async throws {
            let parameters: [String: String] = [
                "userAccount": username,
                "userPassword": password,
                "RANDOMCODE": captcha,
                "encoded": "\(username.base64String)%%%\(password.base64String)",
            ]
            let response = try await session.post("http://xk.csust.edu.cn/jsxsd/xk/LoginToXk", parameters).string()
            if response.contains("验证码错误") {
                throw EduHelperError.loginFailed("验证码错误")
            }
            if isLoginRequired(response: response) {
                throw EduHelperError.loginFailed("用户名或密码错误")
            }
        }

        /// 登出当前用户
        public func logout() async throws {
            try await session.request("http://xk.csust.edu.cn/jsxsd/xk/LoginToXk?method=exit&tktime=\(Date().millisecondsSince1970)").data()
            self.session = Session()
        }
    }
}
