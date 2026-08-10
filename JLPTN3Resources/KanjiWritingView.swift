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

// MARK: - Kanji Writing View

struct KanjiWritingView: View {
    @State private var steps: [WritingStep] = []
    @State private var stepIndex = 0
    @State private var drawings: [UUID: PKDrawing] = [:]
    @State private var showHint = false
    @State private var isErasing = false
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
                        canvasArea(step)
                        controls
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
                // 단어 전체를 보여주되 지금 쓸 글자만 강조
                HStack(spacing: 0) {
                    ForEach(Array(step.card.front.enumerated()), id: \.offset) { offset, ch in
                        Text(String(ch))
                            .font(.system(size: 30, weight: .black))
                            .foregroundStyle(offset == step.charOffset
                                             ? Theme.brand
                                             : Theme.textQuaternary)
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
            HStack {
                Text(step.card.meaning)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                if step.kanjiCount > 1 {
                    Text("한자 \(step.kanjiCount)자 중 \(step.kanjiIndex + 1)번째")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.brand)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Theme.brand.opacity(0.14))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Theme.backgroundElevated)
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
                if showHint {
                    Text(String(step.kanji))
                        .font(.system(size: box * 0.72, weight: .black))
                        .foregroundStyle(Theme.brand.opacity(0.22))
                        .allowsHitTesting(false)
                }
                CanvasWrapper(canvas: canvas, isErasing: isErasing)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .frame(width: box, height: box)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 8) {
            // 이전 글자
            ctrlBtn(icon: "chevron.left", label: "이전",
                    tint: stepIndex > 0 ? Theme.textSecondary : Theme.textQuaternary,
                    bg: Theme.surfaceSoft) {
                goTo(stepIndex - 1)
            }
            .disabled(stepIndex == 0)

            // 현재 글자 지우기
            ctrlBtn(icon: "trash", label: "지우기",
                    tint: Theme.textSecondary,
                    bg: Theme.surfaceSoft) {
                clearCurrent()
            }

            // 지우개 토글
            ctrlBtn(icon: isErasing ? "pencil" : "eraser",
                    label: isErasing ? "펜" : "지우개",
                    tint: isErasing ? Theme.brand : Theme.textPrimary,
                    bg: isErasing ? Theme.brand.opacity(0.15) : Theme.surfaceSoft) {
                isErasing.toggle()
            }

            // 힌트
            ctrlBtn(icon: showHint ? "eye.slash.fill" : "eye.fill",
                    label: showHint ? "힌트끄기" : "힌트",
                    tint: showHint ? Theme.brand : Theme.textPrimary,
                    bg: showHint ? Theme.brand.opacity(0.15) : Theme.surfaceSoft) {
                withAnimation(.easeInOut(duration: 0.2)) { showHint.toggle() }
            }

            // 다음 글자
            ctrlBtn(icon: isLastStep ? "checkmark" : "chevron.right",
                    label: isLastStep ? "완료" : "다음",
                    tint: Theme.onBrand,
                    bg: Theme.brand) {
                advance()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .padding(.top, 4)
    }

    private var isLastStep: Bool { stepIndex + 1 >= steps.count }

    private func ctrlBtn(icon: String, label: String,
                          tint: Color, bg: Color,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 17, weight: .semibold))
                Text(label).font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Complete

    private var completeView: some View {
        VStack(spacing: 24) {
            Text("🎉").font(.system(size: 64))
            Text("연습 완료!")
                .font(.system(size: 28, weight: .black)).foregroundStyle(Theme.textPrimary)
            Text("\(wordCount)개 단어 · 한자 \(steps.count)자를 연습했습니다")
                .font(.system(size: 16)).foregroundStyle(Theme.textSecondary)
            Button { setupSteps() } label: {
                Text("다시 연습하기")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.onBrand)
                    .padding(.horizontal, 32).padding(.vertical, 14)
                    .background(Theme.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
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
    }

    private func clearCurrent() {
        canvas.drawing = PKDrawing()
        if let step = currentStep { drawings[step.id] = nil }
        resetTools()
    }

    private func resetTools() {
        showHint = false
        isErasing = false
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
