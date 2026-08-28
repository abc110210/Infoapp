import SwiftUI

// MARK: - 魔法少女主题色
extension Color {
    static let magiBgTop = Color(red: 0.10, green: 0.06, blue: 0.20)      // 深紫黑
    static let magiBgBottom = Color(red: 0.05, green: 0.04, blue: 0.12)   // 更深的夜空
    static let magiPink = Color(red: 1.00, green: 0.51, blue: 0.82)       // 主粉
    static let magiPinkDeep = Color(red: 0.84, green: 0.25, blue: 0.62)
    static let magiPurple = Color(red: 0.63, green: 0.45, blue: 0.95)     // 紫
    static let magiGold = Color(red: 1.00, green: 0.82, blue: 0.44)       // 金
    static let magiSky = Color(red: 0.45, green: 0.76, blue: 1.00)        // 天蓝
    static let magiGreen = Color(red: 0.45, green: 0.95, blue: 0.72)      // 绿
    static let magiGray = Color(red: 0.55, green: 0.52, blue: 0.62)
    static let magiCard = Color.white.opacity(0.07)
    static let magiCardStroke = Color.white.opacity(0.14)
}

// MARK: - 魔法阵
struct MagicCircle: View {
    var size: CGFloat = 280
    var lineWidth: CGFloat = 1.2
    @State private var rotate = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.magiPink.opacity(0.35), lineWidth: lineWidth)
            Circle()
                .stroke(Color.magiPurple.opacity(0.5), lineWidth: lineWidth * 2)
                .frame(width: size * 0.72)
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .stroke(Color.magiGold.opacity(0.3), lineWidth: lineWidth * 0.8)
                    .frame(width: size * 0.1)
                    .offset(y: -size * 0.36)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            // 五芒星
            Pentagram(size: size * 0.52)
                .stroke(Color.magiPink.opacity(0.5), style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
                .rotationEffect(.degrees(rotate ? 180 : 0))
                .animation(.linear(duration: 40).repeatForever(autoreverses: false), value: rotate)
            Circle()
                .stroke(Color.magiGold.opacity(0.55), lineWidth: lineWidth)
                .frame(width: size * 0.3)
            Circle()
                .fill(Color.magiPink.opacity(0.6))
                .frame(width: size * 0.045)
        }
        .frame(width: size, height: size)
        .onAppear { rotate = true }
    }
}

/// 五芒星路径
struct Pentagram: Shape {
    var size: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = size / 2
        let angles: [Double] = [270, 342, 54, 126, 198] // 上顶点开始
        var points: [CGPoint] = []
        for a in angles {
            let rad = a * .pi / 180
            points.append(CGPoint(x: center.x + cos(rad) * radius,
                                  y: center.y + sin(rad) * radius))
        }
        path.move(to: points[0])
        path.addLine(to: points[2])
        path.addLine(to: points[4])
        path.addLine(to: points[1])
        path.addLine(to: points[3])
        path.closeSubpath()
        return path
    }
}

// MARK: - 星光背景
struct StardustBackground: View {
    struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let phase: Double
    }

    /// 可选背景图（assets 名），例如梦幻魔法少女夜空
    var imageName: String? = nil

    @State private var stars: [Star] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color.magiBgTop, Color.magiBgBottom],
                               startPoint: .top, endPoint: .bottom)
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                    // 压低背景亮度，保证卡片/文字可读
                    LinearGradient(colors: [Color.black.opacity(0.30), Color.black.opacity(0.62)],
                                   startPoint: .top, endPoint: .bottom)
                }
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x * geo.size.width,
                                  y: star.y * geo.size.height)
                        .opacity(0.35 + 0.5 * sin(star.phase + Date().timeIntervalSince1970))
                }
            }
            .onAppear {
                var arr: [Star] = []
                for _ in 0..<60 {
                    arr.append(Star(x: CGFloat.random(in: 0...1),
                                    y: CGFloat.random(in: 0...1),
                                    size: CGFloat.random(in: 1...3),
                                    phase: Double.random(in: 0...(.pi * 2))))
                }
                stars = arr
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 毛玻璃卡片（渐变描边 + 柔光，融合 futakire 通透美学）
struct GlassCard<Content: View>: View {
    var padding: CGFloat = 16
    var glow: Color = .magiPink
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.10), Color.white.opacity(0.02)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        // 渐变描边：粉 → 紫 → 半透明
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [glow.opacity(0.55), Color.magiPurple.opacity(0.35), Color.white.opacity(0.08)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.1
                            )
                    )
                    .shadow(color: glow.opacity(0.18), radius: 12, x: 0, y: 4)
                    .shadow(color: Color.magiPurple.opacity(0.10), radius: 22, x: 0, y: 0)
            )
    }
}

// MARK: - 径向柔光（卡片背后/标题的光晕）
struct RadialGlow: View {
    var color: Color = .magiPink
    var radius: CGFloat = 90

    var body: some View {
        RadialGradient(
            colors: [color.opacity(0.40), color.opacity(0.08), .clear],
            center: .center, startRadius: 0, endRadius: radius
        )
        .frame(width: radius * 2, height: radius * 2)
        .allowsHitTesting(false)
    }
}

// MARK: - 环形仪表（系统卡片三环：CPU / 内存 / 磁盘）
struct RingGauge: View {
    let title: String
    let percent: Double
    let valueText: String
    var color: Color = .magiPink
    var icon: String = "cpu"

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: max(0.02, min(1.0, percent / 100)))
                    .stroke(
                        AngularGradient(colors: [color.opacity(0.4), color, .white.opacity(0.9)],
                                        center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(color)
                    Text("\(Int(percent))%")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 74, height: 74)
            Text(title)
                .font(.caption2)
                .foregroundColor(.magiGray)
            Text(valueText)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 渐变标题文字
struct GradientSectionTitle: View {
    let text: String
    var icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.magiPink)
            Text(text)
                .font(.headline)
                .foregroundStyle(
                    LinearGradient(colors: [Color.magiPink, Color(red: 0.85, green: 0.72, blue: 1.0)],
                                   startPoint: .leading, endPoint: .trailing)
                )
            Spacer()
        }
    }
}

// MARK: - 数字小格
struct StatTile: View {
    let title: String
    let value: String
    var color: Color = .magiPink
    var icon: String = "sparkles"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.magiGray)
                Spacer(minLength: 0)
            }
            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 进度排行条
struct RankRow: View {
    let name: String
    let value: Int
    let maxValue: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(value)")
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(
                            LinearGradient(colors: [color.opacity(0.6), color],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: max(8, geo.size.width * (maxValue > 0 ? CGFloat(value) / CGFloat(maxValue) : 0)))
                }
            }
            .frame(height: 7)
        }
    }
}

// MARK: - 状态胶囊
struct Pill: View {
    let text: String
    var color: Color = .magiPink

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.18)))
            .foregroundColor(color)
    }
}

// MARK: - 空态 / 错误态
struct EmptyState: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.magiGray)
            Text(text)
                .font(.footnote)
                .foregroundColor(.magiGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}