import Foundation

extension CampusCardHelper {
    /// 校园卡助手相关错误
    enum CampusCardHelperError: Error, LocalizedError {
        /// 楼栋信息获取失败
        case buildingRetrievalFailed(String)
        /// 未找到校区
        case campusNotFound(String)
        /// 电费信息获取失败
        case electricityRetrievalFailed(String)

        /// 错误描述
        var errorDescription: String? {
            switch self {
            case .buildingRetrievalFailed(let message):
                return "楼栋信息获取失败: \(message)"
            case .campusNotFound(let message):
                return "未找到校区: \(message)"
            case .electricityRetrievalFailed(let message):
                return "电费信息获取失败: \(message)"
            }
        }
    }
}
