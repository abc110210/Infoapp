import Foundation

/// 一条已解析的歌词行
struct LyricLine: Identifiable, Equatable {
    let id = UUID()
    let time: TimeInterval
    let text: String
}

/// LRC 解析器（支持 [mm:ss.xx] / [mm:ss]；一行可携带多个时间戳）
enum LyricsParser {

    private static let tagRegex = try! NSRegularExpression(
        pattern: "\\[(\\d{1,2}):(\\d{2})(?:[.:](\\d{1,3}))?\\]"
    )

    static func parse(_ lrc: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        let ns = lrc as NSString

        lrc.components(separatedBy: .newlines).forEach { raw in
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { return }

            let matches = tagRegex.matches(in: line, options: [], range: NSRange(location: 0, length: (line as NSString).length))
            guard !matches.isEmpty else { return }

            // 取最后一个时间戳之后的文本为歌词正文
            let last = matches.last!
            let lastEnd = last.range.location + last.range.length
            let text = ns.substring(with: NSRange(location: lastEnd,
                                                  length: (line as NSString).length - lastEnd))
                .trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { return }

            for m in matches {
                let min = Double((line as NSString).substring(with: m.range(at: 1))) ?? 0
                let sec = Double((line as NSString).substring(with: m.range(at: 2))) ?? 0
                let fracStr = m.range(at: 3).location != NSNotFound
                    ? (line as NSString).substring(with: m.range(at: 3)) : nil
                var fracSeconds = 0.0
                if let f = fracStr, let n = Double(f) {
                    fracSeconds = n / pow(10.0, Double(f.count)) // .xx 或 .xxx 自适应
                }
                lines.append(LyricLine(time: min * 60 + sec + fracSeconds, text: text))
            }
        }

        return lines.sorted { $0.time < $1.time }
    }
}