import SwiftUI

/// 页面5：设置（后台播放 / 音质 / 淡入淡出 / 缓存上限可调 / 清除缓存）
struct SettingsView: View {
    @EnvironmentObject private var settings: Settings
    @StateObject private var cache = CacheManager.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                group(title: "播放设置") {
                    PinkToggle(title: "后台播放",
                               subtitle: "锁屏 / 切到后台时继续播放音乐",
                               isOn: $settings.backgroundPlay)
                    settingsRow(icon: "slider.horizontal.3", tint: HoshinoTheme.yellow,
                                title: "播放音质", value: settings.quality)
                    PinkToggle(title: "淡入淡出",
                               subtitle: "歌曲切换时音量平滑过渡",
                               isOn: $settings.fadeEnabled)
                }

                group(title: "存储与缓存") {
                    cacheRow
                    clearRow
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 30)
        }
    }

    // MARK: 分组容器
    private func group<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(HoshinoTheme.inkSoft)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white)
                    .shadow(color: HoshinoTheme.pink.opacity(0.2), radius: 12, y: 5)
            )
        }
    }

    // MARK: 普通设置行
    private func settingsRow(icon: String, tint: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(tint))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(HoshinoTheme.ink)
            }
            Spacer()
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(HoshinoTheme.inkSub)
        }
        .padding(.vertical, 11)
    }

    // MARK: 缓存行（滑杆 1~8G + 快捷档 2/4/8）
    private var cacheRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "folder")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(HoshinoTheme.lav))
                VStack(alignment: .leading, spacing: 2) {
                    Text("缓存大小")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(HoshinoTheme.ink)
                    Text("已用 \(cache.usedText) / 上限 \(cacheLimitText)")
                        .font(.system(size: 11))
                        .foregroundColor(HoshinoTheme.inkSub)
                }
                Spacer()
                Text(cacheLimitText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(HoshinoTheme.deepPink)
            }

            Slider(
                value: Binding(
                    get: { settings.cacheLimitGB },
                    set: {
                        settings.cacheLimitGB = max(1, min(8, $0.rounded()))
                        cache.applyQuotaNow()
                    }
                ),
                in: 1...8,
                step: 1
            )
            .tint(HoshinoTheme.yellow)
            .accessibilityLabel("缓存上限")

            HStack(spacing: 8) {
                ForEach([2.0, 4.0, 8.0], id: \.self) { gb in
                    cacheChip(gb)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func cacheChip(_ gb: Double) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) {
                settings.cacheLimitGB = gb
                cache.applyQuotaNow()
            }
        } label: {
            Text(gb == 2 ? "默认 \(Int(gb))G" : "\(Int(gb))G")
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(settings.cacheLimitGB == gb ? .white : HoshinoTheme.inkSub)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(settings.cacheLimitGB == gb
                              ? LinearGradient(colors: [HoshinoTheme.pink, HoshinoTheme.deepPink],
                                               startPoint: .leading, endPoint: .trailing)
                              : LinearGradient(colors: [Color.white, Color.white],
                                               startPoint: .leading, endPoint: .trailing))
                )
        }
        .buttonStyle(.plain)
    }

    private var cacheLimitText: String {
        let gb = Int(settings.cacheLimitGB)
        return "\(gb)GB"
    }

    // MARK: 清除缓存行
    private var clearRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash")
                .font(.system(size: 15))
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(HoshinoTheme.pink))
            VStack(alignment: .leading, spacing: 2) {
                Text("清除缓存")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(HoshinoTheme.ink)
                Text("可释放 \(cache.freeableText) 空间")
                    .font(.system(size: 11))
                    .foregroundColor(HoshinoTheme.inkSub)
            }
            Spacer()
            Button {
                cache.clearAll()
            } label: {
                Text("清理")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(HoshinoTheme.deepPink))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 11)
    }
}