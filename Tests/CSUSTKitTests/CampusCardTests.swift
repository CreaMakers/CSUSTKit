import DotEnvy
import Foundation
import Testing

@testable import CSUSTKit

struct CampusCardTests {
    let campusName: String?
    let buildingName: String?
    let roomName: String?

    // MARK: - Setup

    init() async throws {
        let environment = try? DotEnvironment.make()

        self.campusName = environment?["CSUST_ELEC_CAMPUS"]
        self.buildingName = environment?["CSUST_ELEC_BUILDING_NAME"]
        self.roomName = environment?["CSUST_ELEC_ROOM"]
    }

    // MARK: - Tests

    @Test("获取楼栋列表", arguments: CampusCardHelper.Campus.allCases)
    func fetchBuildings(campus: CampusCardHelper.Campus) async throws {
        let helper = CampusCardHelper()

        print("🔍 正在获取 \(campus.displayName) 的楼栋列表...")
        let buildings = try await helper.getBuildings(for: campus)

        #expect(!buildings.isEmpty, "楼栋列表不应为空")

        print("✅ 成功获取 \(buildings.count) 个楼栋")
    }

    @Test("查询特定宿舍剩余电量")
    func fetchElectricity() async throws {
        try #require(self.campusName != nil, "❌ 未配置 CSUST_ELEC_CAMPUS，无法进行电费测试")
        try #require(self.buildingName != nil, "❌ 未配置 CSUST_ELEC_BUILDING_NAME，无法进行电费测试")
        try #require(self.roomName != nil, "❌ 未配置 CSUST_ELEC_ROOM，无法进行电费测试")

        let campus: CampusCardHelper.Campus = (self.campusName == "金盆岭") ? .jinpenling : .yuntang
        let helper = CampusCardHelper()

        print("🔍 [1/2] 正在 \(campus.displayName) 查找楼栋: \(self.buildingName!)...")
        let buildings = try await helper.getBuildings(for: campus)

        let targetBuilding = try #require(
            buildings.first(where: { $0.name == self.buildingName }),
            "❌ 未能在API返回列表中找到名称为 '\(self.buildingName)' 的楼栋，请检查 .env 配置是否与系统显示一致"
        )
        print("✅ 找到楼栋ID: \(targetBuilding.id)")

        print("🔍 [2/2] 正在查询房间 \(self.roomName!) 的电量...")
        let electricity = try await helper.getElectricity(building: targetBuilding, room: self.roomName!)

        print("⚡️ 宿舍 [\(self.buildingName!) - \(self.roomName!)] 剩余电量: \(electricity) 度")

        #expect(electricity > -1 && electricity < 10000, "电量数值看起来不合理，可能是解析错误")
    }
}
