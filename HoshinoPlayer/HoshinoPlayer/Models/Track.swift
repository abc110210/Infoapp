import Foundation

/// 一首歌（与桌面端 四件套/WebDAV 语义对应：audioURL 直链 + 可选 LRC 歌词）
struct Track: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var artist: String
    var album: String
    /// 时长（秒）；未知时传 0，播放后由实际资源校准
    var duration: TimeInterval
    /// 封面渐变索引（0..3 → HoshinoTheme 四色马卡龙渐变）
    var gradient: Int
    /// 音频直链（http/https）
    var audioURL: String
    /// LRC 歌词文本（可空）
    var lyric: String?
}

extension Track {
    var durationText: String {
        guard duration > 0 else { return "--:--" }
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
    }

    static func demo() -> [Track] {
        let sound1 = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
        let sound2 = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3"
        let sound3 = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3"
        let sound4 = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3"
        return [
            Track(id: "t01", title: "最熟悉的陌生人", artist: "萧亚轩", album: "红蔷薇",
                  duration: 4 * 60 + 24, gradient: 0, audioURL: sound1,
                  lyric: LRC.sample),
            Track(id: "t02", title: "夜に駆ける", artist: "YOASOBI", album: "THE BOOK",
                  duration: 4 * 60 + 18, gradient: 1, audioURL: sound2,
                  lyric: LRC.sample2),
            Track(id: "t03", title: "恋爱サーキュレーション", artist: "花澤香菜", album: "化物語",
                  duration: 4 * 60 + 23, gradient: 2, audioURL: sound3,
                  lyric: LRC.sample),
            Track(id: "t04", title: "群青", artist: "YOASOBI", album: "THE BOOK 2",
                  duration: 4 * 60 + 3, gradient: 3, audioURL: sound4,
                  lyric: LRC.sample),
        ]
    }
}

/// 演示 LRC（正式数据由用户曲库提供）
enum LRC {
    static let sample = """
[00:00.00]作词 : 姚谦
[00:05.20]还记得吗 窗外那被月光染亮的海洋
[00:12.80]你说 爱像云 要自在飘浮才美丽
[00:20.40]我终于渐渐明白 最熟悉的 却是陌生人
[00:29.10]心若知道灵犀的方向 那怕不能够朝夕相伴
[00:37.60]那只是一个古老的传说 美丽而苍凉
[00:45.20]我多么想和你见一面 看看你最近改变
[00:53.00]不再去说从前 只是寒暄 对你说一句 只是说一句
[01:01.50]好久不见
"""
    static let sample2 = """
[00:00.00]作词 : Ayase
[00:04.50]沈むように溶けてゆくように
[00:12.00]二人だけの空が広がる夜に
[00:20.20]さよならだけだった その一言で全てが分かった
[00:28.40]日が沈み出した空と君の姿
[00:36.60]フェンス越しに重なった言葉が 忘れたくなかった
[00:45.20]夜に駆け出して 探しに行ったよ あの光を
"""
}