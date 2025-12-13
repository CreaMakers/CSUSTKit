import Foundation

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var base64String: String {
        return Data(self.utf8).base64EncodedString()
    }
}
