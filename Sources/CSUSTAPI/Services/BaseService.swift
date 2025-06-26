import Alamofire

class BaseService {
    var session: Session

    init(session: Session) {
        self.session = session
    }

    internal func isLoginRequired(response: String) -> Bool {
        return response.contains("请输入账号")
    }
}
