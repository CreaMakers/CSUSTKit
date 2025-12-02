import Alamofire
import Foundation
import SwiftSoup

/// 教务助手
public class EduHelper {
    private let mode: ConnectionMode
    private var session: Session

    /// 认证服务
    public let authService: AuthService
    /// 课程服务
    public let courseService: CourseService
    /// 考试服务
    public let examService: ExamService
    /// 个人档案服务
    public let profileService: ProfileService
    /// 学期服务
    public let semesterService: SemesterService

    public init(mode: ConnectionMode = .direct, session: Session? = nil) {
        self.mode = mode
        let interceptor = EduRequestInterceptor(maxRetryCount: 5)
        if let baseSession = session {
            let cookies = baseSession.sessionConfiguration.httpCookieStorage?.cookies ?? []
            let configuration = URLSessionConfiguration.default
            configuration.httpCookieStorage = HTTPCookieStorage.shared
            for cookie in cookies {
                configuration.httpCookieStorage?.setCookie(cookie)
            }
            self.session = Session(configuration: configuration, interceptor: interceptor)
        } else {
            self.session = Session(interceptor: interceptor)
        }

        authService = AuthService(mode: self.mode, session: self.session)
        courseService = CourseService(mode: self.mode, session: self.session)
        examService = ExamService(mode: self.mode, session: self.session)
        profileService = ProfileService(mode: self.mode, session: self.session)
        semesterService = SemesterService(mode: self.mode, session: self.session)
    }
}
