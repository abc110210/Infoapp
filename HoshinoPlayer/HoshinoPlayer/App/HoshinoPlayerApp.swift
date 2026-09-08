import SwiftUI

@main
struct HoshinoPlayerApp: App {
    @StateObject private var tabRouter = TabRouter()
    @StateObject private var library = LibraryService.shared
    @StateObject private var settings = Settings.shared

    init() {
        // 启动即配置后台音频会话 + 锁屏控制（App init 在 SwiftUI 主线程完成）
        Task { @MainActor in
            PlayerService.shared.configureAudioSession()
            PlayerService.shared.activateRemoteCommands()
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