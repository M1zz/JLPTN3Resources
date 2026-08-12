import SwiftUI
import PencilKit

// MARK: - Helpers

private func isKanji(_ c: Character) -> Bool {
    guard let scalar = c.unicodeScalars.first else { return false }
    let v = scalar.value
    return (0x4E00...0x9FFF).contains(v) || (0x3400...0x4DBF).contains(v)
}

// MARK: - Writing Step

/// 한 화면에 한 글자. 단어의 한자를 낱글자 단위로 펼친 학습 단위.
private struct WritingStep: Identifiable {
    let id = UUID()
    let card: LearningCard
    let kanji: Character
    /// 단어 문자열 내 위치 (같은 한자가 두 번 나와도 구분하기 위함)
    let charOffset: Int
    /// 단어 안에서 몇 번째 한자인지 (0-based)
    let kanjiIndex: Int
    /// 단어에 포함된 한자 총 개수
    let kanjiCount: Int
}

// MARK: - 따라쓰기 밑글자

/// 캔버스 아래에 깔리는 흐릿한 글자. 한자 연습장의 밑글자와 같은 역할이다.
enum TraceGuideLevel: String, CaseIterable {
    case faint, strong, off

    /// 기본은 흐리게 — 획을 덮지 않으면서 형태만 따라갈 수 있는 정도
    var opacity: Double {
        switch self {
        case .faint:  return 0.13
        case .strong: return 0.30
        case .off:    return 0
        }
    }

    var label: String {
        switch self {
        case .faint:  return "흐리게"
        case .strong: return "진하게"
        case .off:    return "없음"
        }
    }

    var icon: String {
        switch self {
        case .faint:  return "eye"
        case .strong: return "eye.fill"
        case .off:    return "eye.slash"
        }
    }

    var next: TraceGuideLevel {
        switch self {
        case .faint:  return .strong
        case .strong: return .off
        case .off:    return .faint
        }
    }
}

// MARK: - 연습 모드

/// 같은 «보고 → 떠올려 쓰고 → 채점» 흐름 위에서, 무엇을 가리느냐만 바꿔
/// 쓰기 · 읽기 · 듣기를 각각 연습한다.
enum WritingMode: String, CaseIterable {
    /// 뜻·읽기를 보고 한자를 떠올려 쓴다 (표기 인출)
    case write
    /// 한자를 보고 읽기를 떠올려 쓴다 (읽기 인출)
    case read
    /// 소리만 듣고 한자를 쓴다 (청해 → 표기)
    case listen
    /// 밑글자를 따라 쓴다 (형태 익히기)
    case trace

    var label: String {
        switch self {
        case .write:  return "쓰기"
        case .read:   return "읽기"
        case .listen: return "듣기"
        case .trace:  return "따라 쓰기"
        }
    }

    var icon: String {
        switch self {
        case .write:  return "pencil.line"
        case .read:   return "text.magnifyingglass"
        case .listen: return "ear"
        case .trace:  return "scribble"
        }
    }

    /// 캔버스에 무엇을 써야 하는지
    var instruction: String {
        switch self {
        case .write:  return "뜻·읽기를 보고 한자를 쓰세요"
        case .read:   return "읽기를 히라가나로 쓰세요"
        case .listen: return "들리는 단어를 한자로 쓰세요"
        case .trace:  return "밑글자를 따라 쓰세요"
        }
    }

    /// 한자를 가린다 — 그게 답이므로
    var hidesKanji: Bool { self == .write || self == .listen }
    /// 읽기를 가린다
    var hidesReading: Bool { self == .read || self == .listen }
    /// 뜻까지 가린다 (듣기는 소리 말고는 아무 단서도 주지 않는다)
    var hidesMeaning: Bool { self == .listen }
    /// 소리를 자동 재생한다
    var speaks: Bool { self == .listen }

    /// 한자 한 글자씩 진행할지, 단어 단위로 진행할지.
    /// 읽기·듣기는 단어 전체가 문제이므로 한 단어에 한 문제다.
    var isPerKanji: Bool { self == .write || self == .trace }
}

