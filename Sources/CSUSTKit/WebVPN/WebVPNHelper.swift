import CryptoSwift
import Foundation

/// WebVPN 助手
public class WebVPNHelper {
    private static let host: String = "vpn.csust.edu.cn"
    private static let key: String = "WRDvpnisthebest!"
    private static let iv: String = "WRDvpnisthebest!"

    /// 将原始 URL 加密为 WebVPN URL
    /// - Parameter originalURL: 原始 URL
    /// - Throws: `WebVPNHelperError`
    /// - Returns: 加密后的 WebVPN URL
    public static func encryptURL(originalURL: String) throws -> String {
        guard let url = URL(string: originalURL),
            let originalHost = url.host,
            let scheme = url.scheme
        else {
            throw WebVPNHelperError.urlEncryptionFailed("无效的 URL 或无法获取主机名/协议")
        }

        let encryptedHost: String
        do {
            encryptedHost = try encryptHost(originalHost)
        } catch {
            throw WebVPNHelperError.urlEncryptionFailed("加密主机名失败: \(error.localizedDescription)")
        }

        var pathPart = url.path
        if let query = url.query {
            pathPart += "?\(query)"
        }
        if let fragment = url.fragment {
            pathPart += "#\(fragment)"
        }

        let finalPath = pathPart.isEmpty ? "" : pathPart

        return "https://\(self.host)/\(scheme)/\(encryptedHost)\(finalPath)"
    }

    /// 将 WebVPN URL 解密为原始 URL
    /// - Parameter vpnURL: WebVPN URL
    /// - Throws: `WebVPNHelperError`
    /// - Returns: 原始 URL
    public static func decryptURL(vpnURL: String) throws -> String {
        guard let url = URL(string: vpnURL) else {
            throw WebVPNHelperError.urlDecryptionFailed("无效的 WebVPN URL")
        }

        let pathComponents = url.pathComponents

        guard pathComponents.count >= 3 else {
            throw WebVPNHelperError.urlDecryptionFailed("WebVPN URL 路径格式不正确")
        }

        let scheme = pathComponents[1]
        let encryptedHost = pathComponents[2]

        let decryptedHost: String
        do {
            decryptedHost = try decryptHost(encryptedHost)
        } catch {
            throw WebVPNHelperError.urlDecryptionFailed("解密主机名失败: \(error.localizedDescription)")
        }

        let prefixToDrop = "/\(scheme)/\(encryptedHost)"
        guard url.path.hasPrefix(prefixToDrop) else {
            throw WebVPNHelperError.urlDecryptionFailed("URL 路径与预期格式不符")
        }

        var originalPath = String(url.path.dropFirst(prefixToDrop.count))

        if originalPath.isEmpty && url.path.hasSuffix("/") {
            originalPath = "/"
        }

        if let query = url.query {
            originalPath += "?\(query)"
        }
        if let fragment = url.fragment {
            originalPath += "#\(fragment)"
        }

        return "\(scheme)://\(decryptedHost)\(originalPath)"
    }

    private static func encryptHost(_ text: String) throws -> String {
        guard let keyBytes = key.data(using: .utf8)?.byteArray,
            let ivBytes = iv.data(using: .utf8)?.byteArray,
            let textBytes = text.data(using: .utf8)?.byteArray
        else {
            throw WebVPNHelperError.hostEncryptionFailed("无法转换密钥、初始向量或文本为字节数组")
        }

        do {
            let aes = try AES(key: keyBytes, blockMode: CFB(iv: ivBytes), padding: .noPadding)
            let paddedTextBytes = textRightAppendBytes(dataBytes: textBytes)
            let encryptedBytes = try aes.encrypt(paddedTextBytes)
            let hexEncrypted = Data(encryptedBytes).toHexString()
            let truncatedHex = String(hexEncrypted.prefix(text.count * 2))
            return Data(ivBytes).toHexString() + truncatedHex
        } catch {
            throw WebVPNHelperError.hostEncryptionFailed("AES加密失败: \(error.localizedDescription)")
        }
    }

    private static func decryptHost(_ hexText: String) throws -> String {
        guard let keyBytes = key.data(using: .utf8)?.byteArray,
            let ivBytes = iv.data(using: .utf8)?.byteArray
        else {
            throw WebVPNHelperError.hostDecryptionFailed("无法转换密钥或初始向量为字节数组")
        }

        do {
            let aes = try AES(key: keyBytes, blockMode: CFB(iv: ivBytes), padding: .noPadding)
            let ivHexLen = Data(ivBytes).toHexString().count
            let encryptedPartHex = String(hexText.dropFirst(ivHexLen))
            let originalTextLength = encryptedPartHex.count / 2
            let paddedHexPayload = textRightAppendHex(hexString: encryptedPartHex)
            let encryptedBytes = [UInt8](hex: paddedHexPayload)

            let decryptedBytes = try aes.decrypt(encryptedBytes)

            let truncatedBytes = Array(decryptedBytes.prefix(originalTextLength))
            guard let result = String(bytes: truncatedBytes, encoding: .utf8) else {
                throw WebVPNHelperError.hostDecryptionFailed("解密后无法转换为字符串")
            }
            return result
        } catch let error as WebVPNHelperError {
            throw error
        } catch {
            throw WebVPNHelperError.hostDecryptionFailed("AES解密失败: \(error.localizedDescription)")
        }
    }

    private static func textRightAppendBytes(dataBytes: [UInt8], segmentByteSize: Int = 16) -> [UInt8] {
        let paddingLen = segmentByteSize - (dataBytes.count % segmentByteSize)
        if paddingLen == segmentByteSize { return dataBytes }
        let padding = [UInt8](repeating: 48, count: paddingLen)  // "0" 的 ASCII 值
        return dataBytes + padding
    }

    private static func textRightAppendHex(hexString: String, segmentHexSize: Int = 32) -> String {
        let paddingLen = segmentHexSize - (hexString.count % segmentHexSize)
        if paddingLen == segmentHexSize { return hexString }
        return hexString + String(repeating: "0", count: paddingLen)
    }
}
