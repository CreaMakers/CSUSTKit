/// 课程成绩信息
public struct CourseGrade: Sendable {
    /// 开课学期
    let semester: String
    /// 课程编号
    let courseID: String
    /// 课程名称
    let courseName: String
    /// 分组名
    let groupName: String
    /// 成绩
    let grade: Int
    /// 详细成绩链接
    let gradeDetailUrl: String
    /// 修读方式
    let studyMode: String
    /// 成绩标识
    let gradeIdentifier: String
    /// 学分
    let credit: Double
    /// 总学时
    let totalHours: Int
    /// 绩点
    let gradePoint: Double
    /// 补重学期
    let retakeSemester: String
    /// 考核方式
    let assessmentMethod: String
    /// 考试性质
    let examNature: String
    /// 课程属性
    let courseAttribute: String
    /// 课程性质
    let courseNature: CourseNature
    /// 课程类别
    let courseCategory: String
}
