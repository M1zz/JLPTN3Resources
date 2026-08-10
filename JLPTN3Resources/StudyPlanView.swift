import SwiftUI

// MARK: - Data Models

struct StudyPhase: Identifiable {
    let id = UUID()
    let number: Int
    let period: String
    let title: String
    let subtitle: String
    let color: Color
    let goals: [String]
    let weeklySchedule: [(day: String, content: String)]
    let resources: [String]
}

struct ExamSection: Identifiable {
    let id = UUID()
    let name: String
    let japaneseLabel: String
    let score: Int
    let strategy: String
    let icon: String
    let color: Color
}

// MARK: - StudyPlanView

struct StudyPlanView: View {
    @State private var expandedPhase: UUID? = nil

    let phases: [StudyPhase] = [
        StudyPhase(
            number: 1,
            period: "4~6월",
            title: "기초 다지기",
            subtitle: "基礎固め",
            color: Color(accentHex: "BE123C"),
            goals: [
                "N3 한자 650자 완성",
                "N3 핵심 어휘 1,500개 습득",
                "N3 문법 패턴 50% 학습"
            ],
            weeklySchedule: [
                ("월·수·금", "어휘 20개 + 한자 10자 암기"),
                ("화·목", "문법 패턴 3~5개 + 예문 작성"),
                ("토", "주간 복습 (플래시카드 전체 회독)"),
                ("일", "짧은 읽기 지문 1~2개 (NHK Web Easy)")
            ],
            resources: ["Anki N3 덱", "Takoboto", "新완全마스터 N3 어휘", "新완全마스터 N3 문법"]
        ),
        StudyPhase(
            number: 2,
            period: "7~9월",
            title: "실력 구축",
            subtitle: "実力養成",
            color: Color(accentHex: "1D4ED8"),
            goals: [
                "N3 어휘 3,750개 완성",
                "문법 패턴 100% 학습",
                "독해·청해 기본기 확립"
            ],
            weeklySchedule: [
                ("월·수·금", "문법 심화 + 독해 지문 1개"),
                ("화·목", "청해 연습 (N3 팟캐스트/유튜브)"),
                ("토", "독해 집중 (N3 기출 독해 문제)"),
                ("일", "청해 집중 + 1주 오답 노트 정리")
            ],
            resources: ["新완全마스터 N3 독해", "日本語の森", "JLPT Sensei", "Bunpro"]
        ),
        StudyPhase(
            number: 3,
            period: "10~12월",
            title: "실전 완성",
            subtitle: "実戦完成",
            color: Color(accentHex: "B45309"),
            goals: [
                "기출 모의고사 5회 이상 완료",
                "취약 섹션 집중 보강",
                "시험 컨디션 관리"
            ],
            weeklySchedule: [
                ("10월", "주 1회 실전 모의고사 + 오답 분석"),
                ("11월", "취약 섹션 2배 집중 + 주 2회 모의고사"),
                ("12월 1~2주", "가벼운 복습 + 청해 매일 30분"),
                ("시험 전날", "충분한 수면, 과부하 금지 ⚡")
            ],
            resources: ["JLPT 공식 기출문제", "Try! N3 교재", "Nihongo-pro 모의시험"]
        )
    ]

