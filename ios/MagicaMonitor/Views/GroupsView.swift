import SwiftUI

struct GroupsView: View {
    @EnvironmentObject private var api: APIService

    var body: some View {
        NavigationStack {
            ZStack {
                StardustBackground(imageName: "page_bg")
                ScrollView {
                    VStack(spacing: 16) {
                        if api.data != nil {
                            if let groups = api.data?.groups?.groups, !groups.isEmpty {
                                groupCard(groups)
                            }
                            if let bl = api.data?.blacklist {
                                blacklistCard(bl)
                            }
                            if let ip = api.data?.ipblacklist {
                                ipCard(ip)
                            }
                            if let inv = api.data?.invites {
                                inviteCard(inv)
                            }
                        } else if let err = api.errorMessage {
                            EmptyState(icon: "exclamationmark.triangle", text: err)
                        } else {
                            ProgressView("读取中…")
                                .tint(.magiPink)
                                .padding(.top, 60)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .refreshable { await api.refresh() }
            }
            .navigationTitle("群与安全")
        }
    }

    // MARK: - 生效群
    private func groupCard(_ groups: [GroupItem]) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("生效群 (\(groups.count))", icon: "person.3.fill")
                let sorted = groups.sorted { ($0.call_total ?? 0) > ($1.call_total ?? 0) }
                let maxV = sorted.first?.call_total ?? 1
                ForEach(sorted, id: \.group_id) { g in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            // 生效群魔法图标
                            MagicIcon(image: "ic_group", size: 26)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(g.displayName)
                                    .font(MagiFont.body(15))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text("群号 \(g.group_id.map { "\($0)" } ?? "--")")
                                    .font(MagiFont.num(10))
                                    .foregroundColor(.magiGray)
                                    .lineLimit(1)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("今日 \(g.call_today ?? 0)")
                                    .font(MagiFont.card(12))
                                    .foregroundColor(.magiPink)
                                Text("累计 \(g.call_total ?? 0)")
                                    .font(MagiFont.num(10))
                                    .foregroundColor(.magiGray)
                            }
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.08))
                                Capsule()
                                    .fill(LinearGradient(colors: [.magiPinkDeep, .magiPink],
                                                         startPoint: .leading, endPoint: .trailing))
                                    .frame(width: max(8, geo.size.width * CGFloat(g.call_total ?? 0) / CGFloat(max(1, maxV))))
                            }
                        }
                        .frame(height: 7)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }

    // MARK: - 黑名单
    private func blacklistCard(_ bl: BlacklistInfo) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("黑名单", icon: "nosign")
                HStack(spacing: 10) {
                    StatTile(title: "网站库号码",
                             value: "\(bl.web_blacklist_count ?? 0)",
                             color: .magiSky, icon: "doc.text.fill")
                    StatTile(title: "群黑名单",
                             value: "\(bl.group_blacklist_groups ?? 0) 群 / \(bl.group_blacklist_members ?? 0) 人",
                             color: .magiGold, icon: "person.2.slash.fill")
                }
                StatTile(title: "关键词惯犯禁言记录",
                         value: "\(bl.keyword_fuzzy_mute_count ?? 0)",
                         color: .magiPurple, icon: "bell.badge.fill")
                if let sample = bl.web_blacklist_sample, !sample.isEmpty {
                    Text("网站骗子库样本")
                        .font(.caption)
                        .foregroundColor(.magiGray)
                    FlowChips(items: Array(sample.prefix(10)))
                }
            }
        }
    }

    // MARK: - IP 黑名单
    private func ipCard(_ ip: IPBlacklistInfo) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("API IP 黑名单", icon: "network")
                Text("已拉黑 \(ip.count ?? 0) 个 IP")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.magiPink)
                if let ips = ip.ips, !ips.isEmpty {
                    FlowChips(items: ips.map { "IP \($0)" })
                }
            }
        }
    }

    // MARK: - 群邀请统计（v3：按群统计邀请人数）
    private func inviteCard(_ inv: InvitesInfo) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("群邀请统计", icon: "person.crop.circle.badge.plus")
                Text("累计邀请 \(inv.total ?? 0) 人")
                    .font(MagiFont.card(16))
                    .foregroundColor(.magiGreen)
                let rows = inv.sortedGroups
                let maxV = max(1, rows.map(\.count).max() ?? 1)
                ForEach(rows) { row in
                    let name = groupName(for: row.name) ?? "群 \(row.name)"
                    VStack(spacing: 5) {
                        HStack(spacing: 10) {
                            // 群邀请魔法图标
                            MagicIcon(image: "ic_invite", size: 22)
                            Text(name)
                                .font(MagiFont.body(13))
                                .foregroundColor(.white.opacity(0.92))
                                .lineLimit(1)
                            Spacer()
                            Text("\(row.count) 人")
                                .font(MagiFont.num(12))
                                .foregroundColor(.magiGreen)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.08))
                                Capsule()
                                    .fill(LinearGradient(colors: [Color.magiGreen.opacity(0.6), Color.magiGreen],
                                                         startPoint: .leading, endPoint: .trailing))
                                    .frame(width: max(6, geo.size.width * CGFloat(row.count) / CGFloat(maxV)))
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    /// 群号 -> 群名
    private func groupName(for id: String) -> String? {
        api.data?.groups?.groups?.first(where: { "\($0.group_id ?? 0)" == id })?.group_name
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        GradientSectionTitle(text: title, icon: icon)
    }
}

// MARK: - 流式 chips
struct FlowChips: View {
    let items: [String]

    var body: some View {
        var width: CGFloat = 0
        var rows: [[String]] = [[]]
        for item in items {
            let len = CGFloat(item.count) * 9 + 24
            if width + len > UIScreen.main.bounds.width - 100 {
                rows.append([item])
                width = len
            } else {
                rows[rows.count - 1].append(item)
                width += len + 8
            }
        }
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { item in
                        Text(item)
                            .font(.caption2.monospaced())
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                }
            }
        }
    }
}