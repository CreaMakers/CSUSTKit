import Alamofire
import Foundation
import SwiftSoup

public class EduHelper {
    var session: Session

    public let authService: AuthService
    public let courseService: CourseService
    public let examService: ExamService
    public let profileService: ProfileService
    public let semesterService: SemesterService

    public init(session: Session? = nil) {
        let interceptor = EduRequestInterceptor(maxRetryCount: 5)
        if let baseSession = session {
            let cookies = baseSession.sessionConfiguration.httpCookieStorage?.cookies ?? []
            let configuration = URLSessionConfiguration.default
            configuration.httpCookieStorage = HTTPCookieStorage.shared
            for cookie in cookies {
                configuration.httpCookieStorage?.setCookie(cookie)
            }
            self.session = Session(
                configuration: configuration, interceptor: interceptor)
        } else {
            self.session = Session(interceptor: interceptor)
        }

        authService = AuthService(session: self.session)
        courseService = CourseService(session: self.session)
        examService = ExamService(session: self.session)
        profileService = ProfileService(session: self.session)
        semesterService = SemesterService(session: self.session)
    }
}
