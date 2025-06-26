import Alamofire
import Foundation
import SwiftSoup

@available(macOS 10.15, *)
class EduHelper {
    var session: Session

    let authService: AuthService
    let courseService: CourseService
    let examService: ExamService
    let profileService: ProfileService

    init() {
        session = Session()

        authService = AuthService(session: session)
        courseService = CourseService(session: session)
        examService = ExamService(session: session)
        profileService = ProfileService(session: session)
    }
}
