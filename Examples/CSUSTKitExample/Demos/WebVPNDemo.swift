import CSUSTKit

func runWebVPNMenu() {
    while true {
        print("")
        print("=== WebVPN 工具 ===")
        print("1. 原始 URL 转 WebVPN URL")
        print("2. WebVPN URL 还原原始 URL")
        print("0. 返回上一级")

        switch prompt("请选择操作") {
        case "1":
            let originalURL = promptNonEmpty("请输入原始 URL")
            do {
                let vpnURL = try WebVPNHelper.encryptURL(originalURL: originalURL)
                print("")
                print("转换结果:")
                print(vpnURL)
            } catch {
                print("转换失败: \(error)")
            }
        case "2":
            let vpnURL = promptNonEmpty("请输入 WebVPN URL")
            do {
                let originalURL = try WebVPNHelper.decryptURL(vpnURL: vpnURL)
                print("")
                print("转换结果:")
                print(originalURL)
            } catch {
                print("转换失败: \(error)")
            }
        case "0":
            return
        default:
            print("输入无效，请重新选择。")
        }
    }
}
