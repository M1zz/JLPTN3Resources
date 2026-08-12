import Foundation

// MARK: - 합격 확률 계산
//
// 「지금 시험을 보면 붙을까」를 앱에 쌓인 풀이 기록으로 추정한다.
//
// 두 가지 불확실성을 나눠서 다룬다.
//  1) 실력 자체를 모른다        — 20문항 중 14개를 맞혔다고 실력이 정확히 70%인 것은 아니다.
//                                 → 정답률 p에 대한 베타 사후분포로 둔다.
//  2) 실력을 알아도 점수는 흔들린다 — 같은 실력으로도 그날 문제에 따라 점수가 달라진다.
//                                 → 실제 시험 문항 수만큼의 이항분포로 둔다.
//
// 둘을 합치면 점수의 예측분포는 베타-이항분포가 된다. 표본추출(몬테카를로) 없이
// 닫힌 식으로 전부 더할 수 있는 크기(문항 58·16·28)라 정확히 계산한다.
// 매번 같은 값이 나와야 하므로 난수는 쓰지 않는다.

struct PassPrediction {

    // MARK: 모델 상수 — 근거를 화면에 그대로 밝힌다

    /// 실제 N3 시험의 과목별 문항 수 (言語知識 文字語彙35+文法23 / 読解16 / 聴解28)
    static func examItems(_ subject: ExamSubject) -> Int {
        switch subject {
        case .language:  return 58
        case .reading:   return 16
        case .listening: return 28
        }
    }

    /// 선택지 수 — 모르는 문제도 찍으면 이 확률로 맞는다
    static let guessRate = 0.25

    /// N3 합격에 필요하다고 보는 누적 어휘 수 (N5~N3). 공식 목록은 없고 기출 분석에서 나온 추정치다.
    static let requiredVocabulary = 3700

    /// 어휘장이 실제 시험 어휘를 덮는 정도 — 상수로 박아 두지 않고 실제 카드 수에서 구한다.
    ///
    /// 예전에는 0.85로 박혀 있었는데, 그때 어휘 카드는 392장(필요량의 11%)이었다.
    /// 진도를 100% 채워도 시험 어휘의 85%를 안다고 계산하고 있었으니 언어지식 점수가 부풀었다.
    /// 카드를 늘리면 이 값도 따라 오른다.
    ///
    /// 낱말 수의 단순 비율로 본다. 어휘장이 빈도순이라 실제 체감 커버리지는 이보다 높겠지만,
    /// 얼마나 높은지는 잴 자료가 없으므로 낮게 잡는 쪽을 택한다.
    static var deckCoverage: Double {
        min(1.0, Double(LearningCard.vocabularyWordCount) / Double(requiredVocabulary))
    }

    /// 사전 지식의 무게 — 「가상의 문항 수」로 환산한 값.
    /// 실제로 푼 문항이 이보다 많아지면 사전 지식보다 실측이 앞선다.
    static let priorWeight = 8.0

    /// 앱 문항 한 개를 실제 시험 문항 몇 개어치 증거로 볼 것인가.
    ///
    /// 앱 문항은 자체 제작이고 시간 제한 없이 풀며, 같은 지문을 다시 열면 답이 기억난다.
    /// 실제 시험과 난이도가 같다는 보장이 없으므로 증거로서 값을 깎는다.
    /// 평균을 한쪽으로 밀지는 않는다 — 어느 쪽으로 얼마나 치우쳤는지는 잴 자료가 없다.
    /// 대신 폭을 넓혀 「아직 모른다」를 그대로 드러낸다.
    static let evidenceDiscount = 0.6

    /// 독해·청해의 사전분포 무게. 4지선다를 찍는 수준보다 조금 나은 쪽에 중심을 둔다.
    /// 4문항을 다 맞혔다고 실력이 100%라고 믿어 버리지 않게 하는 장치.
    static let practicePriorWeight = 6.0

    // MARK: 과목별 추정

    struct SubjectEstimate: Identifiable {
        let subject: ExamSubject
        /// 실제로 푼 문항 수와 맞힌 수 (앱 기록)
        let solved: Int
        let correct: Int
        /// 정답률 사후분포 Beta(alpha, beta)
        let alpha: Double
        let beta: Double
        /// 점수(0~60)의 예측분포 — index가 곧 원점수 k
        let scoreDistribution: [(score: Double, probability: Double)]

        var id: String { subject.id }

        /// 추정 정답률 (사후 평균)
        var expectedAccuracy: Double { alpha / (alpha + beta) }
        /// 기대 점수
        var expectedScore: Double {
            scoreDistribution.reduce(0) { $0 + $1.score * $1.probability }
        }
        /// 이 과목이 기준점(19점)을 넘을 확률
        var passLineProbability: Double {
            scoreDistribution.filter { $0.score >= Double(subject.passLine) }
                .reduce(0) { $0 + $1.probability }
        }
        /// 80% 예측 구간
        var interval80: (low: Double, high: Double) { quantileRange(0.10, 0.90) }

        func quantileRange(_ lo: Double, _ hi: Double) -> (low: Double, high: Double) {
            var cumulative = 0.0
            var low = scoreDistribution.first?.score ?? 0
            var high = scoreDistribution.last?.score ?? 60
            var lowFound = false
            for bin in scoreDistribution {
                cumulative += bin.probability
                if !lowFound, cumulative >= lo { low = bin.score; lowFound = true }
                if cumulative >= hi { high = bin.score; break }
            }
            return (low, high)
        }
    }

