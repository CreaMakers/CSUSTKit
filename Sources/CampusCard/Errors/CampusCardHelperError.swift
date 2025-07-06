enum CampusCardHelperError: Error {
    case buildingRetrievalFailed(String)
    case campusNotFound(String)
    case electricityRetrievalFailed(String)
}
