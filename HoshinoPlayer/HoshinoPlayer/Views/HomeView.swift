import SwiftUI

/// 页面1：我的音乐（问候卡 + 搜索 + 歌单横滑 + 猜你喜欢 + 最近播放）
struct HomeView: View {
    @EnvironmentObject private var library: LibraryService
    @State private var keyword = ""

    var filteredTracks: [Track] {
        guard !keyword.isEmpty else { return library.allTracks }
        return library.allTracks.filter {
            $0.title.localizedCaseInsensitiveContains(keyword) ||
            $0.artist.localizedCaseInsensitiveContains(keyword)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                hero
                searchBar
                    .padding(.top, 14)
                sheets
                SectionTitle(title: "猜你喜欢", trailing: filterText)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                trackList(filteredTracks, limit: 4)
                if filteredTracks.isEmpty && !keyword.isEmpty {
                    // 搜索无结果时不再展示“最近播放”
                } else {
                    SectionTitle(title: "最近播放", trailing: "清空")
                        .padding(.top, 18)
                        .padding(.bottom, 10)
                    trackList(filteredTracks.isEmpty ? library.allTracks : Array(filteredTracks.suffix(2)), limit: 2)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 30)
        }
    }

    private var filterText: String {
        keyword.isEmpty ? "▶ 全部" : "找到 \(filteredTracks.count) 首"
    }

    // MARK: 问候卡
    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            Text("✦")
                .font(.system(size: 26))
                .foregroundColor(.white.opacity(0.55))
                .rotationEffect(.degrees(15))
                .offset(x: -14, y: 6)
                .accessibilityHidden(true)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("こんにちは ♪ 现在是晚上好")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))
                    Text("星野ちゃん の 音乐屋")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                }
                Spacer()
                // 星野头像（App 图标渐变化）
                Circle()
                    .fill(
                        RadialGradient(colors: [HoshinoTheme.yellow, HoshinoTheme.pink],
                                       center: .top, startRadius: 6, endRadius: 30)
                    )
                    .overlay(Text("✦").font(.system(size: 22, weight: .heavy)).foregroundColor(.white))
                    .frame(width: 58, height: 58)
                    .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 3))
                    .shadow(color: HoshinoTheme.deepPink.opacity(0.5), radius: 10, y: 4)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            LinearGradient(colors: [Color(hex: 0xFFC2D5), HoshinoTheme.pink, Color(hex: 0xC9A7F0)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: HoshinoTheme.deepPink.opacity(0.45), radius: 16, y: 10)
    }

    // MARK: 搜索
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(HoshinoTheme.inkSoft)
            TextField("想听点什么？搜索歌曲 / 歌手～", text: $keyword)
                .font(.system(size: 13))
                .foregroundColor(HoshinoTheme.ink)
            if !keyword.isEmpty {
                Button {
                    keyword = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(HoshinoTheme.inkSoft)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Capsule().fill(.white.opacity(0.92)))
        .shadow(color: HoshinoTheme.deepPink.opacity(0.12), radius: 8, y: 3)
    }

    // MARK: 歌单横滑
    private var sheets: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(library.playlists.prefix(3)) { p in
                    SheetCardSmall(name: p.name, emoji: p.emoji,
                                   gradient: p.gradient, note: p.note)
                }
            }
            .padding(.vertical, 14)
        }
    }

    // MARK: 曲目列表
    private func trackList(_ tracks: [Track], limit: Int) -> some View {
        VStack(spacing: 8) {
            if tracks.isEmpty {
                Text(keyword.isEmpty ? "" : "没有找到相关歌曲～")
                    .font(.system(size: 13))
                    .foregroundColor(HoshinoTheme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(tracks.prefix(limit))) { track in
                    TrackRow(track: track, showMeta: true) {
                        PlayerService.shared.play(track: track, in: library.allTracks)
                    }
                }
            }
        }
    }
}