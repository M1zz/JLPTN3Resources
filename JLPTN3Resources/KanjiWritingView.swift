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

enum WritingMode: String, CaseIterable {
    /// 뜻과 읽기만 보고 한자를 떠올려 쓴다 (인출 연습)
    case quiz
    /// 밑글자를 따라 쓴다 (형태 익히기)
    case trace

    var label: String {
        switch self {
        case .quiz:  return "문제 풀기"
        case .trace: return "따라 쓰기"
        }
    }
}

// MARK: - Kanji Writing View

struct KanjiWritingView: View {
    @State private var steps: [WritingStep] = []
    @State private var stepIndex = 0
    @State private var drawings: [UUID: PKDrawing] = [:]
    @State private var isErasing = false
    @State private var strokePhase: Double = 0
    @State private var isPlayingStrokes = false
    /// 재생을 다시 누르면 이전 재생의 «자동 숨김» 예약을 무효화하기 위한 토큰
    @State private var strokePlayToken = 0
    // 글자마다 껐다 켜는 힌트가 아니라 «연습 방식» 설정이므로 앱을 다시 켜도 유지한다
    @AppStorage("kanjiTraceGuide") private var guideRaw = TraceGuideLevel.faint.rawValue
    @AppStorage("kanjiWritingMode") private var modeRaw = WritingMode.quiz.rawValue
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

    private var guide: TraceGuideLevel {
        TraceGuideLevel(rawValue: guideRaw) ?? .faint
    }

    private var mode: WritingMode {
        WritingMode(rawValue: modeRaw) ?? .quiz
    }

