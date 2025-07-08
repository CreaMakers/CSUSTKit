public struct LoginUser: Codable, Sendable {
    public let categoryName: String
    public let userAccount: String
    public let userName: String
    public let certCode: String
    public let phone: String
    public let email: String?
    public let deptName: String
    public let defaultUserAvatar: String
}
