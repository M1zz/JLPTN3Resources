import Foundation
import NaturalLanguage

// MARK: - 내 단어장
//
// 독해 지문에서 모르는 단어를 짚으면(형광펜) 여기에 쌓인다.
// 뜻은 앱이 가진 자료(N3 어휘 574장 · 지문 단어 도움말)에서 찾아 붙이고,
// 없으면 «뜻 미등록»으로 두되 단어 자체는 남긴다. 나중에 직접 채울 수 있다.

struct VocabNote: Codable, Identifiable, Equatable {
    /// 단어 표기 그대로가 곧 id — 같은 단어를 두 번 담지 않는다
    var id: String { word }
    /// 지문에 나온 모양 그대로 (예: 走っています)
    let word: String
    /// 사전에 실리는 기본형 (예: 走る). 활용형이 아니면 word와 같다.
    /// 예전 판에는 없던 항목이라 optional — 옛 기록을 그대로 읽어들일 수 있게.
    var base: String?
    var reading: String
    var meaning: String
    /// 어느 지문에서 담았는지
    let sourceID: String
    let sourceTitle: String
    let addedAt: Date

    var hasMeaning: Bool { !meaning.isEmpty }
    /// 활용형을 담았을 때만 기본형을 따로 보여 준다
    var inflected: Bool { base.map { $0 != word } ?? false }
}

final class VocabNoteStore: ObservableObject {
    @Published private(set) var notes: [VocabNote] = []

    private let key = "n3_vocab_notes_v1"

    init() { load() }

    func contains(_ word: String) -> Bool {
        notes.contains { $0.word == word }
    }

    /// 짚으면 담고, 다시 짚으면 뺀다
    func toggle(word: String, sourceID: String, sourceTitle: String,
                hint: [ReadingVocab] = []) {
        if let i = notes.firstIndex(where: { $0.word == word }) {
            notes.remove(at: i)
        } else {
            let found = VocabNoteStore.lookup(word, hint: hint)
            notes.append(VocabNote(word: word,
                                   base: found?.base,
                                   reading: found?.reading ?? "",
                                   meaning: found?.meaning ?? "",
                                   sourceID: sourceID,
                                   sourceTitle: sourceTitle,
                                   addedAt: Date()))
        }
        save()
    }

    func remove(_ note: VocabNote) {
        notes.removeAll { $0.word == note.word }
        save()
    }

    func removeAll() {
        notes = []
        save()
    }

    /// 뜻을 직접 채워 넣기
    func update(_ note: VocabNote, reading: String, meaning: String) {
        guard let i = notes.firstIndex(where: { $0.word == note.word }) else { return }
        notes[i].reading = reading
        notes[i].meaning = meaning
        save()
    }

    /// 이 지문에서 담은 단어
    func notes(for passageID: String) -> [VocabNote] {
        notes.filter { $0.sourceID == passageID }
    }

    // MARK: 뜻 찾기

    /// 앱이 가진 자료에서 뜻을 찾는다. 활용형(«読んで» → «読む»)도 기본형으로 되돌려 찾는다.
    static func lookup(_ word: String, hint: [ReadingVocab]) -> JapaneseLexicon.Entry? {
        if let v = hint.first(where: { $0.word == word }) {
            return JapaneseLexicon.Entry(base: v.word, reading: v.reading, meaning: v.meaning)
        }
        return JapaneseLexicon.shared.lookup(word)
    }

    // MARK: 저장

    private func save() {
        SharedStore.defaults.set(try? JSONEncoder().encode(notes), forKey: key)
    }

    private func load() {
        guard let data = SharedStore.defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([VocabNote].self, from: data)
        else { return }
        notes = decoded
    }
}

// MARK: - 일본어 낱말 사전
//
// 짚은 낱말의 뜻을 찾으려면 «활용형 → 기본형»을 되돌릴 수 있어야 한다.
// NaturalLanguage의 lemma는 일본어에서 아무것도 돌려주지 않으므로(전부 nil),
// 어휘장·지문 도움말·기초 낱말 사전에서 활용형을 미리 펼쳐 표를 만들어 둔다.

final class JapaneseLexicon {
    struct Entry {
        /// 사전에 실리는 기본형
        let base: String
        let reading: String
        let meaning: String
    }

    static let shared = JapaneseLexicon()

    /// 표기(기본형·활용형 모두) → 뜻
    private var table: [String: Entry] = [:]
    /// 어간(«走» → 走る) — 표에 없는 긴 활용 꼬리를 만났을 때 쓰는 마지막 수단
    private var stems: [String: Entry] = [:]

