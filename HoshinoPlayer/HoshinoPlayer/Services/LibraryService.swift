import Foundation
import Combine

/// 曲库服务：从 NAS WebDAV 加载真实曲库（枚举 /音乐/ → 四件套归组 → 补元数据）
/// 保留内置演示数据作为启动占位；NAS 加载成功即替换
@MainActor
final class LibraryService: ObservableObject {

    static let shared = LibraryService()

    @Published private(set) var playlists: [Playlist]
    /// NAS 是否已成功连接并加载
    @Published private(set) var isNASLoaded = false
    @Published private(set) var loadError: String?
    @Published private(set) var isLoading = false

    init(playlists: [Playlist] = Playlist.demoPlaylists()) {
        self.playlists = playlists
    }

    /// 去重后的全部曲目（首页列表 / 播放队列共用）
    var allTracks: [Track] {
        var seen = Set<String>()
        return playlists.flatMap(\.tracks).filter { seen.insert($0.id).inserted }
    }

    /// 连接 NAS 并加载曲库（失败保留现有数据并暴露错误，供 UI 重试）
    func loadFromNAS() async {
        guard !isLoading else { return }
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            let entries = try await WebDAVClient.shared.fetchLibrary()
            let tracks = await buildTracks(from: entries)
            guard !tracks.isEmpty else {
                loadError = "NAS 曲库为空"
                return
            }
            // 按艺术家分组生成歌单；全部曲目归入"NAS 曲库"
            let allPlaylist = Playlist(id: "nas-all",
                                       name: "NAS 曲库",
                                       emoji: "🌐",
                                       gradient: 0,
                                       note: "\(tracks.count) 首 · WebDAV 直连",
                                       tracks: tracks)
            let byArtist = Dictionary(grouping: tracks) { $0.artist }
                .map { (key, value) in
                    Playlist(id: "nas-\(key)",
                             name: key.isEmpty ? "未知艺术家" : key,
                             emoji: "🎤",
                             gradient: abs(key.hashValue) % 4,
                             note: "\(value.count) 首",
                             tracks: value)
                }
                .sorted { $0.name < $1.name }
            playlists = [allPlaylist] + byArtist
            isNASLoaded = true
        } catch {
            loadError = "无法连接 NAS（\(NASConfig.host):\(NASConfig.port)）\n请确认与 NAS 同一局域网"
        }
    }

    // MARK: - 内部

    private func buildTracks(from entries: [NASEntry]) async -> [Track] {
        var tracks: [Track] = []
        for entry in entries {
            guard let audioRel = entry.audioRel else { continue }

            var info: [String: String] = [:]
            if let infoRel = entry.infoRel {
                info = await WebDAVClient.shared.fetchInfo(relativePath: infoRel)
            }

            let title = info["歌名"] ?? Self.titleFromStem(entry.stem)
            let artist = info["艺术家"] ?? Self.artistFromStem(entry.stem)
            let album = info["专辑"] ?? "未知专辑"

            var lyric: String?
            if let lyricRel = entry.lyricRel {
                lyric = await WebDAVClient.shared.fetchLyrics(relativePath: lyricRel)
            }

            let track = Track(id: entry.stem,
                              title: title,
                              artist: artist,
                              album: album,
                              duration: 0, // 播放时由 AVPlayer 校准
                              gradient: abs(entry.stem.hashValue) % 4,
                              audioURL: DAVURLProtocol.playURL(relativePath: audioRel).absoluteString,
                              lyric: lyric)
            tracks.append(track)
        }
        return tracks
    }

    /// "最熟悉的陌生人 - 萧亚轩" → "最熟悉的陌生人"
    static func titleFromStem(_ stem: String) -> String {
        if let idx = stem.range(of: " - ") {
            return String(stem[..<idx.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return stem
    }

    /// "最熟悉的陌生人 - 萧亚轩" → "萧亚轩"
    static func artistFromStem(_ stem: String) -> String {
        if let idx = stem.range(of: " - ") {
            return String(stem[idx.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        return "未知艺术家"
    }
}
