# 星野播放器 HoshinoPlayer (iOS)

马卡龙治愈系二次元 iOS 音乐播放器。参考 [futakire.com](https://futakire.com/) 的粉系风格，图标为星野团子玩偶（`QQ图片20260812161716.png` 生成全套 AppIcon）。

## 功能

- 5 个页面：我的 / 歌单 / 播放 / 歌词 / 设置
- **后台播放**：AVAudioSession playback 会话 + Info.plist `UIBackgroundModes=audio`，锁屏 / 切后台继续播放
- **锁屏控制中心**：上一首 / 下一首 / 播放暂停 / 拖动进度
- 三种播放模式：顺序 / 随机 / 单曲循环
- LRC 歌词解析、当前行居中高亮、自动滚动
- **磁盘缓存**：边播边缓存，默认上限 **2GB**，设置页可调 1~8G，支持一键清除
- 缓存管理：本地文件优先播放、LRU 配额清理、ByteCount 显示

## 工程结构

```
<仓库根>/
├── .github/workflows/build.yml   # CI：无签名编译 + 打包 unsigned ipa
├── .gitignore
└── HoshinoPlayer/                # 工程根（XcodeGen 在此运行）
    ├── project.yml               # XcodeGen 配置（生成 .xcodeproj）
    ├── HoshinoPlayer/            # 源码
    │   ├── App/                  # 入口 + RootTabView + TabRouter
    │   ├── Models/               # Track / Playlist / Settings
    │   ├── Services/             # PlayerService / LyricsParser / CacheManager / LibraryService
    │   ├── Theme/                # HoshinoTheme 马卡龙色板
    │   ├── Views/                # 5 页面 + Components
    │   └── Resources/
    │       └── Assets.xcassets   # AppIcon（脚本生成，已提交）
    └── tools/make_icons.py       # logo → 全套 AppIcon 生成脚本
```

## 编译

### 方式一：GitHub Actions（推荐，无需本地 Xcode）

1. 把**仓库根（.github/ 与 HoshinoPlayer/ 的上一级）**推到 GitHub
2. 打开 **Actions** → **Build iOS App (unsigned ipa)** → 手动 Run workflow，或推送到 `main` 自动触发
3. 构建成功后到该 run 的 **Artifacts** 下载 `HoshinoPlayer-unsigned-ipa`（未签名 .ipa）

### 方式二：本地 Mac + Xcode

```bash
brew install xcodegen
cd HoshinoPlayer
xcodegen generate          # 在 HoshinoPlayer/ 生成 HoshinoPlayer.xcodeproj
open HoshinoPlayer.xcodeproj
```

用 Xcode 打开后，在 Signing & Capabilities 里选择自己的 Team，连真机即可运行。

## 手动签名（iOS 真机安装）

未签名 ipa 无法直接安装到手机，需先签名。任选其一：

### 方案 A：Xcode（最简单）
1. `xcodegen generate` 后打开工程
2. **Signing & Capabilities** → 勾选 **Automatically manage signing** → 选自己的 Apple ID 团队
3. 把手机连上 Mac，选择真机目标，点击 Run

### 方案 B：命令行 + 免费证书
```bash
# 1. 在 Xcode Accounts 里添加你的 Apple ID（免费开发者账号即可）
# 2. 获取签名身份
security find-identity -v -p codesigning

# 3. 用你的证书 + 描述文件重签（示例）
codesign -f -s "Apple Development: 你的名字 (XXXX)" \
  --entitlements entitlements.plist \
  HoshinoPlayer.ipa/Payload/HoshinoPlayer.app
zip -qry HoshinoPlayer-signed.ipa Payload
```
再通过「Apple Configurator」或「爱思助手」等安装到手机（需同一 Apple ID 信任描述文件）。

### 方案 C：免费签名工具
Xcode 的免费 Provisioning Profile（7 天有效期）配合 `ios-deploy` 或直接 Xcode Run 安装。

## 说明

- **AppIcon 已随仓库提交**（全套尺寸生成于 `Assets.xcassets/AppIcon.appiconset`）；`tools/make_icons.py` 仅在需要重新生成时使用（该脚本为本机工具，读取仓库外部的 `QQ图片20260812161716.png`，不随仓库分发）
- 当前曲库为**内置演示数据**（SoundHelix 公共测试音频 + 示例歌词），替换真实曲库的方式见 `LibraryService.loadFromRemote`（预留 WebDAV / JSON 直链加载口）
- 签名最终由你本人完成，仓库不提交任何证书 / 描述文件 / 私钥
- 缓存 / 设置均持久化在 UserDefaults 与 Caches 目录，清除缓存不丢失设置
