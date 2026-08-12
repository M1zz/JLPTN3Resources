import SwiftUI
import AVFoundation

// MARK: - 청해 재생
//
// 화자별로 pitch를 달리해 男/女/N을 구분한다. (모의고사 탭과 같은 방식)

final class ListeningSpeech: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    @Published private(set) var isPlaying = false
    /// 지금 읽고 있는 줄 (-1이면 재생 중이 아님)
    @Published private(set) var lineIndex = -1

    private var queued = 0

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func play(situation: String, lines: [DialogueLine], rate: Float) {
        stop()
        isPlaying = true
        lineIndex = -1
        queued = 0

        if !situation.isEmpty {
            speak(situation, pitch: 1.0, rate: rate, delay: 0.5)
        }
        for line in lines {
            speak(line.text, pitch: line.speaker.pitch, rate: rate, delay: 0.35)
        }
    }

    private func speak(_ text: String, pitch: Float, rate: Float, delay: TimeInterval) {
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        u.rate = rate
        u.pitchMultiplier = pitch
        u.postUtteranceDelay = delay
        queued += 1
        synthesizer.speak(u)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        lineIndex = -1
        queued = 0
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        lineIndex += 1
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        queued -= 1
        if queued <= 0 {
            isPlaying = false
            lineIndex = -1
        }
    }
}

// MARK: - 청해 연습

struct ListeningView: View {
    @ObservedObject var store: PracticeStore

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryCard

