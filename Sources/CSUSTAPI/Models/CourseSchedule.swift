/// 课表信息
struct CourseSchedule {
    /// 课程名称
    let courseName: String
    /// 授课教师
    let teacherName: String
    /// 课程周次
    let weeks: [Int]
    /// 课程节次
    let sections: [Int]
    /// 上课教室
    let classroom: String
    /// 每周日期
    let dayOfWeek: Int
}
