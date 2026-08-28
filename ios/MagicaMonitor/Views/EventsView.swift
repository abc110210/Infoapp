import SwiftUI

struct EventsView: View {
    @EnvironmentObject private var api: APIService

    private var events: [EventItem] {
        api.data?.events?.events ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StardustBackground(imageName: "page_bg")
                ScrollView {
                    VStack(spacing: 12) {
                        header
                        if api.data != nil && events.isEmpty {
                            EmptyState(icon: "bell.slash", text: "近期没有新事件")
                        } else {
                            ForEach(events, id: \.self) { event in
                                EventRow(event: event)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .refreshable { await api.refresh() }
            }
            .navigationTitle("实时事件")
        }
    }

    private var header: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("事件流")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("最新在前 · 最多保留 50 条")
                        .font(.caption)
                        .foregroundColor(.magiGray)
                }
                Spacer()
                if let count = api.data?.events?.count {
                    Text("\(count)")
                        .font(.title.weight(.heavy))
                        .foregroundColor(.magiPink)
                }
            }
        }
    }
}

private struct EventRow: View {
    let event: EventItem

    private var style: EventKindStyle {
        EventKindStyle.from(event.kind)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(style.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: style.systemImage)
                    .font(.system(size: 16))
                    .foregroundColor(style.color)
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(style.label)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(formatTimestamp(event.ts))
                        .font(.caption2.monospacedDigit())
                        .foregroundColor(.magiGray)
                }
                details
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(colors: [Color.white.opacity(0.09), Color.white.opacity(0.02)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [style.color.opacity(0.5), Color.magiPurple.opacity(0.3), Color.white.opacity(0.08)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
                .shadow(color: style.color.opacity(0.12), radius: 10, x: 0, y: 3)
        )
    }

    @ViewBuilder
    private var details: some View {
        switch style {
        case .banBlock:
            chipRow([KV("QQ", event.qq ?? "--"), KV("群", gid(event.group_id))])
        case .banQuery:
            chipRow([KV("QQ", event.qq ?? "--"), KV("群", gid(event.group_id))])
        case .punish:
            chipRow([
                KV("群", gid(event.group_id)),
                KV("成员", event.user_id.map { "\($0)" } ?? "--"),
                KV("动作", event.action ?? "--"),
            ], extra: { punishExtra })
        case .join:
            chipRow([
                KV("群", gid(event.group_id)),
                KV("新成员", event.user_id.map { "\($0)" } ?? "--"),
                KV("邀请人", event.operator_id.map { "\($0)" } ?? "无"),
            ])
        case .leave:
            chipRow([KV("群", gid(event.group_id)), KV("成员", event.user_id.map { "\($0)" } ?? "--")])
        case .other:
            chipRow([KV("kind", event.kind ?? "?")])
        }
    }

    @ViewBuilder
    private var punishExtra: some View {
        if let ordinal = event.ordinal {
            Text("第 \(ordinal) 次处罚")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.magiGold.opacity(0.2)))
        }
        if let tier = event.tier {
            Text("档位 \(tier)")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.magiGold.opacity(0.2)))
        }
        if let sec = event.mute_sec {
            Text("禁言 \(sec) 秒")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.magiPink.opacity(0.2)))
        }
        if let w = event.warns {
            Text("警告 \(w) 次")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.magiPurple.opacity(0.2)))
        }
    }

    private func chipRow<Extra: View>(_ items: [KV], @ViewBuilder extra: () -> Extra = { EmptyView() }) -> some View {
        HStack(spacing: 6) {
            ForEach(items) { item in
                Text("\(item.key) \(item.value)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }
            extra()
        }
    }

    private func gid(_ id: Int64?) -> String {
        id.map { "\($0)" } ?? "私聊"
    }
}

/// 键值 chip
private struct KV: Identifiable {
    let key: String
    let value: String
    init(_ key: String, _ value: String) {
        self.key = key
        self.value = value
    }
    var id: String { key }
}

// MARK: - Identifiable/Equatable for ForEach
extension EventItem: Identifiable, Hashable {
    var id: String {
        "\(ts ?? 0)-\(kind ?? "")-\(qq ?? "")-\(user_id ?? 0)"
    }
}