    private init() {
        // 뜻이 가장 정확한 순서로 넣는다. 먼저 넣은 쪽이 이긴다.
        var sources: [(String, String, String)] = []
        for card in LearningCard.allCards where !card.front.contains("〜") {
            sources.append((card.front, card.reading, card.meaning))
        }
        for passage in readingPassages {
            for v in passage.vocab { sources.append((v.word, v.reading, v.meaning)) }
        }
        for v in basicWordBank { sources.append((v.word, v.reading, v.meaning)) }

        for (word, reading, meaning) in sources {
            let entry = Entry(base: word, reading: reading, meaning: meaning)
            if table[word] == nil { table[word] = entry }
            if let stem = JapaneseLexicon.stem(of: word), stems[stem] == nil { stems[stem] = entry }
        }
        // 활용형은 기본형을 전부 넣은 뒤에 — 기본형과 부딪히면 기본형이 이겨야 한다
        for (word, reading, meaning) in sources {
            let entry = Entry(base: word, reading: reading, meaning: meaning)
            for form in JapaneseLexicon.inflections(of: word, reading: reading) where table[form] == nil {
                table[form] = entry
            }
        }
    }

    /// 표기 하나를 찾는다. 그대로 없으면 꼬리를 한 글자씩 떼며 기본형·어간을 뒤진다.
    func lookup(_ surface: String) -> Entry? {
        if let e = table[surface] { return e }
        var cur = surface
        while cur.count > 1 {
            cur = String(cur.dropLast())
            if let e = table[cur] { return e }
            if let e = stems[cur] { return e }
        }
        return nil
    }

    /// 이 표기를 아는가 (분절할 때 씀)
    func contains(_ surface: String) -> Bool { table[surface] != nil }

    var longestEntryTokens: Int { 6 }

    // MARK: 활용형 펼치기

    /// 五段동사의 어미 한 글자가 활용에 따라 바뀌는 다섯 줄 + 음편형
    private static let godanRows: [Character: [Character]] = [
        "う": ["わ", "い", "う", "え", "お", "っ"],
        "く": ["か", "き", "く", "け", "こ", "い"],
        "ぐ": ["が", "ぎ", "ぐ", "げ", "ご", "い"],
        "す": ["さ", "し", "す", "せ", "そ"],
        "つ": ["た", "ち", "つ", "て", "と", "っ"],
        "ぬ": ["な", "に", "ぬ", "ね", "の", "ん"],
        "ぶ": ["ば", "び", "ぶ", "べ", "ぼ", "ん"],
        "む": ["ま", "み", "む", "め", "も", "ん"],
        "る": ["ら", "り", "る", "れ", "ろ", "っ"],
    ]

    private static let verbTails = [
        "", "ます", "ました", "ません", "ませんでした", "ましょう",
        "たい", "たく", "たかった", "たくなり", "ながら", "そう", "にくい", "やすい", "すぎる", "すぎて",
        "て", "た", "で", "ている", "ています", "ていた", "ていました", "てある", "ておく", "ておいて",
        "てから", "ても", "てしまう", "てしまった", "てください", "たら", "たり",
        "ない", "なかった", "なくて", "なく", "なくなる", "なくなります",
        "れる", "られる", "られて", "せる", "させる", "ば", "よう", "う", "ろ", "なさい", "ず", "る",
    ]

    private static let adjTails = [
        "い", "く", "くて", "くない", "くなかった", "くなり", "くなる", "かった", "かったら",
        "ければ", "さ", "そう", "すぎる",
    ]

    private static let suruTails = [
        "する", "します", "した", "して", "しました", "しない", "しよう", "しています",
        "してから", "される", "できる", "できます", "できない",
    ]

    /// 활용의 출발점이 되는 어간 («走る» → «走», «高い» → «高»)
    static func stem(of word: String) -> String? {
        guard word.count >= 2, let last = word.last else { return nil }
        guard godanRows[last] != nil || last == "い" else { return nil }
        return String(word.dropLast())
    }