                    ForEach(ListeningKind.allCases) { kind in
                        NavigationLink {
                            ListeningSessionView(kind: kind, store: store)
                        } label: {
                            kindRow(kind)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("모든 대본은 실제 출제 형식만 따라 자체 제작했습니다. 음성은 기기의 일본어 음성으로 읽어 줍니다.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textQuaternary)
                        .padding(.top, 4)
                }
                .padding(16)
            }
        }
        .navigationTitle("청해 연습")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(store.listeningSolved)")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.brand)
                Text("/ \(store.listeningTotal)문항")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                if let acc = store.listeningAccuracy {
                    Text("정답률 \(Int(acc * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.brand)
                }
            }
            ProgressView(value: Double(store.listeningSolved),
                         total: Double(max(store.listeningTotal, 1)))
                .tint(Theme.brand)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func kindRow(_ kind: ListeningKind) -> some View {
        let total = listeningItems.filter { $0.kind == kind }.count
        let solved = store.solvedCount(kind)
        let correct = store.correctCount(kind)
        return HStack(spacing: 12) {
            Image(systemName: kind.icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.brand)
                .frame(width: 36, height: 36)
                .background(Theme.brand.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(kind.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(kind.korean)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(solved)/\(total)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(solved == total ? Color(accentHex: "16A34A") : Theme.textSecondary)
                if solved > 0 {
                    Text("정답 \(correct)")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textQuaternary)
                }
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textQuaternary)
        }
        .padding(14)
        .background(Theme.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - 유형별 세션

struct ListeningSessionView: View {
    let kind: ListeningKind
    @ObservedObject var store: PracticeStore

    @StateObject private var speech = ListeningSpeech()
    @State private var index = 0
    @State private var picked: Int?
    @State private var graded = false
    @State private var showScript = false
    /// 천천히 듣기 — 처음에는 시험 속도, 어려우면 늦춘다
    @AppStorage("listeningSlow") private var slow = false

    private var items: [ListeningItem] { listeningItems.filter { $0.kind == kind } }
    private var item: ListeningItem { items[min(index, items.count - 1)] }
    private var rate: Float { slow ? 0.36 : 0.46 }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        situationBlock
                        playerBlock
                        questionBlock
                        if graded { explanationBlock }
                        actionButton
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle(kind.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    slow.toggle()
                    speech.stop()
                } label: {
                    Text(slow ? "천천히" : "보통 속도")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(slow ? Theme.brand : Theme.textTertiary)
                }
            }
        }
        .onDisappear { speech.stop() }
        .onChange(of: index) { _ in autoPlay() }
        .onAppear { autoPlay() }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Theme.track)
                Rectangle().fill(Theme.brand)
                    .frame(width: geo.size.width * Double(index + 1) / Double(max(items.count, 1)))
            }
        }
        .frame(height: 3)
    }

    /// 상황 설명 — 実際の試験と同じく音声で流し、画面にも残す
    @ViewBuilder
    private var situationBlock: some View {
        HStack {
            Text("\(index + 1) / \(items.count)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textQuaternary)
            Spacer()
            if let ok = store.result(listeningItem: item.id) {
                Text(ok ? "지난번 정답" : "지난번 오답")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ok ? Color(accentHex: "16A34A") : Color(accentHex: "DC2626"))
            }
        }
        if !item.situation.isEmpty {
            Text(item.situation)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var playerBlock: some View {
        VStack(spacing: 12) {
            Button {
                if speech.isPlaying {
                    speech.stop()
                } else {
                    speech.play(situation: item.situation, lines: item.dialogue, rate: rate)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: speech.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(speech.isPlaying ? "멈추기" : "듣기")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(Theme.onBrand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.brand)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // 대본은 답을 고른 뒤에만 열 수 있다 — 읽고 풀면 청해 연습이 되지 않는다
            if graded {
                DisclosureGroup(isExpanded: $showScript) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(item.dialogue.enumerated()), id: \.offset) { _, line in
                            HStack(alignment: .top, spacing: 8) {
                                Text(line.speaker.label)
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(Theme.onBrand)
                                    .frame(width: 20, height: 20)
                                    .background(Theme.brand.opacity(0.75))
                                    .clipShape(Circle())
                                Text(line.text)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(.top, 10)
                } label: {
                    Text("대본 보기")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                }
                .tint(Theme.brand)
                .padding(14)
                .background(Theme.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var questionBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 概要理解·即時応答は音声のあとに質問が出る形式なので、答えを選ぶ前は隠す
            if kind.showsQuestionBeforeAudio || graded || picked != nil {
                Text(item.question)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("音声を聞いてから、合うものを選んでください。")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textTertiary)
            }

            ForEach(Array(item.choices.enumerated()), id: \.offset) { ci, choice in
                choiceRow(index: ci, text: choice)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func choiceRow(index ci: Int, text: String) -> some View {
        let selected = picked == ci
        let isAnswer = item.answerIndex == ci
        let tint: Color = graded
            ? (isAnswer ? Color(accentHex: "16A34A")
                        : (selected ? Color(accentHex: "DC2626") : Theme.textSecondary))
            : (selected ? Theme.brand : Theme.textSecondary)

        return Button {
            guard !graded else { return }
            picked = ci
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Text("\(ci + 1)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(selected || (graded && isAnswer) ? Theme.onBrand : tint)
                    .frame(width: 20, height: 20)
                    .background(selected || (graded && isAnswer) ? tint : tint.opacity(0.12))
                    .clipShape(Circle())
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background((selected || (graded && isAnswer)) ? tint.opacity(0.12) : Theme.surfaceSoft)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var explanationBlock: some View {
        Text(item.explanation)
            .font(.system(size: 12))
            .foregroundStyle(Theme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.brand.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var actionButton: some View {
        if graded {
            Button {
                if index + 1 < items.count {
                    index += 1
                    picked = nil
                    graded = false
                    showScript = false
                }
            } label: {
                Text(index + 1 < items.count ? "다음 문제" : "이 유형 끝")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.onBrand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(index + 1 >= items.count)
        } else {
            Button(action: grade) {
                Text(picked == nil ? "답을 고르세요" : "정답 확인")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(picked == nil ? Theme.textQuaternary : Theme.onBrand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(picked == nil ? Theme.surfaceSoft : Theme.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(picked == nil)
        }
    }

    private func grade() {
        guard let picked else { return }
        speech.stop()
        store.record(listeningItem: item.id, correct: picked == item.answerIndex)
        withAnimation(.easeInOut(duration: 0.2)) { graded = true }
    }

    /// 문제를 열면 한 번 자동 재생 — 시험처럼 «먼저 듣는» 순서를 만든다
    private func autoPlay() {
        speech.play(situation: item.situation, lines: item.dialogue, rate: rate)
    }
}
