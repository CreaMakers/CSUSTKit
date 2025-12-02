public enum ServiceDomain {
    case authServer
    case ehall
    case mooc
    case education
}

extension ServiceDomain {
    var scheme: String {
        switch self {
        case .authServer, .ehall:
            return "https"
        case .mooc, .education:
            return "http"
        }
    }

    var directHost: String {
        switch self {
        case .authServer:
            return "authserver.csust.edu.cn"
        case .ehall:
            return "ehall.csust.edu.cn"
        case .mooc:
            return "pt.csust.edu.cn"
        case .education:
            return "xk.csust.edu.cn"
        }
    }

    var vpnHex: String {
        switch self {
        case .authServer:
            return "57524476706e697374686562657374212a095999a9e22e8d177074d487eb39946bea82e470fa4c"
        case .ehall:
            return "57524476706e697374686562657374212e144c9db6a93f8807712e9991fa3fceb2f8"
        case .mooc:
            return "57524476706e697374686562657374213b080392a9f22f8f5c673ec2dafd24"
        case .education:
            return "57524476706e6973746865626573742133170392a9f22f8f5c673ec2dafd24"
        }
    }
}
