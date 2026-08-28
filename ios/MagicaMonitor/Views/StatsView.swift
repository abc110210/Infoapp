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
                                rankCard(title: "群排行", icon: "person.3.fill",
                                         rows: groups, color: .magiSky)
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
                            x: .value("日期", item.date ?? ""),
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
    private func rankCard(title: String, icon: String, rows: [PVRow], color: Color) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title, icon: icon)
                let maxV = rows.map(\.count).max() ?? 1
                ForEach(Array(rows.prefix(10))) { row in
                    RankRow(name: row.name,
                            value: row.count,
                            maxValue: maxV,
                            color: color)
                }
            }
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        GradientSectionTitle(text: title, icon: icon)
    }

    private func errorCard(_ msg: String) -> some View {
        EmptyState(icon: "exclamationmark.triangle", text: msg)
    }
}