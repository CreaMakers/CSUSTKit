import Foundation

extension String.Encoding {
    #if canImport(CoreFoundation) && os(macOS)
        public static let gbk = String.Encoding(
            rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
            )
        )
    #else
        public static let gbk = String.Encoding(rawValue: 0x8000_0421)
    #endif
}
