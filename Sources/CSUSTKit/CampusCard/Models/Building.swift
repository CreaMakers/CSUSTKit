public struct Building: Sendable {
    public init(name: String, id: String, campus: Campus) {
        self.name = name
        self.id = id
        self.campus = campus
    }

    public let name: String
    public let id: String
    public let campus: Campus
}
