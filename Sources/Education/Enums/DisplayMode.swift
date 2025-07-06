/// 显示模式枚举
enum DisplayMode: String {
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
