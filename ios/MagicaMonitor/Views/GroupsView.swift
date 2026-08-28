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
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("生效群 (\(groups.count))", icon: "person.3.fill")
                let sorted = groups.sorted { ($0.call_total ?? 0) > ($1.call_total ?? 0) }
                let maxV = sorted.first?.call_total ?? 1
                ForEach(sorted, id: \.group_id) { g in
                    VStack(spacing: 6) {
                        HStack {
                            Text("群 \(g.group_id.map { "\($0)" } ?? "--")")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("今日 \(g.call_today ?? 0)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.magiPink)
                            Text("累计 \(g.call_total ?? 0)")
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.magiGray)
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
                        .frame(height: 6)
                    }
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
                    Text("样本号码")
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

    // MARK: - 邀请统计
    private func inviteCard(_ inv: InvitesInfo) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("邀请统计", icon: "person.crop.circle.badge.plus")
                Text("累计邀请 \(inv.count ?? 0) 人")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.magiGreen)
                if let recent = inv.recent, !recent.isEmpty {
                    ForEach(recent, id: \.time) { item in
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.magiGreen)
                            Text("\(item.inviter ?? "--") 邀请 \(item.invitee ?? "--")")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(1)
                            Spacer()
                            Text(formatTimestamp(item.time))
                                .font(.caption2.monospacedDigit())
                                .foregroundColor(.magiGray)
                        }
                        .padding(.vertical, 4)
                        Divider().overlay(Color.white.opacity(0.06))
                    }
                }
            }
        }
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