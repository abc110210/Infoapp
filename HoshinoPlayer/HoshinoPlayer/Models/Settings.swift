import Foundation
import Combine

/// 应用设置（UserDefaults 持久化）
/// - 缓存上限默认 2GB，可在设置页 1~8G 调整
/// - 后台播放开关（iOS 是否真的允许后台由系统 + 工程 Info.plist 的 audio 模式决定，
///   这里仅作为展示开关，真实播放始终配置 playback 会话）
final class Settings: ObservableObject {

    static let shared = Settings()

    private static let keyCacheGB = "cacheLimitGB"
    private static let keyFade = "fadeEnabled"
    private static let keyQuality = "quality"
    private static let keyBgPlay = "backgroundPlay"

    /// 缓存上限（GB），默认 2
    @Published var cacheLimitGB: Double {
        didSet { defaults.set(cacheLimitGB, forKey: Self.keyCacheGB) }
    }
    /// 播放淡入淡出
    @Published var fadeEnabled: Bool {
        didSet { defaults.set(fadeEnabled, forKey: Self.keyFade) }
    }
    /// 音质描述（展示）
    @Published var quality: String {
        didSet { defaults.set(quality, forKey: Self.keyQuality) }
    }
    /// 后台播放（展示用；真实能力恒开）
    @Published var backgroundPlay: Bool {
        didSet {
            defaults.set(backgroundPlay, forKey: Self.keyBgPlay)
            willChangeBackgroundPlay?()
        }
    }

    /// 后台播放开关变化时通知（用于更新锁屏标题等）
    var willChangeBackgroundPlay: (() -> Void)?

    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // didSet 在 init 中不触发，直接读默认值
        let saved = defaults.double(forKey: Self.keyCacheGB)
        cacheLimitGB = (saved > 0) ? saved : 2.0
        fadeEnabled = defaults.object(forKey: Self.keyFade) as? Bool ?? true
        quality = defaults.string(forKey: Self.keyQuality) ?? "超清 FLAC"
        backgroundPlay = defaults.object(forKey: Self.keyBgPlay) as? Bool ?? true
    }

    /// 当前缓存上限（字节）
    var cacheLimitBytes: Int64 {
        Int64(cacheLimitGB * 1024 * 1024 * 1024)
    }
}