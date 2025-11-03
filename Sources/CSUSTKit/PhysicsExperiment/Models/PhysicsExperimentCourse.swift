extension PhysicsExperimentHelper {
    /// 物理实验课程信息
    public struct Course: BaseModel {
        /// 项目编号
        public let id: Int
        /// 项目名称
        public let name: String
        /// 批次
        public let batch: String
        /// 教师
        public let teacher: String
        /// 上课地址
        public let location: String
        /// 上课时间
        public let time: String
        /// 课时
        public let classHours: Int
        /// 星期
        public let weekInfo: String

        public init(
            id: Int,
            name: String,
            batch: String,
            teacher: String,
            location: String,
            time: String,
            classHours: Int,
            weekInfo: String
        ) {
            self.id = id
            self.name = name
            self.batch = batch
            self.teacher = teacher
            self.location = location
            self.time = time
            self.classHours = classHours
            self.weekInfo = weekInfo
        }
    }
}
