import Alamofire
import Foundation
import SwiftSoup

/// 统一身份认证助手
public class SSOHelper {
    struct LoginForm {
        let pwdEncryptSalt: String
        let execution: String
    }

    private var session: Session = Session()
    private let cookieStorage: CookieStorage?

    public init(cookieStorage: CookieStorage? = nil) {
        self.cookieStorage = cookieStorage
        restoreCookies()
    }

    public func saveCookies() {
        cookieStorage?.saveCookies(for: session)
    }

    public func restoreCookies() {
        cookieStorage?.restoreCookies(to: session)
    }

    public func clearCookies() {
        cookieStorage?.clearCookies()
    }

    private func checkNeedCaptcha(username: String) async throws -> Bool {
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
            throw SSOHelperError.getLoginFormFailed("获取登录表单失败")
        }

        let document = try SwiftSoup.parse(value)
        guard let pwdEncryptSaltInput = try document.select("input#pwdEncryptSalt").first()
        else {
            throw SSOHelperError.getLoginFormFailed("未找到pwdEncryptSalt输入框")
        }

        guard let executionInput = try document.select("input#execution").first()
        else {
            throw SSOHelperError.getLoginFormFailed("未找到execution输入框")
        }

        return (
            LoginForm(
                pwdEncryptSalt: try pwdEncryptSaltInput.attr("value"),
                execution: try executionInput.attr("value")
            ), false
        )
    }

    /// 登录统一身份认证
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    /// - Throws: `SSOHelperError`
    public func login(username: String, password: String) async throws {
        let (loginForm, isAlreadyLoggedIn) = try await getLoginForm()
        if isAlreadyLoggedIn {
            return
        }

        guard let loginForm = loginForm else {
            throw SSOHelperError.getLoginFormFailed("未找到登录表单")
        }

        let needCaptcha = try await checkNeedCaptcha(username: username)
        guard !needCaptcha else {
            throw SSOHelperError.loginFailed("需要验证码，请前往ehall.csust.edu.cn手动登录后再重新尝试")
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
            throw SSOHelperError.loginFailed("登录失败，未找到重定向URL")
        }

        guard
            finalURL == URL(string: "https://ehall.csust.edu.cn/index.html")
                || finalURL == URL(string: "https://ehall.csust.edu.cn/default/index.html")
        else {
            throw SSOHelperError.loginFailed("登录失败，重定向URL异常: \(finalURL) 可能是密码错误")
        }
    }

    /// 获取登录用户信息
    /// - Throws: `SSOHelperError`
    /// - Returns: 用户信息
    public func getLoginUser() async throws -> Profile {
        struct LoginUserResponse: Decodable, Sendable {
            let data: Profile?
        }

        let response = try await session.request("https://ehall.csust.edu.cn/getLoginUser")
            .serializingDecodable(LoginUserResponse.self).value

        guard let user = response.data else {
            throw SSOHelperError.loginUserRetrievalFailed("未找到登录用户数据")
        }
        return user
    }

    /// 登出统一身份认证
    public func logout() async throws {
        _ = try await session.request("https://ehall.csust.edu.cn/logout").serializingData().value
        _ = try await session.request("https://authserver.csust.edu.cn/authserver/logout")
            .serializingData().value

        session = Session()
    }

    /// 从统一身份认证登录教务系统
    /// - Throws: `SSOHelperError`
    /// - Returns: 教务系统的会话信息
    public func loginToEducation() async throws -> Session {
        _ = try await session.request(
            "http://xk.csust.edu.cn/sso.jsp",
            interceptor: EduHelper.EduRequestInterceptor(maxRetryCount: 5)
        )
        .serializingString().value
        let response = try await session.request(
            "https://authserver.csust.edu.cn/authserver/login?service=http%3A%2F%2Fxk.csust.edu.cn%2Fsso.jsp",
            interceptor: EduHelper.EduRequestInterceptor(maxRetryCount: 5)
        ).serializingString().value

        guard !response.contains("请输入账号") else {
            throw SSOHelperError.loginToEducationFailed("教务登录失败")
        }

        return session
    }

    /// 从统一身份认证登录网络课程中心
    /// - Throws: `SSOHelperError`
    /// - Returns: 网络课程中心的会话信息
    public func loginToMooc() async throws -> Session {
        let request = session.request("http://pt.csust.edu.cn/meol/homepage/common/sso_login.jsp")
        let response = await request.serializingString().response

        guard let finalURL = response.response?.url else {
            throw SSOHelperError.loginToMoocFailed("网络课程中心登录失败，未找到重定向URL")
        }

        guard finalURL == URL(string: "http://pt.csust.edu.cn/meol/personal.do") else {
            throw SSOHelperError.loginToMoocFailed("网络课程中心登录失败，重定向URL异常: \(finalURL)")
        }

        return session
    }

    /// 获取验证码
    /// - Throws: `SSOHelperError`
    /// - Returns: 验证码图片数据
    public func getCaptcha() async throws -> Data {
        let response = try await session.request(
            "https://authserver.csust.edu.cn/authserver/getCaptcha.htl"
        ).serializingData().value
        guard !response.isEmpty else {
            throw SSOHelperError.captchaRetrievalFailed("获取验证码失败")
        }
        return response
    }

    /// 获取短信动态码
    /// - Parameters:
    ///   - mobile: 用户名
    ///   - captcha: 验证码
    /// - Throws: `SSOHelperError`
    public func getDynamicCode(mobile: String, captcha: String) async throws {
        let url = URL(
            string: "https://authserver.csust.edu.cn/authserver/dynamicCode/getDynamicCode.htl")!
        struct GetDynamicCodeResponse: Decodable {
            let code: String
            let message: String
            let mobile: String?
            let intervalTime: Int?
            let time: Int?
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "mobile=\(mobile)&captcha=\(captcha)".data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        guard !data.isEmpty else {
            throw SSOHelperError.dynamicCodeRetrievalFailed("获取动态码失败")
        }

        let response = try JSONDecoder().decode(GetDynamicCodeResponse.self, from: data)
        guard response.code == "success" else {
            throw SSOHelperError.dynamicCodeRetrievalFailed("获取动态码失败: \(response.message)")
        }
    }

    /// 短信动态码登录
    /// - Parameters:
    ///   - username: 用户名
    ///   - dynamicCode: 短信动态码
    ///   - captcha: 验证码
    /// - Throws: `SSOHelperError`
    public func dynamicLogin(username: String, dynamicCode: String, captcha: String) async throws {
        let (loginForm, isAlreadyLoggedIn) = try await getLoginForm()
        if isAlreadyLoggedIn {
            return
        }

        guard let loginForm = loginForm else {
            throw SSOHelperError.getLoginFormFailed("未找到登录表单")
        }

        let parameters: [String: String] = [
            "username": username,
            "captcha": captcha,
            "dynamicCode": dynamicCode,
            "_eventId": "submit",
            "cllt": "dynamicLogin",
            "dllt": "generalLogin",
            "lt": "",
            "execution": loginForm.execution,
        ]

        let request = session.request(
            "https://authserver.csust.edu.cn/authserver/login?service=https%3A%2F%2Fehall.csust.edu.cn%2Flogin",
            method: .post, parameters: parameters, encoding: URLEncoding.default)

        let response = await request.serializingString().response

        guard let finalURL = response.response?.url else {
            throw SSOHelperError.loginFailed("登录失败，未找到重定向URL")
        }

        guard finalURL == URL(string: "https://ehall.csust.edu.cn/index.html") else {
            throw SSOHelperError.loginFailed("登录失败，重定向URL异常: \(finalURL) 可能是验证码错误")
        }
    }
}
