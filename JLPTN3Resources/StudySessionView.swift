import SwiftUI
import AVFoundation

// MARK: - Speech Manager

/// 일본어 낭독 — 학습 세션과 쓰기 연습(듣기 모드)이 함께 쓴다
class SpeechManager: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.42
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - Study Session View

struct StudySessionView: View {
    let cards: [LearningCard]
    @ObservedObject var store: LearningStore

    @State private var currentIndex: Int = 0
    /// 이 카드에서 고른 보기 (nil = 아직 안 고름). 고르는 순간 정답이 열린다.
    @State private var picked: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var isAnimating: Bool = false
    @State private var sessionFinished: Bool = false
    @State private var correctCount: Int = 0
    @StateObject private var speech = SpeechManager()
    @Environment(\.dismiss) private var dismiss

    var currentCard: LearningCard? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    var progress: Double {
        guard !cards.isEmpty else { return 1 }
        return Double(currentIndex) / Double(cards.count)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if sessionFinished || currentCard == nil {
                sessionSummary
            } else {
                VStack(spacing: 0) {
                    sessionHeader
                    Spacer()
                    cardArea
                    Spacer()
                    if picked != nil {
                        ratingButtons
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    Spacer(minLength: 24)
                }
            }
        }
    }

    // MARK: - Session Header

