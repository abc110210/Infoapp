import Foundation

/// 歌单（与预览页 2×2 歌单卡片对应）
struct Playlist: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    /// 卡片渐变索引
    let gradient: Int
    let note: String
    /// 所属曲目（首页"猜你喜欢"与歌单页共用同一批演示数据）
    var tracks: [Track]
}

extension Playlist {
    static func demoPlaylists() -> [Playlist] {
        let all = Track.demo()
        return [
            Playlist(id: "s1", name: "治愈系の小夜曲", emoji: "🌙", gradient: 0,
                     note: "12 首 · 助眠", tracks: [all[0], all[1], all[2]]),
            Playlist(id: "s2", name: "星空漫步", emoji: "🌌", gradient: 1,
                     note: "8 首 · 轻音乐", tracks: [all[3], all[1]]),
            Playlist(id: "s3", name: "怦然心动の合奏", emoji: "💘", gradient: 2,
                     note: "16 首 · J-POP", tracks: [all[2], all[3], all[1]]),
            Playlist(id: "s4", name: "元气起床铃", emoji: "☀️", gradient: 3,
                     note: "6 首 · 元气", tracks: [all[1], all[0]]),
        ]
    }
}