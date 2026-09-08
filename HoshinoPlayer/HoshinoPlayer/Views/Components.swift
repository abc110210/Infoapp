import SwiftUI

// ============================================================
// 通用小组件：渐变封面 / 曲目行 / 歌单小卡 / 粉色胶囊
// ============================================================

/// 马卡龙渐变封面（无图片曲目用文字音符 + 渐变）
struct CoverArt: View {
    let gradient: Int
    let symbol: String
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(HoshinoTheme.grad(gradient))
            .frame(width: size, height: size)
            .overlay(
                Text(symbol)
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
            )
            .shadow(color: HoshinoTheme.deepPink.opacity(0.35),
                    radius: size * 0.22, y: size * 0.10)
    }
}

/// 曲目行（播放按钮列在标题与信息之间，呼应桌面端排版）
struct TrackRow: View {
    let track: Track
    let showMeta: Bool
    var onPlay: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            CoverArt(gradient: track.gradient, symbol: "♪", size: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(HoshinoTheme.ink)
                    .lineLimit(1)
                Text(showMeta ? "\(track.artist) · 超清母带 FLAC" : track.artist)
                    .font(.system(size: 11))
                    .foregroundColor(HoshinoTheme.inkSub)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 播放按钮
            Button(action: { onPlay?() }) {
                Image(systemName: "play.fill")
                    .font(.system(size: 15))
                    .foregroundColor(HoshinoTheme.pink)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(HoshinoTheme.softPink.opacity(0.45)))
            }
            .buttonStyle(.plain)

            Text(track.durationText)
                .font(.system(size: 11))
                .foregroundColor(HoshinoTheme.inkSoft)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
                .shadow(color: HoshinoTheme.pink.opacity(0.18), radius: 10, y: 4)
        )
    }
}

/// 歌单横滑小卡（首页）
struct SheetCardSmall: View {
    let name: String
    let emoji: String
    let gradient: Int
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(emoji)
                .font(.system(size: 24))
                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
            Text(name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
            Text(note)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(12)
        .frame(width: 128, height: 108, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(HoshinoTheme.grad(gradient))
        )
        .shadow(color: HoshinoTheme.deepPink.opacity(0.3), radius: 10, y: 5)
    }
}

/// 段落标题行
struct SectionTitle: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(HoshinoTheme.ink)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 11))
                    .foregroundColor(HoshinoTheme.inkSoft)
            }
        }
        .padding(.horizontal, 2)
    }
}

/// iOS 风格开关
struct PinkToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(HoshinoTheme.ink)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(HoshinoTheme.inkSub)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(HoshinoTheme.deepPink)
        }
    }
}

/// 歌单页 2×2 卡片
struct SheetCardGrid: View {
    let playlist: Playlist
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(playlist.emoji)
                .font(.system(size: 24))
                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
            Text(playlist.name)
                .font(.system(size: 13.5, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Text(playlist.note)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(HoshinoTheme.grad(playlist.gradient))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white, lineWidth: isSelected ? 3 : 0)
                .opacity(isSelected ? 1 : 0)
        )
        .shadow(color: isSelected
                ? HoshinoTheme.deepPink.opacity(0.55)
                : HoshinoTheme.deepPink.opacity(0.3),
                radius: 10, y: 6)
    }
}