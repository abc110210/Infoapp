import Foundation

/// 自定义 URLProtocol：让 AVPlayer 能流式播放「自签名 HTTPS + Basic 认证」的 WebDAV 音频。
/// - scheme：hoshi://nas/音乐/xxx.flac → 真实 https://nas.xlingran.com:5008/音乐/xxx.flac
/// - 支持 AVPlayer 的 Range 请求（拖动进度 / 分段缓冲）
/// - 信任自签名证书 + 注入 Authorization 头
final class DAVURLProtocol: URLProtocol, URLSessionDataDelegate {

    static let scheme = "hoshi"

    /// 自签名信任委托需被强持有（URLSession 对 delegate 是 weak 引用）
    private static let sessionDelegate = DAVSessionDelegate()

    /// 供 URLSession 数据请求复用（自签名信任 + 认证）
    static let session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 60
        return URLSession(configuration: cfg, delegate: sessionDelegate, delegateQueue: nil)
    }()

    private var dataTask: URLSessionDataTask?
    private var isCancelled = false

    /// URLProtocol 的 client 回调要求主线程，统一派发
    private func dispatch(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }

    // MARK: URLProtocol 注册判定
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.scheme == scheme
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
              let realURL = Self.makeRealURL(from: url) else {
            let proto = self
            dispatch {
                proto.client?.urlProtocol(proto, didFailWithError: NSError(
                    domain: "DAVURLProtocol", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "无效的 hoshi:// URL"]))
            }
            return
        }

        var req = URLRequest(url: realURL)
        req.setValue(NASConfig.basicAuthHeader, forHTTPHeaderField: "Authorization")
        if let range = request.value(forHTTPHeaderField: "Range") {
            req.setValue(range, forHTTPHeaderField: "Range")
        }
        req.setValue("*/*", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 60

        isCancelled = false
        dataTask = Self.session.dataTask(with: req)
        dataTask?.resume()
    }

    override func stopLoading() {
        isCancelled = true
        dataTask?.cancel()
        dataTask = nil
    }

    /// hoshi://nas/音乐/x.flac → https://nas.xlingran.com:5008/音乐/x.flac（中文重新 percent 编码）
    static func makeRealURL(from url: URL) -> URL? {
        var path = url.path  // URL.path 已解码
        if path.hasPrefix("/") { path.removeFirst() }
        return NASConfig.realURL(relativePath: path)
    }

    /// 播放器侧用的 hoshi:// URL
    static func playURL(relativePath: String) -> URL {
        let enc = relativePath.split(separator: "/")
            .map { String($0).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
            .joined(separator: "/")
        return URL(string: "\(scheme)://nas/\(enc)")!
    }

    // MARK: URLSessionDataDelegate
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        // 转发响应：修正 Content-Type 为音频类型，透传 Content-Range / Accept-Ranges
        var headers: [String: String] = [:]
        if let http = response as? HTTPURLResponse {
            for (k, v) in http.allHeaderFields {
                headers["\(k)"] = "\(v)"
            }
        }
        if let ct = contentType(for: request.url) {
            headers["Content-Type"] = ct
        }
        headers["Accept-Ranges"] = "bytes"
        let r = HTTPURLResponse(url: request.url!,
                                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 200,
                                httpVersion: "HTTP/1.1",
                                headerFields: headers)!
        let proto = self
        dispatch {
            proto.client?.urlProtocol(proto, didReceive: r, cacheStoragePolicy: .notAllowed)
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let proto = self
        dispatch {
            proto.client?.urlProtocol(proto, didLoad: data)
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        let proto = self
        dispatch {
            guard !proto.isCancelled else { return }   // stopLoading 已取消，不再通知 client
            if let error {
                proto.client?.urlProtocol(proto, didFailWithError: error)
            } else {
                proto.client?.urlProtocolDidFinishLoading(proto)
            }
        }
        self.dataTask = nil
    }

    private func contentType(for url: URL?) -> String? {
        switch url?.pathExtension.lowercased() {
        case "flac": return "audio/flac"
        case "mp3": return "audio/mpeg"
        case "m4a", "aac": return "audio/mp4"
        case "wav": return "audio/wav"
        default: return nil
        }
    }
}

/// 信任所有自签名证书（内网 NAS 场景；正式上架前应替换为锚定证书）
final class DAVSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
