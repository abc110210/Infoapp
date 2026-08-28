import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var api: APIService
    @Environment(\.dismiss) private var dismiss

    @State private var serverURL = ""
    @State private var token = ""
    @State private var testResult: (Bool, String)?
    @State private var testing = false

    var body: some View {
        NavigationStack {
            ZStack {
                StardustBackground(imageName: "page_bg")
                Form {
                    Section("服务器连接") {
                        TextField("服务器地址", text: $serverURL)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        TextField("访问 Token", text: $token)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    Section {
                        Button {
                            saveAndTest()
                        } label: {
                            Label(testing ? "测试中…" : "保存并测试连接",
                                  systemImage: testing ? "arrow.triangle.2.circlepath" : "link.badge.plus")
                        }
                        .disabled(testing)
                        if let result = testResult {
                            HStack(spacing: 6) {
                                Image(systemName: result.0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(result.0 ? .magiGreen : .magiGold)
                                Text(result.1)
                                    .font(.footnote)
                                    .foregroundColor(.white.opacity(0.85))
                            }
                        }
                    }
                    Section("说明") {
                        Text("""
                        本 App 是“魔法观测”：通过 wss 长连接接入的 Python 聚合服务，\
                        服务器周期推送 QQ Bot 运行数据，支持断线自动重连。

                        地址支持两种写法：wss://你的域名:端口 或 你的域名:端口。\
                        默认已填当前服务器，地址或 token 变更后请“保存并测试连接”。

                        注意：iOS 上如需安装无签名 IPA，请使用 Apple 开发者证书重新签名后再安装。
                        """)
                        .font(.footnote)
                        .foregroundColor(.magiGray)
                    }
                    Section {
                        Button(role: .destructive) {
                            serverURL = ""
                            token = ""
                            testResult = nil
                        } label: {
                            Text("恢复默认配置")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .foregroundColor(.magiPink)
                }
            }
            .onAppear {
                serverURL = api.baseURL
                token = api.token
            }
        }
    }

    private func saveAndTest() {
        guard !serverURL.trimmingCharacters(in: .whitespaces).isEmpty else {
            testResult = (false, "服务器地址不能为空")
            return
        }
        api.baseURL = serverURL
        api.token = token
        testing = true
        Task {
            let (ok, msg) = await api.testConnection(url: serverURL, token: token)
            testResult = (ok, msg)
            testing = false
            if ok {
                api.connect()
            }
        }
    }
}