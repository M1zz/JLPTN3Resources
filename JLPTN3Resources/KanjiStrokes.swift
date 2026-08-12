import SwiftUI

// MARK: - 획순 데이터
//
// 출처: KanjiVG (https://kanjivg.tagaini.net) — CC BY-SA 3.0.
// KanjiStrokes.json은 앱 어휘에 쓰인 한자 1,330자의 획 path만 추려낸 파생물이며
// 원본과 동일하게 CC BY-SA 3.0으로 배포된다. 자세한 내용은 LICENSE-KanjiVG.md 참고.

enum KanjiStrokes {

    /// KanjiVG의 좌표계 (viewBox="0 0 109 109")
    static let canvasUnit: CGFloat = 109

    private static let raw: [String: [String]] = {
        guard let url = Bundle.main.url(forResource: "KanjiStrokes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data)
        else { return [:] }
        return decoded
    }()

    /// 파싱 결과 캐시 — 같은 글자를 다시 그릴 때 매번 파싱하지 않는다
    private static var cache: [Character: [Path]] = [:]

    /// 109×109 좌표계 기준 획 경로. 획순대로 정렬돼 있다.
    static func strokes(for kanji: Character) -> [Path] {
        if let hit = cache[kanji] { return hit }
        let paths = (raw[String(kanji)] ?? []).map { SVGPathParser.parse($0) }
        cache[kanji] = paths
        return paths
    }

    static func strokeCount(for kanji: Character) -> Int {
        raw[String(kanji)]?.count ?? 0
    }

    static func hasData(for kanji: Character) -> Bool {
        raw[String(kanji)] != nil
    }

    /// 획순을 보여 줄 수 있는 한자 수
    static var count: Int { raw.count }
}

// MARK: - SVG path 파서
//
// KanjiVG가 쓰는 명령은 M/m/C/c/S/s 뿐이지만, 데이터가 갱신될 경우를 대비해
// L/l/H/h/V/v/Z/z 까지 처리한다.

enum SVGPathParser {

    static func parse(_ d: String) -> Path {
        var scanner = Scanner(Array(d))
        var path = Path()
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        /// 직전 곡선의 두 번째 제어점 — S/s의 반사 제어점 계산에 쓰인다
        var lastControl: CGPoint?
        var command: Character?

        while true {
            if let next = scanner.peekCommand() {
                command = next
                _ = scanner.nextCommand()
            } else if command == nil {
                break
            }
            guard let cmd = command else { break }
            let relative = cmd.isLowercase

            switch Character(cmd.lowercased()) {
            case "m":
                guard let x = scanner.nextNumber(), let y = scanner.nextNumber() else { return path }
                current = point(x, y, relative: relative, from: current)
                subpathStart = current
                path.move(to: current)
                lastControl = nil
                // M 뒤에 좌표가 더 오면 암묵적으로 L 로 이어진다
                while scanner.peeksNumber() {
                    guard let lx = scanner.nextNumber(), let ly = scanner.nextNumber() else { break }
                    current = point(lx, ly, relative: relative, from: current)
                    path.addLine(to: current)
                }
                lastControl = nil

            case "l":
                while scanner.peeksNumber() {
                    guard let x = scanner.nextNumber(), let y = scanner.nextNumber() else { break }
                    current = point(x, y, relative: relative, from: current)
                    path.addLine(to: current)
                }
                lastControl = nil

            case "h":
                while let x = scanner.nextNumber() {
                    current = CGPoint(x: relative ? current.x + x : x, y: current.y)
                    path.addLine(to: current)
                }
                lastControl = nil

            case "v":
                while let y = scanner.nextNumber() {
                    current = CGPoint(x: current.x, y: relative ? current.y + y : y)
                    path.addLine(to: current)
                }
                lastControl = nil

            case "c":
                while scanner.peeksNumber() {
                    guard let x1 = scanner.nextNumber(), let y1 = scanner.nextNumber(),
                          let x2 = scanner.nextNumber(), let y2 = scanner.nextNumber(),
                          let x = scanner.nextNumber(), let y = scanner.nextNumber() else { break }
                    let c1 = point(x1, y1, relative: relative, from: current)
                    let c2 = point(x2, y2, relative: relative, from: current)
                    current = point(x, y, relative: relative, from: current)
                    path.addCurve(to: current, control1: c1, control2: c2)
                    lastControl = c2
                }

            case "s":
                while scanner.peeksNumber() {
                    guard let x2 = scanner.nextNumber(), let y2 = scanner.nextNumber(),
                          let x = scanner.nextNumber(), let y = scanner.nextNumber() else { break }
                    // 첫 제어점은 직전 제어점을 현재 점 기준으로 반사시킨 위치
                    let c1 = lastControl.map {
                        CGPoint(x: current.x * 2 - $0.x, y: current.y * 2 - $0.y)
                    } ?? current
                    let c2 = point(x2, y2, relative: relative, from: current)
                    current = point(x, y, relative: relative, from: current)
                    path.addCurve(to: current, control1: c1, control2: c2)
                    lastControl = c2
                }

            case "z":
                path.closeSubpath()
                current = subpathStart
                lastControl = nil

            default:
                // 알 수 없는 명령은 건너뛴다
                while scanner.nextNumber() != nil {}
            }

            if scanner.isAtEnd { break }
        }
        return path
    }

