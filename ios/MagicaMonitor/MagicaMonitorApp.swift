import SwiftUI

@main
struct MagicaMonitorApp: App {
    @StateObject private var api = APIService.shared

    init() {
        // 后台保持连接：进后台维持心跳，回前台立即刷新/重连
        APIService.shared.setupBackgroundHandling()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(api)
                .preferredColorScheme(.dark)
        }
    }
}