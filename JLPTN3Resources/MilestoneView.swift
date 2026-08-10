import SwiftUI

// MARK: - Milestone Model

struct Milestone {
    let threshold: Double   // readinessScore 기준
    let emoji: String
    let title: String
    let subtitle: String
    let color: String
}

private let milestones: [Milestone] = [
    Milestone(threshold: 0.00, emoji: "🌱", title: "학습 시작",
              subtitle: "첫 발걸음을 내딛었습니다",           color: "6B7280"),
    Milestone(threshold: 0.15, emoji: "📖", title: "기초 다지기",
              subtitle: "핵심 어휘를 익히는 중입니다",         color: "3B82F6"),
    Milestone(threshold: 0.35, emoji: "💪", title: "도약 단계",
              subtitle: "문법 패턴 학습을 시작했습니다",       color: "8B5CF6"),
    Milestone(threshold: 0.55, emoji: "🎯", title: "합격권 근접",
              subtitle: "전체 내용의 절반 이상 습득했습니다",  color: "F59E0B"),
    Milestone(threshold: 0.70, emoji: "⭐", title: "합격 준비 완료",
              subtitle: "JLPT N3 시험 응시를 권장합니다",     color: "10B981"),
    Milestone(threshold: 0.90, emoji: "🏆", title: "N3 마스터",
              subtitle: "거의 모든 내용을 숙지했습니다",       color: "D4A373"),
]

// MARK: - 채점 과목 (得点区分)

/// JLPT N3는 3개 과목으로 채점된다. 각 과목 0~60점, 총점 180점.
struct ScoringSection {
    let name: String
    let japanese: String
    let icon: String
    let color: String
    /// 이 정도면 과목별 기준점(19점)은 넘는다고 봐도 되는 체감 기준
    let passCheckpoints: [String]
    /// 총점 95점을 여유 있게 넘기기 위한 안정권 기준 (과목당 35점 안팎)
    let stableCheckpoints: [String]
    /// 이 앱이 진도를 추적하는 과목인지 (독해·청해는 앱 밖에서 훈련해야 함)
    let trackedByApp: Bool
}

let scoringSections: [ScoringSection] = [
    ScoringSection(
        name: "언어지식 (문자·어휘·문법)",
        japanese: "言語知識",
        icon: "character.book.closed.ja",
        color: "BE123C",
        passCheckpoints: [
            "N3 한자 약 650자 중 70%를 보고 바로 읽을 수 있다",
            "핵심 어휘 2,000개 수준에서 뜻이 1초 안에 떠오른다",
            "N3 문법 182개 중 120개 정도의 의미와 접속 형태를 구분한다",
            "「〜そうだ」처럼 형태가 겹치는 문법을 문맥으로 골라낸다"
        ],
        stableCheckpoints: [
            "한자 읽기 90% 이상 + 비슷한 어휘(似た言葉) 문제를 구분한다",
            "문법 182개 전체를 예문과 함께 설명할 수 있다"
        ],
        trackedByApp: true
    ),
    ScoringSection(
        name: "독해",
        japanese: "読解",
        icon: "doc.text",
        color: "7C3AED",
        passCheckpoints: [
            "단문(150~200자)을 4분 안에 읽고 질문에 답한다",
            "모르는 단어가 2~3개 있어도 멈추지 않고 문맥으로 넘어간다",
            "지시어(それ·そこ·このこと)가 가리키는 대상을 찾아낸다",
            "필자의 주장과 예시를 구분할 수 있다"
        ],
        stableCheckpoints: [
            "중문(350자) 6분 · 장문(550자) 9분 안에 완독한다",
            "정보검색(광고·안내문)에서 조건에 맞는 항목을 1분 안에 고른다"
        ],
        trackedByApp: false
    ),
    ScoringSection(
        name: "청해",
        japanese: "聴解",
        icon: "headphones",
        color: "0891B2",
        passCheckpoints: [
            "과제이해: 한 번 듣고 «다음에 무엇을 하는지»를 파악한다",
            "숫자·시간·요일·가격을 놓치지 않고 받아 적는다",
            "자막 없이 N3 수준 대화의 60% 정도를 이해한다",
            "질문을 먼저 듣고 필요한 정보만 골라 듣는다"
        ],
        stableCheckpoints: [
            "즉시응답에서 짧은 한마디에 바로 반응한다 (8문항 중 6개)",
            "발화표현에서 장면에 맞는 표현을 고른다"
        ],
        trackedByApp: false
    )
]