// MARK: - Kanji Writing View

struct KanjiWritingView: View {
    /// 단어의 «암기 상태»(SRS 진도)를 함께 보여주기 위해 학습 진도를 읽어 온다
    @StateObject private var store = LearningStore()
    @State private var steps: [WritingStep] = []
    @State private var stepIndex = 0
    @State private var drawings: [UUID: PKDrawing] = [:]
    @State private var strokePhase: Double = 0
    @State private var isPlayingStrokes = false
    /// 재생을 다시 누르면 이전 재생의 «자동 숨김» 예약을 무효화하기 위한 토큰
    @State private var strokePlayToken = 0
    // 글자마다 껐다 켜는 힌트가 아니라 «연습 방식» 설정이므로 앱을 다시 켜도 유지한다
    @AppStorage("kanjiTraceGuide") private var guideRaw = TraceGuideLevel.faint.rawValue
    @AppStorage("kanjiWritingMode") private var modeRaw = WritingMode.write.rawValue
    @StateObject private var speech = SpeechManager()
    /// 문제 모드에서 정답을 공개했는지
    @State private var revealed = false
    /// 스텝별 자기 채점 결과
    @State private var results: [UUID: Bool] = [:]
    @State private var sessionDone = false

    // 한 글자씩 쓰므로 캔버스는 하나만 유지한다. makeUIView는 한 번만 호출되므로
    // 같은 인스턴스를 재사용해야 .drawing 교체가 즉시 반영된다.
    private let canvas: PKCanvasView = {
        let cv = PKCanvasView()
        cv.drawingPolicy = .anyInput
        cv.backgroundColor = .clear
        cv.isOpaque = false
        cv.tool = PKInkingTool(.pen, color: Theme.inkColor, width: 8)
        return cv
    }()

    private var currentStep: WritingStep? {
        guard stepIndex < steps.count else { return nil }
        return steps[stepIndex]
    }

    private var wordCount: Int {
        Set(steps.map { $0.card.id }).count
    }

    private var gradedCount: Int { results.count }
    private var correctCount: Int { results.values.filter { $0 }.count }

    private var guide: TraceGuideLevel {
        TraceGuideLevel(rawValue: guideRaw) ?? .faint
    }

    private var mode: WritingMode {
        WritingMode(rawValue: modeRaw) ?? .write
    }

    /// 정답을 공개한 시점. 따라 쓰기는 처음부터 공개돼 있다.
    private var answerVisible: Bool {
        mode == .trace || revealed
    }

    /// 한자를 보여줘도 되는가 — 읽기 연습에서는 한자가 곧 문제라 처음부터 보인다
    private var kanjiVisible: Bool {
        !mode.hidesKanji || revealed
    }

    private var readingVisible: Bool {
        !mode.hidesReading || revealed
    }

    private var meaningVisible: Bool {
        !mode.hidesMeaning || revealed
    }

    /// 밑글자·획순 표는 «한자를 쓰는» 연습일 때만 의미가 있다.
    /// 읽기 연습에서는 칸에 히라가나를 쓰므로 한자 밑글자를 깔지 않는다.
    private var kanjiAidVisible: Bool {
        mode == .read ? revealed : kanjiVisible
    }

