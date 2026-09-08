import SwiftUI

/// 星野播放器主题：马卡龙治愈系（灵感来自 logo 团子玩偶 + futakire 粉系）
enum HoshinoTheme {
    // MARK: - 色板
    static let pink     = Color(red: 1.00, green: 0.60, blue: 0.71)  // 主粉 #ff9ab5
    static let deepPink = Color(red: 0.96, green: 0.47, blue: 0.62)  // 深粉 #f5799f
    static let softPink = Color(red: 1.00, green: 0.85, blue: 0.89)  // 淡粉 #ffd9e4
    static let cream    = Color(red: 1.00, green: 0.96, blue: 0.97)  // 奶油底 #fff4f7
    static let card     = Color.white
    static let yellow   = Color(red: 1.00, green: 0.85, blue: 0.63)  // 奶油黄 #ffd9a0
    static let mint     = Color(red: 0.71, green: 0.90, blue: 0.83)  // 薄荷绿
    static let lav      = Color(red: 0.80, green: 0.72, blue: 0.96)  // 淡紫
    static let ink      = Color(red: 0.48, green: 0.29, blue: 0.39)  // 主文字 #7a4a63
    static let inkSub   = Color(red: 0.69, green: 0.53, blue: 0.62)  // 次要
    static let inkSoft  = Color(red: 0.85, green: 0.72, blue: 0.78)  // 弱化

    // MARK: - 马卡龙渐变（T-cover / 歌单卡 / 播放封面）
    /// 颜色对（供 LinearGradient 与 artwork 共用）
    static let gradientPalette: [[Color]] = [
        // 渐变 0：暖粉
        [Color(red: 1.00, green: 0.73, blue: 0.81),
         Color(red: 0.96, green: 0.51, blue: 0.67)],
        // 渐变 1：淡紫
        [Color(red: 0.73, green: 0.65, blue: 0.96),
         Color(red: 0.56, green: 0.49, blue: 0.88)],
        // 渐变 2：奶油黄
        [Color(red: 1.00, green: 0.85, blue: 0.63),
         Color(red: 0.96, green: 0.73, blue: 0.42)],
        // 渐变 3：薄荷绿
        [Color(red: 0.65, green: 0.88, blue: 0.78),
         Color(red: 0.44, green: 0.79, blue: 0.65)],
    ]

    /// 取第 i 组渐变色（供 AngularGradient / UIImage 渲染取色用）
    static func gradColors(_ i: Int) -> [Color] {
        gradientPalette[abs(i) % gradientPalette.count]
    }

    /// 取第 i 组 LinearGradient（覆盖 View 用）
    static func grad(_ i: Int) -> LinearGradient {
        let colors = gradColors(i)
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: - 装饰
    /// 全屏奶油渐变背景
    static let pageBg = LinearGradient(colors: [cream, softPink, lav.opacity(0.25)],
                                       startPoint: .top, endPoint: .bottom)
}

extension Color {
    /// #RRGGBB 便捷构造
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255.0,
                  green: Double((hex >> 8) & 0xFF) / 255.0,
                  blue: Double(hex & 0xFF) / 255.0)
    }
}
