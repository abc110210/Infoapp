import SwiftUI

/// 页面2：歌单（曲库卡 + 音乐列表）
struct PlaylistView: View {
    @EnvironmentObject private var library: LibraryService
    @State private var selected = 0

    private var current: Playlist? {
        guard library.playlists.indices.contains(selected) else { return library.playlists.first }
        return library.playlists[selected]
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                head
                cards
                if let current {
                    SectionTitle(title: "音乐列表", trailing: current.note)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                    songs(of: current)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 30)
        }
    }

    private var head: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("我的歌单")
                    .font(.system(size: 21, weight: .heavy))
                    .foregroundColor(HoshinoTheme.ink)
                Text("把喜欢的歌收进星野的小盒子 ♪")
                    .font(.system(size: 11))
                    .foregroundColor(HoshinoTheme.inkSub)
            }
            Spacer()
            Button {
                // 新建歌单（v1 演示占位）
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("新建")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(colors: [HoshinoTheme.pink, HoshinoTheme.deepPink],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
                .shadow(color: HoshinoTheme.deepPink.opacity(0.5), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    private var cards: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<library.playlists.count, id: \.self) { i in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { selected = i }
                } label: {
                    SheetCardGrid(playlist: library.playlists[i], isSelected: i == selected)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 16)
    }

    private func songs(of playlist: Playlist) -> some View {
        VStack(spacing: 8) {
            ForEach(playlist.tracks) { track in
                TrackRow(track: track, showMeta: true) {
                    PlayerService.shared.play(track: track, in: playlist.tracks)
                }
            }
        }
    }
}
