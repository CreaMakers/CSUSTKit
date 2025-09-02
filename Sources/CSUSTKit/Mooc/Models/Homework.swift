extension MoocHelper {
    /// 课程作业
    public struct Homework: Sendable, Codable {
        /// 作业ID
        public let id: Int
        /// 作业标题
        public let title: String
        /// 发布人
        public let publisher: String
        /// 能否提交
        public let canSubmit: Bool
        /// 提交状态
        public let submitStatus: Bool
        /// 提交截止时间
        public let deadline: String
        /// 开始提交时间
        public let startTime: String

        public init(
            id: Int,
            title: String,
            publisher: String,
            canSubmit: Bool,
            submitStatus: Bool,
            deadline: String,
            startTime: String
        ) {
            self.id = id
            self.title = title
            self.publisher = publisher
            self.canSubmit = canSubmit
            self.submitStatus = submitStatus
            self.deadline = deadline
            self.startTime = startTime
        }
    }
}
