extension CampusCardHelper {
    /// 校区
    public enum Campus: String, Sendable, CaseIterable {
        /// 云塘
        case yuntang = "云塘"
        /// 金盆岭
        case jinpenling = "金盆岭"

        /// 校区ID
        public var id: String {
            switch self {
            case .yuntang:
                return "0030000000002501"
            case .jinpenling:
                return "0030000000002502"
            }
        }

        /// 校区显示名称
        public var displayName: String {
            return "\(self.rawValue)校区"
        }
    }
}
