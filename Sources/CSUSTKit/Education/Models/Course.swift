/// 课表信息
public struct Course: Sendable {
    /// 课程名称
    let courseName: String
    /// 课程分组名称
    let groupName: String?
    /// 授课教师
    let teacher: String
    /// 上课时间
    var sessions: [ScheduleSession]
}
