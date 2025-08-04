extension MoocHelper {
    /// 课程信息
    public struct Course: Sendable, Hashable {
        /// 课程ID
        public let id: String
        /// 课程名称
        public let name: String
        /// 所属院系
        public let department: String
        /// 授课教师
        public let teacher: String

        public init(
            id: String,
            name: String,
            department: String,
            teacher: String
        ) {
            self.id = id
            self.name = name
            self.department = department
            self.teacher = teacher
        }
    }
}
