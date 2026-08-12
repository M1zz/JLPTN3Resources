import Foundation
import Combine

// MARK: - SRS Engine (SM-2 simplified)

private func applySchedule(card: inout LearningCard, rating: SRSRating) {
    let now = Date()

    switch rating {
    case .again:
        // 틀림: 학습 단계 초기화, 10분 후 재시도
        card.learningStep = 0
        card.interval = 0
        card.easeFactor = max(1.3, card.easeFactor - 0.2)
        card.nextReviewDate = now.addingTimeInterval(600)  // 10분

    case .hard:
        // 어려움: 간격 1.2배 (또는 1일 고정)
        card.easeFactor = max(1.3, card.easeFactor - 0.15)
        if card.learningStep < 2 {
            card.interval = 1
            card.nextReviewDate = now.addingTimeInterval(86400)
        } else {
            let newInterval = max(1, Int(Double(card.interval) * 1.2))
            card.interval = newInterval
            card.nextReviewDate = now.addingTimeInterval(Double(newInterval) * 86400)
        }
        card.learningStep = max(card.learningStep, 1)

    case .good:
        // 정답: 표준 간격 적용
        card.repetitions += 1
        if card.learningStep == 0 {
            card.interval = 1
            card.learningStep = 1
        } else if card.learningStep == 1 {
            card.interval = 4
            card.learningStep = 2
        } else {
            let newInterval = max(1, Int(Double(card.interval) * card.easeFactor))
            card.interval = newInterval
        }
        card.nextReviewDate = now.addingTimeInterval(Double(card.interval) * 86400)

    case .easy:
        // 쉬움: 간격 보너스 + easeFactor 증가
        card.repetitions += 1
        card.easeFactor = min(4.0, card.easeFactor + 0.15)
        card.learningStep = 2
        if card.interval <= 0 {
            card.interval = 4
        } else {
            card.interval = max(1, Int(Double(card.interval) * card.easeFactor * 1.3))
        }
        card.nextReviewDate = now.addingTimeInterval(Double(card.interval) * 86400)
    }
}

// MARK: - Stats

struct LearningStats: Codable {
    var totalReviewed: Int = 0
    var streak: Int = 0
    var lastStudyDate: Date? = nil
    var todayReviewed: Int = 0
    var todayDate: Date = .distantPast
}

// MARK: - Learning Store

final class LearningStore: ObservableObject {
    @Published private(set) var cards: [LearningCard] = []
    @Published private(set) var stats: LearningStats = LearningStats()

    private let cardsKey = "n3_cards_v2"
    private let statsKey = "n3_stats_v2"

    init() {
        load()
        if cards.isEmpty {
            cards = LearningCard.allCards
            save()
        }
        resetTodayCountIfNeeded()
    }

    // MARK: - Computed

    var dueCards: [LearningCard] {
        cards.filter { !$0.isNew && $0.isDue }
            .sorted { $0.interval < $1.interval }
    }

    var newCards: [LearningCard] {
        cards.filter { $0.isNew }
    }

    var vocabCards: [LearningCard] { cards.filter { $0.type == .vocabulary } }
    var grammarCards: [LearningCard] { cards.filter { $0.type == .grammar } }

    var vocabStudied: Int { vocabCards.filter { $0.repetitions > 0 }.count }
    var grammarStudied: Int { grammarCards.filter { $0.repetitions > 0 }.count }

    var vocabProgress: Double {
        guard !vocabCards.isEmpty else { return 0 }
        return Double(vocabStudied) / Double(vocabCards.count)
    }

    var grammarProgress: Double {
        guard !grammarCards.isEmpty else { return 0 }
        return Double(grammarStudied) / Double(grammarCards.count)
    }

