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

    private func getLoginForm() async throws -> (LoginForm?, Bool) {
        let request = session.request(
            "https://authserver.csust.edu.cn/authserver/login?service=https%3A%2F%2Fehall.csust.edu.cn%2Flogin"
        )
        .serializingString()

        let response = await request.response

        guard response.response?.url != URL(string: "https://ehall.csust.edu.cn/index.html") else {
            return (nil, true)
        }

        guard let value = response.value else {
            throw SSOHelperError.getLoginFormFailed("Failed to retrieve login form")
        }

        let document = try SwiftSoup.parse(value)
        guard let pwdEncryptSaltInput = try document.select("input#pwdEncryptSalt").first()
        else {
            throw SSOHelperError.getLoginFormFailed("pwdEncryptSalt input not found")
        }

        guard let executionInput = try document.select("input#execution").first()
        else {
            throw SSOHelperError.getLoginFormFailed("execution input not found")
        }

        return (
            LoginForm(
                pwdEncryptSalt: try pwdEncryptSaltInput.attr("value"),
                execution: try executionInput.attr("value")
            ), false
        )
    }

    func login(username: String, password: String) async throws {
        let (loginForm, isAlreadyLoggedIn) = try await getLoginForm()
        if isAlreadyLoggedIn {
            return
        }

        guard let loginForm = loginForm else {
            throw SSOHelperError.getLoginFormFailed("Login form not found")
        }

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

    func loginToEducation() async throws -> Session {
        struct LoginToEducationRequest: Encodable {
            let method: String
            let param: Param
            struct Param: Encodable {
                let id: String
                let type: String
            }
        }
        let loginToEducationRequest = LoginToEducationRequest(
            method: "visitService",
            param: LoginToEducationRequest.Param(
                id: "1093931153952317440",
                type: "service"
            )
        )
        struct LoginToEducationResponse: Decodable {
            let data: String
        }

        let loginToEducationResponse = try await session.request(
            "https://ehall.csust.edu.cn/execTemplateMethod", method: .post,
            parameters: loginToEducationRequest, encoder: JSONParameterEncoder.default,
        ).serializingDecodable(LoginToEducationResponse.self).value

        guard loginToEducationResponse.data == "success" else {
            throw SSOHelperError.loginToEducationFailed("Login to education failed")
        }

        _ = try await session.request("http://xk.csust.edu.cn/sso.jsp")
            .serializingString().value
        let response = try await session.request(
            "https://authserver.csust.edu.cn/authserver/login?service=http%3A%2F%2Fxk.csust.edu.cn%2Fsso.jsp",
        ).serializingString().value

        guard !response.contains("请输入账号") else {
            throw SSOHelperError.loginToEducationFailed("Login to education failed")
        }

        return session
    }
}
