/// 学生档案信息
public struct Profile: Sendable {
    /// 院系
    public let department: String
    /// 专业
    public let major: String
    /// 学制
    public let educationSystem: String
    /// 班级
    public let className: String
    /// 学号
    public let studentID: String
    /// 姓名
    public let name: String
    /// 性别
    public let gender: String
    /// 姓名拼音
    public let namePinyin: String
    /// 出生日期
    public let birthDate: String
    /// 民族
    public let ethnicity: String
    /// 学习层次
    public let studyLevel: String
    /// 家庭现住址
    public let homeAddress: String
    /// 家庭电话
    public let homePhone: String
    /// 本人电话
    public let personalPhone: String
    /// 入学日期
    public let enrollmentDate: String
    /// 入学考号
    public let entranceExamID: String
    /// 身份证编号
    public let idCardNumber: String
}
