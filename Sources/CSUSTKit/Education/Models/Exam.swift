/// 考试信息
public struct Exam: Sendable {
    /// 校区
    public let campus: String
    /// 考试场次
    public let session: String
    /// 课程编号
    public let courseID: String
    /// 课程名称
    public let courseName: String
    /// 授课教师
    public let teacher: String
    /// 考试时间
    public let examTime: String
    /// 考场
    public let examRoom: String
    /// 座位号
    public let seatNumber: String
    /// 准考证号
    public let admissionTicketNumber: String
    /// 备注
    public let remarks: String
}
