import Foundation
import SwiftUI

// MARK: - 统一响应外壳
struct APIResponse: Decodable {
    let ok: Bool
    let data: BotInfo?
    let error: String?
    let cached: Bool?
}

// MARK: - 顶层聚合数据
struct BotInfo: Decodable {
    let status: StatusInfo?
    let overview: OverviewInfo?
    let call_stats: CallStatsInfo?
    let ban: BanInfo?
    let ban_stats: BanStatsInfo?
    let events: EventsInfo?
    let groups: GroupsInfo?
    let blacklist: BlacklistInfo?
    let ipblacklist: IPBlacklistInfo?
    let invites: InvitesInfo?
    let system: SystemInfo?
}

// MARK: - 进程状态
struct StatusInfo: Decodable {
    let module: String?
    let time: String?
    let ts: Double?
    let uptime_sec: Double?
    let ws_connected: Bool?
    let version: String?
}

// MARK: - 今日总览
struct OverviewInfo: Decodable {
    let time: String?
    let call_today: Int?
    let ban_query_today: Int?
    let paid_enabled: Bool?
    let events_today: Int?
    let events_today_by_kind: [String: Int]?
    let web_blacklist_count: Int?
    let ip_blacklisted: Int?
}

/// 排行行（避免元组 KeyPath 不可用）
struct PVRow: Identifiable {
    let name: String
    let count: Int
    var id: String { name }
}

// MARK: - 调用统计
struct CallStatsInfo: Decodable {
    let today_count: Int?
    let today_date: String?
    let type_totals: [String: Int]?
    let group_totals: [String: Int]?
    let trend_7d: [TrendItem]?

    /// 按调用量降序排列的指令类型
    var sortedTypes: [PVRow] {
        (type_totals ?? [:]).sorted { $0.value > $1.value }
            .map { PVRow(name: typeDisplayName($0.key), count: $0.value) }
    }

    /// 按调用量降序排列的群
    var sortedGroups: [PVRow] {
        (group_totals ?? [:]).sorted { $0.value > $1.value }
            .map { PVRow(name: $0.key, count: $0.value) }
    }
}

struct TrendItem: Decodable {
    let date: String?
    let count: Int?
}

// MARK: - 服务器系统信息
struct SystemInfo: Decodable {
    let hostname: String?
    let system: String?
    let release: String?
    let version: String?
    let arch: String?
    let uptime_sec: Double?
    let cpu_percent: Double?
    let cpu_count: Int?
    let cpu_freq_mhz: Double?
    let mem_total_gb: Double?
    let mem_used_gb: Double?
    let mem_percent: Double?
    let disk_total_gb: Double?
    let disk_used_gb: Double?
    let disk_percent: Double?

    var osName: String {
        guard let sys = system else { return "--" }
        switch sys {
        case "Windows": return "Windows \(release ?? "")"
        case "Linux": return "Linux \(release ?? "")"
        case "Darwin": return "macOS \(release ?? "")"
        default: return "\(sys) \(release ?? "")"
        }
    }
}

// MARK: - 封号查询状态
struct BanInfo: Decodable {
    let date: String?
    let active_token: String?
    let query_count_today: Int?
    let used_tokens: [String]?
    let paid_enabled: Bool?
    let paid_token_set: Bool?
    let paid_token: String?
    let free_token_total: Int?
    let free_exhausted_count: Int?
    let free_exhausted: [String]?
}

// MARK: - 封禁记录汇总（服务端已精简）
struct BanStatsInfo: Decodable {
    let total: Int?
    let by_date: [String: Int]?
    let by_cat: [String: Int]?

    var sortedCat: [PVRow] {
        (by_cat ?? [:]).sorted { $0.value > $1.value }
            .map { PVRow(name: $0.key, count: $0.value) }
    }
}

// MARK: - 事件流
struct EventsInfo: Decodable {
    let count: Int?
    let events: [EventItem]?
}

