/// 课程成绩信息
public struct CourseGrade: Sendable {
    /// 开课学期
    public let semester: String
    /// 课程编号
    public let courseID: String
    /// 课程名称
    public let courseName: String
    /// 分组名
    public let groupName: String
    /// 成绩
    public let grade: Int
    /// 详细成绩链接
    public let gradeDetailUrl: String
    /// 修读方式
    public let studyMode: String
    /// 成绩标识
    public let gradeIdentifier: String
    /// 学分
    public let credit: Double
    /// 总学时
    public let totalHours: Int
    /// 绩点
    public let gradePoint: Double
    /// 补重学期
    public let retakeSemester: String
    /// 考核方式
    public let assessmentMethod: String
    /// 考试性质
    public let examNature: String
    /// 课程属性
    public let courseAttribute: String
    /// 课程性质
    public let courseNature: CourseNature
    /// 课程类别
    public let courseCategory: String
}
