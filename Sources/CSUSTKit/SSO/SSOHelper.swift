import Alamofire
import Foundation
import SwiftSoup

/// 统一身份认证助手
public class SSOHelper {
    private struct LoginForm {
        let pwdEncryptSalt: String
        let execution: String
    }

    private struct LoginUserResponse: Decodable, Sendable {
        let data: Profile?
    }

    private struct CheckResponse: Decodable {
        let isNeed: Bool
    }

    private struct GetDynamicCodeResponse: Decodable {
        let code: String
        let message: String
        let mobile: String?
        let intervalTime: Int?
        let time: Int?
    }

    private let mode: ConnectionMode
    private var session: Session
    private let factory: URLFactory
    private let cookieStorage: CookieStorage?
    private let interceptor = EduHelper.EduRequestInterceptor(maxRetryCount: 5)

    public init(mode: ConnectionMode = .direct, cookieStorage: CookieStorage? = nil, session: Session = Session()) {
        self.mode = mode
        self.cookieStorage = cookieStorage
        self.session = session
        self.factory = .init(mode: mode)
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

    public func getSession() -> Session {
        session
    }

    private func checkNeedCaptcha(username: String) async throws -> Bool {
        let timestamp = Date().millisecondsSince1970
        let response = try await session.request(factory.make(.authServer, "/authserver/checkNeedCaptcha.htl?username=\(username)&_=\(timestamp)")).decodable(CheckResponse.self)
        return response.isNeed
    }

    // 获取登录表单
    private func getLoginForm() async throws -> (LoginForm?, Bool) {
        let response = await session.request(factory.make(.authServer, "/authserver/login?service=https%3A%2F%2Fehall.csust.edu.cn%2Flogin")).stringResponse()
        // 已经登录
        guard response.response?.url != URL(factory.make(.ehall, "/index.html")) else {
            return (nil, true)
        }
        guard let value = response.value else {
            throw SSOHelperError.getLoginFormFailed("获取登录表单失败")
        }
        let document = try SwiftSoup.parse(value)
        guard let pwdEncryptSaltInput = try document.select("input#pwdEncryptSalt").first() else {
            throw SSOHelperError.getLoginFormFailed("未找到pwdEncryptSalt输入框")
        }
        guard let executionInput = try document.select("input#execution").first() else {
            throw SSOHelperError.getLoginFormFailed("未找到execution输入框")
        }
        let pwdEncryptSalt = try pwdEncryptSaltInput.attr("value")
        let execution = try executionInput.attr("value")
        return (LoginForm(pwdEncryptSalt: pwdEncryptSalt, execution: execution), false)
    }

    /// 登录统一身份认证
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    /// - Throws: `SSOHelperError`
    public func login(username: String, password: String) async throws {
        let (loginForm, isAlreadyLoggedIn) = try await getLoginForm()
        guard !isAlreadyLoggedIn else { return }
        guard let loginForm = loginForm else {
            throw SSOHelperError.getLoginFormFailed("获取登录表单失败")
        }
        let needCaptcha = try await checkNeedCaptcha(username: username)
        guard !needCaptcha else {
            throw SSOHelperError.loginFailed("需要验证码，请前往ehall.csust.edu.cn手动登录后再重新登录")
        }
        let encryptedPassword = AESUtils.encryptPassword(password: password, salt: loginForm.pwdEncryptSalt)
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
        let response = await session.post(factory.make(.authServer, "/authserver/login?service=https%3A%2F%2Fehall.csust.edu.cn%2Flogin"), parameters).stringResponse()
        guard let finalURL = response.response?.url else {
            throw SSOHelperError.loginFailed("登录失败，未找到重定向URL")
        }

        var checkURL: URL = finalURL

        if mode == .webVpn {
            guard finalURL == URL("https://vpn.csust.edu.cn/login") else {
                throw SSOHelperError.loginFailed("登录失败，重定向URL异常: \(finalURL) 可能是密码错误")
            }
            let checkResponse = await session.request("https://vpn.csust.edu.cn/login?cas_login=true").stringResponse()
            guard let checkFinalURL = checkResponse.response?.url else {
                throw SSOHelperError.loginFailed("登录失败，重定向URL异常: \(finalURL) 可能是密码错误")
            }
            checkURL = checkFinalURL
        }

        guard checkURL == URL(factory.make(.ehall, "/index.html")) || finalURL == URL(factory.make(.ehall, "/default/index.html")) else {
            throw SSOHelperError.loginFailed("登录失败，重定向URL异常: \(finalURL) 可能是密码错误")
        }
    }

    /// 获取登录用户信息
    /// - Throws: `SSOHelperError`
    /// - Returns: 用户信息
    public func getLoginUser() async throws -> Profile {
        let response = try await session.request(factory.make(.ehall, "/getLoginUser")).decodable(LoginUserResponse.self)
        guard let user = response.data else {
            throw SSOHelperError.loginUserRetrievalFailed("未找到登录用户数据")
        }
        return user
    }

    /// 登出统一身份认证
    public func logout() async throws {
        try await session.request(factory.make(.ehall, "/logout")).data()
        try await session.request(factory.make(.authServer, "/authserver/logout")).data()
        session = Session()
    }

    /// 从统一身份认证登录教务系统
    /// - Throws: `SSOHelperError`
    /// - Returns: 教务系统的会话信息
    public func loginToEducation() async throws -> Session {
        try await session.request(factory.make(.education, "/sso.jsp"), interceptor: interceptor).data()
        let response = try await session.request(factory.make(.authServer, "/authserver/login?service=http%3A%2F%2Fxk.csust.edu.cn%2Fsso.jsp"), interceptor: interceptor).string()
        guard !response.contains("请输入账号") else {
            throw SSOHelperError.loginToEducationFailed("教务登录失败")
        }
        return session
    }

    /// 从统一身份认证登录网络课程中心
    /// - Throws: `SSOHelperError`
    /// - Returns: 网络课程中心的会话信息
    public func loginToMooc() async throws -> Session {
        let request = session.request(factory.make(.mooc, "/meol/homepage/common/sso_login.jsp"))
        let response = await request.stringResponse()
        guard let finalURL = response.response?.url else {
            throw SSOHelperError.loginToMoocFailed("网络课程中心登录失败，未找到重定向URL")
        }
        guard finalURL == URL(factory.make(.mooc, "/meol/personal.do")) else {
            throw SSOHelperError.loginToMoocFailed("网络课程中心登录失败，重定向URL异常: \(finalURL)")
        }
        return session
    }

    /// 获取验证码
    /// - Throws: `SSOHelperError`
    /// - Returns: 验证码图片数据
    public func getCaptcha() async throws -> Data {
        let response = try await session.request("https://authserver.csust.edu.cn/authserver/getCaptcha.htl").data()
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
        // 这里必须要使用 URLSession，Alamofire无法实现，原因不明
        let url = URL("https://authserver.csust.edu.cn/authserver/dynamicCode/getDynamicCode.htl")
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
        let response = await session.post("https://authserver.csust.edu.cn/authserver/login?service=https%3A%2F%2Fehall.csust.edu.cn%2Flogin", parameters).stringResponse()
        guard let finalURL = response.response?.url else {
            throw SSOHelperError.loginFailed("登录失败，未找到重定向URL")
        }
        guard finalURL == URL("https://ehall.csust.edu.cn/index.html") else {
            throw SSOHelperError.loginFailed("登录失败，重定向URL异常: \(finalURL) 可能是验证码错误")
        }
    }
}
