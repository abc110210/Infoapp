import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var api: APIService
    @State private var showSettings = false

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("总览", systemImage: "sparkles")
                }
            StatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
            ConsoleView()
                .tabItem {
                    Label("控制台", systemImage: "terminal.fill")
                }
            GroupsView()
                .tabItem {
                    Label("群与安全", systemImage: "person.3.fill")
                }
        }
        .tint(Color.magiPink)
        .toolbarBackground(Color(red: 0.08, green: 0.05, blue: 0.16), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.magiPink)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .task {
            api.connect()
            api.startSystemAutoRefresh()   // CPU/内存/磁盘等系统信息 3 秒实时
        }
    }
}