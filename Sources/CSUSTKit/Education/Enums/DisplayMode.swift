extension EduHelper {
    /// 显示模式枚举
    public enum DisplayMode: String, CaseIterable {
        case bestGrade = "显示最好成绩"
        case allGrades = "显示全部成绩"

        var id: String {
            switch self {
            case .bestGrade:
                return "max"
            case .allGrades:
                return "all"
            }
        }
    }
}
