import Alamofire
import Foundation

enum EduHelperError: Error {
    case loginFailed(String)
}

@available(macOS 10.15, *)
class EduHelper {
    let session: Session

    init() {
        session = Session()
    }

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
        if loginResponse.contains("请输入账号") {
            throw EduHelperError.loginFailed("Login failed: Invalid username or password")
        }
    }
}
