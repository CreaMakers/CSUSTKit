/// 上课时间
public struct ScheduleSession: Hashable, Sendable {
    /// 课程周次
    public let weeks: [Int]
    /// 课程节次
    public let sections: [Int]
    //// 每周日期
    public let dayOfWeek: DayOfWeek
    /// 上课教室
    public let classroom: String?
}
