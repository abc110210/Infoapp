import SwiftUI

/// 页面4：歌词（封面 + 当前行高亮 + 自动滚动居中）
struct LyricsView: View {
    @ObservedObject private var player = PlayerService.shared
    @State private var scrollID: UUID?

    private var lines: [LyricLine] {
        LyricsParser.parse(player.currentTrack?.lyric ?? "")
    }

    private var currentIndex: Int {
        guard !lines.isEmpty else { return -1 }
        var idx = 0
        for (i, line) in lines.enumerated() where line.time <= player.currentTime {
            idx = i
        }
        return idx
    }

    var body: some View {
        VStack(spacing: 0) {
            if let track = player.currentTrack {
                Text(track.title)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(HoshinoTheme.ink)
                Text("\(track.artist) · 歌词 LRC")
                    .font(.system(size: 11))
                    .foregroundColor(HoshinoTheme.inkSub)
                    .padding(.top, 3)
            }

            Spacer(minLength: 12)

            // 旋转封面（播放中转，暂停时停下）
            DiscThumb(gradient: player.currentTrack?.gradient ?? 0,
                      spinning: player.isPlaying)
                .padding(.bottom, 24)

            if lines.isEmpty {
                Text("暂无歌词～\n去听一首带歌词的歌吧")
                    .font(.system(size: 14))
                    .foregroundColor(HoshinoTheme.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(lines) { line in
                                let idx = lines.firstIndex(where: { $0.id == line.id }) ?? 0
                                Text(line.text)
                                    .font(.system(size: idx == currentIndex ? 19 : 15,
                                                  weight: idx == currentIndex ? .heavy : .regular))
                                    .foregroundColor(idx == currentIndex
                                                     ? HoshinoTheme.deepPink
                                                     : HoshinoTheme.inkSub)
                                    .multilineTextAlignment(.center)
                                    .id(line.id)
                                    .padding(.horizontal, 10)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onChange(of: currentIndex) { newIdx in
                        guard lines.indices.contains(newIdx) else { return }
                        let line = lines[newIdx]
                        withAnimation(.easeOut(duration: 0.35)) {
                            proxy.scrollTo(line.id, anchor: .center)
                        }
                    }
                }
            }

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 20)
    }
}

/// 播放页/歌词页共用小唱片
struct DiscThumb: View {
    let gradient: Int
    var spinning = true
    @State private var spin = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(AngularGradient(colors: [HoshinoTheme.grad(gradient).colors[0], .white,
                                                HoshinoTheme.softPink, .white, HoshinoTheme.lav,
                                                HoshinoTheme.grad(gradient).colors[0]],
                                      center: .center))
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(spin ? 360 : 0))
                .animation(spinning
                           ? .linear(duration: 18).repeatForever(autoreverses: false)
                           : .default,
                           value: spin)
                .onAppear { spin = spinning }
                .onChange(of: spinning) { on in
                    spin = on
                }
        }
        .overlay(
            Circle().fill(.white.opacity(0.35)).padding(10)
        )
        .shadow(color: HoshinoTheme.deepPink.opacity(0.45), radius: 16, y: 10)
    }
}