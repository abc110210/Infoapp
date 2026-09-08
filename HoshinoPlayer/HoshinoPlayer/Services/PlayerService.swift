import Foundation
import AVFoundation
import Combine
import MediaPlayer
import UIKit

/// 播放模式：顺序 / 随机 / 单曲循环
enum PlayMode: Int, CaseIterable {
    case sequence = 0
    case shuffle = 1
    case single = 2

    var title: String {
        switch self {
        case .sequence: return "顺序播放"
        case .shuffle: return "随机播放"
        case .single: return "单曲循环"
        }
    }

    var symbolName: String {
        switch self {
        case .sequence: return "list.number"
        case .shuffle: return "shuffle"
        case .single: return "repeat.1"
        }
    }
}

/// 播放核心：AVPlayer 封装（后台播放 / 锁屏 NowPlaying / 远程控制 / 三种播放模式）
/// 线程模型：本类全部状态 @MainActor 隔离；耗时 IO 由 CacheManager 的 ioQueue 承担。
@MainActor
final class PlayerService: ObservableObject {

    static let shared = PlayerService()

    // MARK: - 对外状态
    @Published private(set) var currentTrack: Track?
    @Published private(set) var queue: [Track] = []
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var mode: PlayMode = .sequence

    var hasTrack: Bool { currentTrack != nil }

    // MARK: - 内部
    private let player = AVPlayer()
    private var timeObserver: Any?
    private var remoteRegistered = false
    /// 远程曲目缓冲就绪后自动续播的 KVO 观察（需持有，否则回调不触发）
    private var pendingResumeObservation: NSKeyValueObservation?

    private init() {
        configureAudioSession()
        activateRemoteCommands()
        addPeriodicTimeObserver()
        addEndNotification()
    }

