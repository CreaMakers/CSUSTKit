/// 上课时间
struct ScheduleSession: Hashable {
    /// 课程周次
    let weeks: [Int]
    /// 课程节次
    let sections: [Int]
    //// 每周日期
    let dayOfWeek: DayOfWeek
    /// 上课教室
    let classroom: String?
}
