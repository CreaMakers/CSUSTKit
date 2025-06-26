enum EduHelperError: Error {
    case loginFailed(String)
    case profileRetrievalFailed(String)
    case notLoggedIn(String)
    case examScheduleRetrievalFailed(String)
    case availableSemestersForExamScheduleRetrievalFailed(String)
    case courseGradesRetrievalFailed(String)
    case availableSemestersForCourseGradesRetrievalFailed(String)
    case gradeDetailRetrievalFailed(String)
}
