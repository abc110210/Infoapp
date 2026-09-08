import SwiftUI

// ============================================================
// 根视图：粉色渐变背景 + 自绘底部五 Tab（我的/歌单/播放/歌词/设置）
// ============================================================
struct RootTabView: View {
    @EnvironmentObject private var router: TabRouter

    private let items: [(symbol: String, title: String)] = [
        ("house.fill", "我的"),
        ("music.note.list", "歌单"),
        ("play.fill", "播放"),
        ("text.quote", "歌词"),
        ("gearshape.fill", "设置"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            HoshinoTheme.pageBg
                .ignoresSafeArea()

            // 页面内容
            Group {
                switch router.tab {
                case 0: HomeView()
                case 1: PlaylistView()
                case 2: PlayerView()
                case 3: LyricsView()
                default: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 底部 Tab
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    ForEach(0..<items.count, id: \.self) { i in
                        TabButton(symbol: items[i].symbol,
                                  title: items[i].title,
                                  selected: router.tab == i) {
                            withAnimation(.easeOut(duration: 0.22)) { router.tab = i }
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.94))
                        .shadow(color: HoshinoTheme.deepPink.opacity(0.22), radius: 12, y: 5)
                )
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 8)
        }
        .preferredColorScheme(.light)
    }
}

private struct TabButton: View {
    let symbol: String
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                Text(title)
                    .font(.system(size: 9, weight: selected ? .heavy : .medium))
            }
            .foregroundColor(selected ? HoshinoTheme.deepPink : HoshinoTheme.inkSoft)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(selected ? HoshinoTheme.softPink.opacity(0.65) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}