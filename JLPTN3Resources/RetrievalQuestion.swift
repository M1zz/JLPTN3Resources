import Foundation

// MARK: - 인출 문제 만들기
//
// 카드를 보여 주고 «기억났나요?»를 묻는 방식은, 본 것을 «안다»고 착각하기 쉽다(유창성 착각).
// 그래서 세션을 «먼저 답을 꺼내게» 하는 문제로 시작한다.
//
// 문제는 두 가지다.
//  1) 예문 빈칸 — 예문이 있는 카드. 문장 속 낱말을 지우고 무엇이 들어갈지 고르게 한다.
//  2) 뜻 → 낱말 — 예문이 없는 카드. 한국어 뜻만 주고 표기를 고르게 한다.
//
// 어느 쪽이든 «읽기(히라가나)»는 주지 않는다. 한자를 소리로 되살리는 것 자체가
// 외워야 할 내용이므로, 문제에 읽기를 적어 두면 인출할 것이 없어진다.

struct RetrievalQuestion {

    enum Kind {
        case cloze     // 예문 빈칸
        case meaning   // 뜻 → 낱말
    }

    let kind: Kind
    /// 빈칸을 뚫은 예문 (cloze일 때만)
    let sentence: String?
    /// 한국어 뜻 — meaning 문제의 질문이자, cloze에서는 정답 확인 후에만 쓴다
    let meaning: String
    /// 고를 표기 4개
    let choices: [String]
    let answerIndex: Int

    static let blank = "＿＿＿"

    var correctChoice: String { choices[answerIndex] }

    // MARK: 만들기

    static func make(for card: LearningCard) -> RetrievalQuestion {
        let needle = card.front.replacingOccurrences(of: "〜", with: "")
        let example = N3Examples.sentence(for: card)

        // 예문에 표기가 그대로 들어 있을 때만 빈칸을 뚫을 수 있다.
        // 문법 카드의 «〜あまり»처럼 물결표가 붙은 표제어는 떼고 찾는다.
        var kind: Kind = .meaning
        var sentence: String? = nil
        if let ja = example?.japanese, !needle.isEmpty, ja.contains(needle) {
            kind = .cloze
            sentence = ja.replacingOccurrences(of: needle, with: blank)
        }

        let distractors = pickDistractors(for: card, avoiding: sentence)
        // 정답 위치도 카드마다 고정되게 흩는다 (매번 1번이면 «찍으면 1번»을 배운다)
        var pool = distractors + [card.front]
        var rng = SeededRandom(seed: hash(card.id) &+ 7)
        pool.shuffle(using: &rng)
        let answerIndex = pool.firstIndex(of: card.front) ?? 0

        return RetrievalQuestion(kind: kind, sentence: sentence,
                                 meaning: card.meaning,
                                 choices: pool, answerIndex: answerIndex)
    }

    /// 헷갈릴 만한 오답 3개.
    /// 같은 품사·같은 종류에서 고르고, 글자 수가 비슷한 것을 앞세운다 —
    /// 길이만 봐도 답이 보이면 인출이 아니라 눈치 게임이 된다.
    private static func pickDistractors(for card: LearningCard,
                                        avoiding sentence: String?) -> [String] {
        let all = LearningCard.allCards
        var candidates = all.filter { candidate -> Bool in
            guard candidate.front != card.front,
                  candidate.type == card.type,
                  candidate.category == card.category else { return false }
            // 빈칸 문장에 이미 나오는 낱말은 오답으로 쓰지 않는다
            if let s = sentence, s.contains(candidate.front) { return false }
            return true
        }
        if candidates.count < 3 {
            candidates = all.filter { $0.front != card.front && $0.type == card.type }
        }
        guard candidates.count >= 3 else {
            return Array(all.filter { $0.front != card.front }.prefix(3)).map(\.front)
        }

        let target = card.front.count
        var rng = SeededRandom(seed: hash(card.id))
        // 글자 수 차이로 묶고, 같은 묶음 안에서는 카드마다 고정된 순서로 섞는다
        var shuffled = candidates
        shuffled.shuffle(using: &rng)
        let sorted = shuffled.sorted { abs($0.front.count - target) < abs($1.front.count - target) }

        var seen = Set<String>()
        var out: [String] = []
        for c in sorted where !seen.contains(c.front) {
            seen.insert(c.front)
            out.append(c.front)
            if out.count == 3 { break }
        }
        return out
    }

    /// 같은 카드면 늘 같은 문제가 나오도록 — 화면을 다시 그릴 때마다
    /// 보기가 뒤바뀌면 고르는 중에 답이 움직인다.
    private static func hash(_ s: String) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in s.utf8 {
            h = (h ^ UInt64(b)) &* 0x100000001b3
        }
        return h
    }
}

/// 씨앗을 주면 늘 같은 순서를 내는 난수 (SplitMix64)
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
