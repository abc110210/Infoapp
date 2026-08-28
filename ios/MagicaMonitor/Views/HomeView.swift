import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var api: APIService

    var body: some View {
        NavigationStack {
            ZStack {
                StardustBackground(imageName: "page_bg")

                ScrollView {
                    VStack(spacing: 16) {
                        hero
                        if api.isLoading && api.data == nil {
                            ProgressView("魔法加载中…")
                                .tint(.magiPink)
                                .padding(.top, 40)
                        } else if let err = api.errorMessage {
                            errorCard(err)
                        } else if api.data != nil {
                            serverCard
                            systemCard
                            overviewCard
                            banCard
                            banStatsCard
                            footer
                        } else {
                            EmptyState(icon: "wand.and.stars", text: "还没有数据，点击下方刷新")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await api.refresh()
                }
            }
            .navigationTitle("魔法观测")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Hero
    private var hero: some View {
        ZStack {
            // 魔法少女氛围背景：AI 生成的魔法圆环天空（暗化处理）
            Image("hero_sky")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [Color.magiPinkDeep.opacity(0.20), Color.magiPurple.opacity(0.30), Color.black.opacity(0.55)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            // 底部柔光提升层次
            RadialGlow(color: .magiPink, radius: 150)
                .offset(x: 0, y: 120)
                .opacity(0.55)

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(
                    LinearGradient(colors: [Color.magiPink.opacity(0.6), Color.magiPurple.opacity(0.4), Color.white.opacity(0.15)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.2
                )

            MagicCircle(size: 160)
                .offset(x: 120, y: -90)
                .opacity(0.6)

            VStack(alignment: .leading, spacing: 14) {
                Text("魔法观测")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, Color.magiPink, Color(red: 1.0, green: 0.85, blue: 0.95)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .magiPink.opacity(0.7), radius: 14)

                HStack(spacing: 6) {
                    if let v = api.data?.status?.version, !v.isEmpty {
                        Pill(text: "version \(v)", color: .white)
                    }
                    if let ws = api.data?.status?.ws_connected {
                        Pill(text: ws ? "WS 在线" : "WS 掉线", color: ws ? .magiGreen : .magiGold)
                    }
                }

                // 状态光环
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(wsColor.opacity(0.25))
                            .frame(width: 54, height: 54)
                        Circle()
                            .fill(wsColor)
                            .frame(width: 30, height: 30)
                            .shadow(color: wsColor, radius: 12)
                        Circle()
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 10, height: 10)
                            .offset(x: -6, y: -6)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(wsText)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)
                        Text("已运行 \(humanUptime(api.data?.status?.uptime_sec))")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    Spacer()
                    Text(formatTimestamp(api.data?.status?.ts))
                        .font(.caption2.monospacedDigit())
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var wsColor: Color {
        (api.data?.status?.ws_connected) == true ? .magiGreen : .magiGold
    }

    private var wsText: String {
        guard let ws = api.data?.status?.ws_connected else { return "连接中…" }
        return ws ? "魔法契约 · 已连接" : "契约已断 · 未连接"
    }

    // MARK: - 服务器信息
    private var serverCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("服务器状态", icon: "server.rack")
                HStack(spacing: 8) {
                    infoItem("模块", api.data?.status?.module ?? "--")
                    Divider().frame(height: 28)
                    infoItem("版本", api.data?.status?.version ?? "--")
                    Divider().frame(height: 28)
                    infoItem("服务器时间", api.data?.status?.time?.serverTimeShort ?? "--")
                }
            }
        }
    }

    // MARK: - 服务器系统（三环仪表卡片）
    private var systemCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    RadialGlow(color: .magiPurple, radius: 100)
                        .offset(x: 150, y: -60)
                    GradientSectionTitle(text: "服务器系统", icon: "desktopcomputer")
                }

                // 主机 / 系统 / 架构 / 开机时长 一行
                HStack(spacing: 8) {
                    infoItem("主机", api.data?.system?.hostname ?? "--")
                    Divider().frame(height: 28)
                    infoItem("系统", api.data?.system?.osName)
                    Divider().frame(height: 28)
                    infoItem("架构", api.data?.system?.arch ?? "--")
                }

                // 三环仪表：CPU / 内存 / 磁盘
                if let sys = api.data?.system {
                    HStack(spacing: 6) {
                        RingGauge(title: "CPU 使用",
                                  percent: sys.cpu_percent ?? 0,
                                  valueText: "\(sys.cpu_count ?? 0) 核",
                                  color: .magiSky, icon: "cpu")
                        RingGauge(title: "内存占用",
                                  percent: sys.mem_percent ?? 0,
                                  valueText: "\(gb(sys.mem_used_gb)) / \(gb(sys.mem_total_gb)) GB",
                                  color: .magiPink, icon: "memorychip")
                        RingGauge(title: "磁盘占用",
                                  percent: sys.disk_percent ?? 0,
                                  valueText: "\(gb(sys.disk_used_gb)) / \(gb(sys.disk_total_gb)) GB",
                                  color: .magiGreen, icon: "externaldrive")
                    }
                    .padding(.top, 2)

                    // 运行时长 + 主频 徽标行
                    HStack(spacing: 8) {
                        Label("运行 \(humanUptime(sys.uptime_sec))", systemImage: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(.magiGold)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Capsule().fill(Color.magiGold.opacity(0.12)))
                        if let f = sys.cpu_freq_mhz {
                            Label("\(Int(f)) MHz", systemImage: "speedometer")
                                .font(.caption2)
                                .foregroundColor(.magiSky)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Capsule().fill(Color.magiSky.opacity(0.12)))
                        }
                        Spacer()
                    }
                } else {
                    Text("暂无数据")
                        .font(.footnote)
                        .foregroundColor(.magiGray)
                }
            }
        }
    }

    private func gb(_ v: Double?) -> String {
        guard let v else { return "--" }
        return String(format: "%.1f", v)
    }

    // MARK: - 今日总览
    private var overviewCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("今日总览", icon: "calendar")
                if let date = api.data?.call_stats?.today_date {
                    Text(date)
                        .font(.caption)
                        .foregroundColor(.magiGray)
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                    if let o = api.data?.overview {
                        StatTile(title: "今日调用",
                                 value: "\(o.call_today ?? 0)",
                                 color: .magiPink, icon: "message.fill")
                        StatTile(title: "封号查询",
                                 value: "\(o.ban_query_today ?? 0)",
                                 color: .magiPurple, icon: "shield.lefthalf.filled")
                        StatTile(title: "今日事件",
                                 value: "\(o.events_today ?? 0)",
                                 color: .magiGold, icon: "bolt.fill")
                        StatTile(title: "网站库黑名单",
                                 value: "\(o.web_blacklist_count ?? 0)",
                                 color: .magiSky, icon: "nosign")
                    }
                }
                // 事件类型分解
                if let kinds = api.data?.overview?.events_today_by_kind, !kinds.isEmpty {
                    eventKindRow(kinds)
                }
                // 付费 token 状态
                if let ban = api.data?.ban {
                    HStack(spacing: 6) {
                        Image(systemName: ban.paid_enabled == true ? "checkmark.seal.fill" : "seal")
                            .foregroundColor(.magiGold)
                        Text(ban.paid_enabled == true ? "付费 Token 已启用" : "付费 Token 未启用")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        if let t = ban.paid_token {
                            Text("Token \(t)")
                                .font(.caption2.monospaced())
                                .foregroundColor(.magiGray)
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                }
            }
        }
    }

    // MARK: - 封号查询状态
    private var banCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("封号查询状态", icon: "shield.lefthalf.filled")
                if let ban = api.data?.ban {
                    HStack(spacing: 10) {
                        StatTile(title: "今日查询",
                                 value: "\(ban.query_count_today ?? 0)",
                                 color: .magiPurple, icon: "magnifyingglass")
                        StatTile(title: "主力 Token",
                                 value: ban.active_token ?? "未配置",
                                 color: .magiGold, icon: "key.fill")
                    }
                    HStack(spacing: 10) {
                        StatTile(title: "免费池总数",
                                 value: "\(ban.free_token_total ?? 0)",
                                 color: .magiSky, icon: "tray.full.fill")
                        StatTile(title: "已耗尽",
                                 value: "\(ban.free_exhausted_count ?? 0)",
                                 color: (ban.free_exhausted_count ?? 0) > 0 ? .magiGold : .magiGreen,
                                 icon: "flame.fill")
                    }
                } else {
                    Text("暂无数据")
                        .font(.footnote)
                        .foregroundColor(.magiGray)
                }
            }
        }
    }

    // MARK: - 封禁总览
    private var banStatsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("封禁记录总览", icon: "chart.pie.fill")
                if let bs = api.data?.ban_stats {
                    Text("累计封禁 \(bs.total ?? 0) 个账号")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.magiPink)
                    if !bs.sortedCat.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(bs.sortedCat) { item in
                                VStack(spacing: 2) {
                                    Text(catShort(item.name))
                                        .font(.caption)
                                        .foregroundColor(.magiGray)
                                    Text("\(item.count)")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
                            }
                        }
                    }
                    // 最近 7 天封禁趋势
                    if let byDate = bs.by_date {
                        recentBanTrend(byDate)
                    }
                } else {
                    Text("暂无数据")
                        .font(.footnote)
                        .foregroundColor(.magiGray)
                }
            }
        }
    }

    private func recentBanTrend(_ byDate: [String: Int]) -> some View {
        let sorted = byDate.sorted { $0.key < $1.key }.suffix(7).map { PVRow(name: $0.key, count: $0.value) }
        let maxV = max(1, sorted.map(\.count).max() ?? 1)
        return VStack(alignment: .leading, spacing: 8) {
            Text("近 7 天封禁")
                .font(.footnote)
                .foregroundColor(.magiGray)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(sorted) { item in
                    VStack(spacing: 4) {
                        Text("\(item.count)")
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(.white.opacity(0.85))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(colors: [.magiPinkDeep, .magiPink],
                                               startPoint: .bottom, endPoint: .top)
                            )
                            .frame(height: max(6, 60 * CGFloat(item.count) / CGFloat(maxV)))
                        Text(String(item.name.suffix(5)))
                            .font(.system(size: 9))
                            .foregroundColor(.magiGray)
                    }
                }
            }
        }
    }

    private func infoItem(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.magiGray)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        GradientSectionTitle(text: title, icon: icon)
    }

    private func eventKindRow(_ kinds: [String: Int]) -> some View {
        let rows = kinds.sorted { $0.value > $1.value }.map { PVRow(name: $0.key, count: $0.value) }
        return HStack(spacing: 8) {
            ForEach(rows) { item in
                let style = EventKindStyle.from(item.name)
                HStack(spacing: 4) {
                    Image(systemName: style.systemImage)
                        .font(.caption2)
                    Text("\(item.count)")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(style.color.opacity(0.25)))
            }
        }
    }

    private func errorCard(_ msg: String) -> some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.magiGold)
                Text(msg)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                Button {
                    Task { await api.refresh() }
                } label: {
                    Text("重新连接")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.magiPink))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(connColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: connColor.opacity(0.8), radius: 4)
                Text(connText)
                    .font(.caption)
                    .foregroundColor(.magiGray)
                if let t = api.lastUpdated {
                    Text("· 最后更新 \(t, format: .dateTime.hour().minute().second())")
                        .font(.caption2)
                        .foregroundColor(.magiGray)
                }
            }
            Button {
                Task { await api.refresh() }
            } label: {
                Label(api.isLoading ? "刷新中…" : "刷新",
                      systemImage: api.isLoading ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.magiPink)
            }
            .disabled(api.isLoading)
        }
        .padding(.top, 4)
    }

    private var connColor: Color {
        switch api.connectionState {
        case .connected: return .magiGreen
        case .connecting: return .magiGold
        case .failed: return .magiGold
        case .disconnected: return .magiGray
        }
    }

    private var connText: String {
        api.connectionState.rawValue
    }
}

private func catShort(_ cat: String) -> String {
    switch cat {
    case "1d": return "1天"
    case "30d": return "30天"
    case "3y": return "3年"
    case "other": return "其他"
    default: return cat
    }
}