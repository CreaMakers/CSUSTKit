import Foundation

extension MoocHelper {
    /// 课程测试
    public struct Test: Sendable {
        /// 测试标题
        public let title: String
        /// 开始时间
        public let startTime: String
        /// 截止时间
        public let endTime: String
        /// 允许测试次数（空为不限制）
        public let allowRetake: Int?
        /// 限制用时（分钟）
        public let timeLimit: Int
        /// 是否交卷
        public let isSubmitted: Bool

        public init(
            title: String,
            startTime: String,
            endTime: String,
            allowRetake: Int?,
            timeLimit: Int,
            isSubmitted: Bool
        ) {
            self.title = title
            self.startTime = startTime
            self.endTime = endTime
            self.allowRetake = allowRetake
            self.timeLimit = timeLimit
            self.isSubmitted = isSubmitted
        }
    }
}
