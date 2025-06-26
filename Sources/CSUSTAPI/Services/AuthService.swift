import Alamofire
import Foundation

class AuthService: BaseService {
    /**
     * 检查当前登录状态
     */
    func checkLoginStatus() async throws -> Bool {
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
    func login(username: String, password: String) async throws {
        let codeResponse = try await session.request(
            "http://xk.csust.edu.cn/Logon.do?method=logon&flag=sess", method: .post
        ).serializingString().value
        guard !codeResponse.isEmpty else {
            throw EduHelperError.loginFailed("Code response is empty")
        }

        let params = codeResponse.components(separatedBy: "#")
        guard params.count == 2 else {
            throw EduHelperError.loginFailed("Invalid code response format")
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
                    throw EduHelperError.loginFailed("Invalid character in sequenceHint")
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
            throw EduHelperError.loginFailed("Invalid username or password")
        }
    }

    /**
     * 登出
     */
    func logout() async throws {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        _ = try await session.request(
            "http://xk.csust.edu.cn/jsxsd/xk/LoginToXk?method=exit&tktime=\(timestamp)"
        )
        .serializingData().value

        self.session = Session()
    }
}
