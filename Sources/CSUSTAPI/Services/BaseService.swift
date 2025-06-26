import Alamofire

class BaseService {
    var session: Session

    init(session: Session) {
        self.session = session
    }

    internal func isLoginRequired(response: String) -> Bool {
        return response.contains("请输入账号")
    }

    internal func performRequest(
        _ url: String, _ method: HTTPMethod = .get, _ parameters: [String: String]? = nil
    ) async throws -> String {
        let response = try await session.request(
            url, method: method, parameters: parameters, encoding: URLEncoding.default
        )
        .serializingString().value

        if isLoginRequired(response: response) {
            throw EduHelperError.notLoggedIn("User is not logged in")
        }

        return response
    }
}
