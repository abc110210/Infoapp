import Foundation
import Combine

/// 曲库服务：内置演示歌单 + 预留远程 JSON 歌单加载口
@MainActor
final class LibraryService: ObservableObject {

    static let shared = LibraryService()

    @Published private(set) var playlists: [Playlist]

    init(playlists: [Playlist] = Playlist.demoPlaylists()) {
        self.playlists = playlists
    }

    /// 去重后的全部曲目（首页列表 / 播放队列共用）
    var allTracks: [Track] {
        var seen = Set<String>()
        return playlists.flatMap(\.tracks).filter { seen.insert($0.id).inserted }
    }

    /// 预留：从 JSON 加载歌单（未来接 NAS WebDAV / 自定义曲库）
    func loadFromRemote(_ url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let list = try JSONDecoder().decode([PlaylistDTO].self, from: data)
            playlists = list.map { $0.toPlaylist() }
        } catch {
            // 失败保留现有数据
        }
    }
}

/// 远程 JSON 结构（与本地 Playlist/Track 字段一致）
struct PlaylistDTO: Decodable {
    let id: String
    let name: String
    let emoji: String
    let gradient: Int
    let note: String
    let tracks: [TrackDTO]

    func toPlaylist() -> Playlist {
        Playlist(id: id, name: name, emoji: emoji, gradient: gradient,
                 note: note, tracks: tracks.map { $0.toTrack() })
    }
}

struct TrackDTO: Decodable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let gradient: Int
    let audioURL: String
    let lyric: String?

    func toTrack() -> Track {
        Track(id: id, title: title, artist: artist, album: album,
              duration: duration, gradient: gradient, audioURL: audioURL, lyric: lyric)
    }
}