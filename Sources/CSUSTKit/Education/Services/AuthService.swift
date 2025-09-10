import Alamofire
import Foundation

extension EduHelper {
    public class AuthService: BaseService {
        /**
         * 检查当前登录状态
         */
        public func checkLoginStatus() async throws -> Bool {
            let response = try await session.request(
                "http://xk.csust.edu.cn/jsxsd/framework/xsMain.jsp"
            ).serializingString().value

            return !isLoginRequired(response: response)
        }

        /**
         * 登录
         * - Parameters:
         *   - username: 用户名
         *   - password: 密码
         */
        public func login(username: String, password: String) async throws {
            let codeResponse = try await session.request(
                "http://xk.csust.edu.cn/Logon.do?method=logon&flag=sess", method: .post
            ).serializingString().value
            guard !codeResponse.isEmpty else {
                throw EduHelperError.loginFailed("验证码响应为空")
            }

            let params = codeResponse.components(separatedBy: "#")
            guard params.count == 2 else {
                throw EduHelperError.loginFailed("验证码响应格式无效")
            }
            var sourceCode = params[0]
            let sequenceHint = params[1]
            let code = "\(username)%%%\(password)"
            var encoded = ""
            for i in 0..<code.count {
                if i < 20 {
                    let charFromCode = String(code[code.index(code.startIndex, offsetBy: i)])
                    let hintChar = sequenceHint[
                        sequenceHint.index(sequenceHint.startIndex, offsetBy: i)]
                    guard let n = Int(String(hintChar)) else {
                        throw EduHelperError.loginFailed("序列提示中字符无效")
                    }
                    let extractedChars = String(sourceCode.prefix(n))
                    encoded += charFromCode + extractedChars
                    sourceCode.removeFirst(n)
                } else {
                    let remaining = code[code.index(code.startIndex, offsetBy: i)...]
                    encoded += remaining
                    break
                }
            }

            let loginParameters: [String: String] = [
                "userAccount": username,
                "userPassword": password,
                "encoded": encoded,
            ]
            let loginResponse = try await session.request(
                "http://xk.csust.edu.cn/Logon.do?method=logon",
                method: .post,
                parameters: loginParameters,
                encoding: URLEncoding.default
            ).serializingString().value
            if isLoginRequired(response: loginResponse) {
                throw EduHelperError.loginFailed("用户名或密码错误")
            }
        }

        /**
         * 登出
         */
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
