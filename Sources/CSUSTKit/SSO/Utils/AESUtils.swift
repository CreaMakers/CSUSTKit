import CommonCrypto
import Foundation

struct AESUtils {
    static func randomString(length: Int) -> String {
        let letters = "ABCDEFGHJKMNPQRSTWXYZabcdefhijkmnprstwxyz2345678"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    static func aesEncrypt(data: String, key: String, iv: String) -> String? {
        guard let keyData = key.data(using: .utf8),
            let ivData = iv.data(using: .utf8),
            let dataToEncrypt = data.data(using: .utf8)
        else {
            return nil
        }

        let keyBytes = Array(keyData.prefix(16))
        let ivBytes = Array(ivData.prefix(16))
        var encryptedBytes = [UInt8](repeating: 0, count: dataToEncrypt.count + kCCBlockSizeAES128)
        var encryptedLength = 0

        let status = CCCrypt(
            CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding),
            keyBytes, kCCKeySizeAES128, ivBytes, Array(dataToEncrypt), dataToEncrypt.count,
            &encryptedBytes, encryptedBytes.count, &encryptedLength)

        if status == kCCSuccess {
            let encryptedData = Data(bytes: encryptedBytes, count: encryptedLength)
            return encryptedData.base64EncodedString()
        } else {
            return nil
        }
    }

    static func encryptPassword(password: String, salt: String?) -> String {
        guard let key = salt, !key.isEmpty else {
            return password
        }

        let salt = randomString(length: 64)
        let iv = randomString(length: 16)
        let combinedData = salt + password

        if let encryptedData = aesEncrypt(data: combinedData, key: key, iv: iv) {
            return encryptedData
        } else {
            return password
        }
    }
}
