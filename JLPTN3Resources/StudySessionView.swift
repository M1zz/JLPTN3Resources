import SwiftUI
import AVFoundation

// MARK: - Speech Manager

private class SpeechManager: ObservableObject {
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
    @State private var isFlipped: Bool = false
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
                    if isFlipped {
                        ratingButtons
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        revealHint
                            .transition(.opacity)
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

    private var cardArea: some View {
        ZStack {
            if let card = currentCard {
                // Back face
                if isFlipped {
                    CardBackView(card: card, onSpeak: { speech.speak(card.front) })
                        .rotation3DEffect(.degrees(0), axis: (x: 0, y: 1, z: 0))
                        .transition(.asymmetric(
                            insertion: .identity,
                            removal: .identity
                        ))
                }
                // Front face
                if !isFlipped {
                    CardFrontView(card: card, onSpeak: { speech.speak(card.front) })
                }
            }
        }
        .padding(.horizontal, 20)
        .onTapGesture {
            guard !isFlipped else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isFlipped = true
            }
        }
        .onAppear {
            if let card = currentCard {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    speech.speak(card.front)
                }
            }
        }
        .onChange(of: currentIndex) { _ in
            if let card = currentCard {
                speech.speak(card.front)
            }
        }
    }

    // MARK: - Reveal Hint

    private var revealHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.tap")
                .font(.system(size: 20))
                .foregroundStyle(Theme.textTertiary)
            Text("카드를 탭하면 정답 확인")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Rating Buttons

    private var ratingButtons: some View {
        VStack(spacing: 10) {
            Text("얼마나 잘 기억했나요?")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 8) {
                ForEach(SRSRating.allCases, id: \.rawValue) { rating in
                    ratingButton(rating)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 4)
    }

    private func ratingButton(_ rating: SRSRating) -> some View {
        Button {
            guard !isAnimating, let card = currentCard else { return }
            isAnimating = true
            if rating == .good || rating == .easy { correctCount += 1 }
            store.rate(cardId: card.id, rating: rating)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.35)) {
                    if currentIndex + 1 >= cards.count {
                        speech.stop()
                        sessionFinished = true
                    } else {
                        currentIndex += 1
                        isFlipped = false
                    }
                }
                isAnimating = false
            }
        } label: {
            VStack(spacing: 4) {
                Text(rating.label)
                    .font(.system(size: 14, weight: .bold))
                Text(rating.hint)
                    .font(.system(size: 10))
                    .opacity(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
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