// MARK: - Milestone View

struct MilestoneView: View {
    @StateObject private var store = LearningStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    readinessHero
                    passCriteriaSection
                    selfCheckSection
                    milestoneRoadmap
                    categoryBreakdown
                    statsGrid
                    Spacer(minLength: 40)
                }
            }
            .background(Theme.background)
            .navigationTitle("합격 마일스톤")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.backgroundElevated, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Hero Section

    private var readinessHero: some View {
        VStack(spacing: 0) {
            ZStack {
                Theme.backgroundElevated

                VStack(spacing: 20) {
                    // Circular gauge
                    ZStack {
                        Circle()
                            .stroke(Theme.track, lineWidth: 16)
                            .frame(width: 160, height: 160)

                        Circle()
                            .trim(from: 0, to: store.readinessScore)
                            .stroke(
                                AngularGradient(
                                    colors: [Color(accentHex: "3B82F6"), Color(accentHex: "10B981"), Theme.brand],
                                    center: .center,
                                    startAngle: .degrees(-90),
                                    endAngle: .degrees(270)
                                ),
                                style: StrokeStyle(lineWidth: 16, lineCap: .round)
                            )
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.2), value: store.readinessScore)

                        VStack(spacing: 4) {
                            Text("\(Int(store.readinessScore * 100))%")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Text("합격 준비도")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }

                    // Days estimate
                    if let days = store.estimatedDaysToPass {
                        VStack(spacing: 6) {
                            Text("현재 속도 유지 시")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textTertiary)
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("약")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Theme.textSecondary)
                                Text("\(days)")
                                    .font(.system(size: 42, weight: .black, design: .rounded))
                                    .foregroundStyle(Theme.brand)
                                Text("일 후")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Text("합격 준비 완료 예상")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Theme.surfaceSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else if store.readinessScore >= 0.70 {
                        HStack(spacing: 10) {
                            Text("⭐")
                                .font(.system(size: 28))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("합격 준비 완료!")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundStyle(Color(accentHex: "10B981"))
                                Text("지금 JLPT N3에 응시해 보세요")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(Color(accentHex: "10B981").opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        VStack(spacing: 6) {
                            Text("매일 꾸준히 학습하면")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textTertiary)
                            Text("합격까지의 날짜가 계산됩니다")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Theme.surfaceSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
            }
        }
    }

    // MARK: - 합격 조건

    private var passCriteriaSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("합격 조건")

            VStack(spacing: 12) {
                // 두 조건을 나란히 — 하나라도 못 채우면 불합격
                HStack(spacing: 12) {
                    criteriaCard(
                        caption: "총점",
                        value: "95",
                        unit: "/ 180점",
                        detail: "3개 과목 합계",
                        color: "D4A373"
                    )
                    criteriaCard(
                        caption: "과목별 기준점",
                        value: "19",
                        unit: "/ 60점",
                        detail: "3개 과목 각각",
                        color: "F59E0B"
                    )
                }

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(accentHex: "F59E0B"))
                    Text("총점이 95점을 넘어도 한 과목이라도 19점 미만이면 불합격입니다. 약한 과목을 버리는 전략은 통하지 않습니다.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineSpacing(3)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(accentHex: "F59E0B").opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // 채점 과목 구성 + 시험 시간
                VStack(spacing: 0) {
                    examRow(name: "언어지식 (문자·어휘·문법)", jp: "言語知識",
                            score: "0~60점", time: "30분 + 70분", color: "BE123C")
                    Divider().background(Theme.stroke)
                    examRow(name: "독해", jp: "読解",
                            score: "0~60점", time: "문법과 합쳐 70분", color: "7C3AED")
                    Divider().background(Theme.stroke)
                    examRow(name: "청해", jp: "聴解",
                            score: "0~60점", time: "40분", color: "0891B2")
                }
                .padding(.vertical, 4)
                .background(Theme.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    private func criteriaCard(caption: String, value: String, unit: String,
                              detail: String, color: String) -> some View {
        let c = Color(accentHex: color)
        return VStack(alignment: .leading, spacing: 6) {
            Text(caption)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(c)
                Text(unit)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(c.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(c.opacity(0.22), lineWidth: 1))
    }

    private func examRow(name: String, jp: String, score: String,
                         time: String, color: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(accentHex: color))
                .frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(jp) · \(time)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Text(score)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - 섹션별 자가 진단

    private var selfCheckSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("이 정도면 합격선을 넘었다")

            Text("과목별 기준점 19점을 넘겼다고 봐도 되는 체감 기준입니다. 항목을 모두 «예»라고 답할 수 있으면 그 과목은 합격선 안쪽입니다.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textTertiary)
                .lineSpacing(3)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            VStack(spacing: 12) {
                ForEach(scoringSections, id: \.name) { section in
                    selfCheckCard(section)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    private func selfCheckCard(_ section: ScoringSection) -> some View {
        let c = Color(accentHex: section.color)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(c)
                Text(section.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(section.japanese)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Text("19점")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(c)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(c.opacity(0.15))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 7) {
                ForEach(section.passCheckpoints, id: \.self) { item in
                    checkRow(item, color: c, filled: true)
                }
            }

            // 앱이 추적하는 과목이면 현재 진도를 기준과 나란히 보여준다
            if section.trackedByApp {
                VStack(alignment: .leading, spacing: 6) {
                    Text("지금 내 진도")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                    HStack(spacing: 14) {
                        progressAgainstTarget(label: "어휘",
                                              current: store.vocabReadiness, target: 0.6)
                        progressAgainstTarget(label: "문법",
                                              current: store.grammarReadiness, target: 0.6)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                    Text("이 과목은 앱이 진도를 추적하지 않습니다. 기출·교재로 직접 훈련하세요.")
                        .font(.system(size: 11))
                }
                .foregroundStyle(Theme.textTertiary)
            }

            Divider().background(Theme.stroke)

            VStack(alignment: .leading, spacing: 7) {
                Text("안정권 (35점 안팎)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                ForEach(section.stableCheckpoints, id: \.self) { item in
                    checkRow(item, color: c, filled: false)
                }
            }
        }
        .padding(16)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(c.opacity(0.20), lineWidth: 1))
    }

    private func checkRow(_ text: String, color: Color, filled: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: filled ? "checkmark.circle.fill" : "star.circle")
                .font(.system(size: 13))
                .foregroundStyle(color.opacity(filled ? 0.9 : 0.6))
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(filled ? Theme.textSecondary : Theme.textTertiary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func progressAgainstTarget(label: String, current: Double, target: Double) -> some View {
        let reached = current >= target
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Text("\(Int(current * 100))%")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(reached ? Color(accentHex: "10B981") : Theme.textPrimary)
                Text("/ \(Int(target * 100))%")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textQuaternary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.track)
                    Capsule()
                        .fill(reached ? Color(accentHex: "10B981") : Theme.brand)
                        .frame(width: geo.size.width * min(current / target, 1))
                        .animation(.easeInOut(duration: 0.8), value: current)
                }
            }
            .frame(height: 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Milestone Roadmap

    private var milestoneRoadmap: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("마일스톤 로드맵")

            VStack(spacing: 0) {
                ForEach(Array(milestones.enumerated()), id: \.offset) { idx, milestone in
                    milestoneRow(milestone, index: idx, isLast: idx == milestones.count - 1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    private func milestoneRow(_ milestone: Milestone, index: Int, isLast: Bool) -> some View {
        let isUnlocked = store.readinessScore >= milestone.threshold
        let isCurrent = currentMilestoneIndex == index
        let color = Color(accentHex: milestone.color)

        return HStack(alignment: .top, spacing: 16) {
            // Timeline line + circle
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? color : Theme.track)
                        .frame(width: 44, height: 44)

                    if isUnlocked {
                        Text(milestone.emoji)
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textQuaternary)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(isCurrent ? color : Color.clear, lineWidth: 2.5)
                        .padding(-4)
                )

                if !isLast {
                    Rectangle()
                        .fill(isUnlocked ? color.opacity(0.4) : Theme.stroke)
                        .frame(width: 2, height: 44)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(milestone.title)
                        .font(.system(size: 16, weight: isCurrent ? .black : .semibold))
                        .foregroundStyle(isUnlocked ? Theme.textPrimary : Theme.textQuaternary)

                    if isCurrent {
                        Text("현재")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(color)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(color.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Text("\(Int(milestone.threshold * 100))%")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(isUnlocked ? color : Theme.textQuaternary)
                }

                Text(milestone.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(isUnlocked ? Theme.textSecondary : Theme.textQuaternary)

                // Progress bar towards next milestone
                if isCurrent {
                    let next = milestones[safe: index + 1]
                    let from = milestone.threshold
                    let to = next?.threshold ?? 1.0
                    let progress = to > from
                        ? (store.readinessScore - from) / (to - from)
                        : 1.0

                    VStack(alignment: .leading, spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Theme.track)
                                Capsule()
                                    .fill(color)
                                    .frame(width: geo.size.width * min(max(progress, 0), 1))
                                    .animation(.easeInOut(duration: 0.8), value: progress)
                            }
                        }
                        .frame(height: 6)

                        if let next = next {
                            Text("다음: \(next.emoji) \(next.title)")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textQuaternary)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.bottom, isLast ? 0 : 28)
            .padding(.top, 8)
        }
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("영역별 준비도")

            HStack(spacing: 12) {
                categoryCard(
                    title: "어휘",
                    icon: "character.book.closed.ja",
                    readiness: store.vocabReadiness,
                    total: store.vocabCards.count,
                    mastered: store.vocabCards.filter { $0.interval >= 7 }.count,
                    color: "BE123C"
                )
                categoryCard(
                    title: "문법",
                    icon: "text.book.closed",
                    readiness: store.grammarReadiness,
                    total: store.grammarCards.count,
                    mastered: store.grammarCards.filter { $0.interval >= 7 }.count,
                    color: "1D4ED8"
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    private func categoryCard(title: String, icon: String, readiness: Double,
                               total: Int, mastered: Int, color: String) -> some View {
        let c = Color(accentHex: color)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(c)
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(Int(readiness * 100))%")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(c)
            }

            // Segmented bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.track)
                    Capsule()
                        .fill(c)
                        .frame(width: geo.size.width * readiness)
                        .animation(.easeInOut(duration: 1.0), value: readiness)
                }
            }
            .frame(height: 8)

            HStack {
                Label("\(mastered) 숙지", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(c.opacity(0.8))
                Spacer()
                Text("/ \(total)개")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textQuaternary)
            }
        }
        .padding(16)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(c.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("학습 현황")

            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 10) {
                statCell(value: "\(store.stats.streak)", label: "연속 학습일", icon: "flame.fill", color: "F59E0B")
                statCell(value: "\(store.stats.totalReviewed)", label: "누적 복습", icon: "arrow.clockwise", color: "3B82F6")
                statCell(value: "\(store.masteredCards)", label: "완전 숙지", icon: "star.fill", color: "D4A373")
                statCell(value: "\(store.learnedCards)", label: "장기 기억", icon: "brain", color: "8B5CF6")
                statCell(value: "\(store.reviewingCards)", label: "복습 중", icon: "clock.fill", color: "10B981")
                statCell(value: "\(store.newCards.count)", label: "미학습", icon: "sparkles", color: "6B7280")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    private func statCell(value: String, label: String, icon: String, color: String) -> some View {
        let c = Color(accentHex: color)
        return VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(c)
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(c.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Theme.textTertiary)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 12)
    }

    private var currentMilestoneIndex: Int {
        var idx = 0
        for (i, m) in milestones.enumerated() {
            if store.readinessScore >= m.threshold { idx = i }
        }
        // If not yet at next milestone, current is idx
        // If already past last, stay at last
        if idx < milestones.count - 1 && store.readinessScore < milestones[idx + 1].threshold {
            return idx
        }
        return idx
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
