/// 课表信息
public struct Course: Sendable, Codable {
    /// 课程名称
    public let courseName: String
    /// 课程分组名称
    public let groupName: String?
    /// 授课教师
    public let teacher: String
    /// 上课时间
    public var sessions: [ScheduleSession]
}
