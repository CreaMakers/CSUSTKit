extension MoocHelper {
    /// 个人资料
    public struct Profile: Sendable {
        /// 姓名
        public let name: String
        /// 最后登录时间
        public let lastLoginTime: String
        /// 总在线时长
        public let totalOnlineTime: String
        /// 登录次数
        public let loginCount: Int
    }
}
