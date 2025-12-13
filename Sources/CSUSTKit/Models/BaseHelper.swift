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
}
