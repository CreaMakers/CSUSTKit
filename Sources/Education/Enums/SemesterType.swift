/// 学期类型枚举
enum SemesterType: String {
    /// 期初
    case beginning = "期初"
    /// 期中
    case middle = "期中"
    /// 期末
    case end = "期末"

    var id: String {
        switch self {
        case .beginning:
            return "1"
        case .middle:
            return "2"
        case .end:
            return "3"
        }
    }
}
