public enum Campus: String, Sendable, CaseIterable {
    case yuntang = "云塘"
    case jinpenling = "金盆岭"

    public var id: String {
        switch self {
        case .yuntang:
            return "0030000000002501"
        case .jinpenling:
            return "0030000000002502"
        }
    }

    public var displayName: String {
        return "\(self.rawValue)校区"
    }
}
