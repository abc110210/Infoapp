import Foundation
import Combine

/// 磁盘缓存管理器（"边播边缓存" + 上限配额 + LRU 清理）
/// - 上限默认 2GB，跟随 Settings.cacheLimitGB 实时变化
/// - 清除缓存：清空 downloads 目录并按配额校准
final class CacheManager: ObservableObject {

    static let shared = CacheManager()

    /// 已用缓存字节数（主线程展示用）
    @Published private(set) var usedBytes: Int64 = 0
    /// 最近一次清除释放的字节
    @Published private(set) var lastFreedBytes: Int64 = 0

    private let downloadsURL: URL
    private let ioQueue = DispatchQueue(label: "com.hoshino.cache.io", qos: .utility)

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        downloadsURL = caches.appendingPathComponent("downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: downloadsURL, withIntermediateDirectories: true)
        refresh()
    }

    // MARK: - 路径 / 判断
    func cachedURL(for track: Track) -> URL? {
        let url = downloadsURL.appendingPathComponent(Self.safeName(track.id)).appendingPathExtension("mp3")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    var usedText: String {
        ByteCountFormatter.string(fromByteCount: usedBytes, countStyle: .file)
    }

    var freeableText: String {
        ByteCountFormatter.string(fromByteCount: max(0, usedBytes - quotaBytes), countStyle: .file)
    }

    var quotaBytes: Int64 { Settings.shared.cacheLimitBytes }

    // MARK: - 统计
    func refresh() {
        ioQueue.async { [weak self] in
            guard let self else { return }
            let bytes = Self.folderSize(self.downloadsURL)
            DispatchQueue.main.async {
                self.usedBytes = bytes
            }
        }
    }

    // MARK: - 下载（播放时后台补缓存）
    /// 若非本地已缓存则返回 nil 并开始下载；已缓存则校验配额。
    func ensureDownload(_ track: Track) {
        ioQueue.async { [weak self] in
            guard let self else { return }
            let dest = self.downloadsURL.appendingPathComponent(Self.safeName(track.id)).appendingPathExtension("mp3")
            guard !FileManager.default.fileExists(atPath: dest.path) else {
                self.enforceQuotaIfNeeded()
                return
            }
            guard let url = URL(string: track.audioURL) else { return }
            let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, _, _ in
                guard let tempURL, let self else { return }
                do {
                    try FileManager.default.moveItem(at: tempURL, to: dest)
                    self.enforceQuotaIfNeeded()
                    self.refresh()
                } catch {
                    // 下载失败静默：仍可走远程播放
                }
            }
            task.resume()
        }
    }

    // MARK: - 配额 / 清理
    private func enforceQuotaIfNeeded() {
        let quota = quotaBytes
        var files = (try? FileManager.default.contentsOfDirectory(
            at: downloadsURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [])) ?? []
        let total = Self.filesSize(files)
        guard total > quota else { return }
        // 旧→新 逐个删
        files.sort {
            let d0 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let d1 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return d0 < d1
        }
        var remaining = total
        for file in files {
            guard remaining > quota else { break }
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            try? FileManager.default.removeItem(at: file)
            remaining -= Int64(size)
        }
        DispatchQueue.main.async { [weak self] in
            self?.usedBytes = max(0, remaining)
        }
    }

    /// 清除全部缓存
    func clearAll() {
        ioQueue.async { [weak self] in
            guard let self else { return }
            let freed = Self.folderSize(self.downloadsURL)
            try? FileManager.default.removeItem(at: self.downloadsURL)
            try? FileManager.default.createDirectory(at: self.downloadsURL, withIntermediateDirectories: true)
            DispatchQueue.main.async {
                self.usedBytes = 0
                self.lastFreedBytes = freed
            }
        }
    }

    /// 上限变更后立即校准（设置页调整滑杆 / 快捷档时调用）
    func applyQuotaNow() {
        ioQueue.async { [weak self] in
            guard let self else { return }
            self.enforceQuotaIfNeeded()
        }
    }

    // MARK: - 工具
    static func safeName(_ id: String) -> String {
        let invalid = CharacterSet.alphanumerics.inverted
        return id.components(separatedBy: invalid).joined()
    }

    private static func folderSize(_ url: URL) -> Int64 {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [])) ?? []
        return filesSize(files)
    }

    private static func filesSize(_ files: [URL]) -> Int64 {
        files.reduce(Int64(0)) { acc, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return acc + Int64(size)
        }
    }
}