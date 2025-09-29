import Alamofire
import Foundation

extension EduHelper {
    /// 认证服务
    public class AuthService: BaseService {
        /// 检查当前登录状态
        /// - Returns: 是否已登录
        public func checkLoginStatus() async throws -> Bool {
            let response = try await session.request(
                "http://xk.csust.edu.cn/jsxsd/framework/xsMain.jsp"
            ).serializingString().value

            return !isLoginRequired(response: response)
        }

        /// 获取登录验证码
        /// - Returns: 登录验证码图片数据
        public func getCaptcha() async throws -> Data {
            return try await session.request("http://xk.csust.edu.cn/jsxsd/verifycode.servlet").serializingData().value
        }

        /// 登录
        /// - Parameters:
        ///   - username: 用户名
        ///   - password: 密码
        ///   - captcha: 验证码
        /// - Throws: `EduHelperError`
        public func login(username: String, password: String, captcha: String) async throws {
            let encoded = "\(Data(username.utf8).base64EncodedString())%%%\(Data(password.utf8).base64EncodedString())"
            let loginParameters: [String: String] = [
                "userAccount": username,
                "userPassword": password,
                "RANDOMCODE": captcha,
                "encoded": encoded,
            ]
            let response = try await session.request(
                "http://xk.csust.edu.cn/jsxsd/xk/LoginToXk",
                method: .post,
                parameters: loginParameters,
                encoding: URLEncoding.default
            ).serializingString().value
            if response.contains("验证码错误") {
                throw EduHelperError.loginFailed("验证码错误")
            }
            if isLoginRequired(response: response) {
                throw EduHelperError.loginFailed("用户名或密码错误")
            }
        }

        /// 登出当前用户
        public func logout() async throws {
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            _ = try await session.request(
                "http://xk.csust.edu.cn/jsxsd/xk/LoginToXk?method=exit&tktime=\(timestamp)"
            )
            .serializingData().value

            self.session = Session()
        }
    }
}
