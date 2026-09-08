import SwiftUI

/// 页面3：正在播放（旋转渐变唱片 + 进度 + 控制 + 底部按钮组）
struct PlayerView: View {
    @ObservedObject private var player = PlayerService.shared
    @EnvironmentObject private var router: TabRouter
    @State private var rotation: Double = 0

    private var track: Track? { player.currentTrack }

    var body: some View {
        VStack(spacing: 0) {
            if let track {
                Spacer(minLength: 8)
                Text(track.title)
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundColor(HoshinoTheme.ink)
                Text("\(track.artist) · 超清母带 FLAC")
                    .font(.system(size: 12))
                    .foregroundColor(HoshinoTheme.inkSub)
                    .padding(.top, 4)

                Spacer(minLength: 16)
                disc
                Spacer(minLength: 18)

                progress
                controls
                    .padding(.top, 20)
                footer
                    .padding(.top, 22)
                Spacer(minLength: 10)
            } else {
                Spacer()
                Image(systemName: "music.note")
                    .font(.system(size: 56))
                    .foregroundColor(HoshinoTheme.softPink)
                Text("还没有在播放的歌曲\n去「我的」或「歌单」挑一首吧")
                    .font(.system(size: 14))
                    .foregroundColor(HoshinoTheme.inkSub)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.top, 18)
                Spacer()
            }
        }
        .padding(.horizontal, 30)
        .onReceive(player.$isPlaying) { playing in
            // 每次恢复播放时累计一个 360°，repeatForever 无缝循环
            guard playing else { return }
            withAnimation(.linear(duration: 22).repeatForever(autoreverses: false)) {
                rotation += 360
            }
        }
    }

    // MARK: 唱片
    private var disc: some View {
        ZStack {
            // 旋转渐变圆盘
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(
                    AngularGradient(colors: [HoshinoTheme.pink, .white, HoshinoTheme.softPink,
                                             .white, HoshinoTheme.lav, HoshinoTheme.pink],
                                    center: .center)
                )
                .frame(width: 238, height: 238)
                .rotationEffect(.degrees(rotation))
                .animation(.linear(duration: 22).repeatForever(autoreverses: false), value: rotation)
                .overlay(
                    RoundedRectangle(cornerRadius: 60, style: .continuous)
                        .fill(HoshinoTheme.softPink.opacity(0.5))
                        .padding(8)
                )
                .shadow(color: HoshinoTheme.deepPink.opacity(0.5), radius: 26, y: 16)

            // 中央 logo 头像
            Circle()
                .fill(.white)
                .frame(width: 64, height: 64)
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(colors: [HoshinoTheme.yellow, HoshinoTheme.pink],
                                           center: .top, startRadius: 6, endRadius: 30)
                        )
                        .overlay(Text("✦").font(.system(size: 24, weight: .heavy)).foregroundColor(.white))
                        .padding(6)
                )
                .shadow(color: HoshinoTheme.deepPink.opacity(0.4), radius: 8, y: 3)
        }
    }

    // MARK: 进度
    private var progress: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { player.currentTime },
                    set: { player.seek(to: $0) }
                ),
                in: 0...max(player.duration, 1)
            )
            .tint(HoshinoTheme.deepPink)

            HStack {
                Text(player.currentTime.timeText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(HoshinoTheme.inkSub)
                Spacer()
                Text(player.duration.timeText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(HoshinoTheme.inkSub)
            }
        }
    }

    // MARK: 控制
    private var controls: some View {
        HStack(spacing: 26) {
            Button { player.cycleMode() } label: {
                Image(systemName: player.mode.symbolName)
                    .font(.system(size: 17))
                    .foregroundColor(player.mode == .sequence ? HoshinoTheme.inkSoft : HoshinoTheme.deepPink)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(.white).shadow(color: .black.opacity(0.08), radius: 6, y: 2))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(player.mode.title)

            Button { player.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 22))
                    .foregroundColor(HoshinoTheme.deepPink)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(.white).shadow(color: .black.opacity(0.1), radius: 8, y: 3))
            }
            .buttonStyle(.plain)

            Button { player.toggle() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 68, height: 68)
                    .background(
                        LinearGradient(colors: [HoshinoTheme.pink, HoshinoTheme.deepPink],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
                    .shadow(color: HoshinoTheme.deepPink.opacity(0.6), radius: 14, y: 8)
            }
            .buttonStyle(.plain)

            Button { player.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 22))
                    .foregroundColor(HoshinoTheme.deepPink)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(.white).shadow(color: .black.opacity(0.1), radius: 8, y: 3))
            }
            .buttonStyle(.plain)

            Button { } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 17))
                    .foregroundColor(HoshinoTheme.inkSoft)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(.white).shadow(color: .black.opacity(0.08), radius: 6, y: 2))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: 底部按钮组
    private var footer: some View {
        HStack(spacing: 34) {
            FooterButton(symbol: "heart.fill", label: "收藏", active: true) { }
            FooterButton(symbol: "text.quote", label: "歌词", active: false) { router.tab = 3 }
            FooterButton(symbol: "list.bullet", label: "歌单", active: false) { router.tab = 1 }
        }
    }
}

private struct FooterButton: View {
    let symbol: String
    let label: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 19))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundColor(active ? HoshinoTheme.deepPink : HoshinoTheme.inkSub)
        }
        .buttonStyle(.plain)
    }
}

extension TimeInterval {
    var timeText: String {
        guard isFinite, self >= 0 else { return "--:--" }
        let m = Int(self) / 60
        let s = Int(self) % 60
        return String(format: "%d:%02d", m, s)
    }
}