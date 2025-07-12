/// 成绩组成
public struct GradeComponent: Sendable {
    /// 成绩类型
    public let type: String
    /// 成绩
    public let grade: Double
    /// 成绩比例
    public let ratio: Int
}

/// 成绩详情
public struct GradeDetail: Sendable {
    /// 成绩组成
    public let components: [GradeComponent]
    /// 总成绩
    public let totalGrade: Int
}
