import Foundation

enum CampusCardHelperError: Error, LocalizedError {
    case buildingRetrievalFailed(String)
    case campusNotFound(String)
    case electricityRetrievalFailed(String)

    var errorDescription: String? {
        switch self {
        case .buildingRetrievalFailed(let message):
            return "Building retrieval failed: \(message)"
        case .campusNotFound(let message):
            return "Campus not found: \(message)"
        case .electricityRetrievalFailed(let message):
            return "Electricity retrieval failed: \(message)"
        }
    }
}
