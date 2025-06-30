import Alamofire
import Foundation

class FinanceHelper {
    let session: Session = Session()

    func getBuildings(for campus: Campus) async throws -> [Building] {
        struct QueryElecBuilding: Codable {
            let retcode: String?
            let errmsg: String?
            let aid: String
            let account: String
            let area: Area
            var buildingtab: [Building]?
            struct Area: Codable {
                let area: String
                let areaname: String
            }
            struct Building: Codable {
                let buildingid: String
                let building: String
            }
        }
        struct BuildingResponse: Codable {
            let queryElecBuilding: QueryElecBuilding
            enum CodingKeys: String, CodingKey {
                case queryElecBuilding = "query_elec_building"
            }
        }

        let requestData = QueryElecBuilding(
            retcode: nil,
            errmsg: nil,
            aid: campus.id,
            account: "000001",
            area: QueryElecBuilding.Area(
                area: campus.displayName,
                areaname: campus.displayName
            ),
            buildingtab: nil
        )
        let requestDict = ["query_elec_building": requestData]

        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(requestDict)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw FinanceHelperError.buildingRetrievalFailed("Failed to encode JSON")
        }

        let parameters: [String: String] = [
            "jsondata": jsonString,
            "funname": "synjones.onecard.query.elec.building",
            "json": "true",
        ]

        let responseData = try await session.request(
            "http://yktwd.csust.edu.cn:8988/web/Common/Tsm.html", method: .post,
            parameters: parameters, encoding: URLEncoding.default,
        ).serializingDecodable(BuildingResponse.self).value

        guard let buildingTab = responseData.queryElecBuilding.buildingtab else {
            throw FinanceHelperError.buildingRetrievalFailed(
                "No buildings found for campus \(campus.displayName)")
        }

        var buildings: [Building] = []
        for building in buildingTab {
            buildings.append(
                Building(
                    name: building.building, id: building.buildingid,
                    campus: campus
                )
            )
        }

        return buildings
    }
}
