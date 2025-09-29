import Alamofire
import Foundation

/// 校园卡助手
public actor CampusCardHelper {
    private let session: Session = Session()

    private struct QueryElecBuilding: Codable {
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

    private struct BuildingResponse: Codable {
        let queryElecBuilding: QueryElecBuilding
        enum CodingKeys: String, CodingKey {
            case queryElecBuilding = "query_elec_building"
        }
    }

    private struct QueryElecRoomInfo: Codable {
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

    private struct RoomResponse: Codable {
        let queryElecRoomInfo: QueryElecRoomInfo
        enum CodingKeys: String, CodingKey {
            case queryElecRoomInfo = "query_elec_roominfo"
        }
    }

    public init() {}

    /// 获取指定校区的楼栋列表
    /// - Parameter campus: 校区
    /// - Throws: `CampusCardHelperError`
    /// - Returns: 楼栋列表
    public func getBuildings(for campus: Campus) async throws -> [Building] {
        let requestData = QueryElecBuilding(
            retcode: nil,
            errmsg: nil,
            aid: campus.id,
            account: "000001",
            area: QueryElecBuilding.Area(area: campus.displayName, areaname: campus.displayName),
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
        let responseData = try await session.post("http://yktwd.csust.edu.cn:8988/web/Common/Tsm.html", parameters).decodable(BuildingResponse.self)
        guard let buildingTab = responseData.queryElecBuilding.buildingtab else {
            throw CampusCardHelperError.buildingRetrievalFailed("未找到校区 \(campus.displayName) 的楼栋信息")
        }
        var buildings: [Building] = []
        for building in buildingTab {
            buildings.append(Building(name: building.building, id: building.buildingid, campus: campus))
        }
        return buildings
    }

    /// 获取指定宿舍的剩余电量
    /// - Parameters:
    ///   - building: 宿舍所在楼栋
    ///   - room: 宿舍号
    /// - Throws: `CampusCardHelperError`
    /// - Returns: 剩余电量（单位：度）
    public func getElectricity(building: Building, room: String) async throws -> Double {
        let requestData = QueryElecRoomInfo(
            errmsg: nil,
            aid: building.campus.id,
            account: "000001",
            room: QueryElecRoomInfo.Room(roomid: room, room: room),
            floor: QueryElecRoomInfo.Floor(floorid: "", floor: ""),
            area: QueryElecRoomInfo.Area(area: building.campus.displayName, areaname: building.campus.displayName),
            building: QueryElecRoomInfo.Building(buildingid: building.id, building: "")
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
        let responseData = try await session.post("http://yktwd.csust.edu.cn:8988/web/Common/Tsm.html", parameters).decodable(RoomResponse.self)
        guard let errmsg = responseData.queryElecRoomInfo.errmsg else {
            throw CampusCardHelperError.electricityRetrievalFailed("未找到错误信息")
        }
        let pattern = #"(\d+(\.\d+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
            let match = regex.firstMatch(in: errmsg, options: [], range: NSRange(location: 0, length: errmsg.utf16.count)),
            let range = Range(match.range(at: 1), in: errmsg)
        else {
            throw CampusCardHelperError.electricityRetrievalFailed("未能在信息中找到电费数值: \(errmsg)")
        }
        let electricityString = String(errmsg[range])
        guard let electricity = Double(electricityString) else {
            throw CampusCardHelperError.electricityRetrievalFailed("无法从信息中解析电费数值: \(errmsg)")
        }
        return electricity
    }
}
