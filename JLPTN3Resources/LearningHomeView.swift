import SwiftUI

// MARK: - Learning Home View

private struct SessionItem: Identifiable {
    let id = UUID()
    let cards: [LearningCard]
}

struct LearningHomeView: View {
    @EnvironmentObject private var store: LearningStore
    @State private var sessionItem: SessionItem? = nil

    private var totalToday: Int { store.dueCards.count + min(store.newCards.count, 10) }

    /// 위젯·잠금화면에서 «학습하러 가기»를 눌렀을 때 세션을 바로 연다
    private func startSessionFromWidget() {
        guard sessionItem == nil else { return }        // 이미 열려 있으면 그대로 둔다
        let cards = store.buildSession()
        guard !cards.isEmpty else { return }
        sessionItem = SessionItem(cards: cards)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    todayCards
                    progressSection
                    quickStats
                    Spacer(minLength: 32)
                }
            }
            .background(Theme.background)
            .navigationBarHidden(true)
            .fullScreenCover(item: $sessionItem) { item in
                StudySessionView(cards: item.cards, store: store)
            }
            .onOpenURL { url in
                guard url.scheme == "jlptn3", url.host == "study" else { return }
                startSessionFromWidget()
            }
            .onAppear { store.publishWidgetSnapshot() }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Subtle gradient background
            LinearGradient(
                colors: [Theme.backgroundElevated, Theme.background],
                startPoint: .top, endPoint: .bottom
            )

            // Decorative kanji
            Text("習")
                .font(.system(size: 200, weight: .black))
                .foregroundStyle(Theme.decoration)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .offset(x: 20, y: 30)

            VStack(alignment: .leading, spacing: 0) {
                // Top bar: date + streak
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(todayLabel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                        Text("JLPT N3")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Spacer()
                    streakBadge
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)

                Spacer(minLength: 24)

                // Status line
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if totalToday > 0 {
                        Text("\(totalToday)")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.brand)
                        Text("장 남음")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.bottom, 6)
                    } else {
                        Text("완료")
                            .font(.system(size: 46, weight: .black, design: .rounded))
                            .foregroundStyle(Color(accentHex: "10B981"))
                    }
                }
                .padding(.horizontal, 22)

                Text(statusSubtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, 22)
                    .padding(.top, 4)

                Spacer(minLength: 20)

                // CTA Button
                Button {
                    let cards = store.buildSession(newLimit: 10)
                    sessionItem = SessionItem(cards: cards)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: totalToday > 0 ? "play.fill" : "checkmark")
                            .font(.system(size: 15, weight: .bold))
                        Text(totalToday > 0 ? "지금 학습하기" : "오늘 학습 완료!")
                            .font(.system(size: 17, weight: .black))
                    }
                    .foregroundStyle(Theme.onBrand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        totalToday > 0
                            ? Theme.brand
                            : Color(accentHex: "10B981")
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(totalToday == 0)
                .padding(.horizontal, 22)
                .padding(.bottom, 24)
            }
        }
        .frame(minHeight: 260)
    }

    private var streakBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.system(size: 13))
                .foregroundStyle(store.stats.streak > 0 ? Color(accentHex: "F59E0B") : Theme.textQuaternary)
            Text("\(store.stats.streak)일")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.surfaceSoft)
        .clipShape(Capsule())
    }

    private var todayLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 EEEE"
        return f.string(from: Date())
    }

    private var statusSubtitle: String {
        let due = store.dueCards.count
        let new = min(store.newCards.count, 10)
        if due == 0 && new == 0 { return "오늘의 모든 학습을 마쳤습니다" }
        var parts: [String] = []
        if due > 0 { parts.append("복습 \(due)장") }
        if new > 0 { parts.append("신규 \(new)장") }
        return parts.joined(separator: " · ")
    }

    // MARK: - Today Cards (컴팩트)

    private var todayCards: some View {
        HStack(spacing: 10) {
            todayChip(value: store.dueCards.count, label: "복습 대기",
                      icon: "arrow.clockwise", color: "F59E0B")
            todayChip(value: min(store.newCards.count, 10), label: "신규",
                      icon: "plus.circle.fill", color: "3B82F6")
            todayChip(value: store.stats.todayReviewed, label: "오늘 완료",
                      icon: "checkmark.circle.fill", color: "10B981")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private func todayChip(value: Int, label: String, icon: String, color: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(Color(accentHex: color))
            VStack(alignment: .leading, spacing: 1) {
                Text("\(value)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(accentHex: color).opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(accentHex: color).opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 10) {
            progressBar(
                label: "어휘",
                icon: "character.book.closed.ja",
                studied: store.vocabStudied,
                total: store.vocabCards.count,
                progress: store.vocabProgress,
                color: "BE123C"
            )
            progressBar(
                label: "문법",
                icon: "text.book.closed",
                studied: store.grammarStudied,
                total: store.grammarCards.count,
                progress: store.grammarProgress,
                color: "1D4ED8"
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private func progressBar(label: String, icon: String,
                              studied: Int, total: Int,
                              progress: Double, color: String) -> some View {
        let c = Color(accentHex: color)
        return VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(c)
                Text(label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(studied)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(c)
                Text("/ \(total)")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textQuaternary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.track)
                    Capsule()
                        .fill(c)
                        .frame(width: geo.size.width * progress)
                        .animation(.easeInOut(duration: 0.8), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Quick Stats

    private var quickStats: some View {
        HStack(spacing: 10) {
            statCell(value: store.stats.totalReviewed, label: "누적 학습",
                     icon: "books.vertical.fill", color: "8B5CF6")
            statCell(value: store.masteredCards, label: "완전 숙지",
                     icon: "star.fill", color: "D4A373")
            statCell(value: store.newCards.count, label: "미학습",
                     icon: "sparkles", color: "6B7280")
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private func statCell(value: Int, label: String, icon: String, color: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(accentHex: color))
            Text("\(value)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(accentHex: color).opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    LearningHomeView()
        .environmentObject(LearningStore())
}
