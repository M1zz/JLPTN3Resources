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

    var label: String {
        switch self {
        case .again: return "다시"
        case .hard:  return "어려움"
        case .good:  return "양호"
        case .easy:  return "쉬움"
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

    var hint: String {
        switch self {
        case .again: return "<10분"
        case .hard:  return "1일"
        case .good:  return "4일"
        case .easy:  return "7일+"
        }
    }
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
