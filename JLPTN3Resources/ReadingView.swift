import SwiftUI

// MARK: - 독해 연습
//
// 지문 목록 → 지문 화면(지문 + 문항 + 채점 + 해설).
// 시험처럼 «먼저 읽고 답을 고른 뒤 해설»의 순서를 지킨다.

struct ReadingView: View {
    @ObservedObject var store: PracticeStore
    @ObservedObject var notes: VocabNoteStore

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    summaryCard

                    ForEach(ReadingKind.allCases) { kind in
                        let passages = readingPassages.filter { $0.kind == kind }
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: kind.icon)
                                    .font(.system(size: 12, weight: .bold))
                                Text(kind.name)
                                    .font(.system(size: 15, weight: .black))
                                Text(kind.korean)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            .foregroundStyle(Theme.textPrimary)

                            ForEach(passages) { passage in
                                NavigationLink {
                                    ReadingPassageView(passage: passage, store: store, notes: notes)
                                } label: {
                                    passageRow(passage)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("독해 연습")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryCard: some View {
        let done = store.readingSolved
        let total = store.readingTotal
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(done)")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.brand)
                Text("/ \(total)문항")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                if let acc = store.readingAccuracy {
                    Text("정답률 \(Int(acc * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.brand)
                }
            }
            ProgressView(value: Double(done), total: Double(max(total, 1)))
                .tint(Theme.brand)
            Text("지문 \(readingPassages.count)개 · 실제 출제 형식(短文·中文·情報検索)으로 자체 제작")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textQuaternary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func passageRow(_ passage: ReadingPassage) -> some View {
        let finished = store.isFinished(passage)
        let correct = store.correctCount(passage)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(passage.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(passage.body.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("\(passage.questions.count)문항")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.textQuaternary)
                    Text("목표 \(passage.kind.minutesPerPassage)분")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textQuaternary)
                }
            }
            Spacer(minLength: 4)
            if finished {
                Text("\(correct)/\(passage.questions.count)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(correct == passage.questions.count
                                     ? Color(accentHex: "16A34A") : Color(accentHex: "D97706"))
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

// MARK: - 지문 화면

struct ReadingPassageView: View {
    let passage: ReadingPassage
    @ObservedObject var store: PracticeStore
    @ObservedObject var notes: VocabNoteStore

    /// 이번에 고른 답 (채점 전)
    @State private var picked: [String: Int] = [:]
    @State private var graded = false
    @State private var showVocab = false
    /// 한국어 번역을 펼쳤는지
    @State private var showTranslation = false

    private var highlighted: Set<String> {
        Set(notes.notes(for: passage.id).map { $0.word })
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // 지문 — 낱말을 누르면 형광펜이 그어지고 단어장에 담긴다
                    VStack(alignment: .leading, spacing: 12) {
                        HighlightableText(text: passage.body,
                                          fontSize: 15,
                                          highlighted: highlighted) { word in
                            notes.toggle(word: word,
                                         sourceID: passage.id,
                                         sourceTitle: passage.title,
                                         hint: passage.vocab)
                        }
                        highlightHint
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Theme.backgroundElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    translationBlock

                    // 단어 도움말 — 먼저 스스로 읽게 하려고 접어 둔다
                    DisclosureGroup(isExpanded: $showVocab) {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(passage.vocab) { v in
                                HStack(spacing: 8) {
                                    Text(v.word)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Theme.brand)
                                    Text(v.reading)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Theme.textQuaternary)
                                    Text(v.meaning)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.textSecondary)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        Text("단어 도움말 \(passage.vocab.count)개")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .tint(Theme.brand)
                    .padding(14)
                    .background(Theme.surfaceSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // 문항
                    ForEach(Array(passage.questions.enumerated()), id: \.element.id) { i, q in
                        questionBlock(index: i, question: q)
                    }

                    actionButton
                }
                .padding(16)
            }
        }
        .navigationTitle(passage.kind.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    VocabNotebookView(store: notes)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "highlighter")
                        if !notes.notes.isEmpty {
                            Text("\(notes.notes.count)")
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .foregroundStyle(Theme.brand)
                }
            }
        }
        .onAppear(perform: restorePreviousAnswers)
    }

    /// 처음 들어온 사람에게 «눌러서 담는다»는 것을 한 번 알려 준다
    @ViewBuilder
    private var highlightHint: some View {
        let count = notes.notes(for: passage.id).count
        HStack(spacing: 5) {
            Image(systemName: "highlighter")
                .font(.system(size: 10))
            Text(count > 0
                 ? "이 지문에서 \(count)개 담음 · 다시 누르면 지워집니다"
                 : "모르는 단어를 누르면 형광펜으로 표시되고 단어장에 담깁니다")
                .font(.system(size: 10))
        }
        .foregroundStyle(Theme.textQuaternary)
    }

    /// 한국어 번역 — 기본은 접힘. 먼저 일본어로 읽고 확인할 때만 연다.
    private var translationBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showTranslation.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showTranslation ? "eye.slash" : "eye")
                        .font(.system(size: 12, weight: .bold))
                    Text(showTranslation ? "번역 가리기" : "번역 보기")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Image(systemName: showTranslation ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(Theme.brand)
            }
            .buttonStyle(.plain)

