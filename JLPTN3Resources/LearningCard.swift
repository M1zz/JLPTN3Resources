import Foundation
import SwiftUI

// MARK: - Card Type

enum CardType: String, Codable, CaseIterable, Identifiable {
    case vocabulary = "어휘"
    case grammar    = "문법"
    case kanji      = "한자"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .vocabulary: return Color(accentHex: "BE123C")
        case .grammar:    return Color(accentHex: "1D4ED8")
        case .kanji:      return Color(accentHex: "7C3AED")
        }
    }

    var icon: String {
        switch self {
        case .vocabulary: return "character.book.closed.ja"
        case .grammar:    return "text.book.closed"
        case .kanji:      return "pencil.and.outline"
        }
    }
}

// MARK: - SRS Rating

enum SRSRating: Int, CaseIterable {
    case again = 1, hard = 2, good = 3, easy = 4

    /// 「어려움 / 양호」처럼 느낌을 묻지 않고, «무엇까지 할 수 있었는지»를 묻는다.
    ///
    /// 느낌으로 고르면 사람마다·날마다 기준이 흔들려 복습 간격이 엉킨다.
    /// 인출의 깊이는 «뜻 → 소리 → 표기» 순으로 단계가 분명하므로, 그 단계를 그대로 쓴다.
    /// 문법 카드에는 «읽기»가 어울리지 않아 «이해 → 활용»으로 바꾼다.
    func label(for type: CardType) -> String {
        switch (self, type) {
        case (.again, _):          return "찍음"
        case (.hard,  _):          return "뜻만"
        case (.good,  .grammar):   return "이해"
        case (.good,  _):          return "읽기"
        case (.easy,  .grammar):   return "활용"
        case (.easy,  _):          return "쓰기"
        }
    }

    /// 버튼 아래 작은 글씨 — 그 단계의 판단 기준
    func criterion(for type: CardType) -> String {
        switch (self, type) {
        case (.again, _):        return "몰랐다"
        case (.hard,  .grammar): return "의미는 안다"
        case (.hard,  _):        return "뜻은 안다"
        case (.good,  .grammar): return "예문이 읽힌다"
        case (.good,  _):        return "소리 내어 읽는다"
        case (.easy,  .grammar): return "문장을 만든다"
        case (.easy,  _):        return "한자까지 쓴다"
        }
    }

    var colorHex: String {
        switch self {
        case .again: return "DC2626"
        case .hard:  return "D97706"
        case .good:  return "16A34A"
        case .easy:  return "1D4ED8"
        }
    }

    // 예전에는 여기서 «1일 / 4일»처럼 다음 복습까지의 날짜를 보여 줬다.
    // 그 숫자는 SM-2가 알아서 정하는 것이고, 고르는 사람이 알아야 할 정보가 아니다.
    // 오히려 「4일 뒤에 또 보기 싫으니 쉬움을 누르자」처럼 기준을 왜곡시킨다.
}

// MARK: - Learning Card

struct LearningCard: Identifiable, Codable {
    let id: String
    let type: CardType
    let front: String           // 日本語 (word or grammar pattern)
    let reading: String         // ひらがな読み
    let meaning: String         // 한국어 뜻
    let example: String?        // 例文
    let exampleMeaning: String? // 例文 한국어 번역
    let category: String        // 品詞 or 文法 grouping
    let level: Int              // 1=핵심, 2=표준, 3=고급

    // SRS state (mutable on review)
    var interval: Int = 0           // 다음 복습까지 일수
    var easeFactor: Double = 2.5    // SM-2 난이도 계수
    var repetitions: Int = 0        // 성공 복습 횟수
    var nextReviewDate: Date = .distantPast
    var learningStep: Int = 0       // 0=신규, 1=학습 중, 2=졸업

    /// 마지막 인출 문제를 맞혔는지. 아직 풀지 않았으면 nil.
    /// 자기 평가(찍음/뜻만/…)와 달리 «객관적으로 맞았는지»를 남긴다 — 학습 현황의 근거.
    /// 예전 판에는 없던 항목이라 optional (옛 기록을 그대로 읽어들이기 위해)
    var lastCorrect: Bool? = nil

    var isNew: Bool { repetitions == 0 && learningStep == 0 }

    /// 학습 현황 화면에서 쓰는 구분
    enum Progress {
        case untouched   // 아직 공부 안 함
        case correct     // 마지막에 맞힘
        case wrong       // 마지막에 틀림
        case studied     // 공부는 했지만 인출 기록이 없음 (기록 기능 이전에 본 카드)
    }

    var progress: Progress {
        if let last = lastCorrect { return last ? .correct : .wrong }
        return isNew ? .untouched : .studied
    }

    /// 습득 정도 — 「알게 된 것 / 아직 습득 못한 것 / 앞으로 알아야 할 것」
    ///
    /// 「마지막에 맞혔나」와는 다르다. 한 번 맞힌 것은 다음 날 잊을 수 있으므로,
    /// 일주일 넘는 간격을 견딘 카드(interval >= 7)만 «알게 된 것»으로 본다.
    /// 그러다 최근에 틀렸다면 다시 «습득 못한 것»으로 내려온다.
    enum Mastery {
        case acquired   // 알게 된 것
        case learning   // 아직 습득 못한 것 (보고는 있으나 굳지 않음)
        case upcoming   // 앞으로 알아야 할 것 (아직 안 본 것)
    }

    var mastery: Mastery {
        if isNew { return .upcoming }
        if interval >= 7, lastCorrect != false { return .acquired }
        return .learning
    }
    var isDue: Bool { nextReviewDate <= Date() }

    var statusLabel: String {
        if isNew { return "신규" }
        if learningStep < 2 { return "학습 중" }
        if interval < 21 { return "복습" }
        return "숙련"
    }

    var statusColor: Color {
        if isNew { return Color(accentHex: "1D4ED8") }
        if learningStep < 2 { return Color(accentHex: "D97706") }
        if interval < 21 { return Color(accentHex: "16A34A") }
        return Color(accentHex: "7C3AED")
    }
}