    /// 이 낱말이 취할 수 있는 표기들을 만들어 낸다.
    /// 품사 정보가 없으므로 五段·一段을 둘 다 만든다 — 실제로 없는 형태가 섞여도
    /// 본문에 나타나지 않으니 해가 없고, 놓치는 것보다 낫다.
    static func inflections(of word: String, reading: String) -> [String] {
        guard word.count >= 2, let last = word.last else { return [] }
        var out: [String] = []
        let stem = String(word.dropLast())

        if let rows = godanRows[last] {
            for row in rows {
                for tail in verbTails { out.append(stem + String(row) + tail) }
            }
            if last == "る" {                      // 一段동사 (食べる → 食べます)
                for tail in verbTails where !tail.isEmpty { out.append(stem + tail) }
            }
        }
        if last == "い", reading.hasSuffix("い") {   // い형용사
            for tail in adjTails { out.append(stem + tail) }
        }
        if word.hasSuffix("する") {                  // 명사 + する
            let noun = String(word.dropLast(2))
            for tail in suruTails { out.append(noun + tail) }
        }
        return out
    }
}

// MARK: - 일본어 낱말 나누기
//
// 일본어는 띄어쓰기가 없어 «단어를 짚으려면» 먼저 낱말로 잘라야 한다.
// NLTokenizer는 형태소까지 잘게 쪼개므로(«走っ|て|い|ます») 그대로 쓸 수 없다.
// 토큰 경계는 그대로 두되, 그 위에서 사전 최장일치로 다시 묶는다.

enum JapaneseText {

    /// 화면에 그릴 한 조각.
    /// display는 «보이는 글자»(문장부호까지 붙인 것), word는 «담을 낱말»(없으면 짚을 수 없음).
    struct Unit: Identifiable {
        let id: Int
        let display: String
        let word: String?
    }

    private static let trailingMarks = Set("。、」』）】〉!?！？…‥・：；:;,.")
    private static let leadingMarks  = Set("「『（【〈")

    /// 앞 낱말에 달라붙는 조동사·활용 꼬리 — 따로 짚을 이유가 없다
    private static let auxiliaries: Set<String> = [
        "ます", "ました", "ません", "ましょ", "まし", "ませ", "た", "て", "っ",
        "ない", "なかっ", "なく", "なり", "なっ", "ながら",
        "いる", "いた", "いま", "います", "いました", "ある", "あり", "おく", "おき",
        "しまう", "しまい", "しまっ", "くれる", "くれ", "もらう", "もらい", "あげる",
        "れる", "られる", "られ", "せる", "させる", "させ",
        "たい", "たく", "たかっ", "そう", "すぎる", "すぎ", "らしい", "みたい",
        "う", "よう", "ろ", "ず", "ぬ", "ば", "なさい", "ください", "くださ",
        "たり", "たら", "さ", "み", "め", "たち", "的",
    ]

    /// 앞뒤를 끊는 조사 — 짚어도 뜻이 없다
    private static let particles: Set<String> = [
        "は", "が", "を", "に", "へ", "も", "の", "と", "か", "や", "から", "まで", "より",
        "ので", "のに", "けど", "けれど", "し", "ね", "よ", "な", "だ", "です", "でし", "で",
        "でも", "ても", "では", "には", "とは", "こそ", "さえ", "しか", "だけ", "ほど",
        "ずつ", "など", "って", "という", "ばかり",
    ]

    /// 낱말로 자르되, 문장부호는 앞뒤 낱말에 붙여 준다.
    /// 붙이지 않으면 「。」만 다음 줄로 넘어가 어색해진다.
    static func units(of line: String) -> [Unit] {
        var units: [Unit] = []
        var pendingLead = ""

        for chunk in chunks(of: line) {
            if chunk.word == nil {
                let text = chunk.display
                // 여는 부호는 다음 낱말 앞에, 나머지는 앞 낱말 뒤에 붙인다
                if text.allSatisfy({ leadingMarks.contains($0) }) {
                    pendingLead += text
                } else if text.allSatisfy({ trailingMarks.contains($0) }), let last = units.popLast() {
                    units.append(Unit(id: last.id, display: last.display + text, word: last.word))
                } else {
                    units.append(Unit(id: units.count, display: pendingLead + text, word: nil))
                    pendingLead = ""
                }
                continue
            }
            units.append(Unit(id: units.count, display: pendingLead + chunk.display, word: chunk.word))
            pendingLead = ""
        }
        if !pendingLead.isEmpty {
            units.append(Unit(id: units.count, display: pendingLead, word: nil))
        }
        return units
    }

    private struct Chunk {
        let display: String
        /// 짚을 수 있는 낱말이면 그 표기, 아니면 nil
        let word: String?
    }

