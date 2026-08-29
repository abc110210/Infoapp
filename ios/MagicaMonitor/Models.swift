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
    let groups: GroupsInfo?
    let blacklist: BlacklistInfo?
    let ipblacklist: IPBlacklistInfo?
    let invites: InvitesInfo?
    let console: ConsoleInfo?
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

    /// 按调用量降序排列的指令类型（排除内部模块 group_blacklist）
    var sortedTypes: [PVRow] {
        (type_totals ?? [:]).filter { $0.key != "group_blacklist" }
            .sorted { $0.value > $1.value }
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

// MARK: - 控制台（带 ANSI 颜色的日志，来自上游 /info/console）
struct ConsoleInfo: Decodable {
    let count: Int?
    let lines: [String]?
    let file: String?
    let level: String?
    let total_lines: Int?
}

// MARK: - 生效群
struct GroupsInfo: Decodable {
    let enabled_groups: [Int64]?
    let groups: [GroupItem]?
    let scope_ids: [Int64]?
}

struct GroupItem: Decodable {
    let group_id: Int64?
    let group_name: String?
    let call_total: Int?
    let call_today: Int?
    let keyword_recall_groups: [Int64]?
    let fuzzy_groups: [Int64]?

    /// 显示名：优先群名，无则群号
    var displayName: String {
        if let n = group_name, !n.isEmpty { return n }
        return group_id.map { "\($0)" } ?? "--"
    }
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

// MARK: - 群邀请统计（v3 简化：按群统计人数）
struct InvitesInfo: Decodable {
    let total: Int?
    let per_group: [String: Int]?

    var sortedGroups: [PVRow] {
        (per_group ?? [:]).sorted { $0.value > $1.value }
            .map { PVRow(name: $0.key, count: $0.value) }
    }
}

// MARK: - 展示辅助

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

// MARK: - ANSI 颜色解析（控制台日志）
struct ANSISegment {
    let text: String
    let color: Color
    let bold: Bool
}

/// 把带 ANSI 24-bit 颜色的控制台行解析成带色文本段。
/// 支持 `\x1b[38;2;R;G;Bm` 前景色、`\x1b[1m` 加粗、`\x1b[0m` 复位。
func parseANSI(_ raw: String) -> [ANSISegment] {
    let esc = "\u{1B}["
    var segments: [ANSISegment] = []
    var current: Color = .white.opacity(0.85)
    var currentBold = false
    var buf = ""
    var i = raw.startIndex
    let end = raw.endIndex

    func flush() {
        if !buf.isEmpty {
            segments.append(ANSISegment(text: buf, color: current, bold: currentBold))
            buf = ""
        }
    }

    while i < end {
        // 找 ESC 序列
        if raw[i] == "\u{1B}" {
            let rest = raw[i...]
            guard rest.hasPrefix("\u{1B}[") else {
                buf.append(raw[i]); i = raw.index(after: i); continue
            }
            // 提取到 m 为止
            let afterEsc = rest.dropFirst(2)
            if let mIdx = afterEsc.firstIndex(of: "m") {
                let codeStr = String(afterEsc[..<mIdx])
                flush()
                applyANSI(codeStr, current: &current, bold: &currentBold)
                i = afterEsc.index(after: mIdx)
                continue
            }
        }
        buf.append(raw[i])
        i = raw.index(after: i)
    }
    flush()
    return segments
}

private func applyANSI(_ codeStr: String, current: inout Color, bold: inout Bool) {
    let parts = codeStr.split(separator: ";").compactMap { Int($0) }
    if parts.isEmpty {
        bold = false
        current = .white.opacity(0.85)
        return
    }
    // 查找 38;2;R;G;B 序列
    var idx = 0
    while idx < parts.count {
        if parts[idx] == 1 { bold = true; idx += 1; continue }
        if parts[idx] == 22 { bold = false; idx += 1; continue }
        if parts[idx] == 0 { bold = false; current = .white.opacity(0.85); idx += 1; continue }
        if parts[idx] == 38, idx + 3 < parts.count, parts[idx + 1] == 2 {
            // 24-bit RGB 前景色
            let r = min(255, max(0, parts[idx + 2]))
            let g = min(255, max(0, parts[idx + 3]))
            let b = min(255, max(0, parts[idx + 4]))
            current = Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
            idx += 5
            continue
        }
        idx += 1
    }
}

/// 把解析出的片段拼成 SwiftUI Text（保留各段颜色/加粗）
func ansiText(_ raw: String, font: Font = .system(size: 11, weight: .regular, design: .monospaced)) -> Text {
    let segs = parseANSI(raw)
    if segs.isEmpty {
        return Text(raw).font(font)
    }
    var result = Text("")
    for seg in segs {
        var t = Text(seg.text).font(font)
        if seg.bold { t = t.bold() }
        t = t.foregroundColor(seg.color)
        result = result + t
    }
    return result
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