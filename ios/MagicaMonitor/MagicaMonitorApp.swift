import SwiftUI

@main
struct MagicaMonitorApp: App {
    @StateObject private var api = APIService.shared

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(api)
                .preferredColorScheme(.dark)
        }
    }
}