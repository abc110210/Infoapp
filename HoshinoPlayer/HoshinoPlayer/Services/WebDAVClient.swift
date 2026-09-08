import Foundation

/// NAS 曲库条目（从 PROPFIND href 归组，语义对齐桌面端四件套）
struct NASEntry {
    let stem: String
    var audioRel: String? = nil
    var lyricRel: String? = nil
    var coverRel: String? = nil
    var infoRel: String? = nil
}

/// WebDAV 客户端：PROPFIND 枚举 /music → 归组四件套；GET lrc/jpg/txt 解析
@MainActor
final class WebDAVClient {

    static let shared = WebDAVClient()

    private let session: URLSession

    private init() {
        session = DAVURLProtocol.session
    }

    /// 1) 枚举库目录，返回按 stem 归组的条目（只保留有音频主文件的曲目）
    func fetchLibrary() async throws -> [NASEntry] {
        let url = NASConfig.realURL(relativePath: NASConfig.libDir)!
        var req = URLRequest(url: url)
        req.httpMethod = "PROPFIND"
        req.setValue(NASConfig.basicAuthHeader, forHTTPHeaderField: "Authorization")
        req.setValue("1", forHTTPHeaderField: "Depth")
        req.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        req.httpBody = Data("<?xml version=\"1.0\"?><propfind xmlns=\"DAV:\"><allprop/></propfind>".utf8)

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let hrefs = Self.parseHrefs(data)
        return Self.groupByStem(hrefs)
    }

    /// 2) 拉取 .txt 信息（歌名/艺术家/专辑/音质）
    func fetchInfo(relativePath: String) async -> [String: String] {
        guard let url = NASConfig.realURL(relativePath: relativePath) else { return [:] }
        var req = URLRequest(url: url)
        req.setValue(NASConfig.basicAuthHeader, forHTTPHeaderField: "Authorization")
        do {
            let (data, resp) = try await session.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return [:] }
            guard let text = String(data: data, encoding: .utf8) else { return [:] }
            var kv: [String: String] = [:]
            text.components(separatedBy: .newlines).forEach { line in
                let parts = line.split(separator: ":", maxSplits: 1)
                guard parts.count == 2 else { return }
                kv[String(parts[0]).trimmingCharacters(in: .whitespaces)] =
                    String(parts[1]).trimmingCharacters(in: .whitespaces)
            }
            return kv
        } catch {
            return [:]
        }
    }

    /// 3) 拉取 .lrc 歌词文本
    func fetchLyrics(relativePath: String) async -> String? {
        guard let url = NASConfig.realURL(relativePath: relativePath) else { return nil }
        var req = URLRequest(url: url)
        req.setValue(NASConfig.basicAuthHeader, forHTTPHeaderField: "Authorization")
        do {
            let (data, resp) = try await session.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            if let s = String(data: data, encoding: .utf8) { return s }
            // 兼容 BOM / 其他编码
            let bytes = data.count > 3 && data.starts(with: [0xEF, 0xBB, 0xBF]) ? data.dropFirst(3) : data
            return String(data: bytes, encoding: .utf8)
        } catch {
            return nil
        }
    }

    /// 4) 封面二进制（失败返回 nil，UI 用渐变兜底）
    func fetchCover(relativePath: String) async -> Data? {
        guard let url = NASConfig.realURL(relativePath: relativePath) else { return nil }
        var req = URLRequest(url: url)
        req.setValue(NASConfig.basicAuthHeader, forHTTPHeaderField: "Authorization")
        do {
            let (data, resp) = try await session.data(for: req)
            return (resp as? HTTPURLResponse)?.statusCode == 200 ? data : nil
        } catch {
            return nil
        }
    }

    // MARK: - 解析

    /// 提取全部 <href>（兼容 D:/d: 前缀），并 percent 解码
    static func parseHrefs(_ data: Data) -> [String] {
        guard let body = String(data: data, encoding: .utf8) else { return [] }
        var hrefs: [String] = []
        let openers = ["<D:href>", "<d:href>", "<href>"]
        var pos = body.startIndex
        while pos < body.endIndex {
            var best: String.Index?
            for op in openers {
                if let f = body.range(of: op, range: pos..<body.endIndex) {
                    if best == nil || f.lowerBound < best! { best = f.lowerBound }
                }
            }
            guard let start = best, let gt = body[start...].firstIndex(of: ">") else { break }
            let contentStart = body.index(after: gt)
            guard let end = body[contentStart...].range(of: "</")?.lowerBound else { break }
            let raw = String(body[contentStart..<end])
            hrefs.append(raw.removingPercentEncoding ?? raw)
            pos = end
        }
        return hrefs
    }

    /// href → stem 归组（忽略 @ 与 . 开头；只保留 flac/mp3 主文件的曲目）
    static func groupByStem(_ hrefs: [String]) -> [NASEntry] {
        var byStem: [String: NASEntry] = [:]
        for href in hrefs {
            let name = href.split(separator: "/").last.map(String.init) ?? href
            if name.isEmpty || name.hasPrefix("@") || name.hasPrefix(".") { continue }
            guard let dot = name.lastIndex(of: ".") else { continue }
            let stem = String(name[..<dot])
            let ext = String(name[name.index(after: dot)...]).lowercased()
            var entry = byStem[stem] ?? NASEntry(stem: stem)
            // 相对共享根的路径（去掉前导 /）
            var rel = href
            while rel.hasPrefix("/") { rel.removeFirst() }
            if NASConfig.audioExts.contains(ext) { entry.audioRel = rel }
            else if ext == NASConfig.lyricExt { entry.lyricRel = rel }
            else if NASConfig.coverExts.contains(ext) { entry.coverRel = rel }
            else if ext == NASConfig.infoExt { entry.infoRel = rel }
            byStem[stem] = entry
        }
        return byStem.values.filter { $0.audioRel != nil }.sorted { $0.stem < $1.stem }
    }
}
