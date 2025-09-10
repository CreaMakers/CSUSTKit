import Foundation

extension CampusCardHelper {
    enum CampusCardHelperError: Error, LocalizedError {
        case buildingRetrievalFailed(String)
        case campusNotFound(String)
        case electricityRetrievalFailed(String)

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
