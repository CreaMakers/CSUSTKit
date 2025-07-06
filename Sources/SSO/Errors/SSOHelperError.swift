enum SSOHelperError: Error {
    case getLoginFormFailed(String)
    case loginFailed(String)
    case loginUserRetrievalFailed(String)
    case loginToEducationFailed(String)
}
