extension SSOHelper {
    /// 用户信息
    public struct Profile: Codable, Sendable {
        /// 学生类别
        public let categoryName: String
        /// 学号
        public let userAccount: String
        /// 姓名
        public let userName: String
        /// 身份证号（打码）
        public let certCode: String
        /// 手机号（打码）
        public let phone: String
        /// 邮箱
        public let email: String?
        /// 学院名称
        public let deptName: String
        /// 默认头像链接
        public let defaultUserAvatar: String
        /// 用户设置的头像链接
        public let headImageIcon: String?

        /// 头像链接
        public var avatar: String {
            if let headImageIcon = headImageIcon {
                return headImageIcon
            } else {
                return defaultUserAvatar
            }
        }

        public init(
            categoryName: String,
            userAccount: String,
            userName: String,
            certCode: String,
            phone: String,
            email: String?,
            deptName: String,
            defaultUserAvatar: String,
            headImageIcon: String?
        ) {
            self.categoryName = categoryName
            self.userAccount = userAccount
            self.userName = userName
            self.certCode = certCode
            self.phone = phone
            self.email = email
            self.deptName = deptName
            self.defaultUserAvatar = defaultUserAvatar
            self.headImageIcon = headImageIcon
        }
    }
}
