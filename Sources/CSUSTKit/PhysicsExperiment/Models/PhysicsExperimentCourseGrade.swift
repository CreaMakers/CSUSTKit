extension PhysicsExperimentHelper {
    /// 课程成绩
    public struct CourseGrade: BaseModel {
        /// 课程代码
        public let courseCode: String
        /// 课程名称
        public let courseName: String
        /// 项目名称
        public let itemName: String
        /// 预习成绩
        public let previewGrade: String
        /// 操作成绩
        public let operationGrade: String
        /// 报告成绩
        public let reportGrade: String
        /// 总成绩
        public let totalGrade: String

        public init(
            courseCode: String,
            courseName: String,
            itemName: String,
            previewGrade: String,
            operationGrade: String,
            reportGrade: String,
            totalGrade: String
        ) {
            self.courseCode = courseCode
            self.courseName = courseName
            self.itemName = itemName
            self.previewGrade = previewGrade
            self.operationGrade = operationGrade
            self.reportGrade = reportGrade
            self.totalGrade = totalGrade
        }
    }
}
