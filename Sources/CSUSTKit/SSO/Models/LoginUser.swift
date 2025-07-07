public struct LoginUser: Codable, Sendable {
    let categoryName: String
    let userAccount: String
    let userName: String
    let certCode: String
    let phone: String
    let email: String?
    let deptName: String
}