            if showTranslation {
                Text(passage.translation)
                    .font(.system(size: 14))
                    .lineSpacing(5)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func questionBlock(index: Int, question: ReadingQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("問\(index + 1)  \(question.prompt)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(question.choices.enumerated()), id: \.offset) { ci, choice in
                choiceRow(question: question, index: ci, text: choice)
            }

            if graded {
                Text(question.explanation)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.brand.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func choiceRow(question: ReadingQuestion, index: Int, text: String) -> some View {
        let selected = picked[question.id] == index
        let isAnswer = question.answerIndex == index
        // 채점 뒤에는 정답을 초록, 내가 고른 오답을 빨강으로 물들인다
        let tint: Color = graded
            ? (isAnswer ? Color(accentHex: "16A34A")
                        : (selected ? Color(accentHex: "DC2626") : Theme.textSecondary))
            : (selected ? Theme.brand : Theme.textSecondary)

        return Button {
            guard !graded else { return }
            picked[question.id] = index
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Text("\(index + 1)")
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

    private var allAnswered: Bool {
        passage.questions.allSatisfy { picked[$0.id] != nil }
    }

    @ViewBuilder
    private var actionButton: some View {
        if graded {
            let correct = passage.questions.filter { picked[$0.id] == $0.answerIndex }.count
            VStack(spacing: 10) {
                Text("\(correct) / \(passage.questions.count) 정답")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Theme.brand)
                Button {
                    picked = [:]
                    graded = false
                } label: {
                    Text("다시 풀기")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Theme.surfaceSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        } else {
            Button(action: grade) {
                Text(allAnswered ? "채점하기" : "답을 모두 고르세요")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(allAnswered ? Theme.onBrand : Theme.textQuaternary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(allAnswered ? Theme.brand : Theme.surfaceSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!allAnswered)
        }
    }

    private func grade() {
        for q in passage.questions {
            store.record(readingQuestion: q.id, correct: picked[q.id] == q.answerIndex)
        }
        withAnimation(.easeInOut(duration: 0.2)) { graded = true }
    }

    /// 예전에 푼 지문을 다시 열면 그때 결과를 그대로 보여 준다
    private func restorePreviousAnswers() {
        guard picked.isEmpty, store.isFinished(passage) else { return }
        for q in passage.questions {
            // 맞았으면 정답을, 틀렸으면 «정답이 아닌 첫 선택지»를 골라 둔 것으로 되살린다
            if store.result(readingQuestion: q.id) == true {
                picked[q.id] = q.answerIndex
            } else {
                picked[q.id] = q.choices.indices.first { $0 != q.answerIndex } ?? 0
            }
        }
        graded = true
    }
}
