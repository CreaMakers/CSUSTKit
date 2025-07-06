import Alamofire
import CryptoKit
import Foundation
import SwiftSoup

class SSOHelper {
    var session: Session = Session()

    func checkNeedCaptcha(username: String) async throws -> Bool {
        struct CheckResponse: Decodable {
            let isNeed: Bool
        }

        let timestamp = Int(Date().timeIntervalSince1970 * 1000)

        let response = try await session.request(
            "https://authserver.csust.edu.cn/authserver/checkNeedCaptcha.htl?username=\(username)&_=\(timestamp)",
            method: .get
        ).serializingDecodable(
            CheckResponse.self
        ).value

        return response.isNeed
    }

    func getLoginForm() async throws -> LoginForm {
        let response = try await session.request(
            "https://authserver.csust.edu.cn/authserver/login?service=https%3A%2F%2Fehall.csust.edu.cn%2Flogin"
        )
        .serializingString().value

        let document = try SwiftSoup.parse(response)
        guard let pwdEncryptSaltInput = try document.select("input#pwdEncryptSalt").first()
        else {
            throw SSOHelperError.getLoginFormFailed("pwdEncryptSalt input not found")
        }

        guard let executionInput = try document.select("input#execution").first()
        else {
            throw SSOHelperError.getLoginFormFailed("execution input not found")
        }

        return LoginForm(
            pwdEncryptSalt: try pwdEncryptSaltInput.attr("value"),
            execution: try executionInput.attr("value")
        )
    }

    func login(username: String, password: String) async throws {
        let loginForm = try await getLoginForm()

        let needCaptcha = try await checkNeedCaptcha(username: username)
        guard !needCaptcha else {
            throw SSOHelperError.loginFailed("Captcha is required, not implemented yet")
        }

        let encryptedPassword = AESUtils.encryptPassword(
            password: password, salt: loginForm.pwdEncryptSalt)

        let parameters: [String: String] = [
            "username": username,
            "password": encryptedPassword,
            "captcha": "",
            "rememberMe": "true",
            "_eventId": "submit",
            "cllt": "userNameLogin",
            "dllt": "generalLogin",
            "lt": "",
            "execution": loginForm.execution,
        ]

        let request = session.request(
            "https://authserver.csust.edu.cn/authserver/login?service=https%3A%2F%2Fehall.csust.edu.cn%2Flogin",
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.default
        )

        let response = await request.serializingString().response

        guard let finalURL = response.response?.url else {
            throw SSOHelperError.loginFailed("Login failed, no redirect URL found")
        }

        guard
            finalURL == URL(string: "https://ehall.csust.edu.cn/index.html")
        else {
            throw SSOHelperError.loginFailed("Login failed, unexpected redirect URL: \(finalURL)")
        }
    }

    func getLoginUser() async throws -> LoginUser {
        struct LoginUserResponse: Decodable {
            let data: LoginUser?
        }

        let response = try await session.request("https://ehall.csust.edu.cn/getLoginUser")
            .serializingDecodable(LoginUserResponse.self).value

        guard let user = response.data else {
            throw SSOHelperError.loginUserRetrievalFailed("Login user data not found")
        }
        return user
    }

    func logout() async throws {
        _ = try await session.request("https://ehall.csust.edu.cn/logout").serializingData().value
        _ = try await session.request("https://authserver.csust.edu.cn/authserver/logout")
            .serializingData().value

        session = Session()
    }
}
