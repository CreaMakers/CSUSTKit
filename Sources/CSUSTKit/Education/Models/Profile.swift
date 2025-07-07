/// 学生档案信息
public struct Profile: Sendable {
    /// 院系
    let department: String
    /// 专业
    let major: String
    /// 学制
    let educationSystem: String
    /// 班级
    let className: String
    /// 学号
    let studentID: String
    /// 姓名
    let name: String
    /// 性别
    let gender: String
    /// 姓名拼音
    let namePinyin: String
    /// 出生日期
    let birthDate: String
    /// 民族
    let ethnicity: String
    /// 学习层次
    let studyLevel: String
    /// 家庭现住址
    let homeAddress: String
    /// 家庭电话
    let homePhone: String
    /// 本人电话
    let personalPhone: String
    /// 入学日期
    let enrollmentDate: String
    /// 入学考号
    let entranceExamID: String
    /// 身份证编号
    let idCardNumber: String
}
