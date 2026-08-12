import SwiftUI

// MARK: - 합격 확률
//
// 숫자 하나만 크게 보여 주면 그 숫자를 믿게 된다.
// 그래서 확률과 함께 «어떤 근거로, 얼마나 흔들리는 값인지»를 같은 화면에 둔다.

struct PassPredictionView: View {
    @EnvironmentObject private var learning: LearningStore
    @EnvironmentObject private var practice: PracticeStore

    @State private var showAssumptions = false

    private var prediction: PassPrediction {
        PassPrediction(practice: practice, languageReadiness: learning.readinessScore)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    let p = prediction

                    if p.hasEnoughEvidence {
                        heroCard(p)
                        conditionCard(p)
                    } else {
                        notEnoughCard(p)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("과목별 예상 점수", icon: "chart.bar.xaxis")
                        ForEach(p.estimates) { e in
                            subjectCard(e)
                        }
                    }

                    if p.hasEnoughEvidence {
                        adviceCard(p)
                    }

                    assumptionsCard(p)
                }
                .padding(16)
            }
        }
        .navigationTitle("합격 확률")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: 확률

    private func heroCard(_ p: PassPrediction) -> some View {
        let percent = Int((p.passProbability * 100).rounded())
        let accent = Color(accentHex: percent >= 70 ? "10B981" : (percent >= 40 ? "D97706" : "DC2626"))
        return VStack(spacing: 12) {
            Text("지금 시험을 본다면")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(percent)")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundStyle(accent)
                Text("%")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(accent)
            }

            Text("합격 확률")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.textSecondary)

            Divider().overlay(Theme.stroke)

            HStack(spacing: 0) {
                statColumn("예상 총점", "\(Int(p.expectedTotal.rounded()))점")
                Rectangle().fill(Theme.stroke).frame(width: 1, height: 30)
                statColumn("흔히 나올 범위",
                           "\(Int(p.totalInterval80.low))–\(Int(p.totalInterval80.high))점")
                Rectangle().fill(Theme.stroke).frame(width: 1, height: 30)
                statColumn("합격선", "95점")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Theme.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func statColumn(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textQuaternary)
        }
        .frame(maxWidth: .infinity)
    }

    /// 합격은 두 조건을 «둘 다» 만족해야 한다 — 어느 쪽이 발목을 잡는지 보여 준다
    private func conditionCard(_ p: PassPrediction) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("두 조건을 모두 넘어야 합격", icon: "checklist")

            conditionRow(name: "총점 95점 이상",
                         probability: p.totalScoreProbability)
            conditionRow(name: "전 과목 각각 19점 이상",
                         probability: p.allSubjectsProbability)

            let binding = p.totalScoreProbability < p.allSubjectsProbability
                ? "총점" : "과목별 기준점"
            Text("지금은 «\(binding)» 쪽이 더 아슬아슬합니다.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func conditionRow(name: String, probability: Double) -> some View {
        HStack(spacing: 10) {
            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 8)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.track)
                    Capsule().fill(Theme.brand)
                        .frame(width: geo.size.width * probability)
                }
            }
            .frame(width: 80, height: 6)
            Text("\(Int((probability * 100).rounded()))%")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(Theme.brand)
                .frame(width: 38, alignment: .trailing)
        }
    }

    // MARK: 자료가 모자랄 때

    private func notEnoughCard(_ p: PassPrediction) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 14, weight: .bold))
                Text("아직 확률을 내기 어렵습니다")
                    .font(.system(size: 15, weight: .black))
            }
            .foregroundStyle(Theme.textPrimary)

            Text("지금까지 푼 문항이 \(p.evidenceCount)개입니다. 10개는 넘어야 «추측»이 아니라 «추정»이 됩니다. "
                 + "연습 탭의 독해·청해를 풀거나 모의고사를 한 번 보고 오세요.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("아래 과목별 점수는 지금 있는 자료(학습 진도)만으로 그린 «출발선»입니다.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textQuaternary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: 과목별

    private func subjectCard(_ e: PassPrediction.SubjectEstimate) -> some View {
        let color = Color(accentHex: e.subject.colorHex)
        let interval = e.interval80
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: e.subject.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)
                Text(e.subject.name)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 4)
                Text("\(Int(e.expectedScore.rounded()))")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(color)
                Text("/ 60")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textQuaternary)
            }

            scoreBar(interval: interval, expected: e.expectedScore, color: color)

            HStack(spacing: 6) {
                Text("흔히 \(Int(interval.low))–\(Int(interval.high))점")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                Spacer(minLength: 4)
                Text("19점 넘을 확률 \(Int((e.passLineProbability * 100).rounded()))%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(e.passLineProbability >= 0.9
                                     ? Color(accentHex: "16A34A") : Color(accentHex: "D97706"))
            }

            Text(evidenceText(e))
                .font(.system(size: 10))
                .foregroundStyle(Theme.textQuaternary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    /// 0~60점 자 위에 80% 구간을 띠로, 기대 점수를 점으로, 19점을 선으로 그린다
    private func scoreBar(interval: (low: Double, high: Double),
                          expected: Double, color: Color) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let x = { (score: Double) in w * score / 60 }
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.track)
                Capsule().fill(color.opacity(0.35))
                    .frame(width: max(2, x(interval.high) - x(interval.low)))
                    .offset(x: x(interval.low))
                Circle().fill(color)
                    .frame(width: 10, height: 10)
                    .offset(x: min(max(x(expected) - 5, 0), w - 10))
                // 기준점 19
                Rectangle().fill(Theme.textPrimary.opacity(0.55))
                    .frame(width: 1.5, height: 16)
                    .offset(x: x(19))
            }
        }
        .frame(height: 16)
    }

    private func evidenceText(_ e: PassPrediction.SubjectEstimate) -> String {
        guard e.solved > 0 else {
            return e.subject == .language
                ? "근거: 어휘·문법 학습 진도 (모의고사를 보면 정확해집니다)"
                : "근거: 아직 없음 — 연습을 풀면 여기에 반영됩니다"
        }
        let rate = Int((Double(e.correct) / Double(e.solved) * 100).rounded())
        return "근거: 푼 문항 \(e.solved)개 중 \(e.correct)개 정답 (\(rate)%)"
    }

    // MARK: 무엇을 하면 오르나

    private func adviceCard(_ p: PassPrediction) -> some View {
        let weak = p.weakestSubject
        return VStack(alignment: .leading, spacing: 8) {
            sectionTitle("확률을 가장 크게 올리는 일", icon: "arrow.up.right")

            Text("지금은 «\(weak.subject.name)»이 가장 불안합니다 — 기준점 19점을 넘을 확률이 "
                 + "\(Int((weak.passLineProbability * 100).rounded()))%입니다.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(weak.solved < 10
                 ? "이 과목은 푼 문항이 \(weak.solved)개뿐이라 확률이 넓게 벌어져 있습니다. "
                   + "몇 문항만 더 풀어도 예측이 뚜렷해집니다."
                 : "한 과목이라도 19점에 못 미치면 총점과 무관하게 불합격입니다. "
                   + "총점을 올리는 것보다 이 과목을 끌어올리는 편이 합격 확률을 더 많이 올립니다.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.brand.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: 이 숫자를 어디까지 믿을 것인가

    private func assumptionsCard(_ p: PassPrediction) -> some View {
        DisclosureGroup(isExpanded: $showAssumptions) {
            VStack(alignment: .leading, spacing: 10) {
                assumption("이 앱 문제 기준입니다",
                           "지문·문항·대본은 전부 자체 제작이라 실제 기출과 난이도가 같다는 보장이 없습니다. "
                           + "그래서 푼 문항 하나를 \(Int(PassPrediction.evidenceDiscount * 100))%짜리 증거로만 셉니다.")
                assumption("시간 압박이 빠져 있습니다",
                           "실제 시험은 언어지식·독해 100분, 청해 40분 안에 풀어야 합니다. "
                           + "앱에서는 시간을 재지 않으므로 실제 점수는 예측 범위의 아래쪽에 가까울 수 있습니다.")
                assumption("점수 환산은 단순 비례입니다",
                           "실제 JLPT는 문항 난이도를 반영한 척도점수를 씁니다. "
                           + "여기서는 정답률 × 60점으로 환산합니다.")
                assumption("언어지식은 진도로 추정합니다",
                           "아는 것은 맞히고 모르는 것은 4지선다로 찍는다고 봅니다. "
                           + "어휘장이 실제 시험 어휘의 \(Int(PassPrediction.deckCoverage * 100))%를 덮는다고 가정했습니다. "
                           + "모의고사를 볼수록 이 가정 대신 실제 성적이 쓰입니다.")
                assumption("과목끼리 독립이라고 봅니다",
                           "실제로는 한 사람의 실력이라 세 과목이 함께 움직이지만, "
                           + "그 상관을 잴 자료가 앱에 없습니다.")
                assumption("계산 방법",
                           "과목마다 정답률의 사후분포(베타)를 두고, 실제 시험 문항 수"
                           + "(언어지식 \(PassPrediction.examItems(.language)) · 독해 \(PassPrediction.examItems(.reading)) · 청해 \(PassPrediction.examItems(.listening)))"
                           + "만큼의 이항분포로 점수를 펼친 뒤, 세 과목을 합쳐 두 합격 조건을 모두 만족할 확률을 더했습니다.")
            }
            .padding(.top, 10)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12, weight: .bold))
                Text("이 숫자를 어디까지 믿을 것인가")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(Theme.textSecondary)
        }
        .tint(Theme.brand)
        .padding(16)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func assumption(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(body)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionTitle(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
            Text(text)
                .font(.system(size: 14, weight: .black))
        }
        .foregroundStyle(Theme.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
