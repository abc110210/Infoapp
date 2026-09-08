import Foundation
import Combine

/// 底部 Tab 导航（跨页面跳转：播放页 → 歌词 / 歌单）
final class TabRouter: ObservableObject {
    @Published var tab = 0
}