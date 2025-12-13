import Testing

@testable import CSUSTKit

struct WebVPNTests {
    @Test(
        "验证特定 WebVPN 链接解密为原始 URL",
        arguments: [
            (
                "https://vpn.csust.edu.cn/http/57524476706e697374686562657374213b080392a9f22f8f5c673ec2dafd24",
                "http://pt.csust.edu.cn"
            ),
            (
                "https://vpn.csust.edu.cn/http/57524476706e6973746865626573742133170392a9f22f8f5c673ec2dafd24",
                "http://xk.csust.edu.cn"
            ),
            (
                "https://vpn.csust.edu.cn/http-8080/57524476706e697374686562657374217a451fdfebb164d5432c6b/index.html",
                "http://192.168.1.1:8080/index.html"
            )
        ]
    )
    func verifyDecryption(vpnURL: String, originalURL: String) throws {
        let decrypted = try WebVPNHelper.decryptURL(vpnURL: vpnURL)

        if decrypted != originalURL {
            print("❌ 解密不匹配")
            print("期望: \(originalURL)")
            print("实际: \(decrypted)")
        }

        #expect(decrypted == originalURL)
    }

    @Test(
        "验证原始 URL 加密为特定 WebVPN 链接",
        arguments: [
            (
                "http://xk.csust.edu.cn",
                "https://vpn.csust.edu.cn/http/57524476706e6973746865626573742133170392a9f22f8f5c673ec2dafd24"
            ),
            (
                "http://pt.csust.edu.cn",
                "https://vpn.csust.edu.cn/http/57524476706e697374686562657374213b080392a9f22f8f5c673ec2dafd24"
            ),
            (
                "http://192.168.1.1:8080/index.html",
                "https://vpn.csust.edu.cn/http-8080/57524476706e697374686562657374217a451fdfebb164d5432c6b/index.html"
            )
        ]
    )
    func verifyEncryption(originalURL: String, expectedVPNURL: String) throws {
        let encrypted = try WebVPNHelper.encryptURL(originalURL: originalURL)

        if encrypted != expectedVPNURL {
            print("⚠️ 加密结果不一致")
            print("输入: \(originalURL)")
            print("期望: \(expectedVPNURL)")
            print("实际: \(encrypted)")
        }

        #expect(encrypted == expectedVPNURL)
    }

    @Test(
        "WebVPN 加密解密往返测试",
        arguments: [
            "http://www.baidu.com",
            "https://jwc.csust.edu.cn",
            "http://192.168.1.1:8080/index.html",
            "https://lofter.com/front/login?id=123",
        ]
    )
    func verifyRoundTrip(url: String) throws {
        let encrypted = try WebVPNHelper.encryptURL(originalURL: url)
        let decrypted = try WebVPNHelper.decryptURL(vpnURL: encrypted)

        #expect(decrypted == url)
    }
}