    var body: some View {
        // 내비게이션 바·세그먼트·푸터를 모두 걷어내고 쓰는 칸에 화면을 몰아준다.
        // 설정(연습 모드·밑글자)은 헤더 오른쪽 메뉴 하나로 접어 넣었다.
        ZStack {
            Theme.background.ignoresSafeArea()

            if sessionDone {
                completeView
            } else if let step = currentStep {
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        // 뜻·읽기는 아래 학습 패널이 크게 보여 준다.
                        // 패널이 들어갈 자리가 없는 작은 화면에서만 헤더가 대신 짊어진다.
                        header(step, showsGloss: panelBudget(geo.size) < 60)
                        progressBar
                        canvasArea(step)
                        // 정사각 칸은 가로폭이 상한이라 세로가 남는다.
                        // 그 남는 만큼만 학습 패널에 내주고, 쓰는 칸은 절대 줄이지 않는다.
                        learningPanel(step, size: geo.size)
                        controls
                    }
                }
            } else {
                ProgressView().tint(Theme.brand)
            }
        }
        .onAppear { if steps.isEmpty { setupSteps() } }
    }

    // MARK: - Header

    private func header(_ step: WritingStep, showsGloss: Bool) -> some View {
        HStack(alignment: .center, spacing: 10) {
            // 단어 전체를 보여주되 지금 쓸 글자만 강조.
            // 쓰기에서는 그 글자를, 듣기에서는 단어 전체를 «〇»로 가린다.
            HStack(spacing: 0) {
                ForEach(Array(step.card.front.enumerated()), id: \.offset) { offset, ch in
                    let isTarget = mode.isPerKanji && offset == step.charOffset
                    let hidden = !kanjiVisible && (isTarget || mode == .listen)
                    Text(hidden ? "〇" : String(ch))
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(isTarget ? Theme.brand : Theme.textQuaternary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            // 긴 단어라도 오른쪽 칩들과 부딪히지 않게 글자 크기를 줄여 가며 자리를 지킨다
            .layoutPriority(1)

            if showsGloss {
                VStack(alignment: .leading, spacing: 1) {
                    Text(readingVisible ? step.card.reading : "· · ·")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                    Text(meaningVisible ? step.card.meaning : "· · ·")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                .lineLimit(1)
            }

            Spacer(minLength: 4)

            // 이번 세션 성적 — «지금 얼마나 맞히고 있는지»
            if gradedCount > 0 {
                Text("\(correctCount)/\(gradedCount)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.brand)
            }

            Text("\(stepIndex + 1)/\(steps.count)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.textQuaternary)

            settingsMenu
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    /// 연습 모드·밑글자 설정과 획순 데이터 출처를 한 곳에 모은 메뉴
    private var settingsMenu: some View {
        Menu {
            Picker("연습 모드", selection: Binding(
                get: { mode },
                set: { newValue in
                    guard newValue != mode else { return }
                    modeRaw = newValue.rawValue
                    // 쓰기는 한자 한 글자, 읽기·듣기는 단어 하나가 한 문제라
                    // 문제 목록 자체가 달라진다 → 세션을 새로 짠다
                    setupSteps()
                }
            )) {
                ForEach(WritingMode.allCases, id: \.rawValue) { m in
                    Label(m.label, systemImage: m.icon).tag(m)
                }
            }

            Picker("밑글자", selection: Binding(
                get: { guide },
                set: { guideRaw = $0.rawValue }
            )) {
                ForEach(TraceGuideLevel.allCases, id: \.rawValue) { level in
                    Label(level.label, systemImage: level.icon).tag(level)
                }
            }

            Section {
                Text("획순 데이터 © KanjiVG · CC BY-SA 3.0")
            }
        } label: {
            // 지금 어떤 연습을 하고 있는지가 곧 메뉴 버튼이다
            HStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.system(size: 11, weight: .bold))
                Text(mode.label)
                    .font(.system(size: 11, weight: .bold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(Theme.brand)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Theme.brand.opacity(0.14))
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Theme.track)
                Rectangle()
                    .fill(Theme.brand)
                    .frame(width: geo.size.width * progress)
                    .animation(.easeInOut(duration: 0.25), value: progress)
            }
        }
        .frame(height: 2)
    }

    private var progress: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(stepIndex + 1) / Double(steps.count)
    }

    // MARK: - Canvas Area

    private func canvasArea(_ step: WritingStep) -> some View {
        GeometryReader { geo in
            // 여백을 최소로 줄여 쓰는 칸을 화면 가로폭까지 키운다
            let w = min(geo.size.width - 16, geo.size.height / cellRatio)
            let h = min(w * cellRatio, geo.size.height)
            let inner = min(w, h)

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.canvasCell)
                GridGuide(width: w, height: h)
                if guide != .off, mode != .read, kanjiVisible {
                    Text(String(step.kanji))
                        .font(.system(size: inner * 0.74, weight: .medium))
                        .foregroundStyle(Theme.textPrimary.opacity(guide.opacity))
                        .animation(.easeInOut(duration: 0.2), value: guideRaw)
                        .allowsHitTesting(false)
                }
                // 획순 안내는 밑글자 위, 필기 아래에 그린다
                if isPlayingStrokes {
                    StrokeOrderView(kanji: step.kanji, phase: strokePhase, size: inner)
                }

                CanvasWrapper(canvas: canvas)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .frame(width: w, height: h)
            // 획순 버튼은 반드시 overlay로 얹는다.
            // ZStack 안에서 .frame(maxWidth:.infinity, maxHeight:.infinity)로 감싸면
            // 그 프레임이 Button 자신의 크기가 되어 칸 전체가 터치 영역이 되고,
            // 필기 입력이 전부 버튼에 먹힌다.
            .overlay(alignment: .topTrailing) {
                if KanjiStrokes.hasData(for: step.kanji), kanjiAidVisible {
                    strokeOrderButton(step.kanji)
                        .padding(8)
                }
            }
            // 획수는 답에 대한 힌트라 문제 모드에서는 확인 후에 보여준다.
            // 칸 안에 얹어 세로 공간을 쓰지 않는다.
            .overlay(alignment: .topLeading) {
                let strokes = KanjiStrokes.strokeCount(for: step.kanji)
                if strokes > 0, kanjiAidVisible {
                    Text("\(strokes)획")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.textQuaternary)
                        .padding(14)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.vertical, 6)
    }

    private func strokeOrderButton(_ kanji: Character) -> some View {
        Button {
            playStrokeOrder(kanji)
        } label: {
            Image(systemName: isPlayingStrokes ? "arrow.clockwise" : "play.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.brand)
                .frame(width: 30, height: 30)
                .background(Theme.brand.opacity(0.16))
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 학습 패널

    /// 칸의 세로/가로 비. 한자는 정사각 칸에 쓰고,
    /// 읽기 연습은 히라가나 여러 글자를 가로로 쓰므로 납작한 칸이 맞다.
    private var cellRatio: CGFloat { mode == .read ? 0.62 : 1 }

    /// 쓰는 칸을 채우고 남는 세로 여백. 이 높이 안에서만 학습 내용을 보여준다.
    private func panelBudget(_ size: CGSize) -> CGFloat {
        let box = (size.width - 16) * cellRatio   // 칸은 가로폭이 상한
        let chrome: CGFloat = 44 + 2 + 52 + 24    // 헤더 · 진행 바 · 컨트롤 · 위아래 여백
        return max(0, size.height - box - chrome)
    }

    /// 지금 쓰는 한자에 대해 «쓰면서 배울» 거리를 붙인다.
    /// - 정답 공개 전(문제 모드): 같은 한자를 쓰는 다른 단어를 «〇»로 가려 보여 준다.
    ///   답을 알려주지 않으면서 «이 한자가 어디에 쓰이는 글자인지»를 단서로 준다.
    /// - 공개 후·따라 쓰기: 예문과 같은 한자를 쓰는 단어를 그대로 보여 준다.
    ///
    /// 내용이 남는 높이(budget)를 넘치면 잘라내지 않고 세로로 스크롤한다.
    @ViewBuilder
    private func learningPanel(_ step: WritingStep, size: CGSize) -> some View {
        let budget = panelBudget(size)
        if budget >= 60 {
            // 듣기 연습에서는 단어 자체가 문제라 힌트가 될 만한 줄을 공개 전까지 감춘다
            let revealAids = mode != .listen || revealed
            let related = revealAids ? relatedWords(step) : []

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 12) {
                    glossBlock(step)
                    if revealAids, let example = N3Examples.sentence(for: step.card) {
                        exampleBlock(example, word: step.card.front)
                    }
                    if !related.isEmpty {
                        relatedRow(related, kanji: step.kanji)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
            }
            .frame(height: budget)
            .padding(.horizontal, 14)
        }
    }

    /// 예문 — 단어가 실제 문장에서 어떻게 쓰이는지. 단어 부분은 브랜드 컬러로 짚어 준다.
    private func exampleBlock(_ example: N3Example, word: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionLabel("예문")
            highlightedSentence(example.japanese, word: word)
                .font(.system(size: 15, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
            Text(example.korean)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// 문장 안에서 지금 연습하는 단어만 색을 달리한 Text
    private func highlightedSentence(_ sentence: String, word: String) -> Text {
        guard let range = sentence.range(of: word) else {
            return Text(sentence).foregroundColor(Theme.textPrimary)
        }
        return Text(String(sentence[sentence.startIndex..<range.lowerBound]))
                .foregroundColor(Theme.textPrimary)
            + Text(word).foregroundColor(Theme.brand).bold()
            + Text(String(sentence[range.upperBound...]))
                .foregroundColor(Theme.textPrimary)
    }

    /// 읽기 · 뜻 · 암기 상태. 모드에 따라 답에 해당하는 칸만 가린다.
    /// - 쓰기: 읽기·뜻을 주고 한자를 감춘다
    /// - 읽기: 한자·뜻을 주고 읽기를 감춘다
    /// - 듣기: 소리만 주고 전부 감춘다
    private func glossBlock(_ step: WritingStep) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                // 듣기 연습에서는 이 자리에 다시 듣기 버튼이 온다
                if mode.speaks {
                    replayButton(step)
                }
                Text(readingVisible ? step.card.reading : "?")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(readingVisible ? Theme.brand : Theme.textQuaternary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                memoryChip(step.card)
                    .layoutPriority(1)
            }
            HStack(spacing: 6) {
                Text(meaningVisible ? step.card.meaning : "?")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(meaningVisible ? Theme.textPrimary : Theme.textQuaternary)
                    // 뜻이 길면 잘라내지 않고 줄을 늘린다 (패널이 스크롤되므로 넘쳐도 된다)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                // 읽기 연습에서는 소리로도 확인할 수 있게 해 둔다
                if mode == .read, revealed {
                    replayButton(step)
                        .layoutPriority(1)
                }
            }

            // 이 칸에 무엇을 써야 하는지 — 모드가 4개라 매번 알려 준다
            Text(mode.instruction)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textQuaternary)
                .padding(.top, 1)
        }
    }

    private func replayButton(_ step: WritingStep) -> some View {
        Button {
            speech.speak(step.card.front)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.onBrand)
                .frame(width: 32, height: 26)
                .background(Theme.brand)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("다시 듣기")
    }

    /// 이 단어를 얼마나 외웠는지 — 학습 탭의 SRS 진도를 그대로 가져온다.
    /// 이번 세션에서 이미 채점한 글자는 그 결과를 우선 보여 준다.
    private func memoryChip(_ card: LearningCard) -> some View {
        let sessionResult = currentStep.flatMap { results[$0.id] }
        let label: String
        let color: Color

        if let ok = sessionResult {
            label = ok ? "이번엔 맞음" : "이번엔 틀림"
            color = ok ? Color(accentHex: "16A34A") : Color(accentHex: "DC2626")
        } else {
            label = card.isNew ? "아직 안 외움"
                               : (card.interval >= 21 ? "숙련 · \(card.interval)일 간격"
                                                      : "\(card.statusLabel) · \(card.repetitions)회")
            color = card.statusColor
        }

        return Text(label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Theme.textQuaternary)
            .frame(height: 14)
    }

    /// 같은 한자가 들어간 다른 N3 어휘 — 한 글자를 여러 단어에서 다시 만나게 한다
    private func relatedWords(_ step: WritingStep) -> [LearningCard] {
        LearningCard.allCards
            .filter { $0.type == .vocabulary
                      && $0.id != step.card.id
                      && $0.front.contains(step.kanji) }
            .prefix(6)
            .map { $0 }
    }

    /// 같은 한자를 쓰는 단어를 한 줄에 늘어놓는다. 읽기를 함께 보여 줘야
    /// «이 글자가 이 단어에서 어떻게 읽히는지»가 같이 남는다.
    private func relatedRow(_ cards: [LearningCard], kanji: Character) -> some View {
        HStack(spacing: 8) {
            Text("같은 한자")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.textQuaternary)
                .fixedSize()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(cards) { card in
                        HStack(spacing: 4) {
                            HStack(spacing: 0) {
                                ForEach(Array(card.front.enumerated()), id: \.offset) { _, ch in
                                    let isTarget = ch == kanji
                                    Text(isTarget && !kanjiVisible ? "〇" : String(ch))
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(isTarget ? Theme.brand : Theme.textPrimary)
                                }
                            }
                            Text(card.reading)
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textTertiary)
                            Text(card.meaning)
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textQuaternary)
                                .lineLimit(1)
                        }
                        .fixedSize()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.surfaceSoft)
                        .clipShape(Capsule())
                    }
                }
                .padding(.trailing, 4)
            }
        }
        .frame(height: 26)
    }

    // MARK: - Controls

    private var controls: some View {
        Group {
            if mode == .trace {
                traceControls
            } else if revealed {
                gradingControls
            } else {
                answeringControls
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 2)
        .padding(.bottom, 4)
    }

    /// 따라 쓰기: 밑글자를 보며 그대로 옮겨 쓴다
    private var traceControls: some View {
        HStack(spacing: 6) {
            prevButton
            clearButton

            wideBtn(icon: isLastStep ? "checkmark" : "chevron.right",
                    label: isLastStep ? "완료" : "다음",
                    tint: Theme.onBrand, bg: Theme.brand) {
                advance()
            }
        }
    }

    /// 문제 풀기 — 답을 쓰는 중
    private var answeringControls: some View {
        HStack(spacing: 6) {
            prevButton
            clearButton

            wideBtn(icon: "eye.fill", label: "정답 확인",
                    tint: Theme.onBrand, bg: Theme.brand) {
                withAnimation(.easeInOut(duration: 0.2)) { revealed = true }
            }
        }
    }

    /// 문제 풀기 — 답을 보고 스스로 채점
    private var gradingControls: some View {
        HStack(spacing: 6) {
            prevButton
            clearButton

            wideBtn(icon: "xmark", label: "틀림",
                    tint: Color(accentHex: "DC2626"),
                    bg: Color(accentHex: "DC2626").opacity(0.15)) {
                grade(false)
            }

            wideBtn(icon: isLastStep ? "checkmark.circle.fill" : "checkmark",
                    label: isLastStep ? "맞음 · 완료" : "맞음",
                    tint: Theme.onBrand, bg: Theme.brand) {
                grade(true)
            }
        }
    }

    private var prevButton: some View {
        iconBtn(icon: "chevron.left", hint: "이전 글자",
                tint: stepIndex > 0 ? Theme.textSecondary : Theme.textQuaternary,
                bg: Theme.surfaceSoft) {
            goTo(stepIndex - 1)
        }
        .disabled(stepIndex == 0)
    }

    private var clearButton: some View {
        iconBtn(icon: "trash", hint: "지우기",
                tint: Theme.textSecondary,
                bg: Theme.surfaceSoft) {
            clearCurrent()
        }
    }

    private var isLastStep: Bool { stepIndex + 1 >= steps.count }

    /// 남는 폭을 차지하는 주요 동작 버튼
    private func wideBtn(icon: String, label: String,
                         tint: Color, bg: Color,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .bold))
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    /// 보조 동작은 글자 없이 아이콘만 — 이름은 보이스오버로만 읽힌다
    private func iconBtn(icon: String, hint: String,
                         tint: Color, bg: Color,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 46, height: 44)
                .background(bg)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel(hint)
    }

    // MARK: - Complete

    private var completeView: some View {
        let graded = steps.filter { results[$0.id] != nil }
        let correct = steps.filter { results[$0.id] == true }
        let wrong = steps.filter { results[$0.id] == false }

        return ScrollView {
            VStack(spacing: 20) {
                Text("🎉").font(.system(size: 60))
                Text("연습 완료!")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(Theme.textPrimary)

                Text("\(mode.label) 연습")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.brand)

                if graded.isEmpty {
                    // 따라 쓰기만 한 경우 — 채점할 것이 없다
                    Text(mode.isPerKanji
                         ? "\(wordCount)개 단어 · 한자 \(steps.count)자를 연습했습니다"
                         : "\(steps.count)개 단어를 연습했습니다")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    VStack(spacing: 6) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(correct.count)")
                                .font(.system(size: 46, weight: .black, design: .rounded))
                                .foregroundStyle(Theme.brand)
                            Text(mode.isPerKanji ? "/ \(graded.count)자 정답" : "/ \(graded.count)개 정답")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Text(mode.isPerKanji
                             ? "\(wordCount)개 단어 · 한자 \(steps.count)자 중 \(graded.count)자 채점"
                             : "\(steps.count)개 단어 중 \(graded.count)개 채점")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity)
                    .background(Theme.brand.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    if !wrong.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(mode.isPerKanji ? "다시 볼 한자 \(wrong.count)자" : "다시 볼 단어 \(wrong.count)개")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Theme.textTertiary)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)],
                                      spacing: 8) {
                                ForEach(wrong) { step in
                                    VStack(spacing: 2) {
                                        Text(mode.isPerKanji ? String(step.kanji) : step.card.front)
                                            .font(.system(size: mode.isPerKanji ? 26 : 18, weight: .bold))
                                            .foregroundStyle(Theme.textPrimary)
                                        Text(step.card.reading)
                                            .font(.system(size: 9))
                                            .foregroundStyle(Theme.textTertiary)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color(accentHex: "DC2626").opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surfaceSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                Button { setupSteps() } label: {
                    Text("다시 연습하기")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.onBrand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Theme.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
        }
    }

    // MARK: - Logic

    private func setupSteps() {
        // 진도(암기 상태)가 실린 카드를 쓴다 — 화면에 «신규/학습 중/복습/숙련»을 그대로 표시하기 위함
        let cards = store.cards.filter {
            $0.type == .vocabulary && $0.front.contains(where: { isKanji($0) })
        }
        // 쓰기·따라쓰기는 한자 한 글자가 한 문제, 읽기·듣기는 단어 하나가 한 문제다
        let perKanji = mode.isPerKanji
        steps = Array(cards.shuffled().prefix(perKanji ? 20 : 30)).flatMap { card -> [WritingStep] in
            let kanjiOffsets = card.front.enumerated().filter { isKanji($0.element) }
            let picked = perKanji ? Array(kanjiOffsets) : Array(kanjiOffsets.prefix(1))
            return picked.enumerated().map { kanjiIndex, item in
                WritingStep(card: card, kanji: item.element,
                            charOffset: item.offset,
                            kanjiIndex: kanjiIndex,
                            kanjiCount: kanjiOffsets.count)
            }
        }
        stepIndex = 0
        drawings = [:]
        results = [:]
        canvas.drawing = PKDrawing()
        sessionDone = false
        resetTools()
        speakIfNeeded()
    }

    /// 듣기 연습은 문제를 열 때마다 단어를 한 번 읽어 준다
    private func speakIfNeeded() {
        guard mode.speaks, let step = currentStep else { return }
        speech.speak(step.card.front)
    }

    /// 현재 획을 보관하고 지정한 글자로 이동. 되돌아오면 쓰던 글씨가 그대로 남는다.
    private func goTo(_ index: Int) {
        guard index >= 0, index < steps.count else { return }
        if let step = currentStep { drawings[step.id] = canvas.drawing }
        stepIndex = index
        canvas.drawing = drawings[steps[index].id] ?? PKDrawing()
        resetTools()
        // 이미 채점한 글자로 되돌아오면 정답이 보이던 상태를 유지한다
        if results[steps[index].id] != nil { revealed = true }
        speakIfNeeded()
    }

    private func clearCurrent() {
        canvas.drawing = PKDrawing()
        if let step = currentStep { drawings[step.id] = nil }
        resetTools()
    }

    private func resetTools() {
        isPlayingStrokes = false
        strokePhase = 0
        revealed = false
    }

    /// 자기 채점 후 다음 글자로. 마지막이면 결과 화면으로 넘어간다.
    private func grade(_ correct: Bool) {
        guard let step = currentStep else { return }
        results[step.id] = correct
        advance()
    }

    /// 획을 하나씩 순서대로 그린다. phase 0 → 획수 를 선형으로 움직이면
    /// StrokeShape가 자기 구간만 잘라 그리므로 순차 애니메이션이 된다.
    private func playStrokeOrder(_ kanji: Character) {
        let count = KanjiStrokes.strokeCount(for: kanji)
        guard count > 0 else { return }
        let duration = 0.42 * Double(count)

        strokePhase = 0
        isPlayingStrokes = true
        strokePlayToken += 1
        let token = strokePlayToken

        // 0으로 되돌린 값이 반영된 다음 프레임부터 애니메이션을 시작해야
        // 다시 재생할 때 처음부터 그려진다
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            withAnimation(.linear(duration: duration)) {
                strokePhase = Double(count)
            }
        }
        // 다 그린 뒤 잠깐 보여 주고 사라진다. 재생 중 다시 눌렀다면 이 예약은 무시한다.
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 1.2) {
            guard token == strokePlayToken else { return }
            withAnimation(.easeOut(duration: 0.4)) { isPlayingStrokes = false }
        }
    }

    private func advance() {
        if isLastStep {
            if let step = currentStep { drawings[step.id] = canvas.drawing }
            sessionDone = true
        } else {
            goTo(stepIndex + 1)
        }
    }
}

