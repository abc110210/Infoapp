import Foundation
import Combine

/// 负责与 Python 聚合服务端的 wss 长连接通信。
/// 协议：连接后服务端周期推送 {"type":"data",...} 与心跳 {"type":"ping"}，
/// 客户端主动要数据发 {"type":"refresh"}，收到 ping 回 {"type":"pong"}。
final class APIService: ObservableObject {

    static let shared = APIService()

    enum ConnectionState: String {
        case disconnected = "未连接"
        case connecting = "连接中…"
        case connected = "已连接"
        case failed = "连接断开"
    }

    @Published var data: BotInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published var connectionState: ConnectionState = .disconnected

    private var wsTask: URLSessionWebSocketTask?
    private var reconnectTask: Task<Void, Never>?
    private var watchdogTask: Task<Void, Never>?
    private var receiveActive = false
    private var reconnectAttempts = 0
    private var lastMessageAt = Date()
    private let session: URLSession

    private init() {
        session = URLSession(configuration: .default)
    }

    // MARK: - 配置（默认值 = 服务器当前 config.json）
    var baseURL: String {
        get {
            let stored = UserDefaults.standard.string(forKey: "serverURL")
            if let stored, !stored.isEmpty { return stored }
            return "wss://api.xlingran.com:31888"
        }
        set { UserDefaults.standard.set(newValue, forKey: "serverURL") }
    }

    var token: String {
        get {
            let stored = UserDefaults.standard.string(forKey: "serverToken")
            if let stored, !stored.isEmpty { return stored }
            return "Nhs76__D{#{,ve[k[MpRu2cGfnm_r)7"
        }
        set { UserDefaults.standard.set(newValue, forKey: "serverToken") }
    }

    // MARK: - 连接管理

    /// 建立（或重连）wss 长连接
    func connect() {
        disconnect()

        guard let url = wsURL(from: baseURL, path: "/ws", token: token) else {
            errorMessage = "服务器地址无效"
            connectionState = .failed
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let task = session.webSocketTask(with: request)
        wsTask = task
        connectionState = .connecting
        isLoading = true
        errorMessage = nil
        task.resume()
        receiveLoop()
        startWatchdog()
        reconnectAttempts = 0
    }

    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        watchdogTask?.cancel()
        watchdogTask = nil
        wsTask?.cancel(with: .goingAway, reason: nil)
        wsTask = nil
        receiveActive = false
        connectionState = .disconnected
    }

    /// App 主动要一帧数据（下拉刷新 / 按钮刷新）
    func refresh() async {
        sendRaw(#"{"type":"refresh"}"#)
    }

    // MARK: - 收发

    private func receiveLoop() {
        guard let task = wsTask, !receiveActive else { return }
        receiveActive = true
        task.receive { [weak self] result in
            guard let self else { return }
            // URLSession 回调在后台队列，UI 状态必须切回主线程更新
            DispatchQueue.main.async {
                self.receiveActive = false
                switch result {
                case .success(let message):
                    self.lastMessageAt = Date()
                    self.handleMessage(message)
                    self.receiveLoop()   // 继续监听
                case .failure(let error):
                    self.handleDisconnect(error.localizedDescription, reconnect: true)
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            guard let obj = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any],
                  let type = obj["type"] as? String else { return }
            switch type {
            case "hello":
                connectionState = .connected
                isLoading = false
                reconnectAttempts = 0
                sendRaw(#"{"type":"refresh"}"#)   // 进来先要一帧数据
            case "data":
                if let raw = obj["data"] as? [String: Any],
                   let info = try? JSONDecoder().decode(
                       BotInfo.self,
                       from: JSONSerialization.data(withJSONObject: raw)
                   ) {
                    data = info
                    lastUpdated = Date()
                    isLoading = false
                    errorMessage = nil
                    connectionState = .connected
                }
            case "ping":
                sendRaw(#"{"type":"pong"}"#)
            case "error":
                errorMessage = obj["error"] as? String ?? "上游异常"
                isLoading = false
            default:
                break
            }
        case .data:
            break
        @unknown default:
            break
        }
    }

    private func sendRaw(_ payload: String) {
        guard let task = wsTask else { return }
        task.send(.string(payload)) { _ in }
    }

    // MARK: - 断线检测与重连

    private func startWatchdog() {
        watchdogTask?.cancel()
        watchdogTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000) // 每 15s 检查一次
                guard let self, self.wsTask != nil else { continue }
                // 超过 60s 没收到任何消息（含心跳）→ 判定掉线，重连
                if Date().timeIntervalSince(self.lastMessageAt) > 60 {
                    self.handleDisconnect("心跳超时，自动重连", reconnect: true)
                    return
                }
            }
        }
    }

    private func handleDisconnect(_ reason: String, reconnect: Bool) {
        wsTask = nil
        receiveActive = false
        watchdogTask?.cancel()
        connectionState = .failed
        errorMessage = reason
        lastUpdated = Date()
        if reconnect {
            scheduleReconnect()
        }
    }

    private func scheduleReconnect() {
        reconnectTask?.cancel()
        let delay = min(30.0, pow(2.0, Double(reconnectAttempts)))  // 1s,2s,4s…封顶 30s
        reconnectAttempts += 1
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.connect()
        }
    }

    // MARK: - 设置页“测试连接”

    func testConnection(url: String, token: String) async -> (Bool, String) {
        guard let target = wsURL(from: url, path: "/ws", token: token) else {
            return (false, "地址无效（示例: wss://你的域名:31888）")
        }
        var request = URLRequest(url: target)
        request.timeoutInterval = 10
        let task = session.webSocketTask(with: request)
        task.resume()
        let outcome: (Bool, String) = await withCheckedContinuation { cont in
            task.receive { result in
                switch result {
                case .success(.string(let text)):
                    if text.contains(#""hello""#) {
                        cont.resume(returning: (true, "连接成功 · 服务器在线"))
                    } else {
                        cont.resume(returning: (true, "已连接"))
                    }
                case .success(.data):
                    cont.resume(returning: (true, "已连接"))
                case .success:
                    cont.resume(returning: (true, "已连接"))
                case .failure(let error):
                    cont.resume(returning: (false, error.localizedDescription))
                }
            }
        }
        task.cancel(with: .goingAway, reason: nil)
        return outcome
    }

    // MARK: - 工具

    /// 把用户输入（可能带/不带协议头、可能是 http(s)）规范成 ws(s) 地址
    private func wsURL(from input: String, path: String, token: String?) -> URL? {
        var raw = input.trimmingCharacters(in: .whitespaces)
        if raw.isEmpty { raw = "wss://api.xlingran.com:31888" }
        var comps = URLComponents(string: raw.contains("://") ? raw : "wss://" + raw)
        if comps?.scheme == "http" { comps?.scheme = "ws" }
        if comps?.scheme == "https" { comps?.scheme = "wss" }
        comps?.path = path
        if let token {
            comps?.queryItems = [URLQueryItem(name: "token", value: token)]
        }
        return comps?.url
    }
}