    let estimates: [SubjectEstimate]
    /// 합격 확률 — 「총점 95점 이상」과 「전 과목 19점 이상」을 동시에 만족할 확률
    let passProbability: Double
    /// 두 조건을 따로 본 확률 (어느 쪽이 발목을 잡는지 보여 주려고)
    let totalScoreProbability: Double
    let allSubjectsProbability: Double
    let expectedTotal: Double
    /// 총점의 80% 예측 구간
    let totalInterval80: (low: Double, high: Double)
    /// 근거가 된 문항 수 — 적으면 예측을 믿을 수 없다
    let evidenceCount: Int

    func estimate(_ subject: ExamSubject) -> SubjectEstimate {
        estimates.first { $0.subject == subject }!
    }

    /// 예측을 내놓을 만큼 자료가 있는가.
    /// 독해·청해를 한 문항도 풀지 않았다면 그건 예측이 아니라 사전 가정일 뿐이다.
    var hasEnoughEvidence: Bool { evidenceCount >= 10 }

    /// 가장 불안한 과목 — 기준점을 넘을 확률이 가장 낮은 쪽
    var weakestSubject: SubjectEstimate {
        estimates.min { $0.passLineProbability < $1.passLineProbability }!
    }

    // MARK: 만들기

    /// - Parameters:
    ///   - practice: 독해·청해·모의고사 풀이 기록
    ///   - languageReadiness: 어휘·문법 SRS 진도 (0~1) — 언어지식의 사전 지식으로 쓴다
    init(practice: PracticeStore, languageReadiness: Double) {
        // 사전 분포의 중심: 아는 만큼 맞히고, 모르는 것은 찍는다
        let known = PassPrediction.deckCoverage * languageReadiness
        let priorMean = known + (1 - known) * PassPrediction.guessRate

        var estimates: [SubjectEstimate] = []
        var evidence = 0

        for subject in ExamSubject.allCases {
            let record = practice.record(for: subject)
            evidence += record.solved

            // 언어지식만 SRS 진도를 사전 지식으로 삼는다.
            // 독해·청해는 앱이 진도를 따로 재지 않으므로 「찍기」를 중심으로 둔 약한 사전분포.
            let mean = subject == .language ? priorMean : PassPrediction.guessRate + 0.15
            let weight = subject == .language
                ? PassPrediction.priorWeight : PassPrediction.practicePriorWeight

            // 푼 문항은 증거로서 값을 깎아 센다 (0.6문항어치)
            let discount = PassPrediction.evidenceDiscount
            let alpha = mean * weight + Double(record.correct) * discount
            let beta = (1 - mean) * weight + Double(record.solved - record.correct) * discount

            let n = PassPrediction.examItems(subject)
            let distribution = (0...n).map { k in
                (score: 60.0 * Double(k) / Double(n),
                 probability: PassPrediction.betaBinomial(k: k, n: n, alpha: alpha, beta: beta))
            }
            estimates.append(SubjectEstimate(subject: subject,
                                             solved: record.solved,
                                             correct: record.correct,
                                             alpha: alpha, beta: beta,
                                             scoreDistribution: distribution))
        }

        self.estimates = estimates
        self.evidenceCount = evidence

        // 세 과목을 합성한다. 과목끼리 독립이라고 본다 —
        // 실제로는 같은 사람의 실력이라 양의 상관이 있지만, 그 상관을 잴 자료가 없다.
        let language  = estimates.first { $0.subject == .language }!.scoreDistribution
        let reading   = estimates.first { $0.subject == .reading }!.scoreDistribution
        let listening = estimates.first { $0.subject == .listening }!.scoreDistribution

        var pass = 0.0, totalOK = 0.0, subjectsOK = 0.0, mean = 0.0
        var totalBins: [Double: Double] = [:]   // 총점 → 확률 (구간 계산용, 1점 단위로 모음)

        for l in language where l.probability > 1e-12 {
            let lPass = l.score >= 19
            for r in reading where r.probability > 1e-12 {
                let rPass = r.score >= 19
                let lr = l.probability * r.probability
                for s in listening where s.probability > 1e-12 {
                    let p = lr * s.probability
                    let total = l.score + r.score + s.score
                    let everySubject = lPass && rPass && s.score >= 19
                    let totalPass = total >= 95

                    mean += total * p
                    if totalPass { totalOK += p }
                    if everySubject { subjectsOK += p }
                    if totalPass && everySubject { pass += p }
                    totalBins[total.rounded(), default: 0] += p
                }
            }
        }

        self.passProbability = pass
        self.totalScoreProbability = totalOK
        self.allSubjectsProbability = subjectsOK
        self.expectedTotal = mean

        // 총점 80% 구간
        var low = 0.0, high = 180.0, cumulative = 0.0, lowFound = false
        for score in totalBins.keys.sorted() {
            cumulative += totalBins[score] ?? 0
            if !lowFound, cumulative >= 0.10 { low = score; lowFound = true }
            if cumulative >= 0.90 { high = score; break }
        }
        self.totalInterval80 = (low, high)
    }

    // MARK: 베타-이항 확률

    /// P(k개 정답 | 문항 n개, 정답률 ~ Beta(alpha, beta))
    static func betaBinomial(k: Int, n: Int, alpha: Double, beta: Double) -> Double {
        let logChoose = lgamma(Double(n + 1)) - lgamma(Double(k + 1)) - lgamma(Double(n - k + 1))
        let logNumerator = logBeta(Double(k) + alpha, Double(n - k) + beta)
        let logDenominator = logBeta(alpha, beta)
        return exp(logChoose + logNumerator - logDenominator)
    }

    private static func logBeta(_ a: Double, _ b: Double) -> Double {
        lgamma(a) + lgamma(b) - lgamma(a + b)
    }
}
