import SwiftUI

/// 控制台页：实时显示服务器带 ANSI 颜色的日志（远程控制台）
struct ConsoleView: View {
    @EnvironmentObject private var api: APIService
    @State private var autoRefresh = true
    @State private var filterText = ""
    @State private var timer: Timer?
    @FocusState private var filterFocused: Bool

    private var lines: [String] {
        guard let ls = api.console?.lines, !ls.isEmpty else { return [] }
        if filterText.isEmpty { return ls }
        return ls.filter { $0.localizedCaseInsensitiveContains(filterText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                    StardustBackground(imageName: "page_bg")

                    VStack(spacing: 0) {
                        headerBar

                        if api.console?.lines?.isEmpty != false && api.console == nil {
                            EmptyState(icon: "terminal", text: "等待控制台数据…")
                                .frame(maxHeight: .infinity)
                        } else if lines.isEmpty {
                            EmptyState(icon: "doc.text.magnifyingglass",
                                       text: filterText.isEmpty
                                           ? "控制台暂无日志（请确认服务器 chaxun.log 有内容）"
                                           : "没有匹配的日志行：\(filterText)")
                                .frame(maxHeight: .infinity)
                        } else {
                            consoleBody
                        }
                    }
                }
                // 点击输入框以外的空白处收起键盘（TextField 内部点击不会受影响）
                .contentShape(Rectangle())
                .onTapGesture {
                    filterFocused = false
                }
            .navigationTitle("远程控制台")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        api.refreshConsole()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.magiPink)
                    }
                }
            }
            .task {
                api.refreshConsole()
            }
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
            .onChange(of: autoRefresh) { newValue in
                guard newValue else { return }
                startTimer()
            }
        }
    }

    // MARK: - 顶部信息条
    private var headerBar: some View {
        GlassCard(padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    // 自动刷新开关
                    Toggle(isOn: $autoRefresh) {
                        Label("实时", systemImage: autoRefresh ? "antenna.radiowaves.left.and.right" : "pause.circle")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(autoRefresh ? .magiGreen : .magiGold)
                    }
                    .toggleStyle(.switch)
                    .labelsHidden()

                    Label(autoRefresh ? "实时刷新中" : "已暂停", systemImage: "dot.radiowaves.left.and.right")
                        .font(.caption)
                        .foregroundColor(autoRefresh ? .magiGreen : .magiGray)

                    Spacer()

                    if let lv = api.console?.level {
                        Pill(text: lv.uppercased(), color: .magiPurple)
                    }
                    if let c = api.console?.count {
                        Pill(text: "\(c) 行", color: .magiSky)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption2)
                        .foregroundColor(.magiGray)
                    TextField("过滤关键词…", text: $filterText)
                        .font(.caption)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .focused($filterFocused)
                    if !filterText.isEmpty {
                        Button {
                            filterText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.magiGray)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))

                if let file = api.console?.file, !file.isEmpty {
                    Text(file)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.magiGray)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if let t = api.consoleUpdatedAt {
                    Text("更新于 \(t, format: .dateTime.hour().minute().second())")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.magiGray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // MARK: - 日志体
    private var consoleBody: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    // 最新在上：lines 是倒序尾部，直接顺序显示就是最新优先
                    ForEach(Array(lines.enumerated()), id: \.offset) { idx, line in
                        consoleRow(line)
                            .id(idx)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.top, 2)
            // 控制台窗口高度约半屏（不再撑满到底部）
            .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
        }
    }

    private func consoleRow(_ line: String) -> some View {
        let color = levelColor(from: line)
        return Text(plain(line))
            .font(.system(size: 13, weight: .regular, design: .monospaced))
            .foregroundColor(color)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
    }

    /// 去掉行内 ANSI 码，保留纯文本
    private func plain(_ line: String) -> String {
        guard line.contains("\u{1B}[") else { return line }
        var out = ""
        var i = line.startIndex
        let end = line.endIndex
        while i < end {
            if line[i] == "\u{1B}" {
                let rest = line[i...]
                if rest.hasPrefix("\u{1B}["), let m = rest.firstIndex(of: "m") {
                    i = line.index(after: m)
                    continue
                }
            }
            out.append(line[i])
            i = line.index(after: i)
        }
        return out
    }

    private func levelColor(from line: String) -> Color {
        let up = line.uppercased()
        if up.contains("ERROR") { return .red }
        if up.contains("IMPORTANT") { return Color(red: 0.92, green: 0.28, blue: 0.60) }
        if up.contains("WARNING") || up.contains("WARN") { return .orange }
        if up.contains("SUCCESS") { return .green }
        if up.contains("NETWORK") { return .cyan }
        if up.contains("DEBUG") { return .gray }
        return .blue   // info
    }

    private func startTimer() {
        stopTimer()
        guard autoRefresh else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            api.refreshConsole()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}