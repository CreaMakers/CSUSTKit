import Foundation

extension String.Encoding {
    public static let gbk: String.Encoding = .init(
        rawValue: CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
}
