import Alamofire
import Foundation
import SwiftSoup

class EduHelper {
    var session: Session

    let authService: AuthService
    let courseService: CourseService
    let examService: ExamService
    let profileService: ProfileService
    let semesterService: SemesterService

    init() {
        session = Session()

        authService = AuthService(session: session)
        courseService = CourseService(session: session)
        examService = ExamService(session: session)
        profileService = ProfileService(session: session)
        semesterService = SemesterService(session: session)
    }
}
