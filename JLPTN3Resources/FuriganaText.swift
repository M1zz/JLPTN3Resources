import SwiftUI

// MARK: - 후리가나 (한자 위에 읽기)
//
// 예문에 한자가 섞여 있으면 읽지 못해 문제가 성립하지 않는다.
// 그렇다고 문장 전체를 히라가나로 바꾸면 한자를 볼 기회가 사라진다.
// 그래서 한자 위에 작은 글씨로 읽기를 얹는다.
//
// 읽기는 CFStringTokenizer의 발음 전사(라틴)를 히라가나로 되돌려 얻는다.
// 활용형(«読んで» 같은 것)도 문맥에 맞게 나오므로 사전 표제어 읽기보다 낫다.
// 다만 이름·드문 낱말은 틀릴 수 있어, 앱이 아는 낱말이면 사전 읽기를 우선한다.

enum Furigana {

    struct Token: Identifiable {
        let id: Int
        let surface: String
        /// 위에 얹을 읽기. 한자가 없으면 nil (가나는 그대로 읽으면 된다)
        let reading: String?
    }

    private static var cache: [String: [Token]] = [:]

    static func tokens(of text: String) -> [Token] {
        if let hit = cache[text] { return hit }
        let built = build(text)
        cache[text] = built
        return built
    }

    private static func build(_ text: String) -> [Token] {
        var out: [Token] = []
        let ns = text as NSString
        guard let tokenizer = CFStringTokenizerCreate(
            kCFAllocatorDefault, text as CFString,
            CFRangeMake(0, ns.length),
            kCFStringTokenizerUnitWordBoundary,
            Locale(identifier: "ja_JP") as CFLocale)
        else { return [Token(id: 0, surface: text, reading: nil)] }

        var cursor = 0
        while CFStringTokenizerAdvanceToNextToken(tokenizer) != [] {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            // 토크나이저가 건너뛴 구두점·공백도 빠뜨리지 않는다
            if range.location > cursor {
                let skipped = ns.substring(with: NSRange(location: cursor,
                                                         length: range.location - cursor))
                out.append(Token(id: out.count, surface: skipped, reading: nil))
            }
            let surface = ns.substring(with: NSRange(location: range.location,
                                                     length: range.length))
            out.append(Token(id: out.count, surface: surface, reading: reading(for: surface,
                                                                               tokenizer: tokenizer)))
            cursor = range.location + range.length
        }
        if cursor < ns.length {
            out.append(Token(id: out.count,
                             surface: ns.substring(from: cursor), reading: nil))
        }
        return out
    }

    private static func reading(for surface: String,
                                tokenizer: CFStringTokenizer) -> String? {
        guard surface.contains(where: isKanji) else { return nil }

        // 1) 발음 전사를 히라가나로 되돌린다.
        //    문맥을 보고 읽으므로 «5日 → か», «一日 → ついたち»처럼 같은 한자의
        //    다른 읽기를 가려낸다. 어휘장 읽기는 문맥을 모르므로 여기서 앞세우면
        //    「日」을 늘 «ひ»로 달아 버린다.
        if let latin = CFStringTokenizerCopyCurrentTokenAttribute(
                tokenizer, kCFStringTokenizerAttributeLatinTranscription) as? String {
            let mutable = NSMutableString(string: latin) as CFMutableString
            if CFStringTransform(mutable, nil, kCFStringTransformLatinHiragana, false) {
                let hira = (mutable as String).trimmingCharacters(in: .whitespaces)
                // 읽기가 표기와 같으면(가나뿐인 낱말) 얹을 필요가 없다
                if !hira.isEmpty, hira != surface { return hira }
            }
        }

        // 2) 전사가 없을 때만 어휘장을 본다
        if let entry = JapaneseLexicon.shared.lookup(surface), entry.base == surface,
           !entry.reading.isEmpty, entry.reading.allSatisfy(isKana) {
            return entry.reading
        }
        return nil
    }

    private static func isKanji(_ c: Character) -> Bool {
        c.unicodeScalars.allSatisfy {
            (0x4E00...0x9FFF).contains($0.value) || (0x3400...0x4DBF).contains($0.value)
        }
    }

    private static func isKana(_ c: Character) -> Bool {
        c.unicodeScalars.allSatisfy { (0x3040...0x30FF).contains($0.value) }
    }
}

// MARK: - 그리기
//
// SwiftUI에는 루비 문자가 없으므로 «읽기 위, 표기 아래» 한 쌍을 만들어
// FlowLayout(HighlightableText.swift)으로 흘려 담는다.

struct FuriganaText: View {
    let text: String
    var size: CGFloat = 17
    var color: Color = Theme.textPrimary
    /// 후리가나를 달지 여부. 끄면 한자만 보인다(읽기 연습용).
    var showsReading: Bool = true

    var body: some View {
        FlowLayout(spacing: 0, lineSpacing: showsReading ? 8 : 6) {
            ForEach(Furigana.tokens(of: text)) { token in
                VStack(spacing: 1) {
                    if showsReading, let reading = token.reading {
                        Text(reading)
                            .font(.system(size: size * 0.5))
                            .foregroundStyle(color.opacity(0.65))
                            .lineLimit(1)
                            .fixedSize()
                    } else if showsReading {
                        // 읽기가 없는 토큰도 같은 높이를 차지해야 글줄이 흔들리지 않는다
                        Color.clear.frame(height: size * 0.5 + 1)
                    }
                    Text(token.surface)
                        .font(.system(size: size))
                        .foregroundStyle(color)
                        .fixedSize()
                }
            }
        }
    }
}