struct EventItem: Decodable, Hashable, Identifiable {
    let ts: Double?
    let kind: String?
    let qq: String?
    let group_id: Int64?
    let user_id: Int64?
    let operator_id: Int64?
    let action: String?
    let ordinal: Int?
    let tier: Int?
    let mute_sec: Int?
    let warns: Int?

    var id: String {
        "\(ts ?? 0)-\(kind ?? "")-\(qq ?? "")-\(user_id ?? 0)"
    }
}

// MARK: - 生效群
struct GroupsInfo: Decodable {
    let enabled_groups: [Int64]?
    let groups: [GroupItem]?
    let scope_ids: [Int64]?
}

struct GroupItem: Decodable {
    let group_id: Int64?
    let call_total: Int?
    let call_today: Int?
    let keyword_recall_groups: [Int64]?
    let fuzzy_groups: [Int64]?
}

// MARK: - 黑名单
struct BlacklistInfo: Decodable {
    let web_blacklist_count: Int?
    let web_blacklist_sample: [String]?
    let group_blacklist_groups: Int?
    let group_blacklist_members: Int?
    let keyword_fuzzy_mute_count: Int?
}

// MARK: - IP 黑名单
struct IPBlacklistInfo: Decodable {
    let count: Int?
    let ips: [String]?
}

// MARK: - 邀请统计
struct InvitesInfo: Decodable {
    let count: Int?
    let recent: [InviteItem]?
}

struct InviteItem: Decodable {
    let group_id: String?
    let inviter: String?
    let invitee: String?
    let time: Double?
}

// MARK: - 展示辅助

enum EventKindStyle {
    case banBlock, banQuery, punish, join, leave, other

    static func from(_ kind: String?) -> EventKindStyle {
        switch kind {
        case "ban_block": return .banBlock
        case "ban_query": return .banQuery
        case "punish": return .punish
        case "member_join": return .join
        case "member_leave": return .leave
        default: return .other
        }
    }

    var label: String {
        switch self {
        case .banBlock: return "骗子拦截"
        case .banQuery: return "封号查询"
        case .punish: return "关键词处罚"
        case .join: return "成员入群"
        case .leave: return "成员退群"
        case .other: return "未知事件"
        }
    }

    var systemImage: String {
        switch self {
        case .banBlock: return "shield.lefthalf.filled"
        case .banQuery: return "magnifyingglass"
        case .punish: return "exclamationmark.triangle"
        case .join: return "sparkles"
        case .leave: return "person.crop.circle.badge.minus"
        case .other: return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .banBlock: return .magiPink
        case .banQuery: return .magiSky
        case .punish: return .magiGold
        case .join: return .magiGreen
        case .leave: return .magiPurple
        case .other: return .magiGray
        }
    }
}

extension String {
    /// "2026-08-29 02:41:11" -> 只留时间 HH:mm
    var serverTimeShort: String {
        guard count >= 16 else { return self }
        let idx = index(startIndex, offsetBy: 11)
        return String(suffix(from: idx))
    }

    var serverDateShort: String {
        guard count >= 10 else { return self }
        return String(prefix(10))
    }
}

func humanUptime(_ seconds: Double?) -> String {
    guard let s = seconds, s > 0 else { return "--" }
    let total = Int(s)
    let d = total / 86400
    let h = (total % 86400) / 3600
    let m = (total % 3600) / 60
    if d > 0 { return "\(d)天 \(h)小时" }
    if h > 0 { return "\(h)小时 \(m)分" }
    return "\(m)分钟"
}

func formatTimestamp(_ ts: Double?) -> String {
    guard let t = ts else { return "--" }
    let date = Date(timeIntervalSince1970: t)
    let fmt = DateFormatter()
    fmt.dateFormat = "MM-dd HH:mm:ss"
    return fmt.string(from: date)
}

/// 指令类型英文 -> 中文
func typeDisplayName(_ key: String) -> String {
    switch key {
    case "ban": return "封号查询"
    case "query": return "战绩查询"
    case "lolrecord": return "战绩记录"
    case "heji": return "合集查询"
    case "aram": return "极地大乱斗"
    case "opgg": return "OPGG 查询"
    case "group_blacklist": return "群黑名单"
    default: return key
    }
}