    private var sessionHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Theme.surfaceSoft)
                        .clipShape(Circle())
                }

                Spacer()

                if let card = currentCard {
                    HStack(spacing: 6) {
                        Image(systemName: card.type.icon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(card.type.color)
                        Text(card.category)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(card.type.color)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(card.type.color.opacity(0.15))
                    .clipShape(Capsule())
                }

                Spacer()

                Text("\(currentIndex + 1) / \(cards.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.track)
                        .frame(height: 4)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.brand, Color(accentHex: "BE123C")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Card Area
    //
    // 인출로 시작한다: 문제 → (고르면) 정답 확인 → 4단계 평가.
    // 문제 화면에는 읽기(히라가나)도, 뜻도, 음성도 주지 않는다.

    private var question: RetrievalQuestion? {
        currentCard.map { RetrievalQuestion.make(for: $0) }
    }

    private var cardArea: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                if let card = currentCard, let q = question {
                    questionCard(q)
                    choiceList(q)
                    if picked != nil {
                        answerCard(card, q)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }

    /// 문제 — 예문 빈칸이면 문장만, 예문이 없으면 뜻만 준다
    private func questionCard(_ q: RetrievalQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(q.kind == .cloze ? "빈칸에 알맞은 것은?" : "이 뜻을 가진 낱말은?")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textTertiary)

            if q.kind == .cloze, let sentence = q.sentence {
                // 한자 위에 읽기를 얹는다 — 문장을 못 읽으면 빈칸 문제가 성립하지 않는다.
                // 정답이 들어갈 자리는 «＿＿＿»이라 읽기가 새지 않는다.
                FuriganaText(text: sentence, size: 20)
            } else {
                Text(q.meaning)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func choiceList(_ q: RetrievalQuestion) -> some View {
        VStack(spacing: 8) {
            ForEach(Array(q.choices.enumerated()), id: \.offset) { i, choice in
                choiceRow(q, index: i, text: choice)
            }
        }
    }

    private func choiceRow(_ q: RetrievalQuestion, index: Int, text: String) -> some View {
        let isAnswer = index == q.answerIndex
        let isPicked = picked == index
        let decided = picked != nil
        let tint: Color = decided
            ? (isAnswer ? Color(accentHex: "16A34A")
                        : (isPicked ? Color(accentHex: "DC2626") : Theme.textTertiary))
            : Theme.textPrimary

        return Button {
            guard picked == nil else { return }
            withAnimation(.easeInOut(duration: 0.2)) { picked = index }
            if isAnswer { correctCount += 1 }
            if let card = currentCard { store.record(cardId: card.id, correct: isAnswer) }
            // 답을 고른 뒤에야 소리를 들려준다
            if let card = currentCard { speech.speak(card.front) }
        } label: {
            HStack(spacing: 10) {
                Text(text)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(tint)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if decided, isAnswer {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(accentHex: "16A34A"))
                } else if decided, isPicked {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(accentHex: "DC2626"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(decided && (isAnswer || isPicked)
                        ? tint.opacity(0.12) : Theme.surfaceSoft)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(decided && (isAnswer || isPicked) ? tint.opacity(0.5) : .clear,
                            lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(picked != nil)
    }

    /// 정답을 고른 뒤에 비로소 읽기·뜻·예문을 펼친다
    private func answerCard(_ card: LearningCard, _ q: RetrievalQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(card.front)
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(Theme.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(card.reading)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textTertiary)
                Spacer(minLength: 4)
                Button {
                    speech.speak(card.front)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.brand)
                        .frame(width: 34, height: 34)
                        .background(Theme.brand.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Text(card.meaning)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let ex = N3Examples.sentence(for: card) {
                Divider().overlay(Theme.stroke)
                FuriganaText(text: ex.japanese, size: 16)
                Text(ex.korean)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Rating Buttons

    private var ratingButtons: some View {
        VStack(spacing: 10) {
            Text("어디까지 할 수 있었나요?")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 8) {
                ForEach(SRSRating.allCases, id: \.rawValue) { rating in
                    ratingButton(rating, type: currentCard?.type ?? .vocabulary)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 4)
    }

    private func ratingButton(_ rating: SRSRating, type: CardType) -> some View {
        Button {
            guard !isAnimating, let card = currentCard else { return }
            isAnimating = true
            // 정답 수는 인출 문제를 맞혔는지로 센다 (여기서 또 세면 두 번 세어진다).
            // 자기 평가는 복습 간격을 정하는 데만 쓴다.
            store.rate(cardId: card.id, rating: rating)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.35)) {
                    if currentIndex + 1 >= cards.count {
                        speech.stop()
                        sessionFinished = true
                    } else {
                        currentIndex += 1
                        picked = nil
                    }
                }
                isAnimating = false
            }
        } label: {
            VStack(spacing: 3) {
                Text(rating.label(for: type))
                    .font(.system(size: 14, weight: .bold))
                // 판단 기준. 좁은 화면에서도 줄이 접히지 않게 한 줄로 눌러 담는다
                Text(rating.criterion(for: type))
                    .font(.system(size: 9))
                    .opacity(0.75)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .padding(.horizontal, 2)
            .background(Color(accentHex: rating.colorHex).opacity(0.18))
            .foregroundStyle(Color(accentHex: rating.colorHex))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(accentHex: rating.colorHex).opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: - Session Summary

    private var sessionSummary: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("完了")
                .font(.system(size: 72, weight: .black))
                .foregroundStyle(Theme.brand)

            VStack(spacing: 8) {
                Text("세션 완료!")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(cards.count)장 학습 · 정답 \(correctCount)장")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textSecondary)
            }

            HStack(spacing: 16) {
                summaryChip(value: cards.count, label: "총 학습", color: "1D4ED8")
                summaryChip(value: correctCount, label: "정답", color: "16A34A")
                summaryChip(value: cards.count - correctCount, label: "재학습", color: "DC2626")
            }
            .padding(.horizontal, 20)

            // Accuracy
            let accuracy = cards.count > 0 ? Int(Double(correctCount) / Double(cards.count) * 100) : 0
            VStack(spacing: 6) {
                Text("정답률")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textTertiary)
                Text("\(accuracy)%")
                    .font(.system(size: 48, weight: .black))
                    .foregroundStyle(accuracyColor(accuracy))
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Theme.surfaceSoft)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("학습 완료")
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.brand)
                    .foregroundStyle(Theme.onBrand)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private func summaryChip(value: Int, label: String, color: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(Color(accentHex: color))
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(accentHex: color).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func accuracyColor(_ pct: Int) -> Color {
        if pct >= 80 { return Color(accentHex: "16A34A") }
        if pct >= 60 { return Color(accentHex: "D97706") }
        return Color(accentHex: "DC2626")
    }
}

// MARK: - Card Front View

struct CardFrontView: View {
    let card: LearningCard
    var onSpeak: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Type badge
            HStack {
                Spacer()
                HStack(spacing: 5) {
                    Text(card.statusLabel)
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(card.statusColor.opacity(0.2))
                .foregroundStyle(card.statusColor)
                .clipShape(Capsule())
            }
            .padding(.bottom, 8)

            Spacer()

            // Main front content
            VStack(spacing: 12) {
                Text(card.front)
                    .font(.system(size: card.type == .grammar ? 28 : 52, weight: .black))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .lineLimit(3)

                if card.type == .vocabulary {
                    Text(card.reading)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Theme.brand)
                }

                // Speaker button
                Button {
                    onSpeak?()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.brand.opacity(0.9))
                        .frame(width: 44, height: 44)
                        .background(Theme.brand.opacity(0.14))
                        .clipShape(Circle())
                }
            }

            Spacer()

            // Category
            Text(card.category)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textQuaternary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 300)
        .background(
            LinearGradient(
                colors: [Theme.cardFaceTop, Theme.cardFaceBottom],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(card.type.color.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: Theme.shadow, radius: 20, x: 0, y: 10)
    }
}

// MARK: - Card Back View

struct CardBackView: View {
    let card: LearningCard
    var onSpeak: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Type badge
            HStack {
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: card.type.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(card.type.rawValue)
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(card.type.color.opacity(0.2))
                .foregroundStyle(card.type.color)
                .clipShape(Capsule())
            }
            .padding(.bottom, 8)

            Spacer()

            VStack(spacing: 16) {
                // Front word (small reminder) + speaker
                HStack(spacing: 10) {
                    Text(card.front)
                        .font(.system(size: card.type == .grammar ? 18 : 28, weight: .black))
                        .foregroundStyle(Theme.textTertiary)
                        .multilineTextAlignment(.center)

                    Button {
                        onSpeak?()
                    } label: {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.brand.opacity(0.75))
                            .frame(width: 32, height: 32)
                            .background(Theme.brand.opacity(0.12))
                            .clipShape(Circle())
                    }
                }

                if card.type == .vocabulary {
                    Text(card.reading)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.brand.opacity(0.9))
                }

                Divider()
                    .background(Theme.stroke)
                    .padding(.horizontal, 24)

                // Meaning
                Text(card.meaning)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Example sentence
            if let ex = card.example, let exMeaning = card.exampleMeaning {
                VStack(alignment: .leading, spacing: 8) {
                    Label("예문", systemImage: "quote.opening")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.brand.opacity(0.85))

                    Text(ex)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary.opacity(0.9))
                        .lineSpacing(4)

                    Text(exMeaning)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                        .lineSpacing(3)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 300)
        .background(
            LinearGradient(
                colors: [Theme.cardFaceBottom, Theme.cardFaceTop],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(card.type.color.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: card.type.color.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}
