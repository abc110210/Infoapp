import SwiftUI

@main
struct HoshinoPlayerApp: App {
    @StateObject private var tabRouter = TabRouter()
    @StateObject private var library = LibraryService.shared
    @StateObject private var settings = Settings.shared

    init() {
        // 注册自定义协议：AVPlayer 经 DAVURLProtocol 播放 NAS 音频（认证+自签名+Range）
        URLProtocol.registerClass(DAVURLProtocol.self)
        // 启动即配置后台音频会话 + 锁屏控制
        Task { @MainActor in
            PlayerService.shared.configureAudioSession()
            PlayerService.shared.activateRemoteCommands()
            // 从 NAS 拉取真实曲库（失败时界面显示重试）
            await LibraryService.shared.loadFromNAS()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(tabRouter)
                .environmentObject(library)
                .environmentObject(settings)
                .tint(HoshinoTheme.deepPink)
        }
    }
}
