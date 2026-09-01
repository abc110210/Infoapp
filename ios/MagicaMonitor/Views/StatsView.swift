import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject private var api: APIService

    var body: some View {
        NavigationStack {
            ZStack {
                StardustBackground(imageName: "page_bg")
                ScrollView {
                    VStack(spacing: 16) {
                        if api.data != nil {
                            todayCard
                            trendCard
                            if let types = api.data?.call_stats?.sortedTypes, !types.isEmpty {
                                rankCard(title: "指令类型排行", icon: "square.grid.2x2.fill",
                                         rows: types, color: .magiPurple)
                            }
                            if let groups = api.data?.call_stats?.sortedGroups, !groups.isEmpty {
                                // 群排行：把群号显示成群名（有名字用名字）
                                let named = groups.map { row in
                                    PVRow(name: groupName(for: row.name) ?? row.name, count: row.count)
                                }
                                rankCard(title: "群排行", icon: "person.3.fill",
                                         rows: named, color: .magiSky, image: "ic_rank")
                            }
                            if let sp = api.data?.speech {
                                speechCard(sp)
                            }
                        } else if let err = api.errorMessage {
                            errorCard(err)
                        } else {
                            ProgressView("计算中…")
                                .tint(.magiPink)
                                .padding(.top, 60)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .refreshable { await api.refresh() }
            }
            .navigationTitle("调用统计")
        }
    }

    // MARK: - 今日
    private var todayCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    sectionHeader("今日调用", icon: "flame.fill")
                    Spacer()
                    if let d = api.data?.call_stats?.today_date {
                        Pill(text: d, color: .magiPink)
                    }
                }
                HStack(spacing: 10) {
                    StatTile(title: "今日总数",
                             value: "\(api.data?.call_stats?.today_count ?? 0)",
                             color: .magiPink, icon: "bolt.fill")
                    if let o = api.data?.overview {
                        StatTile(title: "封号查询",
                                 value: "\(o.ban_query_today ?? 0)",
                                 color: .magiPurple, icon: "shield.lefthalf.filled")
                    }
                }
            }
        }
    }

    // MARK: - 7 天趋势
    private var trendCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("近 7 天趋势", icon: "chart.xyaxis.line")
                if let trend = api.data?.call_stats?.trend_7d, !trend.isEmpty {
                    Chart(trend, id: \.date) { item in
                        BarMark(
                            x: .value("日期", monthDay(item.date)),
                            y: .value("调用", item.count ?? 0)
                        )
                        .foregroundStyle(
                            LinearGradient(colors: [.magiPinkDeep, .magiPink],
                                           startPoint: .bottom, endPoint: .top)
                        )
                        .cornerRadius(6)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 7)) { _ in
                            AxisValueLabel()
                                .font(.system(size: 9))
                                .foregroundStyle(Color.magiGray)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                            AxisValueLabel()
                                .font(.system(size: 9))
                                .foregroundStyle(Color.magiGray)
                        }
                    }
                    .frame(height: 180)
                } else {
                    Text("暂无趋势数据")
                        .font(.footnote)
                        .foregroundColor(.magiGray)
                }
            }
        }
    }

    // MARK: - 排行卡
    private func rankCard(title: String, icon: String, rows: [PVRow], color: Color, image: String? = nil) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title, icon: icon)
                let maxV = rows.map(\.count).max() ?? 1
                ForEach(Array(rows.prefix(10))) { row in
                    RankRow(name: row.name,
                            value: row.count,
                            maxValue: maxV,
                            color: color,
                            image: image)
                }
            }
        }
    }

    // MARK: - 发言排行（仅星野开黑群二级排行，带头像）
    private func speechCard(_ sp: SpeechInfo) -> some View {
        // 目标群固定为星野开黑群（1058823513）；找不到则取 30 日消息最多的群兜底
        guard let group = sp.groups?["1058823513"] ?? sp.sortedGroups.first?.1,
              let groupID = sp.groups?["1058823513"] != nil ? "1058823513" : sp.sortedGroups.first?.0 else {
            return AnyView(EmptyView())
        }
        let dim = group.month30 ?? group.today
        let targetName = api.data?.groups?.groups?.first(where: { "\($0.group_id ?? 0)" == groupID })?.group_name ?? "星野开黑群"
        let name = (targetName.isEmpty ? "星野开黑群" : targetName)
        let tops = Array((dim?.topList ?? []).prefix(5))
        return AnyView(
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("发言排行 · \(name)", icon: "bubble.left.and.bubble.right.fill")
                    HStack(spacing: 8) {
                        Pill(text: "今日 \(group.today?.messages ?? 0)", color: .magiSky)
                        Pill(text: "近30日 \(group.month30?.messages ?? 0)", color: .magiPink)
                        if let members = group.month30?.members {
                            Pill(text: "成员 \(members)", color: .magiPurple)
                        }
                    }
                    ForEach(Array(tops.enumerated()), id: \.offset) { idx, row in
                        rankRow(idx: idx, row: row)
                    }
                }
            }
        )
    }

    private func rankRow(idx: Int, row: SpeechTop) -> some View {
        HStack(spacing: 10) {
            Text("\(idx + 1)")
                .font(MagiFont.num(14))
                .foregroundColor(idx < 3 ? .magiGold : .magiGray)
                .frame(width: 20)
            AsyncImage(url: qqAvatarURL(row.user_id)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    Circle().fill(Color.white.opacity(0.15))
                }
            }
            .frame(width: 34, height: 34)
            .clipShape(Circle())
            Text(row.user_id ?? "--")
                .font(MagiFont.num(13))
                .foregroundColor(.white)
            Spacer()
            Text("\(row.count ?? 0) 条")
                .font(MagiFont.num(13))
                .foregroundColor(.magiPink)
        }
        .padding(.vertical, 2)
    }

    /// QQ 头像地址（q1.qlogo.cn）
    private func qqAvatarURL(_ qq: String?) -> URL? {
        guard let qq, !qq.isEmpty else { return nil }
        return URL(string: "https://q1.qlogo.cn/g?b=qq&nk=\(qq)&s=640")
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        GradientSectionTitle(text: title, icon: icon)
    }

    private func errorCard(_ msg: String) -> some View {
        EmptyState(icon: "exclamationmark.triangle", text: msg)
    }

    /// 群号 -> 群名（用 groups 段的 group_name）
    private func groupName(for id: String) -> String? {
        api.data?.groups?.groups?.first(where: { "\($0.group_id ?? 0)" == id })?.group_name
    }

    /// 日期 "YYYY-MM-DD" -> "MM-dd"（近 7 天趋势标签不带年份）
    private func monthDay(_ date: String?) -> String {
        guard let date, date.count >= 10 else { return date ?? "" }
        return String(date.suffix(5))
    }
}