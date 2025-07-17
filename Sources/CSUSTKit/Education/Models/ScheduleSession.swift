/// 上课时间
public struct ScheduleSession: Hashable, Sendable {
    /// 课程周次
    public let weeks: [Int]
    /// 课程开始节次
    public let startSection: Int
    /// 课程结束节次
    public let endSection: Int
    //// 每周日期
    public let dayOfWeek: DayOfWeek
    /// 上课教室
    public let classroom: String?
}
