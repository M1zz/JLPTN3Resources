import SwiftUI
import AVFoundation

// MARK: - 청해 음성

/// 대사마다 음높이를 바꿔 남녀 화자를 구분해 읽어 준다.
private final class ExamSpeech: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ lines: [DialogueLine]) {
        synthesizer.stopSpeaking(at: .immediate)
        for line in lines {
            let utterance = AVSpeechUtterance(string: line.text)
            utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
            utterance.rate = 0.45
            utterance.pitchMultiplier = line.speaker.pitch
            utterance.postUtteranceDelay = 0.3
            synthesizer.speak(utterance)
        }
    }

    func stop() { synthesizer.stopSpeaking(at: .immediate) }
}

// MARK: - Mock Exam View

struct MockExamView: View {
    private enum Phase { case intro, exam, result }

    @EnvironmentObject private var practice: PracticeStore

    @State private var phase: Phase = .intro
    @State private var index = 0
    @State private var answers: [String: Int] = [:]
    @StateObject private var speech = ExamSpeech()

    private let questions = mockExamQuestions

    private var current: MockQuestion { questions[index] }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                switch phase {
                case .intro:  introView
                case .exam:   examView
                case .result: MockExamResultView(questions: questions,
                                                 answers: answers,
                                                 onRetry: reset)
                }
            }
            .navigationTitle("미니 모의고사")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.backgroundElevated, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - 안내 화면

    private var introView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("実力チェック")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Theme.brand)
                    Text("18문항 미니 모의고사")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(Theme.textPrimary)
                    Text("실제 시험의 출제 형식 그대로, 과목별 점수를 환산해 합격 기준과 비교해 드립니다.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                        .lineSpacing(4)
                }

                VStack(spacing: 0) {
                    ForEach(ExamSubject.allCases) { subject in
                        let count = questions.filter { $0.subject == subject }.count
                        HStack(spacing: 10) {
                            Image(systemName: subject.icon)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(accentHex: subject.colorHex))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(subject.name)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(subject.japanese)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            Spacer()
                            Text("\(count)문항")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)

                        if subject != ExamSubject.allCases.last {
                            Divider().background(Theme.stroke).padding(.leading, 50)
                        }
                    }
                }
                .background(Theme.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 10) {
                    noticeRow(icon: "speaker.wave.2.fill",
                              text: "청해는 음성으로 나옵니다. 소리를 켜 주세요. 실제 시험은 1회만 들려주지만 여기서는 다시 들을 수 있습니다.")
                    noticeRow(icon: "exclamationmark.circle",
                              text: "실제 기출문제가 아니라 출제 형식을 따라 만든 자체 문항입니다. 문항 수가 적어 환산 점수는 참고용입니다.")
                }
                .padding(14)
                .background(Theme.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    phase = .exam
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill").font(.system(size: 14, weight: .bold))
                        Text("시작하기").font(.system(size: 17, weight: .black))
                    }
                    .foregroundStyle(Theme.onBrand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
        }
    }

    private func noticeRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Theme.brand)
                .frame(width: 16)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 문제 풀이

    private var examView: some View {
        VStack(spacing: 0) {
            examHeader

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let passage = current.passage {
                        passageBox(passage)
                    }
                    if let dialogue = current.dialogue {
                        audioBox(dialogue)
                    }

                    Text(current.prompt)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 8) {
                        ForEach(Array(current.choices.enumerated()), id: \.offset) { i, choice in
                            choiceRow(i, choice)
                        }
                    }
                }
                .padding(20)
            }

            navigationBar
        }
        .onAppear { playIfListening() }
        .onChange(of: index) { _ in playIfListening() }
        .onDisappear { speech.stop() }
    }

    private var examHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: current.subject.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(current.subject.name)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Color(accentHex: current.subject.colorHex))
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Color(accentHex: current.subject.colorHex).opacity(0.15))
                .clipShape(Capsule())

                Text(current.format)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)

                Spacer()

                Text("\(index + 1) / \(questions.count)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Theme.track)
                    Rectangle()
                        .fill(Theme.brand)
                        .frame(width: geo.size.width * Double(index + 1) / Double(questions.count))
                        .animation(.easeInOut(duration: 0.25), value: index)
                }
            }
            .frame(height: 3)
        }
        .background(Theme.backgroundElevated)
    }

    private func passageBox(_ passage: String) -> some View {
        Text(passage)
            .font(.system(size: 14))
            .foregroundStyle(Theme.textPrimary)
            .lineSpacing(7)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Theme.surfaceSoft)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.stroke, lineWidth: 1))
    }

    private func audioBox(_ dialogue: [DialogueLine]) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: 30))
                .foregroundStyle(Color(accentHex: ExamSubject.listening.colorHex))
            Text("음성을 듣고 문제에 답하세요")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
            Button {
                speech.speak(dialogue)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .bold))
                    Text("다시 듣기")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(Color(accentHex: ExamSubject.listening.colorHex))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Color(accentHex: ExamSubject.listening.colorHex).opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func choiceRow(_ i: Int, _ choice: String) -> some View {
        let selected = answers[current.id] == i
        return Button {
            answers[current.id] = i
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text("\(i + 1)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(selected ? Theme.onBrand : Theme.textTertiary)
                    .frame(width: 26, height: 26)
                    .background(selected ? Theme.brand : Theme.track)
                    .clipShape(Circle())
                Text(choice)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Theme.brand.opacity(0.12) : Theme.surfaceSoft)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Theme.brand.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var navigationBar: some View {
        HStack(spacing: 10) {
            Button {
                speech.stop()
                if index > 0 { index -= 1 }
            } label: {
                Text("이전")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(index > 0 ? Theme.textSecondary : Theme.textQuaternary)
                    .frame(width: 90)
                    .padding(.vertical, 14)
                    .background(Theme.surfaceSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(index == 0)

            Button {
                speech.stop()
                if index + 1 < questions.count {
                    index += 1
                } else {
                    // 채점 결과를 남긴다 — 언어지식 실력을 재는 유일한 기록이다
                    practice.record(mockAnswers: answers, questions: questions)
                    phase = .result
                }
            } label: {
                Text(index + 1 < questions.count ? "다음" : "채점하기")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(Theme.onBrand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Theme.backgroundElevated)
    }

    // MARK: - Logic

    private func playIfListening() {
        guard let dialogue = current.dialogue else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            speech.speak(dialogue)
        }
    }

    private func reset() {
        answers = [:]
        index = 0
        phase = .intro
    }
}

// MARK: - 결과 화면

private struct MockExamResultView: View {
    let questions: [MockQuestion]
    let answers: [String: Int]
    let onRetry: () -> Void

    @State private var showReview = false

    private var result: MockExamResult {
        MockExamResult(subjectResults: ExamSubject.allCases.map { subject in
            let qs = questions.filter { $0.subject == subject }
            let correct = qs.filter { answers[$0.id] == $0.answerIndex }.count
            return SubjectResult(subject: subject, correct: correct, total: qs.count)
        })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                verdictCard

                VStack(spacing: 12) {
                    ForEach(result.subjectResults) { sr in
                        subjectScoreCard(sr)
                    }
                }

                Button {
                    withAnimation { showReview.toggle() }
                } label: {
                    HStack {
                        Text(showReview ? "해설 접기" : "문항별 해설 보기")
                            .font(.system(size: 15, weight: .bold))
                        Image(systemName: showReview ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.surfaceSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if showReview {
                    VStack(spacing: 10) {
                        ForEach(questions) { q in
                            reviewCard(q)
                        }
                    }
                }

                Button(action: onRetry) {
                    Text("다시 풀기")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.onBrand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Theme.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
    }

    private var verdictCard: some View {
        let passed = result.passed
        let accent = Color(accentHex: passed ? "10B981" : "F59E0B")
        return VStack(spacing: 14) {
            Text(passed ? "合格ライン" : "もう少し")
                .font(.system(size: 12, weight: .bold))
                .tracking(2)
                .foregroundStyle(accent)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(result.totalScore)")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(accent)
                Text("/ 180점")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }

            Text("정답 \(result.totalCorrect) / \(result.totalQuestions)문항 · 환산 예상 점수")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textTertiary)

            VStack(spacing: 6) {
                verdictRow(label: "총점 95점 이상", ok: result.totalPassed)
                verdictRow(label: "전 과목 19점 이상", ok: result.allSubjectsPassed)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(accent.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(accent.opacity(0.25), lineWidth: 1))
    }

    private func verdictRow(label: String, ok: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color(accentHex: ok ? "10B981" : "DC2626"))
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func subjectScoreCard(_ sr: SubjectResult) -> some View {
        let c = Color(accentHex: sr.subject.colorHex)
        let verdict = Color(accentHex: sr.passedSubject ? "10B981" : "DC2626")
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: sr.subject.icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(c)
                Text(sr.subject.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(sr.correct)/\(sr.total)문항")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                Text("\(sr.scaledScore)점")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(verdict)
            }

            // 60점 만점 막대 위에 기준점 19점을 표시
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.track)
                    Capsule()
                        .fill(verdict)
                        .frame(width: w * Double(sr.scaledScore) / 60)
                    Rectangle()
                        .fill(Theme.textPrimary.opacity(0.55))
                        .frame(width: 2, height: 14)
                        .offset(x: w * Double(sr.subject.passLine) / 60 - 1)
                }
            }
            .frame(height: 10)

            HStack {
                Text("기준점 19점")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Text(sr.passedSubject ? "기준점 통과" : "기준점 미달")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(verdict)
            }
        }
        .padding(16)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(c.opacity(0.20), lineWidth: 1))
    }

    private func reviewCard(_ q: MockQuestion) -> some View {
        let picked = answers[q.id]
        let correct = picked == q.answerIndex
        let accent = Color(accentHex: correct ? "10B981" : "DC2626")

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(accent)
                Text(q.format)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(accentHex: q.subject.colorHex))
                Spacer()
                Text(q.subject.name)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
            }

            Text(q.prompt)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // 청해는 대본을 여기서 처음 공개한다
            if let dialogue = q.dialogue {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(dialogue.enumerated()), id: \.offset) { _, line in
                        Text("\(line.speaker.label)：\(line.text)")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.track)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                if let picked, !correct {
                    Text("내 답 · \(picked + 1). \(q.choices[picked])")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(accentHex: "DC2626"))
                        .fixedSize(horizontal: false, vertical: true)
                } else if picked == nil {
                    Text("무응답")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(accentHex: "DC2626"))
                }
                Text("정답 · \(q.answerIndex + 1). \(q.choices[q.answerIndex])")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(accentHex: "10B981"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(q.explanation)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.25), lineWidth: 1))
    }
}

#Preview {
    MockExamView()
        .environmentObject(PracticeStore())
}