// MARK: - Grid Guide

private struct GridGuide: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Canvas { ctx, _ in
            let w = width, h = height
            let midX = w / 2, midY = h / 2
            ctx.stroke(
                Path(roundedRect: CGRect(x: 1, y: 1, width: w-2, height: h-2), cornerRadius: 18),
                with: .color(Theme.stroke), lineWidth: 1.5)
            var cross = Path()
            cross.move(to: CGPoint(x: midX, y: 6)); cross.addLine(to: CGPoint(x: midX, y: h-6))
            cross.move(to: CGPoint(x: 6, y: midY)); cross.addLine(to: CGPoint(x: w-6, y: midY))
            ctx.stroke(cross, with: .color(Theme.stroke.opacity(0.8)),
                       style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
            var diag = Path()
            diag.move(to: CGPoint(x: 14, y: 14)); diag.addLine(to: CGPoint(x: w-14, y: h-14))
            diag.move(to: CGPoint(x: w-14, y: 14)); diag.addLine(to: CGPoint(x: 14, y: h-14))
            ctx.stroke(diag, with: .color(Theme.stroke.opacity(0.5)), lineWidth: 1)
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }
}

// MARK: - Canvas Wrapper

private struct CanvasWrapper: UIViewRepresentable {
    let canvas: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.layer.cornerRadius = 20
        canvas.layer.masksToBounds = true
        // 도구는 펜 하나뿐이다. 부분 지우기 대신 «지우기»로 칸을 통째로 비운다.
        canvas.tool = PKInkingTool(.pen, color: Theme.inkColor, width: 8)
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
