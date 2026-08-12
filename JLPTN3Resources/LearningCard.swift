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

    var isNew: Bool { repetitions == 0 && learningStep == 0 }
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