    // N3 채점 과목은 3개. 문자·어휘와 문법은 «언어지식» 하나로 묶여 60점 만점이다.
    let examSections: [ExamSection] = [
        ExamSection(name: "언어지식 (문자·어휘·문법)", japaneseLabel: "言語知識", score: 60,
                    strategy: "한국어 한자 활용 → 빠른 습득. 한자어 40~50% 유추 가능",
                    icon: "character.book.closed.ja", color: Color(accentHex: "BE123C")),
        ExamSection(name: "독해", japaneseLabel: "読解", score: 60,
                    strategy: "전체 파악 → 세부 → 문제 순서로 읽기. 시간 배분 필수",
                    icon: "doc.text", color: Color(accentHex: "7C3AED")),
        ExamSection(name: "청해", japaneseLabel: "聴解", score: 60,
                    strategy: "매일 일본어 듣기 습관이 핵심. Shadowing 병행 권장",
                    icon: "headphones", color: Color(accentHex: "0891B2"))
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    planHeader

                    VStack(alignment: .leading, spacing: 20) {
                        // Exam info
                        examInfoCard

                        // Phases
                        sectionHeader(title: "3단계 로드맵", jp: "3段階ロードマップ")
                        ForEach(phases) { phase in
                            PhaseCard(phase: phase, isExpanded: expandedPhase == phase.id) {
                                withAnimation(.spring(response: 0.35)) {
                                    expandedPhase = expandedPhase == phase.id ? nil : phase.id
                                }
                            }
                        }

                        // Exam sections
                        sectionHeader(title: "섹션별 전략", jp: "セクション別戦略")
                        ForEach(examSections) { section in
                            ExamSectionCard(section: section)
                        }

                        // Korean advantage
                        koreanAdvantageCard

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .background(Theme.background)
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header

    private var planHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Theme.heroBanner

            Text("合格")
                .font(.system(size: 100, weight: .black))
                .foregroundStyle(Color.white.opacity(0.06))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)

            VStack(alignment: .leading, spacing: 6) {
                Text("2026 하반기 학습 플랜")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color(hex: "E0B98C"))

                Text("N3\n합격 로드맵")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(Theme.onHeroBanner)
                    .lineSpacing(2)
            }
            .padding(20)
        }
        .frame(height: 150)
    }

    // MARK: - Exam Info Card

    private var examInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("시험 정보", systemImage: "info.circle")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                infoChip(icon: "calendar", title: "목표 시험", value: "2026년 12월")
                infoChip(icon: "clock", title: "남은 기간", value: "약 9개월")
            }
            HStack(spacing: 12) {
                infoChip(icon: "checkmark.seal", title: "합격 기준", value: "총점 95점 이상")
                infoChip(icon: "slider.horizontal.3", title: "각 섹션", value: "19점 이상")
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Theme.shadow, radius: 6, x: 0, y: 2)
    }

    private func infoChip(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.brand)
                .frame(width: 28, height: 28)
                .background(Theme.brand.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Korean Advantage

    private var koreanAdvantageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("한국인 강점 포인트", systemImage: "star.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(hex: "E0B98C"))

            ForEach([
                ("🏯", "문법 구조", "한국어와 어순이 동일 → 문법 학습 속도 ↑"),
                ("📖", "한자어", "한국어 한자 지식으로 N3 어휘 40~50% 유추 가능"),
                ("🔗", "조사 체계", "한국어 조사와 유사한 일본어 조사 구조")
            ], id: \.1) { emoji, title, desc in
                HStack(alignment: .top, spacing: 12) {
                    Text(emoji).font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.system(size: 13, weight: .bold))
                        Text(desc).font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.heroBanner)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "E0B98C").opacity(0.35), lineWidth: 1)
        )
    }

    private func sectionHeader(title: String, jp: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Theme.brand)
                .frame(width: 3, height: 20)
            Text(title)
                .font(.system(size: 17, weight: .black))
            Text(jp)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - PhaseCard

struct PhaseCard: View {
    let phase: StudyPhase
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack(alignment: .center, spacing: 12) {
                    // Phase number circle
                    ZStack {
                        Circle()
                            .fill(phase.color)
                            .frame(width: 40, height: 40)
                        Text("\(phase.number)")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(Color.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(phase.period)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(phase.color)
                        Text(phase.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(phase.subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 16) {
                    // Goals
                    VStack(alignment: .leading, spacing: 8) {
                        Label("목표", systemImage: "target")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)

                        ForEach(phase.goals, id: \.self) { goal in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(phase.color)
                                    .frame(width: 6, height: 6)
                                Text(goal)
                                    .font(.system(size: 13))
                            }
                        }
                    }

                    Divider()

                    // Weekly schedule
                    VStack(alignment: .leading, spacing: 8) {
                        Label("주간 루틴", systemImage: "calendar.badge.clock")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)

                        ForEach(phase.weeklySchedule, id: \.day) { item in
                            HStack(alignment: .top, spacing: 0) {
                                Text(item.day)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(phase.color)
                                    .frame(width: 70, alignment: .leading)
                                Text(item.content)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }

                    Divider()

                    // Resources
                    VStack(alignment: .leading, spacing: 8) {
                        Label("추천 교재·도구", systemImage: "books.vertical")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(phase.resources, id: \.self) { resource in
                                    Text(resource)
                                        .font(.system(size: 11, weight: .bold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(phase.color.opacity(0.1))
                                        .foregroundStyle(phase.color)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Theme.shadow, radius: 6, x: 0, y: 2)
    }
}

// MARK: - ExamSectionCard

struct ExamSectionCard: View {
    let section: ExamSection

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: section.icon)
                .font(.system(size: 20))
                .foregroundStyle(section.color)
                .frame(width: 44, height: 44)
                .background(section.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(section.name)
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Text("\(section.score)점")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(section.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(section.color.opacity(0.1))
                        .clipShape(Capsule())
                }
                Text(section.strategy)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Theme.shadow, radius: 4, x: 0, y: 1)
    }
}

#Preview {
    StudyPlanView()
}
