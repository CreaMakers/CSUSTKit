import Alamofire
import SwiftSoup

class MoocHelper {
    var session: Session

    init(session: Session = Session()) {
        self.session = session
    }

    func getProfile() async throws -> MoocProfile {
        let responseData = try await session.request("http://pt.csust.edu.cn/meol/personal.do")
            .serializingData().value

        guard let response = String(data: responseData, encoding: .gbk) else {
            throw MoocHelperError.profileRetrievalFailed("Failed to decode response data")
        }

        let document = try SwiftSoup.parse(response)

        let elements = try document.select(".userinfobody > ul > li")

        let name = try elements[1].text()
        let lastLoginTime = try elements[2].text().replacingOccurrences(of: "登录时间：", with: "")
        let totalOnlineTime = try elements[3].text().replacingOccurrences(of: "在线总时长： ", with: "")
        let loginCountText = try elements[4].text().replacingOccurrences(of: "登录次数：", with: "")

        guard let loginCount = Int(loginCountText) else {
            throw MoocHelperError.profileRetrievalFailed("Invalid login count format")
        }

        return MoocProfile(
            name: name,
            lastLoginTime: lastLoginTime,
            totalOnlineTime: totalOnlineTime,
            loginCount: loginCount
        )
    }
}
