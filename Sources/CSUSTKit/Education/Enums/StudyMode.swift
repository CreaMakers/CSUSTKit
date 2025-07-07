/// 修读方式枚举
public enum StudyMode: String {
    case major = "主修"
    case minor = "辅修"
    case all = "全部"

    var id: String {
        switch self {
        case .major:
            return "0"
        case .minor:
            return "1"
        case .all:
            return "2"
        }
    }
}