    /// 한 줄을 «짚을 만한 낱말» 단위로 묶는다.
    private static func chunks(of line: String) -> [Chunk] {
        let tokens = rawTokens(of: line)
        let lexicon = JapaneseLexicon.shared
        var out: [Chunk] = []
        var i = 0

        while i < tokens.count {
            // 1) 사전 최장일치 — 토큰 경계에 맞춰서만 묶는다.
            //    글자 단위로 맞추면 «送りま|すので» 같은 조각이 생긴다.
            var matched = false
            var span = min(lexicon.longestEntryTokens, tokens.count - i)
            while span >= 1 {
                let candidate = tokens[i..<(i + span)].joined()
                if lexicon.contains(candidate),
                   !(span == 1 && (particles.contains(candidate) || auxiliaries.contains(candidate))) {
                    var surface = candidate
                    var j = i + span
                    while j < tokens.count, auxiliaries.contains(tokens[j]) { surface += tokens[j]; j += 1 }
                    out.append(Chunk(display: surface, word: surface))
                    i = j
                    matched = true
                    break
                }
                span -= 1
            }
            if matched { continue }

            let token = tokens[i]

            // 2) 조사·부호·공백은 짚을 수 없게 둔다
            if particles.contains(token) || !isSelectable(token) {
                out.append(Chunk(display: token, word: nil))
                i += 1
                continue
            }

            // 3) 앞 낱말에 붙는 꼬리
            if auxiliaries.contains(token), let last = out.last, last.word != nil {
                out[out.count - 1] = Chunk(display: last.display + token, word: last.word! + token)
                i += 1
                continue
            }

            // 4) 사전에 없는 낱말.
            //    한자·가타카나가 든 것만 짚을 수 있게 한다. 히라가나만으로 된 조각은
            //    사전에 없다면 «こと·その·ため» 같은 기능어이므로 짚어도 담을 것이 없다.
            guard token.contains(where: { isKanji($0) || isKatakana($0) }) else {
                out.append(Chunk(display: token, word: nil))
                i += 1
                continue
            }

            // 한자 낱글자가 이어지면 한 낱말로 본다 (会 + 議 → 会議)
            var surface = token
            i += 1
            while i < tokens.count, tokens[i].count == 1,
                  tokens[i].allSatisfy(isKanji), surface.allSatisfy(isKanji) {
                surface += tokens[i]
                i += 1
            }
            while i < tokens.count, auxiliaries.contains(tokens[i]) { surface += tokens[i]; i += 1 }
            out.append(Chunk(display: surface, word: surface))
        }
        return out
    }

    /// 한 줄을 형태소 단위로 자른다. 구두점·기호도 빠뜨리지 않고 돌려준다.
    static func rawTokens(of line: String) -> [String] {
        guard !line.isEmpty else { return [] }
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = line
        tokenizer.setLanguage(.japanese)

        var result: [String] = []
        var cursor = line.startIndex
        tokenizer.enumerateTokens(in: line.startIndex..<line.endIndex) { range, _ in
            // 토크나이저가 건너뛴 구두점·기호도 넣는다
            if cursor < range.lowerBound {
                result.append(String(line[cursor..<range.lowerBound]))
            }
            result.append(String(line[range]))
            cursor = range.upperBound
            return true
        }
        if cursor < line.endIndex {
            result.append(String(line[cursor...]))
        }
        return result
    }

    private static func isKanji(_ c: Character) -> Bool {
        c.unicodeScalars.allSatisfy {
            (0x4E00...0x9FFF).contains($0.value) || (0x3400...0x4DBF).contains($0.value)
        }
    }

    /// 「・」(U+30FB)는 가타카나 영역에 있지만 글자가 아니라 부호다
    private static func isKatakana(_ c: Character) -> Bool {
        c.unicodeScalars.allSatisfy {
            $0.value != 0x30FB && ((0x30A0...0x30FF).contains($0.value) || $0.value == 0xFF70)
        }
    }

    /// 짚을 수 있는 낱말인지 — 구두점·공백·숫자만 있는 조각은 제외한다.
    /// 「・」는 가타카나 영역(U+30FB)에 있으므로 따로 걸러 낸다.
    static func isSelectable(_ token: String) -> Bool {
        token.unicodeScalars.contains { scalar in
            let v = scalar.value
            guard v != 0x30FB else { return false }
            let isKanji = (0x4E00...0x9FFF).contains(v) || (0x3400...0x4DBF).contains(v)
            let isKana = (0x3040...0x30FF).contains(v)
            let isLatin = (0x41...0x5A).contains(v) || (0x61...0x7A).contains(v)
            return isKanji || isKana || isLatin
        }
    }
}
