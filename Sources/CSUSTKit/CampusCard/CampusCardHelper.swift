import Alamofire
import Foundation

public actor CampusCardHelper {
    let session: Session = Session()

    public init() {}

    public func getBuildings(for campus: Campus) async throws -> [Building] {
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
            throw CampusCardHelperError.buildingRetrievalFailed("JSON编码失败")
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
            throw CampusCardHelperError.buildingRetrievalFailed(
                "未找到校区 \(campus.displayName) 的楼栋信息")
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

    public func getElectricity(building: Building, room: String) async throws -> Double {
        struct QueryElecRoomInfo: Codable {
            let errmsg: String?
            let aid: String
            let account: String
            let room: Room
            let floor: Floor
            let area: Area
            let building: Building
            struct Room: Codable {
                let roomid: String
                let room: String
            }
            struct Floor: Codable {
                let floorid: String
                let floor: String
            }
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
            let queryElecRoomInfo: QueryElecRoomInfo
            enum CodingKeys: String, CodingKey {
                case queryElecRoomInfo = "query_elec_roominfo"
            }
        }

        let requestData = QueryElecRoomInfo(
            errmsg: nil,
            aid: building.campus.id,
            account: "000001",
            room: QueryElecRoomInfo.Room(
                roomid: room, room: room
            ),
            floor: QueryElecRoomInfo.Floor(
                floorid: "", floor: ""
            ),
            area: QueryElecRoomInfo.Area(
                area: building.campus.displayName,
                areaname: building.campus.displayName
            ),
            building: QueryElecRoomInfo.Building(
                buildingid: building.id, building: ""
            )
        )
        let requestDict = ["query_elec_roominfo": requestData]

        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(requestDict)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw CampusCardHelperError.electricityRetrievalFailed("JSON编码失败")
        }

        let parameters: [String: String] = [
            "jsondata": jsonString,
            "funname": "synjones.onecard.query.elec.roominfo",
            "json": "true",
        ]
        let responseData = try await session.request(
            "http://yktwd.csust.edu.cn:8988/web/Common/Tsm.html", method: .post,
            parameters: parameters, encoding: URLEncoding.default,
        ).serializingDecodable(BuildingResponse.self).value

        guard let errmsg = responseData.queryElecRoomInfo.errmsg else {
            throw CampusCardHelperError.electricityRetrievalFailed("未找到错误信息")
        }

        let pattern = #"(\d+(\.\d+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
            let match = regex.firstMatch(
                in: errmsg, options: [], range: NSRange(location: 0, length: errmsg.utf16.count)),
            let range = Range(match.range(at: 1), in: errmsg)
        else {
            throw CampusCardHelperError.electricityRetrievalFailed(
                "未能在信息中找到电费数值: \(errmsg)"
            )
        }

        let electricityString = String(errmsg[range])

        guard let electricity = Double(electricityString) else {
            throw CampusCardHelperError.electricityRetrievalFailed(
                "无法从信息中解析电费数值: \(errmsg)"
            )
        }

        return electricity
    }
}