    var totalProgress: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(cards.filter { $0.repetitions > 0 }.count) / Double(cards.count)
    }

    // MARK: - Milestone / Readiness

    // 카드별 가중 점수로 합격 준비도 계산
    // interval >= 21 → 완전 숙지 (1.0)
    // interval >= 7  → 장기 기억 (0.75)
    // interval >= 1  → 단기 기억 (0.4)
    // repetitions > 0 → 학습 시작 (0.15)
    private static func cardWeight(_ card: LearningCard) -> Double {
        if card.interval >= 21 { return 1.00 }
        if card.interval >= 7  { return 0.75 }
        if card.interval >= 1  { return 0.40 }
        if card.repetitions > 0 { return 0.15 }
        return 0.0
    }

    private static func readiness(for subset: [LearningCard]) -> Double {
        guard !subset.isEmpty else { return 0 }
        var total = 0.0
        for card in subset { total += cardWeight(card) }
        return min(1.0, total / Double(subset.count))
    }

    var readinessScore: Double { LearningStore.readiness(for: cards) }
    var vocabReadiness: Double  { LearningStore.readiness(for: vocabCards) }
    var grammarReadiness: Double { LearningStore.readiness(for: grammarCards) }

    var masteredCards: Int  { cards.filter { $0.interval >= 21 }.count }
    var learnedCards: Int   { cards.filter { $0.interval >= 7 && $0.interval < 21 }.count }
    var reviewingCards: Int { cards.filter { $0.interval >= 1 && $0.interval < 7 }.count }

    // 실제 학습일 수 (streak이 끊어진 경우를 대비해 totalReviewed 기반 보정)
    private var effectiveStudyDays: Double {
        let streakDays = Double(max(stats.streak, 1))
        // 하루 평균 30장 기준으로 학습일 추정
        let estimatedDays = Double(stats.totalReviewed) / 30.0
        return max(streakDays, estimatedDays, 1)
    }

    // 현재 속도 유지 시 합격 준비(readiness >= 0.70) 도달까지 남은 일수
    // nil이면 이미 목표 달성 또는 데이터 부족
    var estimatedDaysToPass: Int? {
        let target = 0.70
        guard readinessScore < target else { return nil }
        let scorePerDay = readinessScore / effectiveStudyDays
        guard scorePerDay > 0.0005 else { return nil }
        return Int(ceil((target - readinessScore) / scorePerDay))
    }

    // MARK: - Session Builder (학습과학 기반)
    // 원칙: 교차 학습(interleaving) + 인출 연습(retrieval) 최우선
    // 1. 오늘 만기된 복습 카드 (간격이 짧은 것 우선)
    // 2. 신규 카드 (하루 최대 10장, 어휘/문법 교차)

    /// 하루에 새로 꺼내는 카드 수 — 앱 화면과 위젯이 같은 값을 써야 숫자가 어긋나지 않는다
    static let dailyNewLimit = 10
    var dailyNewLimit: Int { LearningStore.dailyNewLimit }

    func buildSession(newLimit: Int = LearningStore.dailyNewLimit) -> [LearningCard] {
        let reviewBatch = dueCards
        let newBatch = buildInterleavedNewCards(limit: newLimit)

        guard !reviewBatch.isEmpty else { return newBatch }
        guard !newBatch.isEmpty else { return reviewBatch }

        // 교차 방식: 복습 1장 → 신규 1장 반복
        var result: [LearningCard] = []
        let maxLen = max(reviewBatch.count, newBatch.count)
        for i in 0..<maxLen {
            if i < reviewBatch.count { result.append(reviewBatch[i]) }
            if i < newBatch.count    { result.append(newBatch[i]) }
        }
        return result
    }

    // 어휘와 문법 교차 배열 (interleaved practice)
    private func buildInterleavedNewCards(limit: Int) -> [LearningCard] {
        let newVocab = newCards.filter { $0.type == .vocabulary }
            .sorted { $0.level < $1.level }  // 핵심 어휘부터
        let newGram  = newCards.filter { $0.type == .grammar }
            .sorted { $0.level < $1.level }

        var result: [LearningCard] = []
        var vi = 0, gi = 0
        // 어휘 2 : 문법 1 비율로 교차
        while result.count < limit {
            if vi < newVocab.count { result.append(newVocab[vi]); vi += 1 }
            if result.count >= limit { break }
            if vi < newVocab.count { result.append(newVocab[vi]); vi += 1 }
            if result.count >= limit { break }
            if gi < newGram.count  { result.append(newGram[gi]);  gi += 1 }
            if vi >= newVocab.count && gi >= newGram.count { break }
        }
        return Array(result.prefix(limit))
    }

    // MARK: - Rating

    func rate(cardId: String, rating: SRSRating) {
        guard let idx = cards.firstIndex(where: { $0.id == cardId }) else { return }
        applySchedule(card: &cards[idx], rating: rating)
        stats.totalReviewed += 1
        stats.todayReviewed += 1
        markStudiedToday()
        save()
    }

    // MARK: - Streak

    private func markStudiedToday() {
        let cal = Calendar.current
        if let last = stats.lastStudyDate, cal.isDateInToday(last) { return }
        if let last = stats.lastStudyDate, cal.isDateInYesterday(last) {
            stats.streak += 1
        } else {
            stats.streak = 1
        }
        stats.lastStudyDate = Date()
        save()
    }

    private func resetTodayCountIfNeeded() {
        let cal = Calendar.current
        if !cal.isDateInToday(stats.todayDate) {
            stats.todayReviewed = 0
            stats.todayDate = Date()
        }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(cards) {
            SharedStore.defaults.set(data, forKey: cardsKey)
        }
        if let data = try? JSONEncoder().encode(stats) {
            SharedStore.defaults.set(data, forKey: statsKey)
        }
        publishWidgetSnapshot()
    }

    /// 위젯이 읽을 요약을 갱신하고 새로 그리게 한다.
    /// 위젯이 카드 2,798장을 훑지 않도록, 보여 줄 것만 미리 적어 둔다.
    func publishWidgetSnapshot(revealed: Bool = false) {
        let next = nextCardForWidget
        // 오늘 몫만 센다. 미학습 2,798장을 그대로 보여 주면 위젯에
        // 「2,798장 남음」이 뜨고, 앱 화면(오늘 10장)과 숫자가 어긋난다.
        SharedStore.writeSnapshot(.init(dueCount: dueCards.count,
                                        newCount: min(newCards.count, dailyNewLimit),
                                        todayReviewed: stats.todayReviewed,
                                        streak: stats.streak,
                                        cardID: next?.id,
                                        front: next?.front,
                                        reading: next?.reading,
                                        meaning: next?.meaning,
                                        revealed: revealed))
        SharedStore.reloadWidgets()
    }

    /// 위젯에 낼 다음 한 장 — 복습이 밀린 것부터, 없으면 새 카드
    var nextCardForWidget: LearningCard? {
        dueCards.first ?? buildInterleavedNewCards(limit: 1).first
    }

    private func load() {
        if let data = SharedStore.defaults.data(forKey: cardsKey),
           let decoded = try? JSONDecoder().decode([LearningCard].self, from: data) {
            // 저장된 배열을 그대로 쓰면 안 된다.
            // 그러면 어휘장에 카드를 더해도 이미 앱을 켠 적 있는 사람에게는 영영 보이지 않고,
            // 뜻·예문을 고쳐도 옛 내용이 남는다.
            // 카드 목록은 언제나 최신 어휘장을 따르고, 저장된 것에서는 SRS 진도만 이어받는다.
            let saved = Dictionary(decoded.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            cards = LearningCard.allCards.map { card in
                guard let old = saved[card.id] else { return card }   // 새로 추가된 카드
                var merged = card
                merged.interval = old.interval
                merged.easeFactor = old.easeFactor
                merged.repetitions = old.repetitions
                merged.nextReviewDate = old.nextReviewDate
                merged.learningStep = old.learningStep
                return merged
            }
        }
        if let data = SharedStore.defaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(LearningStats.self, from: data) {
            stats = decoded
        }
    }

    // MARK: - Debug / Reset

    func resetProgress() {
        cards = LearningCard.allCards
        stats = LearningStats()
        save()
    }
}