    // MARK: - 音频会话（后台播放关键）
    /// 会话配置：类别 playback + 激活（锁屏/后台可继续出声）
    func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            // 首次无音频设备等场景静默降级，播放时再重试
        }
    }

    // MARK: - 播放控制
    /// 播放指定曲目（自动切歌单场景）
    func play(track: Track, in queue: [Track], startIndex: Int? = nil) {
        self.queue = queue
        let idx = startIndex ?? firstIndex(of: track, in: queue)
        playAt(idx)
    }

    func playAt(_ index: Int) {
        guard !queue.isEmpty else { return }
        let clamped = min(max(0, index), queue.count - 1)
        let track = queue[clamped]
        setCurrent(track)
    }

    func toggle() {
        guard currentTrack != nil else { return }
        if isPlaying {
            fadeOutThenPause()
        } else {
            configureAudioSession()
            player.play()
            isPlaying = true
            fadeIn()
        }
        updateNowPlaying()
    }

    func playFromBeginning() {
        currentTime = 0
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        if isPlaying { player.play() }
    }

    func next(_ manual: Bool = true) {
        guard !queue.isEmpty else { return }
        let i = currentIndex()
        var target = i + 1
        if mode == .shuffle {
            target = Int.random(in: 0..<queue.count)
        }
        if target >= queue.count { target = 0 }
        playAt(target)
    }

    func previous() {
        guard !queue.isEmpty else { return }
        let i = currentIndex()
        let target = (i - 1 + queue.count) % queue.count
        playAt(target)
    }

    func seek(to seconds: TimeInterval) {
        let clamped = min(max(0, seconds), max(duration, 0.01))
        currentTime = clamped
        player.seek(to: CMTime(seconds: clamped, preferredTimescale: 600))
        updateNowPlaying()
    }

    /// 切换播放模式（顺序/随机/单曲）
    func cycleMode() {
        let all = PlayMode.allCases
        let nextIdx = (mode.rawValue + 1) % all.count
        mode = all[nextIdx]
    }

    // MARK: - 内部实现
    private func currentIndex() -> Int {
        guard let track = currentTrack else { return 0 }
        return firstIndex(of: track, in: queue)
    }

    private func firstIndex(of track: Track, in q: [Track]) -> Int {
        q.firstIndex(where: { $0.id == track.id }) ?? 0
    }

    private func setCurrent(_ track: Track) {
        currentTrack = track
        duration = track.duration
        currentTime = 0
        pendingResumeObservation?.invalidate()
        pendingResumeObservation = nil

        // 1) 本地缓存优先
        if let cached = CacheManager.shared.cachedURL(for: track) {
            player.replaceCurrentItem(with: AVPlayerItem(url: cached))
            configureAudioSession()
            player.play()
            isPlaying = true
            updateNowPlaying()
            updateLockScreenProgress()
            return
        }

        // 2) 远程：缓冲完成后由 KVO 自动续播（不提前置 isPlaying=true，避免误判）
        guard let url = URL(string: track.audioURL) else {
            isPlaying = false
            return
        }
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        CacheManager.shared.ensureDownload(track)
        isPlaying = true
        pendingResumeObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    guard let cur = self.player.currentItem, cur === item, self.isPlaying else { return }
                    self.configureAudioSession()
                    self.player.play()
                    self.updateNowPlaying()
                case .failed:
                    // 资源不可达 / 解码失败：回退为暂停态，避免 UI 假播放
                    self.isPlaying = false
                    self.updateNowPlaying()
                default:
                    break
                }
            }
        }
        updateNowPlaying()
        updateLockScreenProgress()
    }

    // MARK: - 淡入淡出
    private func fadeIn(duration: TimeInterval = 0.4) {
        guard Settings.shared.fadeEnabled else { player.volume = 1; return }
        player.volume = 0
        player.play()
        UIViewPropertyAnimator(duration: duration, curve: .linear) { [player] in
            player.volume = 1
        }.startAnimation()
    }

    private func fadeOutThenPause(duration: TimeInterval = 0.3) {
        guard Settings.shared.fadeEnabled else { player.pause(); isPlaying = false; return }
        let animator = UIViewPropertyAnimator(duration: duration, curve: .linear) { [player] in
            player.volume = 0
        }
        animator.addCompletion { [weak self] _ in
            Task { @MainActor in
                self?.player.pause()
                self?.isPlaying = false
                self?.player.volume = 1
                self?.updateNowPlaying()
            }
        }
        animator.startAnimation()
    }

    // MARK: - 进度观察
    private func addPeriodicTimeObserver() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            // 周期回调不是 MainActor 上下文：切换到主线程再更新 UI 状态
            Task { @MainActor in
                guard let self else { return }
                let t = CMTimeGetSeconds(time)
                if t.isFinite, t >= 0 {
                    self.currentTime = t
                    if self.duration <= 1 { self.syncDuration() }
                }
                self.updateLockScreenProgress()
            }
        }
    }

    private func syncDuration() {
        if let item = player.currentItem, item.duration.isNumeric {
            let d = CMTimeGetSeconds(item.duration)
            if d.isFinite, d > 1 { duration = d }
        }
    }

    private func addEndNotification() {
        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            // 播完回调节点不保证 MainActor 上下文：切回主线程处理
            let ended = note.object as? AVPlayerItem
            Task { @MainActor in
                guard let self,
                      let ended,
                      ended === self.player.currentItem else { return }
                switch self.mode {
                case .single:
                    self.playFromBeginning()
                case .sequence, .shuffle:
                    self.next(false)
                }
                self.updateNowPlaying()
            }
        }
    }

    // MARK: - 锁屏 / 控制中心
    /// 注册远程控制命令（启动时调用；单例只注册一次）
    func activateRemoteCommands() {
        guard !remoteRegistered else { return }
        remoteRegistered = true
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.toggle() }
            return .success
        }
        c.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.toggle() }
            return .success
        }
        c.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.toggle() }
            return .success
        }
        c.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.next() }
            return .success
        }
        c.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.previous() }
            return .success
        }
        c.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let ev = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in self?.seek(to: ev.positionTime) }
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let track = currentTrack else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.album,
            MPMediaItemPropertyPlaybackDuration: max(duration, 0),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]
        if let art = Self.makeArtwork(gradient: track.gradient) {
            info[MPMediaItemPropertyArtwork] = art
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateLockScreenProgress() {
        guard let track = currentTrack else { return }
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPMediaItemPropertyPlaybackDuration] = max(duration, 0)
        info[MPMediaItemPropertyTitle] = track.title
        info[MPMediaItemPropertyArtist] = track.artist
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// 渐变幻色封面（无歌曲图片时的兜底 artwork）
    /// 注意：UIGraphicsImageRenderer 与 CAGradientLayer 均要求主线程，本类已 @MainActor。
    private static func makeArtwork(gradient: Int) -> MPMediaItemArtwork? {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let colors = HoshinoTheme.gradColors(gradient)
            let cgLayer = CAGradientLayer()
            cgLayer.frame = CGRect(origin: .zero, size: size)
            cgLayer.colors = colors.map { UIColor($0).cgColor }
            cgLayer.startPoint = CGPoint(x: 0, y: 0)
            cgLayer.endPoint = CGPoint(x: 1, y: 1)
            cgLayer.render(in: ctx.cgContext)
        }
        return MPMediaItemArtwork(boundsSize: size) { _ in image }
    }

    // MARK: - 生命周期（前台回来时恢复可用）
    func applicationDidBecomeActive() {
        configureAudioSession()
    }
}
