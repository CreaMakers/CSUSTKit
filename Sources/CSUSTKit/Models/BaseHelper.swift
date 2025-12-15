import Alamofire

public class BaseHelper {
    public let session: Session
    internal let mode: ConnectionMode
    internal let factory: URLFactory

    public init(mode: ConnectionMode = .direct, session: Session = Session()) {
        self.mode = mode
        self.session = session
        self.factory = .init(mode: mode)
    }

    /// 检查是否登录
    /// - Returns: 是否登录
    public func isLoggedIn() async -> Bool {
        return false
    }
}
