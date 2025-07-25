public struct LoginUser: Codable, Sendable {
    public let categoryName: String
    public let userAccount: String
    public let userName: String
    public let certCode: String
    public let phone: String
    public let email: String?
    public let deptName: String
    public let defaultUserAvatar: String
    public let headImageIcon: String?

    public var avatar: String {
        if let headImageIcon = headImageIcon {
            return headImageIcon
        } else {
            return defaultUserAvatar
        }
    }
}