    private static func point(_ x: CGFloat, _ y: CGFloat,
                              relative: Bool, from current: CGPoint) -> CGPoint {
        relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
    }

    // MARK: 토크나이저

    private struct Scanner {
        private let chars: [Character]
        private var i = 0

        init(_ chars: [Character]) { self.chars = chars }

        var isAtEnd: Bool {
            var j = i
            while j < chars.count, isSeparator(chars[j]) { j += 1 }
            return j >= chars.count
        }

        private func isSeparator(_ c: Character) -> Bool {
            c == " " || c == "," || c == "\n" || c == "\t" || c == "\r"
        }

        private func isDigit(_ c: Character) -> Bool { c.isASCII && c.isNumber }

        private mutating func skipSeparators() {
            while i < chars.count, isSeparator(chars[i]) { i += 1 }
        }

        mutating func peekCommand() -> Character? {
            skipSeparators()
            guard i < chars.count, chars[i].isLetter, chars[i].isASCII else { return nil }
            return chars[i]
        }

        mutating func nextCommand() -> Character? {
            guard let c = peekCommand() else { return nil }
            i += 1
            return c
        }

        mutating func peeksNumber() -> Bool {
            skipSeparators()
            guard i < chars.count else { return false }
            let c = chars[i]
            if isDigit(c) || c == "." { return true }
            // 부호 뒤에 숫자가 와야 수. «0.05-0.16»처럼 구분자 없이 붙는 경우가 많다
            if c == "-" || c == "+" {
                let j = i + 1
                return j < chars.count && (isDigit(chars[j]) || chars[j] == ".")
            }
            return false
        }

        mutating func nextNumber() -> CGFloat? {
            guard peeksNumber() else { return nil }
            let start = i
            if chars[i] == "-" || chars[i] == "+" { i += 1 }
            while i < chars.count, isDigit(chars[i]) { i += 1 }
            if i < chars.count, chars[i] == "." {
                i += 1
                while i < chars.count, isDigit(chars[i]) { i += 1 }
            }
            if i < chars.count, chars[i] == "e" || chars[i] == "E" {
                let mark = i
                i += 1
                if i < chars.count, chars[i] == "-" || chars[i] == "+" { i += 1 }
                if i < chars.count, isDigit(chars[i]) {
                    while i < chars.count, isDigit(chars[i]) { i += 1 }
                } else {
                    i = mark
                }
            }
            return CGFloat(Double(String(chars[start..<i])) ?? 0)
        }
    }
}

// MARK: - 획순 애니메이션

/// phase 하나로 여러 획을 순서대로 그린다.
/// phase가 0 → 획수 로 선형 변화할 때, index번째 획은 그 구간에서만 그려진다.
struct StrokeShape: Shape {
    let stroke: Path
    let index: Int
    var phase: Double

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let t = min(max(phase - Double(index), 0), 1)
        guard t > 0 else { return Path() }
        return stroke.trimmedPath(from: 0, to: t)
    }
}

/// 109×109 좌표계에 그린 뒤 실제 칸 크기로 확대한다.
struct StrokeOrderView: View {
    let kanji: Character
    let phase: Double
    let size: CGFloat
    var color: Color = Theme.brand

    var body: some View {
        let strokes = KanjiStrokes.strokes(for: kanji)
        ZStack {
            ForEach(strokes.indices, id: \.self) { i in
                StrokeShape(stroke: strokes[i], index: i, phase: phase)
                    .stroke(color, style: StrokeStyle(lineWidth: 3.2,
                                                      lineCap: .round,
                                                      lineJoin: .round))
            }
        }
        .frame(width: KanjiStrokes.canvasUnit, height: KanjiStrokes.canvasUnit)
        .scaleEffect(size / KanjiStrokes.canvasUnit)
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }
}