    /// 정답(밑글자·획순·획수)을 보여줘도 되는 시점.
    /// 문제 모드에서는 답을 확인하기 전까지 모두 감춘다.
    private var answerVisible: Bool {
        mode == .trace || revealed
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if sessionDone {
                    completeView
                } else if let step = currentStep {
                    VStack(spacing: 0) {
                        header(step)
                        progressBar
                        modePicker
                        canvasArea(step)
                        controls
                        strokeCredit
                    }
                } else {
                    ProgressView().tint(Theme.brand)
                }
            }
            .navigationTitle("쓰기 연습")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.backgroundElevated, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear { if steps.isEmpty { setupSteps() } }
    }

    // MARK: - Header

    private func header(_ step: WritingStep) -> some View {
        VStack(spacing: 8) {
            HStack {
                // 단어 전체를 보여주되 지금 쓸 글자만 강조.
                // 문제 모드에서는 그 글자를 «〇»로 가려 뜻과 읽기만으로 떠올리게 한다.
                HStack(spacing: 0) {
                    ForEach(Array(step.card.front.enumerated()), id: \.offset) { offset, ch in
                        let isTarget = offset == step.charOffset
                        Text(isTarget && !answerVisible ? "〇" : String(ch))
                            .font(.system(size: 30, weight: .black))
                            .foregroundStyle(isTarget ? Theme.brand : Theme.textQuaternary)
                    }
                }
                Text("  \(step.card.reading)")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Text("\(stepIndex + 1)/\(steps.count)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.textQuaternary)
            }
            HStack(spacing: 6) {
                Text(step.card.meaning)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                if step.kanjiCount > 1 {
                    chip("한자 \(step.kanjiCount)자 중 \(step.kanjiIndex + 1)번째")
                }
                // 획수는 답에 대한 힌트이므로 문제 모드에서는 확인 후에 보여준다
                let strokes = KanjiStrokes.strokeCount(for: step.kanji)
                if strokes > 0, answerVisible {
                    chip("\(strokes)획")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Theme.backgroundElevated)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Theme.brand)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Theme.brand.opacity(0.14))
            .clipShape(Capsule())
    }

    private var modePicker: some View {
        Picker("연습 모드", selection: Binding(
            get: { mode },
            set: { newValue in
                modeRaw = newValue.rawValue
                revealed = false
                isPlayingStrokes = false
            }
        )) {
            ForEach(WritingMode.allCases, id: \.rawValue) { m in
                Text(m.label).tag(m)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.top, 12)
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
        .frame(height: 3)
    }

    private var progress: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(stepIndex + 1) / Double(steps.count)
    }

    // MARK: - Canvas Area

    private func canvasArea(_ step: WritingStep) -> some View {
        GeometryReader { geo in
            let box = min(geo.size.width - 40, geo.size.height - 24)

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.canvasCell)
                GridGuide(size: box)
                if guide != .off, answerVisible {
                    Text(String(step.kanji))
                        .font(.system(size: box * 0.74, weight: .medium))
                        .foregroundStyle(Theme.textPrimary.opacity(guide.opacity))
                        .animation(.easeInOut(duration: 0.2), value: guideRaw)
                        .allowsHitTesting(false)
                }
                // 획순 안내는 밑글자 위, 필기 아래에 그린다
                if isPlayingStrokes {
                    StrokeOrderView(kanji: step.kanji, phase: strokePhase, size: box)
                }

                CanvasWrapper(canvas: canvas, isErasing: isErasing)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .frame(width: box, height: box)
            // 획순 버튼은 반드시 overlay로 얹는다.
            // ZStack 안에서 .frame(maxWidth:.infinity, maxHeight:.infinity)로 감싸면
            // 그 프레임이 Button 자신의 크기가 되어 칸 전체가 터치 영역이 되고,
            // 필기 입력이 전부 버튼에 먹힌다.
            .overlay(alignment: .topTrailing) {
                if KanjiStrokes.hasData(for: step.kanji), answerVisible {
                    strokeOrderButton(step.kanji)
                        .padding(10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.vertical, 12)
    }

    private func strokeOrderButton(_ kanji: Character) -> some View {
        Button {
            playStrokeOrder(kanji)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: isPlayingStrokes ? "arrow.clockwise" : "play.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("획순")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(Theme.brand)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.brand.opacity(0.16))
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Controls

    private var controls: some View {
        Group {
            switch mode {
            case .trace:
                traceControls
            case .quiz:
                revealed ? AnyView(gradingControls) : AnyView(answeringControls)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    /// 따라 쓰기: 밑글자를 보며 그대로 옮겨 쓴다
    private var traceControls: some View {
        HStack(spacing: 8) {
            prevButton
            clearButton
            eraserButton

            // 밑글자 진하기 (흐리게 → 진하게 → 없음)
            ctrlBtn(icon: guide.icon,
                    label: guide.label,
                    tint: guide == .off ? Theme.textQuaternary
                                        : (guide == .strong ? Theme.brand : Theme.textPrimary),
                    bg: guide == .strong ? Theme.brand.opacity(0.15) : Theme.surfaceSoft) {
                guideRaw = guide.next.rawValue
            }

            ctrlBtn(icon: isLastStep ? "checkmark" : "chevron.right",
                    label: isLastStep ? "완료" : "다음",
                    tint: Theme.onBrand,
                    bg: Theme.brand) {
                advance()
            }
        }
    }

    /// 문제 풀기 — 답을 쓰는 중
    private var answeringControls: some View {
        HStack(spacing: 8) {
            prevButton
            clearButton
            eraserButton

            wideBtn(icon: "eye.fill", label: "정답 확인",
                    tint: Theme.onBrand, bg: Theme.brand) {
                withAnimation(.easeInOut(duration: 0.2)) { revealed = true }
            }
        }
    }

    /// 문제 풀기 — 답을 보고 스스로 채점
    private var gradingControls: some View {
        HStack(spacing: 8) {
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
        ctrlBtn(icon: "chevron.left", label: "이전",
                tint: stepIndex > 0 ? Theme.textSecondary : Theme.textQuaternary,
                bg: Theme.surfaceSoft) {
            goTo(stepIndex - 1)
        }
        .disabled(stepIndex == 0)
    }

    private var clearButton: some View {
        ctrlBtn(icon: "trash", label: "지우기",
                tint: Theme.textSecondary,
                bg: Theme.surfaceSoft) {
            clearCurrent()
        }
    }

    private var eraserButton: some View {
        ctrlBtn(icon: isErasing ? "pencil" : "eraser",
                label: isErasing ? "펜" : "지우개",
                tint: isErasing ? Theme.brand : Theme.textPrimary,
                bg: isErasing ? Theme.brand.opacity(0.15) : Theme.surfaceSoft) {
            isErasing.toggle()
        }
    }

    private var strokeCredit: some View {
        Text("획순 데이터 © KanjiVG · CC BY-SA 3.0")
            .font(.system(size: 9))
            .foregroundStyle(Theme.textQuaternary)
            .padding(.top, 6)
            .padding(.bottom, 12)
    }

    private var isLastStep: Bool { stepIndex + 1 >= steps.count }

    /// 남는 폭을 차지하는 주요 동작 버튼
    private func wideBtn(icon: String, label: String,
                         tint: Color, bg: Color,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 14, weight: .bold))
                Text(label).font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func ctrlBtn(icon: String, label: String,
                          tint: Color, bg: Color,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 17, weight: .semibold))
                Text(label).font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: mode == .trace ? .infinity : 62)
            .padding(.vertical, 11)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
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

                if graded.isEmpty {
                    // 따라 쓰기만 한 경우 — 채점할 것이 없다
                    Text("\(wordCount)개 단어 · 한자 \(steps.count)자를 연습했습니다")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    VStack(spacing: 6) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(correct.count)")
                                .font(.system(size: 46, weight: .black, design: .rounded))
                                .foregroundStyle(Theme.brand)
                            Text("/ \(graded.count)자 정답")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Text("\(wordCount)개 단어 · 한자 \(steps.count)자 중 \(graded.count)자 채점")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity)
                    .background(Theme.brand.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    if !wrong.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("다시 볼 한자 \(wrong.count)자")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Theme.textTertiary)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)],
                                      spacing: 8) {
                                ForEach(wrong) { step in
                                    VStack(spacing: 2) {
                                        Text(String(step.kanji))
                                            .font(.system(size: 26, weight: .bold))
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
        let cards = LearningCard.allCards.filter {
            $0.type == .vocabulary && $0.front.contains(where: { isKanji($0) })
        }
        steps = Array(cards.shuffled().prefix(20)).flatMap { card -> [WritingStep] in
            let kanjiOffsets = card.front.enumerated().filter { isKanji($0.element) }
            return kanjiOffsets.enumerated().map { kanjiIndex, item in
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
    }

    private func clearCurrent() {
        canvas.drawing = PKDrawing()
        if let step = currentStep { drawings[step.id] = nil }
        resetTools()
    }

    private func resetTools() {
        isErasing = false
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
    let size: CGFloat
    var body: some View {
        Canvas { ctx, _ in
            let s = size, mid = s / 2
            ctx.stroke(
                Path(roundedRect: CGRect(x: 1, y: 1, width: s-2, height: s-2), cornerRadius: 18),
                with: .color(Theme.stroke), lineWidth: 1.5)
            var cross = Path()
            cross.move(to: CGPoint(x: mid, y: 6)); cross.addLine(to: CGPoint(x: mid, y: s-6))
            cross.move(to: CGPoint(x: 6, y: mid)); cross.addLine(to: CGPoint(x: s-6, y: mid))
            ctx.stroke(cross, with: .color(Theme.stroke.opacity(0.8)),
                       style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
            var diag = Path()
            diag.move(to: CGPoint(x: 14, y: 14)); diag.addLine(to: CGPoint(x: s-14, y: s-14))
            diag.move(to: CGPoint(x: s-14, y: 14)); diag.addLine(to: CGPoint(x: 14, y: s-14))
            ctx.stroke(diag, with: .color(Theme.stroke.opacity(0.5)), lineWidth: 1)
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }
}

// MARK: - Canvas Wrapper

private struct CanvasWrapper: UIViewRepresentable {
    let canvas: PKCanvasView
    let isErasing: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.layer.cornerRadius = 20
        canvas.layer.masksToBounds = true
        syncTool(canvas)
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // uiView == canvas (같은 참조). isErasing 변경 시 도구 전환
        syncTool(uiView)
    }

    private func syncTool(_ cv: PKCanvasView) {
        if isErasing {
            cv.tool = PKEraserTool(.vector)
        } else {
            cv.tool = PKInkingTool(.pen, color: Theme.inkColor, width: 8)
        }
    }
}
