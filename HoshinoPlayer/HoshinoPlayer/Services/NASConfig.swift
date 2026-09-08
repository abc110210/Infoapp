import Foundation

/// NAS WebDAV 接入配置（与桌面端 net_bridge.cpp 的 XOR 混淆常量同值）
/// ⚠️ 按用户要求直接写死在程序里；如改换 NAS 请同步修改本文件
enum NASConfig {
    static let host = "nas.xlingran.com"          // 内网解析 192.168.1.124
    static let port = 5008
    static let user = "musicapp"
    static let pass = "@Asd44552211"
    /// 库目录（WebDAV 相对共享根）
    static let libDir = "音乐"
    /// 四件套扩展名（音频主 / 歌词 / 封面 / 信息）
    static let audioExts = ["flac", "mp3"]
    static let lyricExt = "lrc"
    static let coverExts = ["jpg", "jpeg", "png"]
    static let infoExt = "txt"

    static var scheme: String { "https" }
    static var hostURL: URL {
        URL(string: "\(scheme)://\(host):\(port)")!
    }

    static var basicAuthHeader: String {
        "Basic " + Data("\(user):\(pass)".utf8).base64EncodedString()
    }

    /// 库目录的 WebDAV 路径（percent 编码后的相对路径，如 "音乐"）
    static var libDirPath: String {
        libDir.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? libDir
    }

    /// 真实 HTTPS URL（用于歌词 / 封面 / 信息 / PROPFIND）
    static func realURL(relativePath: String) -> URL? {
        let enc = relativePath.split(separator: "/")
            .map { String($0).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
            .joined(separator: "/")
        return URL(string: "\(scheme)://\(host):\(port)/\(enc)")
    }
}
