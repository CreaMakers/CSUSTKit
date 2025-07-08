import Alamofire

public protocol CookieStorage {
    func saveCookies(for session: Session)
    func restoreCookies(to session: Session)
    func clearCookies()
}
