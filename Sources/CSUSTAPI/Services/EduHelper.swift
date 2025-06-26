import Alamofire
import Foundation
import SwiftSoup

@available(macOS 10.15, *)
class EduHelper {
    var session: Session

    let authService: AuthServiceProtocol
    let courseService: CourseServiceProtocol
    let examService: ExamServiceProtocol
    let profileService: ProfileServiceProtocol

    init() {
        session = Session()

        authService = AuthService(session: session)
        courseService = CourseService(session: session)
        examService = ExamService(session: session)
        profileService = ProfileService(session: session)
    }
}
