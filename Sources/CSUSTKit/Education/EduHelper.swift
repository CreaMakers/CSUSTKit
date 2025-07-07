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

    public init(session: Session = Session()) {
        self.session = session

        authService = AuthService(session: session)
        courseService = CourseService(session: session)
        examService = ExamService(session: session)
        profileService = ProfileService(session: session)
        semesterService = SemesterService(session: session)
    }
}
