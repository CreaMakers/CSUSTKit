/// 成绩组成
struct GradeComponent {
    /// 成绩类型
    let type: String
    /// 成绩
    let grade: Double
    /// 成绩比例
    let ratio: String
}

/// 成绩详情
public struct GradeDetail {
    /// 成绩组成
    let components: [GradeComponent]
    /// 总成绩
    let totalGrade: Int
}
